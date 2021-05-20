"""
Data model for battle game lobbies.
"""
from datetime import datetime
import enum
from typing import Optional
import uuid

import grpc
import mongoengine as me

from auth import security
from db.models import ship
from db.models import user
from util import error

def _uuid() -> str:
    return str(uuid.uuid4())

class State(enum.Enum):
    PREGAME = 'PREGAME'

class Crew(me.EmbeddedDocument):
    """Defines a single team's ship in the lobby."""
    crew_id = me.StringField(required=True, default=_uuid)

    name = me.StringField(required=True)
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

    time_limit = me.IntField(min_value=0, required=True, default=300)

    def get_crew(self, crew_id: str) -> Optional[Crew]:
        for crew in self.crews:
            if crew.crew_id == crew_id:
                return crew
        return None

    def new_crew(self, crew_name: str) -> None:
        self.crews.append(Crew(name=crew_name))

    def delete_crew(self, crew_id: str) -> None:
        the_crew = self.get_crew(crew_id)
        if the_crew is None:
            raise error.SpbError(f'Crew {crew_id} not found.',
                                 404, grpc.StatusCode.NOT_FOUND)
        self.crews.remove(crew_id)

    def remove_from_crews(self, the_user: user.User) -> None:
        assert the_user.current_lobby == self

        for crew in self.crews:
            if the_user in crew.crewmates:
                crew.cremates.remove(the_user)
        if the_user not in self.uncrewed_users:
            self.uncrewed_users.append(the_user)

    def add_to_crew(self, the_user: user.User, crew_id: str) -> None:
        assert the_user.current_lobby == self

        self.remove_from_crews(the_user)
        self.uncrewed_users.remove(the_user)
        the_crew = self.get_crew(crew_id)
        if the_crew is None:
            raise error.SpbError(f'Crew {crew_id} not found.',
                                 404, grpc.StatusCode.NOT_FOUND)
        the_crew.crewmates.append(the_user)


    def add_user(self, the_user: user.User, password: Optional[str]) -> None:
        if the_user.current_lobby is not None:
            raise error.SpbError(f'User {the_user.id} is already in a lobby',
                                 400, grpc.StatusCode.FAILED_PRECONDITION)

        if not self.password_matches(password):
            raise error.SpbError('Incorrect password!',
                                 401, grpc.StatusCode.PERMISSION_DENIED)
        the_user.current_lobby = self
        self.uncrewed_users.append(the_user)
        self.save()
        the_user.save()

    def remove_user(self, the_user: user.User) -> None:
        if the_user.current_lobby != self:
            raise error.SpbError(f'User {the_user.id} is not in this lobby',
                                 400, grpc.StatusCode.FAILED_PRECONDITION)

        the_user.current_lobby = None
        self.remove_from_crews(the_user)
        self.uncrewed_users.remove(the_user)

        # TODO(hunter): Special case when the host is removed.
        self.save()
        the_user.save()

    def password_matches(self, password: Optional[str]) -> bool:
        """Returns true if this |password| matches the hash on this lobby."""
        if not password:
            if self.password_hash == '':
                return True
            return False
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
