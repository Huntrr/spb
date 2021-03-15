extends Node

onready var Log: Logger = Logger.new(self)
var _client: WebSocketClient

var _try_connect = true
var _last_try = 0
const TRY_INTERVAL = 5


func _send(message: Dictionary) -> void:
	_client.get_peer(1).put_packet(JSON.print(message).to_utf8())


func _closed(was_clean: bool = false) -> void:
	Log.error("Closed WS connection: %d" % was_clean)
	_try_connect = true
	_last_try = 0


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
		_send({"type": "PONG"})
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
