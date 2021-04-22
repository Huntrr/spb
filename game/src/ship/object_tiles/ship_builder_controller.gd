extends Node

onready var ShipBuilder: PackedScene = load("res://scenes/ship_builder/ship_builder.tscn")

var _overlay: Node
var _local_user: Node

func _ready():
	$"../KeyListener".connect("triggered", self, "_on_triggered")
	$"../KeyListener".connect("exited", self, "_on_exited")

func _on_triggered(node: Node) -> void:
	if not node.is_current_player():
		return
	
	_exit()
	
	_local_user = node
	_local_user.sit()
	
	_overlay = ShipBuilder.instance()
	_overlay.connect("tree_exited", self, "_exit")
	add_child(_overlay)

func _on_exited(node: Node) -> void:
	if _local_user == node:
		_exit()

func _exit() -> void:
	if _local_user:
		_local_user.stand()
		_local_user = null
	
	if _overlay:
		_overlay.queue_free()
