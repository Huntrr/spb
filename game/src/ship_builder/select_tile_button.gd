extends Control
# Controls a single tile-selector button node.

signal tile_selected(tile, rotation)

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

onready var rotation: int setget _set_rotation

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
	self.rotation = tile.blueprint_placement.default_rotation
	
	focus_mode = Control.FOCUS_ALL
	
	connect("mouse_entered", self, "_on_mouse_enter")
	connect("mouse_exited", self, "_on_mouse_exit")
	connect("focus_entered", self, "_on_focus_enter")
	connect("focus_exited", self, "_on_focus_exit")
	
	get_tree().get_root().connect("size_changed", self, "_on_resize")


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


func _update() -> void:
	texture_rect.rect_rotation = _get_yaw(rotation)
	texture_rect.rect_pivot_offset = texture_rect.rect_size / 2


func _on_resize() -> void:
	update()


func _on_click():
	if active and tile.rotatable:
		self.rotation = Rotation.next(rotation)
	emit_signal("tile_selected", tile, rotation)


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

func _set_rotation(new_rotation: int):
	rotation = new_rotation
	_update()


func _get_yaw(rot: int):
	match rot:
		Rotation.UP:
			return 180
		Rotation.RIGHT:
			return 270
		Rotation.DOWN:
			return 0
		Rotation.LEFT:
			return 90


func _get_pos(rot: int):
	match rot:
		Rotation.UP:
			return Vector2(-1, -1)
		Rotation.RIGHT:
			return Vector2(0, -1)
		Rotation.DOWN:
			return Vector2(0, 0)
		Rotation.LEFT:
			return Vector2(-1, 0)
