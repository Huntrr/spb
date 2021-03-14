"""
Launcher for the auth server.
"""
import uuid

from absl import app as base_app
from absl import flags, logging
import bson
import flask
import grpc
import mongoengine as me

from auth import email_utils
from db import connect
from db.models import news, user, server_auth
from lib import flask_utils
from util import error

flags.DEFINE_integer('port', 30202, 'Port to use for the auth server.')

FLAGS = flags.FLAGS

_DATE_FORMAT = '%b %d %Y'
_NUM_NEWS_ITEMS = 5

app = flask.Flask(__name__)

@app.route('/news')
def get_news() -> flask.Response:
    news_items = news.News.objects().order_by('-date')[:_NUM_NEWS_ITEMS]
    formatted_items = [
        dict(title=item.title,
             content=item.content,
             date=item.date.strftime(_DATE_FORMAT))
        for item in news_items]
    return flask.jsonify(formatted_items)


@app.route('/identity', methods=['GET'])
@flask_utils.user_required
def identity(the_user: user.User) -> flask.Response:
    """Returns the name of the currently authenticated user."""
    return dict(name=the_user.get_name())


@app.route('/identity_server', methods=['GET'])
@flask_utils.server_required
def identity_server(server_auth: server_auth.ServerAuth) -> flask.Response:
    """Returns 200 if the server is authenticated."""
    return dict(id=str(server_auth.id))


@app.route('/login/server', methods=['POST'])
def login_server() -> flask.Response:
    data = flask.request.json
    return dict(jwt=server_auth.ServerAuth.get_jwt(data['auth_key']))


@app.route('/login/guest', methods=['POST'])
def login_guest() -> flask.Response:
    guest_name = flask.request.json['name']
    the_user = user.GuestUser(guest_name=guest_name)
    try:
        the_user.save()
    except me.ValidationError as exc:
        logging.exception('Exception creating guest %s', guest_name)
        for _, inner_error in exc.errors.items():
            if 'too short' in str(inner_error):
                raise error.SpbError('Name is too short',
                                     400, grpc.StatusCode.INVALID_ARGUMENT)
        raise error.SpbError('Unable to register a new guest account')

    logging.info('Created a new guest user %s (gid: %d)',
                 the_user.get_name(), the_user.guest_id)
    return dict(jwt=the_user.get_jwt())


@app.route('/login/spb', methods=['POST'])
def login_spb() -> flask.Response:
    data = flask.request.json

    the_user = user.EmailUser.objects(email=data['email']).first()
    if the_user is None:
        raise error.SpbError(
            'Invalid email/password',
            http_code=401,
            spb_code=grpc.StatusCode.PERMISSION_DENIED)

    return dict(jwt=the_user.get_jwt(data['password']))


@app.route('/register/spb', methods=['POST'])
def register_spb() -> flask.Response:
    verification_code = str(uuid.uuid4())

    data = flask.request.json
    the_user = user.EmailUser(
        user_name=data['name'],
        email=data['email'],
        email_verification_code=verification_code)
    the_user.set_password(data['password'])
    try:
        the_user.save()
    except me.ValidationError as exc:
        logging.exception('Exception creating user %s', data['email'])
        errors = []
        for field, inner_error in exc.errors.items():
            field = field if field != 'user_name' else 'username'
            error_type = None
            if 'short' in str(inner_error):
                error_type = 'too short'
            elif 'long' in str(inner_error):
                error_type = 'too long'
            elif 'did not match validation regex' in str(inner_error):
                error_type = ('not valid\nUsernames can only contain letters, '
                              'numbers, and underscores')
            elif 'Invalid email' in str(inner_error):
                error_type = 'not a valid email address'

            if error_type is not None:
                errors.append(f'{field.title()} is {error_type}')

        if len(errors) == 0:
            raise error.SpbError('Unable to register a new account')
        else:
            raise error.SpbError('\n'.join(errors),
                                 400, grpc.StatusCode.INVALID_ARGUMENT)
    except me.NotUniqueError as exc:
        logging.exception('Exception creating user %s', data['email'])
        if 'key: { email' in exc.args[0]:
            raise error.SpbError('That email is already registered',
                                 400, grpc.StatusCode.ALREADY_EXISTS)
        if 'key: { user_name' in exc.args[0]:
            raise error.SpbError('There is already someone with that username',
                                 400, grpc.StatusCode.ALREADY_EXISTS)
        raise error.SpbError('Unable to register a new account')

    verification_link = flask.url_for(
        'verify_spb', user_id=the_user.id, verification_code=verification_code,
        _external=True)
    email_utils.send_verification_email(
        the_user.email, the_user.get_name(), verification_link)

    logging.info('Created a new email user %s (uid: %d)',
                 the_user.email, the_user.user_id)
    return dict()


@app.route(
    '/verify/spb/<string:user_id>/<string:verification_code>', methods=['GET'])
def verify_spb(user_id: str, verification_code: str) -> flask.Response:
    the_user = user.EmailUser.objects(
        id=bson.objectid.ObjectId(user_id)).first()
    if the_user is None:
        return 'Invalid user ID', 404

    try:
        the_user.activate_email(verification_code)
    except ValueError as exc:
        logging.exception('Error validating user')
        return str(exc), 400
    the_user.save()

    logging.info('Successfully verified email user %s', the_user.email)
    return f'Email {the_user.email} successfully verified'


def main(_) -> None:
    logging.info('Registering special routes')
    app.register_error_handler(error.SpbError, flask_utils.error_handler)

    logging.info('Connecting to database')
    connect.connect()

    logging.info(f'Launching auth server on :{FLAGS.port}')
    app.run(host='0.0.0.0', port=FLAGS.port)


if __name__ == '__main__':
    base_app.run(main)
