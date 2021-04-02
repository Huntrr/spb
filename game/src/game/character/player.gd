extends Node2D

var _outfit: Dictionary

func init(peer_id: int, outfit_: Dictionary):
	name = "%d" % peer_id
	_outfit = outfit_
	return self

func _ready():
	$Character.set_outfit(_outfit)
