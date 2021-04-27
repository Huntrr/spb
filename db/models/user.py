"""
Basic data model for a user.
"""
from datetime import datetime, timedelta

import bson
import grpc
import jwt
import mongoengine as me

from auth import jwt_context, security
from db.models import player
from util import error

_JWT_EXPIRE_TIME = timedelta(days=7)
_LEEWAY = timedelta(seconds=1)


class User(me.Document):
    """Base model for all SPB users."""
    meta = {'allow_inheritance': True}
    last_active = me.DateTimeField(default=datetime.utcnow)
    last_login = me.DateTimeField()

    # Game data for this user.
    player = me.EmbeddedDocumentField(player.Player, default=player.Player)

    def touch(self) -> None:
        """Update the last_active field on this user."""
        self.last_active = datetime.utcnow()
        self.save()

    @classmethod
    def pre_save(cls, sender, document):
        document.last_active = datetime.utcnow()

    @classmethod
    def from_jwt(cls, token):
        try:
            user = jwt_context.decode(token)
        except jwt.exceptions.JWTException:
            raise error.SpbError('Invalid auth token', 408,
                                 grpc.StatusCode.UNAUTHENTICATED)

        object_id = bson.objectid.ObjectId(user['id'])
        the_user = cls.objects(id=object_id).first()

        if the_user is None:
            raise error.SpbError('That user no longer exists', 400,
                                 grpc.StatusCode.UNAUTHENTICATED)
        if user['iat'] < the_user.last_login.replace(tzinfo=None) - _LEEWAY:
            raise error.SpbError('JWT has been expired', 408,
                                 grpc.StatusCode.UNAUTHENTICATED)
        return the_user

# Hook up the pre_save signal.
me.signals.pre_save.connect(User.pre_save, sender=User)


class GuestUser(User):
    """Special user subtype for guest accounts."""
    guest_id = me.SequenceField(required=True, unique=True, sparse=True)

    # Guest names do not have to be unique.
    guest_name = me.StringField(
        min_length=1, max_length=20, required=True,
        regex=r'^[A-z\d_]+$')

    def get_name(self) -> str:
        return self.guest_name

    def get_jwt(self) -> str:
        """Returns a JWT authenticating as this user."""
        self.last_login = datetime.utcnow()
        self.save()

        user = dict(
            type='player',
            id=str(self.id),
            guest_id=self.guest_id,
            name=self.get_name(),
        )
        return jwt_context.encode(user, _JWT_EXPIRE_TIME)


class NonGuestUser(User):
    """Base for all permanent non-guest users."""
    user_id = me.SequenceField(required=True, unique=True, sparse=True)

    user_name = me.StringField(
        min_length=1, max_length=20,
        required=True, unique=True,
        sparse=True, regex=r'^[A-z\d_]+$')

    def get_name(self) -> str:
        return self.user_name


class EmailUser(NonGuestUser):
    """A basic email/password-identified user."""
    email = me.EmailField(required=True, unique=True, sparse=True)
    email_verification_code = me.StringField(max_length=256)
    email_date_verified = me.DateTimeField()

    password_hash = me.StringField(max_length=256, required=True)

    def password_matches(self, password: str) -> bool:
        """Returns true if this |password| matches the hash on this user."""
        return security.pwd_context.verify(password, self.password_hash)

    def is_activated(self) -> bool:
        """Returns true if the user's email has been verified."""
        return self.email_data_verified is not None

    def set_password(self, password: str) -> None:
        """Salts, hashes, and sets a new password for this user."""
        if len(password) < 8:
            raise error.SpbError(
                'Password must be at least 8 characters',
                400, grpc.StatusCode.INVALID_ARGUMENT)

        if password == 'password':
            raise error.SpbError(
                'Password cannot be password',
                400, grpc.StatusCode.INVALID_ARGUMENT)

        self.password_hash = security.pwd_context.hash(password)

    def activate_email(self, verification_code: str) -> None:
        """Activates this user's email if the |verification| code is correct."""
        if self.email_date_verified is not None:
            raise ValueError(f'Account already verified.')

        if verification_code != self.email_verification_code:
            raise ValueError('Invalid verification code.')

        self.email_date_verified = datetime.utcnow()
        self.email_verification_code = None

    def get_jwt(self, password: str) -> str:
        """Returns a JWT authenticating as this user."""
        if not self.password_matches(password):
            raise error.SpbError('Invalid email/password',
                                 http_code=401,
                                 spb_code=grpc.StatusCode.PERMISSION_DENIED)

        if self.email_date_verified is None:
            raise error.SpbError('Email is not verified',
                                 http_code=403,
                                 spb_code=grpc.StatusCode.FAILED_PRECONDITION)

        self.last_login = datetime.utcnow()
        self.save()

        user = dict(
            type='player',
            id=str(self.id),
            user_id=self.user_id,
            email=self.email,
            name=self.get_name())
        return jwt_context.encode(user, _JWT_EXPIRE_TIME)
