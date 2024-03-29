"""
Lightweight wrapper around a websocket to allow sending messages
and receiving responses.
"""
from datetime import datetime
import json
import threading
from typing import Optional
import uuid

from absl import logging

class WSManager:

    def __init__(self, ws) -> None:
        self._ws = ws

        # Hold onto the CVs and responses for each request.
        self._req_cvs = {}
        self._req_res = {}

        self._alive_cv = threading.Condition()
        self._alive = True

        self._run_thread = threading.Thread(target=self._run)
        self._run_thread.start()


    def alive(self) -> bool:
        return self._alive

    def wait(self) -> None:
        """Block until the connection dies."""
        with self._alive_cv:
            self._alive_cv.wait_for(lambda: not self._alive)

    def _run(self) -> None:
        """Runs the WSManager until the connection closes."""
        try:
            while not self._ws.closed:
                message = self._ws.receive()
                if message is None:
                    continue
                data = json.loads(message.decode())
                req_id = data.get('req_id')
                if not req_id:
                    logging.error('Got invalid response: %s', message)
                    continue

                if req_id not in self._req_cvs:
                    logging.error('Got unexpected response: %s', message)
                    continue

                with self._req_cvs[req_id]:
                    data['timestamp'] = datetime.now().timestamp()
                    self._req_res[req_id] = data
                    self._req_cvs[req_id].notify_all()
        finally:
            self._alive = False
            self._free_all_reqs()
            with self._alive_cv:
                self._alive_cv.notify_all()

    def send(self, data: dict,
             timeout: Optional[float] = None) -> Optional[dict]:
        """Sends a message over this websocket, blocking until a
        response is received or the connection closes."""
        if not self._alive:
            return None

        req_id = str(uuid.uuid4())[:8]
        data['req_id'] = req_id

        message = json.dumps(data).encode()
        cv = threading.Condition()
        self._req_cvs[req_id] = cv
        with cv:
            self._ws.send(message)
            not_timeout = cv.wait(timeout=timeout)

        if not not_timeout:
            logging.warning('Request timeout req_id=%s', req_id)
            del self._req_cvs[req_id]
            return None
        res = self._req_res.get(req_id)
        del self._req_cvs[req_id]
        del self._req_res[req_id]
        return res

    def _free_all_reqs(self) -> None:
        """Free all in-progress requests."""
        for req_id, cv in self._req_cvs.items():
            with cv:
                self._req_res[req_id] = None
                cv.notify_all()
