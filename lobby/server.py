"""
Launcher for lobby server.
"""
from absl import app as base_app
from absl import flags, logging
import bson
import flask
import grpc

from db import connect
from db.models import lobby
from lib import flask_utils
from util import error

flags.DEFINE_integer('port', 30203, 'Port to use for the lobby server.')

FLAGS = flags.FLAGS

LOBBIES_PER_PAGE = 10

app = flask.Flask(__name__)

@app.route('/list_games')
@flask_utils.user_required
def list_games(_) -> flask.Response:
    data = flask.request.json
    page = data.get('offset', 0)

    start_idx = offset
    end_idx = offset + LOBBIES_PER_PAGE

    lobbies = lobby.Lobby.objects(
        state=lobby.State.PREGAME).order_by('+created_at')[start_idx:end_idx]
    lobbies = [the_lobby.to_dict() for the_lobby in lobbies]
    return dict(lobbies=lobbies, next_offset=end_idx)

@app.route('/get_game')
@flask_utils.user_required
def get_game(_) -> flask.Response:
    data = flask.request.json
    lobby_id = data['lobby_id']

    object_id = bson.objectid.ObjectId(lobby_id)
    the_lobby = lobby.Lobby.objects(id=object_id).first()
    if not the_lobby:
        raise error.SpbError(f'lobby {lobby_id} not found',
                             404, grpc.StatusCode.NOT_FOUND)
    return the_lobby.to_dict()

@app.route('/join_game', methods=['POST'])
@flask_utils.server_required
def join_game(_) -> flask.Response:
    data = flask.request.json
    user_id = data['user_id']
    lobby_id = data['lobby_id']
    maybe_password = data.get('password')
    # TODO(hunter): Join Game.

@app.route('/create_game', methods=['POST'])
@flask_utils.server_required
def create_game(_) -> flask.Response:
    data = flask.request.json
    user_id = data['user_id']
    lobby_name = data['lobby_name']
    password = data['password']
    # TODO(hunter): Create Game.

@app.route('/leave_game', methods=['POST'])
@flask_utils.server_required
def leave_game(_) -> flask.Response:
    data = flask.request.json
    user_id = data['user_id']
    lobby_id = data['lobby_id']
    # TODO(hunter): Leave Game.

@app.route('/kick_user', methods=['POST'])
@flask_utils.server_required
def kick_user(_) -> flask.Response:
    data = flask.request.json
    user_id = data['user_id']
    lobby_id = data['lobby_id']
    # TODO(hunter): Kick User.

@app.route('/join_crew', methods=['POST'])
@flask_utils.server_required
def join_crew(_) -> flask.Response:
    data = flask.request.json
    user_id = data['user_id']
    lobby_id = data['lobby_id']
    crew_id = data['crew_id']
    # TODO(hunter): Join crew.

@app.route('/exit_crew', methods=['POST'])
@flask_utils.server_required
def exit_crew(_) -> flask.Response:
    data = flask.request.json
    user_id = data['user_id']
    lobby_id = data['lobby_id']
    crew_id = data['crew_id']
    # TODO(hunter): Exit crew.

@app.route('/new_crew', methods=['POST'])
@flask_utils.server_required
def join_crew(_) -> flask.Response:
    data = flask.request.json
    lobby_id = data['lobby_id']
    crew_name = data['crew_name']
    # TODO(hunter): New crew.

@app.route('/delete_crew', methods=['POST'])
@flask_utils.server_required
def delete_crew(_) -> flask.Response:
    data = flask.request.json
    lobby_id = data['lobby_id']
    crew_id = data['crew_id']
    # TODO(hunter): Delete crew.

@app.route('/set_team', methods=['POST'])
@flask_utils.server_required
def set_team(_) -> flask.Response:
    data = flask.request.json
    lobby_id = data['lobby_id']
    crew_id = data['crew_id']
    team = data['team']
    # TODO(hunter): Set team.

@app.route('/set_ship', methods=['POST'])
@flask_utils.server_required
def set_ship(_) -> flask.Response:
    data = flask.request.json
    lobby_id = data['lobby_id']
    crew_id = data['crew_id']
    blueprint = data['blueprint']
    # TODO(hunter): Set ship.

@app.route('/set_time_limit', methods=['POST'])
@flask_utils.server_required
def set_time_limit(_) -> flask.Response:
    data = flask.request.json
    lobby_id = data['lobby_id']
    time_limit = data['time_limit']
    # TODO(hunter): Set time_limit.


def main(_) -> None:
    from gevent import pywsgi
    from geventwebsocket.handler import WebSocketHandler

    logging.info('Registering special routes')
    app.register_error_handler(error.SpbError, flask_utils.error_handler)

    logging.info('Connecting to database')
    connect.connect()

    logging.info(f'Launching lobby server on :{FLAGS.port}')
    server = pywsgi.WSGIServer(
        ('', FLAGS.port), app, handler_class=WebSocketHandler)
    server.serve_forever()


if __name__ == "__main__":
    base_app.run(main)
