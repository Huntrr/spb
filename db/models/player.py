"""
Basic data model for a player.
"""
import mongoengine as me

from db.models import ship as _ship


class Outfit(me.EmbeddedDocument):
    base = me.IntValue(min_value=1, required=True, default=1)
    shirt = me.IntValue(min_value=1, required=True, default=1)
    pants = me.IntValue(min_value=1, required=True, default=1)
    eyes = me.IntValue(min_value=1, required=True, default=1)

    def to_dict(self) -> dict:
        return dict(
            base=self.base,
            shirt=self.shirt,
            pants=self.pants,
            eyes=self.eyes)


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
    outfit = me.EmbeddedDocumentField(Outfit, default=Outfit)

    def to_dict(self) -> dict:
        return dict(
            location=self.location.to_dict(),
            outfit=self.outfit.to_dict())
