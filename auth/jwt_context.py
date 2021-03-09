"""
Library function to encode and decode JWTs.
"""
from datetime import datetime, timedelta
import functools
import os
from typing import Optional

import jwt


_ALG = 'RS256'

_JWT_PASSWORD_ENV = 'JWT_PASSWORD'
_JWT_PRIVATE_KEY_ENV = 'JWT_PRIVATE_KEY'
_JWT_PUBLIC_KEY_ENV = 'JWT_PUBLIC_KEY'

_TIME_FIELDS = ['exp', 'iat']


@functools.lru_cache()
def _jwt_instance() -> jwt.JWT:
    return jwt.JWT()


@functools.lru_cache()
def _signing_key() -> jwt.AbstractJWKBase:
    with open(os.environ[_JWT_PRIVATE_KEY_ENV], 'rb') as fh:
        private_password = os.environ[_JWT_PASSWORD_ENV]
        return jwt.jwk_from_pem(
            fh.read(), private_password=private_password.encode())


@functools.lru_cache()
def _verifying_key() -> jwt.AbstractJWKBase:
    with open(os.environ[_JWT_PUBLIC_KEY_ENV], 'rb') as fh:
        return jwt.jwk_from_pem(fh.read())


def encode(content: dict, expire_in: Optional[timedelta] = None) -> str:
    now = datetime.utcnow()
    if expire_in is not None:
        exp = now + expire_in
        content['exp'] = jwt.utils.get_int_from_datetime(exp)
    content['iat'] = jwt.utils.get_int_from_datetime(now)
    return _jwt_instance().encode(content, _signing_key(), alg=_ALG)


def decode(encoded: str) -> dict:
    result = _jwt_instance().decode(
        encoded, _verifying_key(), do_time_check=True)
    for field in _TIME_FIELDS:
        if field in result:
            result[field] = datetime.fromtimestamp(result[field])
    return result
