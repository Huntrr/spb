extends Control
# Controls a single tile-selector button node.

signal tile_selected(tile)

export(Resource) var tile

const normal_style: StyleBox = (
	preload("res://assets/ui/blueprint/button_normal.tres"))
const hover_style: StyleBox = (
	preload("res://assets/ui/blueprint/button_hover.tres"))
const focus_style: StyleBox = (
	preload("res://assets/ui/blueprint/button_focus.tres"))
const active_style: StyleBox = (
	preload("res://assets/ui/blueprint/button_active.tres"))

onready var texture_rect: TextureRect = $VBoxContainer/TextureRect
onready var label: Label = $VBoxContainer/Label

var active := false setget _set_active
var hovered := false setget _set_hovered
var focused := false setget _set_focused

func _get_configuration_warning() -> String:
	if not (tile is Tile):
		return "|tile| is not a Tile"
	return ""


func _ready() -> void:
	label.set_text(tile.pretty_name)
	texture_rect.set_texture(tile.blueprint_placement.tile_texture)
	self.active = false
	
	focus_mode = Control.FOCUS_ALL
	
	connect("mouse_entered", self, "_on_mouse_enter")
	connect("mouse_exited", self, "_on_mouse_exit")
	connect("focus_entered", self, "_on_focus_enter")
	connect("focus_exited", self, "_on_focus_exit")


func _gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT and event.pressed:
			_on_click()
	if event is InputEventKey:
		if event.is_action_pressed("ui_accept"):
			_on_click()


func init(_tile: Tile) -> Node:
	self.tile = _tile
	return self


func _on_click():
	emit_signal("tile_selected", tile)


func _on_mouse_enter():
	self.hovered = true


func _on_mouse_exit():
	self.hovered = false


func _on_focus_enter():
	self.focused = true


func _on_focus_exit():
	self.focused = false


func _set_focused(new_focused: bool):
	focused = new_focused
	if active or hovered:
		return
	if focused:
		add_stylebox_override("panel", focus_style)
	else:
		add_stylebox_override("panel", normal_style)


func _set_hovered(new_hovered: bool):
	hovered = new_hovered
	if active:
		return
	if hovered:
		add_stylebox_override("panel", hover_style)
	else:
		_set_focused(focused)


func _set_active(new_active: bool):
	active = new_active
	if active:
		add_stylebox_override("panel", active_style)
	else:
		_set_hovered(hovered)
