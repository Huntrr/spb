"""
Launcher for universe / worldstate server.
"""
import functools

from absl import app as base_app
from absl import flags, logging
import flask
import grpc

from db import connect
from lib import flask_utils
from util import error

flags.DEFINE_integer('port', 30200, 'Port to use for the universe server.')

FLAGS = flags.FLAGS

app = flask.Flask(__name__)

@app.route('/get_ship/<string:ship_id>')
@flask_utils.server_required
def connect_server(_, ship_id: str) -> flask.Response:
    raise error.SpbError('/get_ship not yet implemented',
                         501, error.grpc.StatusCode.UNIMPLEMENTED)


@app.route('/get_player/<string:user_id>')
@flask_utils.server_required
def connect_server(_, user_id: str) -> flask.Response:
    raise error.SpbError('/get_player not yet implemented',
                         501, error.grpc.StatusCode.UNIMPLEMENTED)


def main(_) -> None:
    from gevent import pywsgi
    from geventwebsocket.handler import WebSocketHandler

    logging.info('Registering special routes')
    app.register_error_handler(error.SpbError, flask_utils.error_handler)

    logging.info('Connecting to database')
    connect.connect()

    logging.info(f'Launching gateway server on :{FLAGS.port}')
    server = pywsgi.WSGIServer(
        ('', FLAGS.port), app, handler_class=WebSocketHandler)
    server.serve_forever()


if __name__ == "__main__":
    base_app.run(main)
