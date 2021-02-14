"""
Basic data model for a piece of news.
"""
from datetime import datetime

import mongoengine as me


class News(me.Document):
    date = me.DateTimeField(default=datetime.utcnow)

    title = me.StringField(max_length=256, required=True)
    content = me.StringField(required=True)
