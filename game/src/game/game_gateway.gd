extends Node

signal connection_established()

onready var Log: Logger = Logger.new(self)

var _current_ship_server: String = ""
var _current_ship_room: String = ""
var _connected = false

const InsideScene: PackedScene = preload("res://scenes/world/inside/inside.tscn")
onready var _inside_wrapper: Node = $InsideMultiplayerWrapper

func _ready() -> void:
	var data_status: StatusOr = yield(Connection.request(
		"auth", "identity", HTTPClient.METHOD_GET, {}), "completed")
	if not data_status.ok():
		push_error(data_status.status.message)
		return
	
	var data: Dictionary = data_status.value
	Log.info("Logged in as: %s" % data.name)
	
	assert(_inside_wrapper.multiplayer.connect(
		"connection_failed", self, "_on_inside_connection_failed") == OK)
	assert(_inside_wrapper.multiplayer.connect(
		"connected_to_server", self, "_on_inside_connected") == OK)
	assert(_inside_wrapper.multiplayer.connect(
		"network_peer_connected", self, "_on_inside_peer_connected") == OK)
	assert(_inside_wrapper.multiplayer.connect(
		"server_disconnected", self, "_on_inside_server_disconnect") == OK)
		
	_join_ship()


func _join_ship() -> void:
	var data_status: StatusOr = yield(Connection.request(
		"gateway", "join_ship", HTTPClient.METHOD_POST, {}), "completed")
	if not data_status.ok():
		Log.error(data_status.status.message)
		Dialog.show_error(data_status.status)
		return
	var data: Dictionary = data_status.value
	
	if _current_ship_server != data.server_ip:
		Log.info("Switching ship server: %s" % data.server_ip)
		_connected = false
		_current_ship_server = data.server_ip
		var peer = NetworkedMultiplayerENet.new()
		peer.create_client(_current_ship_server, Connection.SHIP_PORT)
		_inside_wrapper.multiplayer.set_network_peer(peer)
		yield(self, "connection_established")
	
	if _current_ship_room != data.room_id:
		Log.info("Switching room node")
		_current_ship_room = data.room_id
		for child in _inside_wrapper.get_children():
			child.queue_free()
		var ship: Inside = InsideScene.instance().init(
			data.ship_id, _current_ship_room)
		_inside_wrapper.add_child(ship)
		
		# Send server handshake.
		_inside_wrapper.rpc("request_join_room", _current_ship_room)


func _on_inside_connection_failed() -> void:
	Dialog.show_error(Status.new(
		Status.UNAVAILABLE, "Unable to connect to ship server"))


func _on_inside_connected() -> void:
	Log.info("Successfully connected to ship server: %s" % _current_ship_server)
	_connected = true


func _on_inside_server_disconnected() -> void:
	if _connected:
		Dialog.show_error(Status.new(
			Status.INTERNAL, "Disconnected from ship server"))


func _on_inside_peer_connected(id: int) -> void:
	if id != 1:
		return
	emit_signal("connection_established")
