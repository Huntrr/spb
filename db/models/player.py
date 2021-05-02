"""
Basic data model for a player.
"""
import re

import mongoengine as me

from db.models import ship as _ship

_COLOR_REGEXP = r'^[\da-f]{6}$'

class Outfit(me.EmbeddedDocument):
    base = me.IntField(min_value=1, max_value=1, required=True, default=1)
    base_color = me.StringField(
        regex=_COLOR_REGEXP, required=True, default='663931')
    shirt = me.IntField(min_value=1, max_value=1, required=True, default=1)
    shirt_color = me.StringField(
        regex=_COLOR_REGEXP, required=True, default='301270')
    pants = me.IntField(min_value=1, max_value=1, required=True, default=1)
    pants_color = me.StringField(
        regex=_COLOR_REGEXP, required=True, default='1c1c1c')

    eyes = me.IntField(min_value=1, max_value=2, required=True, default=1)
    mouth = me.IntField(min_value=1, max_value=2, required=True, default=1)

    def to_dict(self) -> dict:
        return dict(
            base=self.base,
            base_color=self.base_color,
            shirt=self.shirt,
            shirt_color=self.shirt_color,
            pants=self.pants,
            pants_color=self.pants_color,
            eyes=self.eyes,
            mouth=self.mouth)

    def update_from_dict(self, outfit) -> None:
        fields = [
            'base',
            'base_color',
            'shirt',
            'shirt_color',
            'pants',
            'pants_color',
            'eyes',
            'mouth']
        for field in fields:
            setattr(self, field, outfit[field])


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
