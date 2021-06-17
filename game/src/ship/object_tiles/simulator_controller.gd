extends OverlayManager

var _lobby: Node

func _ready():
	connect("created_overlay", self, "_on_created_overlay")

func _on_created_overlay(overlay: Node, user: Player) -> void:
	_lobby = overlay
	assert(overlay.create_dialog.connect(
		"create_game", self, "_on_create_game", [user]) == OK)
	assert(overlay.connect(
		"join_game", self, "_on_join_game", [user]) == OK)

puppet func _show_error(code, message) -> void:
	Dialog.show_error(Status.new(code, message))

puppet func _user_join_game(game_id: String) -> void:
	_lobby.show_game_lobby(game_id)

func _on_create_game(game_name: String, password: String, user: Player) -> void:
	rpc("_create_game", get_path_to(user), game_name, password)


func _on_join_game(game_id: String, password: String, user: Player) -> void:
	rpc("_join_game", get_path_to(user), game_id, password)

master func _create_game(
		user_path: NodePath, game_name: String, password: String) -> void:
	var user: Player = get_node(user_path)
	if user.peer_id != multiplayer.get_rpc_sender_id():
		Log.error("Peer %d tried to act as %d" % [
			multiplayer.get_rpc_sender_id(), user.peer_id])
		return
	
	var result = yield(Connection.request(
		"lobby", "create_game", HTTPClient.METHOD_POST, {
			"user_id": user.info.id,
			"lobby_name": game_name,
			"password": password,
		}), "completed")
	if not result.ok():
		rpc_id(
			user.peer_id, "_show_error",
			result.status.code, result.status.message)
		return
	rpc_id(user.peer_id, "_user_join_game", result.value.id)

master func _join_game(
		user_path: NodePath, game_id: String, password: String) -> void:
	var user: Player = get_node(user_path)
	if user.peer_id != multiplayer.get_rpc_sender_id():
		Log.error("Peer %d tried to act as %d" % [
			multiplayer.get_rpc_sender_id(), user.peer_id])
		return
	
	var result = yield(Connection.request(
		"lobby", "join_game", HTTPClient.METHOD_POST, {
			"user_id": user.info.id,
			"lobby_id": game_id,
			"password": password,
		}), "completed")
	if not result.ok():
		rpc_id(
			user.peer_id, "_show_error",
			result.status.code, result.status.message)
		return
	rpc_id(user.peer_id, "_user_join_game", result.value.id)
