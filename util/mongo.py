"""Some common MongoDB utils."""
import bson
import grpc
import mongoengine as me

from util import error

def get_object(document_type, object_id: str) -> me.Document:
    document_id = bson.objectid.ObjectId(object_id)
    document = document_type.objects(id=document_id).first()
    if not document:
        raise error.SpbError(f'{document_type._name} {object_id} not found',
                             404, grpc.StatusCode.NOT_FOUND)
    return document
