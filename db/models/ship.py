"""
Basic data model for an instantiated ship.
"""
import mongoengine as me


BlueprintField = me.ListField(me.DictField())


class Ship(me.Document):
    """Information about a given SPB ship/station."""
    meta = {'allow_inheritance': True}

    blueprint = BlueprintField

    def to_dict(self) -> dict:
        return dict(blueprint=self.blueprint)


class VirtualShip(Ship):
    """A ship that exists only in a given simulator battle."""

class OverworldShip(Ship):
    """A ship that exists in the game's overworld."""
    name = me.StringField(
        min_length=1, max_length=20,
        required=True, unique=True,
        regex='[A-z\d_]+')

    owner = me.ReferenceField('User')

class SpaceStation(OverworldShip):
    spawnable = me.BooleanField()

    @classmethod
    def get_random_player_spawn(cls) -> 'SpaceStation':
        """Get a random player spawn station."""
        pipeline = [
            {'$match' : {'spawnable': True}},
            {'$sample': {'size': 1}},
            {'$project': {'_id': 1}},
        ]
        spawn = next(iter(cls.objects().aggregate(pipeline)), None)
        assert spawn is not None
        return spawn['_id']
