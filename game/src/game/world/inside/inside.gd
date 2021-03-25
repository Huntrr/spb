class_name Inside
extends Node
# Container to control an inside game world.

onready var Log := Logger.new(self)

var _ship_id: String
var _cells := []

var players := {}

func init(ship_id_: String, room_id_: String):
	_ship_id = ship_id_
	set_name(room_id_)
	$Debug/Label.set_text(_ship_id)
	return self

func _ready() -> void:
	if multiplayer.is_network_server():
		var data_status: StatusOr = yield(Connection.request(
			"universe", "get_ship", HTTPClient.METHOD_GET, {
				"ship_id": _ship_id
			}), "completed")
		if not data_status.ok():
			push_error(data_status.status.message)
			return
		
		var ship: Dictionary = data_status.value
		set_blueprint(ship.blueprint)
	else:
		# Introduce self.
		rpc("introduce_player", Connection.session_jwt)

func get_pop() -> int:
	return 0

func get_status() -> Dictionary:
	return {
		"ship_id": _ship_id,
		"pop": get_pop(),
	}

master func introduce_player(jwt: String) -> void:
	var sender_id = multiplayer.get_rpc_sender_id()
	
	var encoded_user: String = jwt.split('.')[1]
	var str_user: String = Base64Url.base64url_to_utf8(encoded_user)
	var json_user: JSONParseResult = JSON.parse(str_user)
	if json_user.error != OK:
		Log.error("Unable to identify user: %d" % sender_id)
		$"../".rpc_id(sender_id, "kick")
		return
	
	var user = json_user.result
	if user.type != "player":
		Log.error("User was not a player: %d was %s" % [sender_id, user.type])
		$"../".rpc_id(sender_id, "kick")
		return
	
	var data_status: StatusOr = yield(Connection.request(
		"universe", "get_player", HTTPClient.METHOD_GET, {
			"user_id": user.id
		}), "completed")
	if not data_status.ok():
		push_error(data_status.status.message)
		$"../".rpc_id(sender_id, "kick")
		return
	
	players[sender_id] = data_status.value
	rpc_id(sender_id, "set_blueprint", _cells)

func remove_player(peer_id: String) -> void:
	players.erase(peer_id)

puppet func set_blueprint(cells: Array) -> void:
	Log.info('Updating ship blueprint')
	_cells = cells
	var spb := SpaceshipBlueprint.new().from_cells(cells)
	$Ship.load_from_spb(spb)