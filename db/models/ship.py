"""
Basic data model for an instantiated ship.
"""
import mongoengine as me


class Ship(me.Document):
    """Information about a given SPB ship/station."""
    meta = {'allow_inheritance': True}

    blueprint = me.ListField(me.DictField())

class VirtualShip(Ship):
    """A ship that exists only in a given simulator battle."""

class OverworldShip(Ship):
    """A ship that exists in the game's overworld."""
    name = me.StringField(
        min_length=1, max_length=20,
        required=True, unique=True,
        regex='[A-z\d_]+')

    owner = me.ReferenceField('User')
