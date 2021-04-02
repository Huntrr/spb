extends Node

var _hidden := true

func _ready() -> void:
	if _hidden:
		hide()
	else:
		show()

func _notification(what):
	if what == NOTIFICATION_ENTER_TREE:
		assert(get_tree().connect("node_added", self, "_on_add_node") == OK)

func _on_add_node(node: Node) -> void:
	if not node.is_in_group("debug"):
		return
	if _hidden:
		node.hide()
	else:
		node.show()

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.is_action_pressed("ui_debug"):
			_hidden = !_hidden
			if _hidden:
				hide()
			else:
				show()

func hide() -> void:
	for node in get_tree().get_nodes_in_group("debug"):
		node.hide()

func show() -> void:
	for node in get_tree().get_nodes_in_group("debug"):
		node.show()
