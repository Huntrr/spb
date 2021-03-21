class_name ShipRooms
extends Node
# Main game server interface for managing ship rooms.

const MAX_PLAYERS: int = 500

const InsideScene: PackedScene = preload("res://scenes/world/inside/inside.tscn")
onready var _wrapper: Node = $MultiplayerWrapper

func _ready() -> void:
	# Initialize the multiplayer server.
	var peer = NetworkedMultiplayerENet.new()
	peer.create_server(Connection.SHIP_PORT, MAX_PLAYERS)
	_wrapper.multiplayer.network_peer = peer

func get_status() -> Dictionary:
	var status: Dictionary = {}
	for inside in _wrapper.get_children():
		status[inside.name] = inside.get_status()
	return status


func get_pop() -> int:
	var total_pop: int = 0
	for inside in _wrapper.get_children():
		total_pop += inside.get_pop()
	return total_pop


func create_ship(ship_id: String) -> StatusOr:
	var room_id = Uuid.v4()
	var ship: Inside = InsideScene.instance().init(ship_id, room_id)
	_wrapper.add_child(ship)
	return StatusOr.new().from_value(room_id)
