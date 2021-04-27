extends OverlayManager

func _ready():
	connect("created_overlay", self, "_on_created_overlay")

func _on_created_overlay(overlay: Node, user: Player) -> void:
	overlay.init(user.get_outfit())
	overlay.connect("set_outfit", self, "_on_set_outfit", [user])

func _on_set_outfit(outfit: Dictionary, user: Player) -> void:
	rpc("_server_set_outfit", outfit, get_path_to(user))

master func _server_set_outfit(outfit: Dictionary, user_path: NodePath) -> void:
	var user: Player = get_node(user_path)
	if user.peer_id != multiplayer.get_rpc_sender_id():
		return
	if user.using != object_tile:
		Log.error("%s tried to change outfits outside of a dressing room!" % 
			user.peer_id)
		return
	
	var response_status: StatusOr = yield(Connection.request(
		"universe", "update_outfit", HTTPClient.METHOD_POST, {
			"user_id": user.info.id,
			"outfit": outfit
		}), "completed")
	if not response_status.ok():
		push_error(response_status.status.message)
		return
	
	var response: Dictionary = response_status.value
	user.set_outfit(response)
