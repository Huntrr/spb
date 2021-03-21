class_name Inside
extends Node
# Container to control an inside game world.

var _ship_id: String

func init(ship_id_: String, room_id_: String):
	_ship_id = ship_id_
	set_name(room_id_)
	$Control/Label.set_text(_ship_id)
	return self

func get_pop() -> int:
	return 0

func get_status() -> Dictionary:
	return {
		"ship_id": _ship_id,
		"pop": get_pop(),
	}
