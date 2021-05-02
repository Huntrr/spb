"""
Data model for battle game lobbies.
"""
import mongoengine as me

from auth import security
from db.models import ship
from db.models import user

class Crew(me.EmbeddedDocument):
    """Defines a single team's ship in the lobby."""
    team = me.IntField(min_value=0, max_value=6, required=True, default=0)

    # Ship used by this crew.
    blueprint = ship.BlueprintField

    crewmates = me.ListField(me.ReferenceField(user.User))


class Lobby(me.Document):
    """Describes a battle game lobby."""
    name = me.StringField(regex=r'^[A-z\d_\' ]+$', required=True)
    host = me.ReferenceField(user.User, required=True)
    password_hash = me.StringField(max_length=256)

    uncrewed_users = me.ListField(me.ReferenceField(user.User))
    crews = me.EmbeddedDocumentListField(Crew)

    time_limit = me.IntField(min_value=0, required=True, default=0)

    def password_matches(self, password: str) -> bool:
        """Returns true if this |password| matches the hash on this lobby."""
        return security.pwd_context.verify(password, self.password_hash)

    def set_password(self, password: str) -> None:
        """Salts, hashes, and sets a new password for this lobby."""
        self.password_hash = security.pwd_context.hash(password)
