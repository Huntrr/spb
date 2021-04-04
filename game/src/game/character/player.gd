extends Node2D

export(float) var _ACCEL
export(float) var _MAX_VELOCITY
export(float) var _FRICTION

var _info: Dictionary
var _peer_id: int

func init(peer_id_: int, player_info_: Dictionary):
	name = "%d" % peer_id_
	_peer_id = peer_id_
	_info = player_info_
	return self

func _ready():
	$Character.set_outfit(_info.outfit)
	
	if _peer_id == multiplayer.get_network_unique_id():
		$Camera2D.make_current()
