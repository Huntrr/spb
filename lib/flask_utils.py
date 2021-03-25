"""
Useful helpers for Flask servers.
"""
import functools
from typing import Callable

from absl import logging
import flask
import grpc

from db.models import user, server_auth
from util import error

def _get_token_str() -> str:
    """Gets the authentication token string from this request."""
    token = flask.request.headers.get('Authorization')
    if token is None:
        raise error.SpbError(
            'Not logged in', 401, grpc.StatusCode.UNAUTHENTICATED)

    if not token.startswith('JWT '):
        raise error.SpbError('Invalid authentication method',
                             400, grpc.StatusCode.UNAUTHENTICATED)

    token = token.replace('JWT ', '').strip()
    return token


def error_handler(spb_error: error.SpbError) -> flask.Response:
    """A useful error handler that unwraps SpbErrors."""
    logging.error(spb_error)
    return spb_error.to_response()


def user_required(func) -> Callable:
    """Requires the request have a proper authorization token, and passes the
    decoded user to the endpoint.
    """
    @functools.wraps(func)
    def inner_user_required(*args, **kwargs):
        the_user = user.User.from_jwt(_get_token_str())
        return func(the_user, *args, **kwargs)

    return inner_user_required


def server_required(func) -> Callable:
    """Requires the request have a proper authorization token for an SPB server.
    """
    @functools.wraps(func)
    def inner_server_required(*args, **kwargs):
        the_server_auth = server_auth.ServerAuth.from_jwt(_get_token_str())
        return func(the_server_auth, *args, **kwargs)

    return inner_server_required
