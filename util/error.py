"""
Helper function for generating SPB server errors.
"""
import enum
from typing import Optional

import flask
import grpc

class SpbError(Exception):
    def __init__(self, spb_error: str, http_code: int = 500,
                 spb_code: Optional[grpc.StatusCode] = None) -> None:
        """Instantiate an SPB error."""
        super().__init__(spb_error)
        self.spb_error = spb_error
        self.http_code = http_code
        self.spb_code = spb_code

    def to_response(self) -> flask.Response:
        """Returns a Flask Response representation of this error."""
        response = dict(spb_error=self.spb_error)
        if self.spb_code is not None:
            response['spb_code'] = self.spb_code.value[0]
        return flask.jsonify(response), self.http_code

    def __str__(self) -> str:
        return (f'SpbError {self.spb_code or "UNKNOWN"} '
                f'(HTTP Code {self.http_code}): {self.spb_error}')
