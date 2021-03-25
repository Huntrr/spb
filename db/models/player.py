"""
Basic data model for a player.
"""
import mongoengine as me

from db.models import ship as _ship


class Location(me.EmbeddedDocument):
    ship = me.ReferenceField(
        _ship.Ship,
        required=True,
        default=_ship.SpaceStation.get_random_player_spawn)

    def to_dict(self) -> dict:
        return dict(ship_id=str(self.ship.id))


class Player(me.EmbeddedDocument):
    """Stores game-relevant information about a specific user."""
    location = me.EmbeddedDocumentField(Location, default=Location)

    def to_dict(self) -> dict:
        return dict(location=self.location.to_dict())
