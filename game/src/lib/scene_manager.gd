extends Node

const LOGIN_SCENE = "res://scenes/menu/login.tscn"
const SERVER_SCENE = "res://scenes/server.tscn"

onready var root: Node = get_tree().get_root()
onready var current_scene: Node = root.get_child(root.get_child_count() - 1)


func goto(path):
	call_deferred("_deferred_goto_scene", path)


func _deferred_goto_scene(path) -> void:
	current_scene.free()
	var new_scene: PackedScene = ResourceLoader.load(path)
	current_scene = new_scene.instance()
	get_tree().get_root().add_child(current_scene)
	
	# Make it compatible with the SceneTree.change_scene() API.
	get_tree().set_current_scene(current_scene)
