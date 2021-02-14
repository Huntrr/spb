"""
Script to publish news content to the database.
"""
from absl import app, logging, flags

from db import connect
from db.models import news

flags.DEFINE_string('title', None, 'Title for this piece of news.')
flags.DEFINE_string('content', None, 'Path to the content to publish.')

FLAGS = flags.FLAGS


def main(_) -> None:
    with open(FLAGS.content, 'r') as f:
        content = f.read()

    connect.connect()
    news_item = news.News(title=FLAGS.title, content=content)
    news_item.save()
    logging.info(f'Published {news_item.title} at {news_item.date}')


if __name__ == '__main__':
    flags.mark_flags_as_required(['title', 'content'])
    app.run(main)
