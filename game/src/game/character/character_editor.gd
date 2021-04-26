extends Node

onready var popup: WindowDialog = $Control/CenterContainer/Popup
onready var outfit_editor: Node = $Control/CenterContainer/Popup/OutfitEditor
onready var character: Node = $Control/CenterContainer/Popup/Character

func _ready():
	popup.popup()
	assert(popup.connect("hide", self, "_on_popup_hide") == OK)
	assert(popup.get_close_button().connect("pressed", self, "_close") == OK)
	
	assert(outfit_editor.connect("updated", self, "_on_updated") == OK)

func init(outfit: Dictionary):
	character.set_outfit(outfit)
	outfit_editor.init(outfit)
	return self

func _on_updated(outfit: Dictionary) -> void:
	character.set_outfit(outfit)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_close()
	
func _on_popup_hide() -> void:
	popup.show()

func _close() -> void:
	queue_free()
