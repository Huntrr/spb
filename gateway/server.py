"""
Launcher for gateway server.
"""
import functools

from absl import app as base_app
from absl import flags, logging
import flask
import flask_sockets

from db import connect
from db.models import server_auth, user
from gateway import game_server_manager, ws_manager
from lib import flask_utils

flags.DEFINE_integer('port', 30201, 'Port to use for the gateway server.')

FLAGS = flags.FLAGS

app = flask.Flask(__name__)
sockets = flask_sockets.Sockets(app)

@functools.lru_cache()
def _game_server_manager() -> game_server_manager.GameServerManager:
    """Returns this server's instance of the GameServerManager."""
    return game_server_manager.GameServerManager()


@sockets.route('/connect_server')
@flask_utils.server_required
def connect_server(server_auth: server_auth.ServerAuth, ws) -> None:
    manager = ws_manager.WSManager(ws)
    server_ip = flask.request.environ.get(
        'HTTP_X_FORWARDED_FOR', flask.request.environ['REMOTE_ADDR'])
    logging.info('Establishing game server connection with %s', server_ip)

    _game_server_manager().register_server(server_ip, manager)
    manager.run()


@app.route('/join_ship', methods=['GET'])
@flask_utils.user_required
def join_ship(the_user: user.User) -> flask.Response:
    """Returns a game server address & ship id that can be used to join a ship.
    """
    the_ship = user.player.location_ship
    server_ip, room_id = (
        _game_server_manager().get_or_make_ship_server(the_ship))
    return dict(server_ip=server_ip, room_id=room_id, ship_id=str(the_ship.id))


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
