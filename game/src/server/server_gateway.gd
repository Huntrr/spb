extends Node

onready var Log: Logger = Logger.new(self)
var _client: WebSocketClient

var _try_connect = true
var _last_try = 0
const TRY_INTERVAL = 5

onready var _ship_rooms: ShipRooms = $ShipRooms


func _ready() -> void:
	var data_status: StatusOr = yield(Connection.request(
		"auth", "identity_server", HTTPClient.METHOD_GET, {}), "completed")
	if not data_status.ok():
		push_error(data_status.status.message)
		return
	
	var data: Dictionary = data_status.value
	Log.info("Server identified as: %s" % data.id)


func _send(message: Dictionary) -> void:
	_client.get_peer(1).put_packet(JSON.print(message).to_utf8())


func _closed(was_clean: bool = false) -> void:
	Log.error("Closed WS connection: was_clean=%s" % was_clean)
	_try_connect = true


func _connected(proto: String = "") -> void:
	Log.info("Connected WS with protocol: %s" % proto)


func _on_data():
	var data_json: JSONParseResult = JSON.parse(
		_client.get_peer(1).get_packet().get_string_from_utf8())
	if data_json.error != OK:
		Log.error("Error parsing incoming WS data")
		return
	
	var data: Dictionary = data_json.result
	
	if data.type == "PING":
		_send({
			"type": "PONG",
			"req_id": data.req_id,
			"timestamp": OS.get_system_time_secs(),
			"total_pop": _ship_rooms.get_pop(),
			"ship_rooms": _ship_rooms.get_status(),
		})
		return
	
	if data.type == "CREATE_SHIP":
		Log.info("Received request to create room for ship %s" % data.ship_id)
		var room_id_status: StatusOr = _ship_rooms.create_ship(data.ship_id)
		if not room_id_status.ok():
			Log.error("Failed to create room: " % room_id_status.status.message)
		else:
			Log.info("Created ship, with room_id=%s" % room_id_status.value)
		_send({
			"type": "CREATED_SHIP",
			"req_id": data.req_id,
			"timestamp": OS.get_system_time_secs(),
			"successful": room_id_status.ok(),
			"room_id": room_id_status.value if room_id_status.ok() else "",
		})
		return
		
	Log.error("Unknown WS message data:\n%s" % JSON.print(data))


func _process(delta):
	if _try_connect:
		_last_try -= delta
		if _last_try < 0:
			Log.info("Attempting to establish WS connection")
			_last_try = TRY_INTERVAL
			var client_status = Connection.ws_connect("gateway", "connect_server")
			if not client_status.ok():
				Log.error(client_status.status.message)
				return
			
			_client = client_status.value
			_client.connect("connection_closed", self, "_closed")
			_client.connect("connection_error", self, "_closed")
			_client.connect("connection_established", self, "_connected")
			_client.connect("data_received", self, "_on_data")
			_try_connect = false
		return
	
	_client.poll()
