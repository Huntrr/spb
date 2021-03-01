"""
Declaration of the global security context for SPB auth.
"""
from passlib.context import CryptContext

pwd_context = CryptContext(
    schemes=['pbkdf2_sha256'],
    deprecated='auto',
)
