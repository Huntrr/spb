"""
Useful helpers for Flask servers.
"""
from typing import Callable

from absl import logging
import flask
import grpc

from db.models import user
from util import error

def error_handler(spb_error: error.SpbError) -> flask.Response:
    """A useful error handler that unwraps SpbErrors."""
    logging.error(spb_error)
    return spb_error.to_response()

def login_required(func) -> Callable:
    """Requires the request have a proper authorization token, and passes the
    decoded user to the endpoint.
    """
    def inner_func(*args, **kwargs):
        token = flask.request.headers.get('Authorization')
        if token is None:
            raise error.SpbError(
                'Not logged in', 401, grpc.StatusCode.UNAUTHENTICATED)

        if not token.startswith('JWT '):
            raise error.SpbError('Invalid authentication method',
                                 400, grpc.StatusCode.UNAUTHENTICATED)

        token = token.replace('JWT ', '').strip()
        the_user = user.User.from_jwt(token)

        return func(the_user, *args, **kwargs)

    return inner_func
