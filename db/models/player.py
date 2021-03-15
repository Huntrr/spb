"""
Basic data model for a player.
"""
import mongoengine as me

from db.models import ship


class Player(me.EmbeddedDocument):
    """Stores game-relevant information about a specific user."""
    location_ship = me.ReferenceField(
        ship.Ship,
        required=True,
        default=ship.SpaceStation.get_random_player_spawn)
