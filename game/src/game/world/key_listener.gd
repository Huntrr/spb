extends CanvasLayer
# Component that can listen to nearby playeys pressing keys, and then
# trigger other actions.

onready var Log := Logger.new(self)

# Emitted when a player triggers this KeyListener.
signal triggered(triggering_node)
# Emitted when a player exits the domain of this KeyListener.
signal exited(triggering_node)

# Area player must be in to trigger this listener.
export(NodePath) var _trigger_area
# Group required by triggerers.
export(String) var _triggerer_group = "player"
# Input action that triggers this.
export(String) var _trigger_action = "game_use"
# Verb relating to this use of this listener.
export(String) var _trigger_verb = "use"
export(Vector2) var _position_offset = Vector2(0, -72)

onready var _trigger_area_node: Area2D = get_node(_trigger_area)
onready var _panel: PanelContainer = $PanelContainer

var _triggerer: Node = null
var _active = false
onready var _id = get_path()

func _ready() -> void:
	var key = InputMap.get_action_list(_trigger_action)[0].as_text()
	$PanelContainer/MarginContainer/Label.set_text(
		"Press [%s] to %s" % [key, _trigger_verb])
	_panel.hide()
	
	var area: Area2D = _trigger_area_node
	assert(area.connect("body_entered", self, "_on_body_entered") == OK)
	assert(area.connect("body_exited", self, "_on_body_exited") == OK)

func _get_configuration_warning() -> String:
	if _trigger_area.is_empty():
		return "Must set a Trigger Area."
	if not _trigger_area is Area2D:
		return "Trigger Area must be an Area2D"
	return ""

func _on_body_entered(node: Node) -> void:
	if node.is_in_group(_triggerer_group) and node.is_current_player():
		_triggerer = node

func _on_body_exited(node: Node) -> void:
	if node.is_in_group(_triggerer_group) and node.is_current_player():
		emit_signal("exited", node)
		_triggerer = null
		KeyListenerOrchestrator.release_active(_id)

func _process(_delta: float) -> void:
	if not _triggerer:
		_panel.hide()
		return
	
	var trigger_position: Vector2 = (
		_triggerer.global_position - _trigger_area_node.global_position)
	if KeyListenerOrchestrator.attempt_active(_id, trigger_position.length()):
		_panel.show()
		var area_position: Vector2 = (
			_triggerer.get_global_transform_with_canvas().origin)
		_panel.set_position(area_position + trigger_position + _position_offset -
					 _panel.rect_size / 2.0)
		if Input.is_action_just_pressed(_trigger_action):
			emit_signal("triggered", _triggerer)
			rpc("_trigger", get_path_to(_triggerer))
	else:
		_panel.hide()

master func _trigger(node_path: NodePath) -> void:
	var node: Node = get_node(node_path)
	if node.peer_id != multiplayer.get_rpc_sender_id():
		Log.error("Peer %d tried to act as %d" % [
			multiplayer.get_rpc_sender_id(), node.peer_id])
		return
	if _trigger_area_node.overlaps_body(node):
		emit_signal("triggered", node)
