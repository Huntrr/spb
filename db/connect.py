"""
Util to connect to the MongoDB instance.
"""
import os

import mongoengine as me

_DB_URI_ENV = 'DB_URI'

def connect() -> None:
    me.connect('spb', host=os.environ[_DB_URI_ENV])

