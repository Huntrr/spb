"""
Manages socket connections from the gateway to various game servers.

TODO(hunter): Test this logic... :/
"""
from concurrent import futures
from datetime import datetime, timedelta
import json
import threading
import time
from typing import Optional, Tuple

from absl import logging
import grpc

from db.models import ship
from gateway import ws_manager
from lib import redis_client
from util import error

_POLL_INTERVAL = 1  # How often we poll the servers.
_ALLOWED_MISSES = 3  # How many misses are allowed before a server is ignored.
_POLL_TIMEOUT = 5  # How long we wait for a response to the poll request.

_LOCK_TIMEOUT = 60  # How long Redis room status locks last.
_WAIT_INTERVAL = 0.2  # Interval we poll at to see if the room was created.
_SEARCH_TIMEOUT = timedelta(minutes=1)  # How long we spend waiting for a room.

_MAX_EXECUTORS = 20  # Max concurrency of the request workers.

# Arbitrary Redis labels.
_REDIS_PREFIX = 'GS'
_LOCK_PREFIX = f'{_REDIS_PREFIX}_LOCK'

_SHIP_KEY = f'{_REDIS_PREFIX}_SHIP'
_STATUS_KEY = f'{_REDIS_PREFIX}_STATUS'
_PUBSUB_TOPIC = f'{_REDIS_PREFIX}_PUBSUB.requests'

class GameServerManager:

    def __init__(self):
        """Constructs a new GameServerManager."""
        self._r = redis_client.redis_client()
        self._p = self._r.pubsub()
        self._p.subscribe(**{_PUBSUB_TOPIC: self._handle_request})
        self._p_thread = self._p.run_in_thread(sleep_time=0.001)

        self._server_managers = {}
        self._server_statuses = {}
        self._server_accesses = {}

        self._poll_thread = threading.Thread(target=self._poll_thread_fn)
        self._poll_lock = threading.Lock()

        self._request_executor = futures.ThreadPoolExecutor(_MAX_EXECUTORS)

    def register_server(self, server_ip: str,
                        manager: ws_manager.WSManager) -> None:
        status = manager.send({'type': 'PING'}, timeout=_POLL_TIMEOUT)
        if not status:
            # Couldn't finish handshake, reject the ws connection.
            raise error.SpbError('Unable to register server %s', server_ip)

        with self._poll_lock:
            self._server_managers[server_ip] = manager
            self._set_status(server_ip, status)

    def get_or_make_ship_server(self, the_ship: ship.Ship) -> Tuple[str, str]:
        """Returns a (server IP, room ID) pair that can host players on a given
        ship."""
        ship_id = str(the_ship.id)
        logging.info('Looking for room for ship_id=%s', ship_id)

        started = datetime.now()
        while datetime.now() - started < _SEARCH_TIMEOUT:
            try:
                with self._lock(ship_id):
                    server = self._r.hget(_SHIP_KEY, ship_id)

                    if server is not None:
                        now = datetime.now().timestamp()
                        [server_ip, room_id] = server.split(',')
                        status = json.loads(
                            self._r.hget(_STATUS_KEY, server_ip) or '{}')

                        if not status or (now - status['timestamp'] >
                                          _POLL_INTERVAL * _ALLOWED_MISSES):
                            # Server hasn't been healthy in too long.
                            glog.warning(
                                'Ship server %s hasn\'t reported in too long',
                                server_ip)
                            self._r.hdel(_SHIP_KEY, ship_id)
                        elif room_id not in status['ship_rooms']:
                            # This server no longer has this room.
                            glog.warning(
                                'Room %s on ship server %s is missing',
                                server_ip)
                            self._r.hdel(_SHIP_KEY, ship_id)
                        else:
                            return server_ip, room_id

                    # Failed to find a usable server, request to create one.
                    glog.info('Couldn\'t find room for ship_id %s', ship_id)
                    self._r.publish(_PUBSUB_TOPIC, f'CREATE_SHIP,{ship_id}')
            except LockError:
                raise error.SpbError(
                    'Error finding a game server', 500, grpc.StatusCode.UNKNOWN)


            logging.info(
                'Couldn\'t find a valid game server... Waiting for creation.')
            while datetime.now() - started < _SEARCH_TIMEOUT:
                time.sleep(_WAIT_INTERVAL)
                if self._r.hexists(_SHIP_KEY, ship_id):
                    break

        raise error.SpbError(
            'Timed out searching a game server',
            504,
            grpc.StatusCode.DEADLINE_EXCEEDED)

    def _create_ship_room(self, ship_id: str) -> None:
        """Works with the connected gameservers to create a room for |ship_id|.
        """
        ordered_servers = [
            server_ip for server_ip, _ in
            sorted(self._server_statuses.items(), key=self._server_sort_key)
        ]
        for server_ip in ordered_servers:
            with self._lock(ship_id):
                if self._r.hexists(_SHIP_KEY, ship_id):
                    # Someone beat us to it! The room already exists.
                    return
                with self._poll_lock:
                    manager = self._server_managers[server_ip]
                    self._server_accesses[server_ip] = time.time()
                    response = manager.send({
                        'type': 'CREATE_SHIP',
                        'ship_id': ship_id,
                    })
                    if response and response['successful']:
                        value = f'{server_ip},{response["room_id"]}'
                        self._hset(_SHIP_KEY, ship_id, value)
                        return


    def _handle_request(self, message) -> None:
        if message['type'] == 'message':
            [command, data] = message['data'].split(',')
            if command == 'CREATE_SHIP':
                self._request_executor.submit(self._create_ship_room, data)
            else:
                raise NotImplementedError(f'Unknown command {command}')

    def _poll_thread_fn(self) -> None:
        """Continuously poll the registered servers."""
        while True:
            with self._poll_lock:
                to_delete = set()
                for server_ip, manager in self._server_managers.items():
                    status = self._poll(server_ip)
                    if not status:
                        if not manager.alive():
                            # This manager is dead; clean it up.
                            to_delete.add(server_ip)
                        else:
                            logging.warning('Game server %s is undead',
                                            server_ip)
                        continue

                    self._set_status(server_ip, status)

                for server_ip in to_delete:
                    logging.info('Cleaning up dead game server %s', server_ip)
                    del self._server_managers[server_ip]
                    del self._server_statuses[server_ip]
                    del self._server_accesses[server_ip]

            time.sleep(_POLL_INTERVAL)

    def _lock(self, location_id: str) -> 'RedisLock':
        return self._r.lock(
            f'{_LOCK_PREFIX}_{location_id}', timeout=_LOCK_TIMEOUT)

    def _set_status(self, server_ip: str, status: dict) -> None:
        status['last_healthy'] = datetime.now().timestamp()
        self._r.hset(_STATUS_KEY, server_ip, status)
        self._server_statuses[server_ip] = status

    def _poll(self, server_ip: str) -> Optional[dict]:
        """Polling pings the |server_ip| (which must have already been registered,
        and returns a status, containing a struct like:
        {
            timestamp: float,
            total_pop: int,
            ship_rooms: {
                <room_id>: {
                    ship_id: str,
                    pop: int,
                },
            },
        }

        Returns None on failure.
        """
        manager = self._server_managers[server_ip]
        return manager.send({'type': 'PING'}, timeout=_POLL_TIMEOUT)

    def _server_sort_key(self,
                         server_status: Tuple[str, dict]) -> Tuple[int, float]:
        # Sort by ascending server population with tie breakers preferring
        # servers we haven't contacted recently.
        server_ip, status = server_status
        total_pop = status['total_pop']
        last_access = self._server_accesses.get(server_ip, 0)
        return total_pop, last_access


