extends Node

signal updated(outfit)

const outfits: Outfits = preload("res://data/character/outfits.tres")

onready var color_picker_panel: Node = $"../ColorPicker"
onready var color_picker: ColorPicker = $"../ColorPicker/ColorPicker"
var coloring: String = ""

var _outfit := {
	"eyes": 1,
	"mouth": 1,
	"base": 1,
	"base_color": "ff0000",
	"shirt": 1,
	"shirt_color": "00ff00",
	"pants": 1,
	"pants_color": "0000ff",
}

func _ready():
	for child in get_children():
		assert(child.connect("prev_pressed", self, "_on_prev_pressed") == OK)
		assert(child.connect("color_pressed", self, "_on_color_pressed") == OK)
		assert(child.connect("next_pressed", self, "_on_next_pressed") == OK)
	
	assert(color_picker.connect("color_changed", self, "_on_color_picked") == OK)

func init(outfit_: Dictionary):
	_outfit = outfit_
	return self

func _incr_type(incr: int, type: String) -> void:
	var old_index: int = _outfit[type]
	var max_index: int = outfits.get_component(type).size()
	var new_index: int = ((old_index + incr - 1) % max_index) + 1

	_outfit[type] = new_index
	emit_signal("updated", _outfit)

func _on_prev_pressed(type: String) -> void:
	_incr_type(-1, type)

func _on_color_pressed(type: String) -> void:
	if coloring == type:
		coloring = ""
	else:
		coloring = type
	
	if coloring.empty():
		color_picker_panel.hide()
	else:
		color_picker.color = _outfit["%s_color" % coloring]
		color_picker_panel.show()

func _on_next_pressed(type: String) -> void:
	_incr_type(1, type)

func _on_color_picked(color: Color) -> void:
	if coloring.empty():
		return
	_outfit["%s_color" % coloring] = color.to_html(false)
	emit_signal("updated", _outfit)
