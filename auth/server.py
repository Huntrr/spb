"""
Launcher for the auth server.
"""
from absl import app as base_app
from absl import flags, logging
import flask

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
    logging.info(flask.request.json)
    the_user = user.GuestUser(name=flask.request.json['name'])
    the_user.save()
    return dict(jwt=the_user.get_jwt())


@app.route('/login/spb', methods=['POST'])
def login_spb() -> flask.Response:
    logging.info(flask.request.json)
    return error.error('error msg')


@app.route('/register/spb', methods=['POST'])
def register_spb() -> flask.Response:
    logging.info(flask.request.json)
    return error.error('error msg')


def main(_) -> None:
    logging.info('Connecting to database')
    connect.connect()

    logging.info(f'Launching auth server on :{FLAGS.port}')
    app.run(host='0.0.0.0', port=FLAGS.port)


if __name__ == '__main__':
    base_app.run(main)
