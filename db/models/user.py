"""
Basic data model for a user.
"""
from datetime import datetime, timedelta

import mongoengine as me

from auth import jwt_context, security
from db.models import player

_JWT_EXPIRE_TIME = timedelta(days=7)


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
    def from_jwt(cls, jwt):
        user = jwt_context.decode(jwt)
        if user['issued'] < self.last_login:
            raise ValueError('JWT has been expired.')
        return cls.objects(id=me.ObjectId(user['id'])).first()

# Hook up the pre_save signal.
me.signals.pre_save.connect(User.pre_save, sender=User)


class GuestUser(User):
    """Special user subtype for guest accounts."""
    guest_id = me.SequenceField(required=True, unique=True)

    # Guest names do not have to be unique.
    name = me.StringField(
        min_length=1, max_length=20, required=True,
        regex='[A-z\d_]+')

    def get_jwt(self) -> str:
        """Returns a JWT authenticating as this user."""
        self.last_login = datetime.utcnow()
        self.save()

        user = dict(id=str(self.id), guest_id=self.guest_id, name=self.name)
        return jwt_context.encode(user, _JWT_EXPIRE_TIME)


class NonGuestUser(User):
    """Base for all permanent non-guest users."""
    user_id = me.SequenceField(required=True, unique=True)

    name = me.StringField(
        min_length=1, max_length=20,
        required=True, unique=True,
        regex='[A-z\d_]+')


class EmailUser(NonGuestUser):
    """A basic email/password-identified user."""
    email = me.EmailField(required=True, unique=True)
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
            raise ValueError('Password must be at least 8 characters')
        self.password_hash = security.pwd_context.hash(password)

    def activate_email(self, verification_code: str) -> None:
        """Activates this user's email if the |verification| code is correct."""
        if self.email_date_verified is not None:
            raise ValueError(f'Email {self.email} already verified.')

        if verification_code != self.email_verification_code:
            raise ValueError('Invalid verification code.')

        self.email_date_verified = datetime.utcnow()
        self.email_verification_code = None

    def get_jwt(self, password: str) -> str:
        """Returns a JWT authenticating as this user."""
        if not self.password_matches(password):
            raise ValueError('Incorrect password.')

        if self.email_date_verified is None:
            raise ValueError('User is not verified.')

        self.last_login = datetime.utcnow()
        self.save()

        user = dict(
            id=str(self.id),
            user_id=self.user_id,
            email=self.email,
            name=self.name)
        return jwt_context.encode(user, _JWT_EXPIRE_TIME)