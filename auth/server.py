"""
Launcher for the auth server.
"""
import uuid

from absl import app as base_app
from absl import flags, logging
import flask
import grpc

from auth import email
from db import connect
from db.models import news, user
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


@app.route('/login/guest', methods=['POST'])
def login_guest() -> flask.Response:
    the_user = user.GuestUser(name=flask.request.json['name'])
    the_user.save()
    return dict(jwt=the_user.get_jwt())


@app.route('/login/spb', methods=['POST'])
def login_spb() -> flask.Response:
    data = flask.request.json

    the_user = user.EmailUser.objects(email=data['email']).first()
    if the_user is None:
        return error.error(
            'Invalid email/password',
            http_code=401,
            spb_code=grpc.StatusCode.PERMISSION_DENIED)

    return dict(jwt=the_user.get_jwt(data['password']))


@app.route('/register/spb', methods=['POST'])
def register_spb() -> flask.Response:
    verification_code = str(uuid.uuid4())

    data = flask.request.json
    the_user = user.EmailUser(
        name=data['name'],
        email=data['email'],
        email_verification_code=verification_code)
    the_user.set_password(data['password'])
    the_user.save()

    verification_link = flask.url_for(
        'verify_spb', user=the_user.id, verification_code=verification_code)
    email.send_verification_email(
        the_user.email, the_user.name, verification_link)

    return dict()


@app.route('/verify/spb/<str:user_id>/<str:verification_code>', methods=['GET'])
def verify_spb(user_id: str, verification_code: str) -> flask.Response:
    the_user = user.EmailUser.objects(id=me.ObjectId(user_id)).first()
    if the_user is None:
        return 'Invalid user ID', 404

    the_user.activate_email(verification_code)
    the_user.save()

    return f'Email {user.email} successfully verified'


def main(_) -> None:
    logging.info('Connecting to database')
    connect.connect()

    logging.info(f'Launching auth server on :{FLAGS.port}')
    app.run(host='0.0.0.0', port=FLAGS.port)


if __name__ == '__main__':
    base_app.run(main)
