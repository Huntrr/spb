extends Node2D

var _info: Dictionary

func init(peer_id: int, player_info_: Dictionary):
	name = "%d" % peer_id
	_info = player_info_
	return self

func _ready():
	$Character.set_outfit(_info.outfit)
