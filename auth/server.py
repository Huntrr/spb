"""
Launcher for the auth server.
"""
from absl import app as base_app
from absl import flags, logging
import flask

from db import connect
from db.models import news

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


def main(_) -> None:
    logging.info('Connecting to database')
    connect.connect()

    logging.info(f'Launching auth server on :{FLAGS.port}')
    app.run(host='0.0.0.0', port=FLAGS.port)


if __name__ == '__main__':
    base_app.run(main)
