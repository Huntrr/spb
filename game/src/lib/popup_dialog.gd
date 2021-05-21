extends Node

const popup_dialog_scene: PackedScene = (
	preload("res://scenes/menu/popup_dialog.tscn"))

func show_fatal(status: Status) -> void:
	# Show a message AND exit back to the menu screen.
	var header: String = (
		"Error %d" % status.code if status.code > 0 else "Error!")
	SceneManager.goto(SceneManager.LOGIN_SCENE)
	show_message(header, status.message)

func show_error(status: Status) -> void:
	var header: String = (
		"Error %d" % status.code if status.code > 0 else "Error!")
	show_message(header, status.message)

func show_message(header: String, message: String) -> void:
	print(message)
	var popup_dialog: Node = popup_dialog_scene.instance()
	get_parent().add_child(popup_dialog)
	popup_dialog.show_popup(header, message)
