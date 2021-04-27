extends Node
class_name OverlayManager
# Simple node that opens an overlay when a user triggers a multi-use station.
# Set as the child to a KeyListener.

onready var Log := Logger.new(self)

signal created_overlay(overlay, user)

export(String, FILE) var overlay_path
onready var overlay: PackedScene = load(overlay_path)

onready var object_tile = $"../../"

var _overlay: Node
var _local_user: Node

func _ready():
	get_parent().connect("triggered", self, "_on_triggered")
	get_parent().connect("exited", self, "_on_exited")

func _physics_process(_delta: float) -> void:
	if _local_user and _local_user.using != object_tile:
		_local_exit()

func _on_triggered(node: Node) -> void:
	if node.is_current_player() and node != _local_user:
		_local_user = node
		_overlay = overlay.instance()
		_overlay.connect("tree_exited", self, "_on_exited", [node])
		add_child(_overlay)
		emit_signal("created_overlay", _overlay, _local_user)
	if node.is_current_player() or multiplayer.is_network_server():
		node.use(object_tile)

func _on_exited(node: Node) -> void:
	if _local_user == node:
		_local_exit()
	
	if multiplayer.is_network_server():
		_server_exit(node)

func _local_exit() -> void:
	# Client-side exit ship builder logic
	if _local_user:
		rpc("_call_server_exit", get_path_to(_local_user))
		_local_user.stand()
		_local_user = null
	
	if _overlay:
		_overlay.queue_free()

master func _call_server_exit(node_path: NodePath) -> void:
	# Server-side exit ship builder logic.
	var node: Node = get_node(node_path)
	if node.peer_id != multiplayer.get_rpc_sender_id():
		Log.error("Peer %d tried to act as %d" % [
			multiplayer.get_rpc_sender_id(), node.peer_id])
		return
	_server_exit(node)
	
master func _server_exit(node: Node) -> void:
	# Server-side exit ship builder logic.
	if node.using == object_tile:
		node.stand()
