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
	$Debug/UI/ShipId.set_text(_ship_id)
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
		Log.info("Introducing myself!")
		rpc("introduce_player", Connection.session_jwt)

func get_pop() -> int:
	return players.size()

func get_status() -> Dictionary:
	return {
		"ship_id": _ship_id,
		"pop": get_pop(),
	}

master func introduce_player(jwt: String) -> void:
	Log.info("Got introduction...")
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
	
	Log.info("Got player %s" % user.name)
	
	# TODO(hunter): Include the JWT to verify this user is themself!
	var data_status: StatusOr = yield(Connection.request(
		"universe", "get_player", HTTPClient.METHOD_GET, {
			"user_id": user.id
		}), "completed")
	if not data_status.ok():
		push_error(data_status.status.message)
		$"../".rpc_id(sender_id, "kick")
		return
	
	Log.info("Verified player %s" % data_status.value)
	if not multiplayer.network_peer.get_peer_address(sender_id):
		Log.info(
			"Peer %d disconnected before they could be verified" % sender_id)
		return
	players[sender_id] = data_status.value
	rpc_id(sender_id, "set_blueprint", _cells)
	$Ship.spawn_player(sender_id, players[sender_id].outfit)

func remove_player(peer_id: int) -> void:
	var erased = players.erase(peer_id)
	if not erased:
		Log.error("Erased peer %d too early" % peer_id)
	else:
		Log.info("Removed peer id=%d" % peer_id)
		
	$Ship.rpc("remove_player", peer_id)
	$Ship.remove_player(peer_id)

puppet func set_blueprint(cells: Array) -> void:
	Log.info("Updating ship blueprint")
	_cells = cells
	var spb := SpaceshipBlueprint.new().from_cells(cells)
	$Ship.load_from_spb(spb)
