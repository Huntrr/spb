"""
Basic data model for a server authentication singleton.
"""
from datetime import datetime, timedelta

import grpc
import jwt
import mongoengine as me

from auth import jwt_context, security
from util import error


_LEEWAY = timedelta(seconds=1)

class ServerAuth(me.Document):
    """Model for SPB server authentication singleton."""

    last_updated = me.DateTimeField(default=datetime.utcnow)
    auth_key_hash = me.StringField()

    @classmethod
    def _get_singleton(cls) -> 'ServerAuth':
        """Gets the singleton ServerAuth object."""
        assert cls.objects().count() <= 1
        server_auth = cls.objects().first()

        if server_auth is None:
            server_auth = cls()
            server_auth.save()

        return server_auth

    @classmethod
    def from_jwt(cls, token: str) -> 'ServerAuth':
        try:
            server = jwt_context.decode(token)
        except jwt.exceptions.JWTException:
            raise error.SpbError('Invalid auth token', 408,
                                 grpc.StatusCode.UNAUTHENTICATED)

        server_auth = cls._get_singleton()

        if (server['iat'] <
                server_auth.last_updated.replace(tzinfo=None) - _LEEWAY):
            raise error.SpbError('JWT has been expired', 408,
                                 grpc.StatusCode.UNAUTHENTICATED)
        return server_auth

    @classmethod
    def get_jwt(cls, auth_key: str) -> str:
        """Returns a JWT authenticating as a valid server."""
        server_auth = cls._get_singleton()
        if not server_auth.key_matches(auth_key):
            raise error.SpbError('Invalid auth key',
                                 http_code=401,
                                 spb_code=grpc.StatusCode.PERMISSION_DENIED)

        server = dict(
            type='server',
            id=str(server_auth.id))
        return jwt_context.encode(server)

    @classmethod
    def set_key(cls, auth_key: str) -> None:
        """Salts, hashes, and sets a new auth for the server."""
        server_auth = cls._get_singleton()

        server_auth.last_updated = datetime.utcnow()
        server_auth.auth_key_hash = security.pwd_context.hash(auth_key)
        server_auth.save()

    def key_matches(self, auth_key: str) -> bool:
        """Returns true if this |auth_key| matches the hash on this server
        auth.
        """
        return security.pwd_context.verify(auth_key, self.auth_key_hash)
