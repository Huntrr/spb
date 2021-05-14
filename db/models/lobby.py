"""
Data model for battle game lobbies.
"""
from datetime import datetime
import enum
import uuid

import mongoengine as me

from auth import security
from db.models import ship
from db.models import user

def _uuid() -> str:
    return str(uuid.uuid4())

class State(enum.Enum):
    PREGAME = 'PREGAME'

class Crew(me.EmbeddedDocument):
    """Defines a single team's ship in the lobby."""
    crew_id = me.StringField(required=True, default=_uuid)
    team = me.IntField(min_value=0, max_value=6, required=True, default=0)

    # Ship used by this crew.
    blueprint = ship.BlueprintField

    crewmates = me.ListField(me.ReferenceField(user.User))

    def to_dict(self) -> dict:
        """Returns a client-friendly dictionary representation of the crew."""
        return dict(
            crew_id=self.crew_id,
            team=self.team,
            blueprint=self.blueprint,
            crewmates=[user.to_dict() for user in self.crewmates])


class Lobby(me.Document):
    """Describes a battle game lobby."""
    created_at = me.DateTimeField(default=datetime.utcnow)
    state = me.EnumField(State, default=State.PREGAME)

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

    def to_dict(self) -> dict:
        """Returns a client-friendly dictionary representation of the
        lobby.
        """
        has_password = self.password_hash != ''
        return dict(
            state=self.state.value,
            name=self.name,
            host=self.host.to_dict(),
            has_password=has_password,
            uncrewed_users=[user.to_dict() for user in self.uncrewed_users],
            crews=[crew.to_dict() for crew in crews],
            time_limit=self.time_limit)
