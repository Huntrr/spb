class_name ShipRooms
extends Node
# Main game server interface for managing ship rooms.

onready var Log := Logger.new(self)

const MAX_PLAYERS: int = 500

const InsideScene: PackedScene = preload("res://scenes/world/inside/inside.tscn")
onready var _wrapper: Node = $MultiplayerWrapper

var peers: Dictionary = {}

func _ready() -> void:
	# Initialize the multiplayer server.
	var peer = NetworkedMultiplayerENet.new()
	peer.create_server(Connection.SHIP_PORT, MAX_PLAYERS)
	_wrapper.multiplayer.network_peer = peer
	
		
	_wrapper.multiplayer.connect(
		"network_peer_disconnected", self, "_on_peer_disconnected")
	_wrapper.multiplayer.connect(
		"network_peer_connected", self, "_on_peer_connected")

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
	var ship: Inside = InsideScene.instance().init(ship_id, room_id, self)
	_wrapper.add_child(ship)
	return StatusOr.new().from_value(room_id)


func kick_user(id: int) -> void:
	_wrapper.rpc_id(id, "kick")


func _on_peer_connected(id: int) -> void:
	Log.info("Got new peer connection, id=%d" % id)
	peers[id] = true


func _on_peer_disconnected(id: int) -> void:
	Log.info("Got peer disconnected, id=%d" % id)
	peers.erase(id)
	for inside in _wrapper.get_children():
		inside.remove_player(id)
