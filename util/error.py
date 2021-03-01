"""
Helper function for generating SPB server errors.
"""
import enum
from typing import Optional

import flask
import grpc

def error(spb_error: str,
          http_code: int = 500,
          spb_code: Optional[grpc.StatusCode] = None) -> flask.Response:
    """Returns a flask.Response that can be used to indicate an error for the
    SPB client.

    Args:
        spb_error: Message describing the error.
        http_code: HTTP code to associate with the error.
        spb_code: Optional gRPC status code to associate with the error.
    """
    response = dict(spb_error=spb_error)
    if spb_code is not None:
        response['spb_code'] = spb_code.value[0]
    return flask.jsonify(response), http_code

