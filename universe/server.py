"""
Launcher for universe / worldstate server.
"""
import functools

from absl import app as base_app
from absl import flags, logging
import bson
import flask
import grpc

from db import connect
from db.models import server_auth, ship, user
from lib import flask_utils
from util import error

flags.DEFINE_integer('port', 30200, 'Port to use for the universe server.')

FLAGS = flags.FLAGS

app = flask.Flask(__name__)

@app.route('/get_ship')
@flask_utils.server_required
def get_ship(_) -> flask.Response:
    data = flask.request.json
    ship_id = data['ship_id']

    object_id = bson.objectid.ObjectId(ship_id)
    the_ship = ship.Ship.objects(id=object_id).first()
    if not the_ship:
        raise error.SpbError(f'ship {ship_id} not found',
                             404, grpc.StatusCode.NOT_FOUND)
    return the_ship.to_dict()


@app.route('/get_player')
@flask_utils.server_required
def get_player(_) -> flask.Response:
    data = flask.request.json
    user_id = data['user_id']

    object_id = bson.objectid.ObjectId(user_id)
    the_user = user.User.objects(id=object_id).first()
    if not the_user:
        raise error.SpbError(f'user {user_id} not found',
                             404, grpc.StatusCode.NOT_FOUND)
    return the_user.player.to_dict()


@app.route('/update_outfit', methods=['POST'])
@flask_utils.server_required
def update_outfit(_) -> flask.Response:
    data = flask.request.json
    user_id = data['user_id']
    outfit = data['outfit']

    object_id = bson.objectid.ObjectId(user_id)
    the_user = user.User.objects(id=object_id).first()
    if not the_user:
        raise error.SpbError(f'user {user_id} not found',
                             404, grpc.StatusCode.NOT_FOUND)
    the_user.player.outfit.update_from_dict(outfit)
    the_user.save()
    return the_user.player.outfit.to_dict()


def main(_) -> None:
    from gevent import pywsgi
    from geventwebsocket.handler import WebSocketHandler

    logging.info('Registering special routes')
    app.register_error_handler(error.SpbError, flask_utils.error_handler)

    logging.info('Connecting to database')
    connect.connect()

    logging.info(f'Launching universe server on :{FLAGS.port}')
    server = pywsgi.WSGIServer(
        ('', FLAGS.port), app, handler_class=WebSocketHandler)
    server.serve_forever()


if __name__ == "__main__":
    base_app.run(main)
