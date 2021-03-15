"""
Manages socket connections from the gateway to various game servers.
"""
from db.models import ship
from lib import redis_client

class GameServerManager:

    def __init__(self):
        """Constructs a new GameServerManager."""
        self._r = redis_client.redis_client()
        self._p = self._r.pubsub()

    def get_or_make_game_server(self, the_ship: ship.Ship) -> str:
        """Returns a server IP that can host players on a given ship."""
        pass
