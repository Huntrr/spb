extends Node

const error_dialog_scene: PackedScene = (
	preload("res://scenes/menu/error_dialog.tscn"))


func show_error(status: Status) -> void:
	var error_dialog: Node = error_dialog_scene.instance()
	get_parent().add_child(error_dialog)
	error_dialog.show_error(status.code, status.message)
