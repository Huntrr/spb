extends WindowDialog

const ValidationError := (
	preload("res://scenes/ship_builder/validation_error.tscn"))

onready var error_container = $VBoxContainer/Box/ScrollContainer/VBoxContainer

func _ready() -> void:
	_clear()


func show_errors(errors: Dictionary) -> void:
	_clear()
	for pos in errors.keys():
		var messages: Array = errors[pos]
		var validation_error = ValidationError.instance().init(pos, messages)
		error_container.add_child(validation_error)
	popup()


func _clear() -> void:
	for child in error_container.get_children():
		child.queue_free()
