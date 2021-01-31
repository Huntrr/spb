extends Popup

# Emitted when one of the validation errors is hovered over.
signal is_highlighted(position)
# Emitted when one of the validation errors is pressed.
signal is_selected(position)

const ValidationError := (
	preload("res://scenes/ship_builder/validation_error.tscn"))

onready var error_container = $VBoxContainer/Box/ScrollContainer/VBoxContainer
var validation_errors := []

func _ready() -> void:
	_clear()


func show_errors(errors: Dictionary) -> void:
	_clear()
	for pos in errors.keys():
		var messages: Array = errors[pos]
		var validation_error = ValidationError.instance().init(pos, messages)
		error_container.add_child(validation_error)
		validation_errors.append(validation_error)
		validation_error.connect("is_highlighted", self, "_on_is_highlighted")
		validation_error.connect("is_selected", self, "_on_is_selected")
	show()


func highlight(position: Vector2) -> void:
	for child in validation_errors:
		child.set_highlighted(child.position == position)
		if child.position == position:
			child.grab_focus()


func _clear() -> void:
	validation_errors = []
	for child in error_container.get_children():
		child.queue_free()


func _on_is_highlighted(position: Vector2) -> void:
	emit_signal("is_highlighted", position)


func _on_is_selected(position: Vector2) -> void:
	emit_signal("is_selected", position)
