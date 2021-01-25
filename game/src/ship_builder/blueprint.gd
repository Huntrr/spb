extends Node2D
# Controller for the Blueprint node.

export(float) var zoom_amount = 1
export(float) var min_zoom = 0.5
export(float) var max_zoom = 10

onready var grid = $Grid
onready var background = $Layers/Background
onready var objects = $Layers/Objects
onready var construct = $Layers/Construct

var dragging := false
var placing := false setget _set_placing
var zoom := 3.0 setget _set_zoom
var current_tile: Tile = null


func _ready() -> void:
	zoom = scale.x


func _input(event: InputEvent) -> void:
	if dragging and event is InputEventMouseMotion:
		translate(event.relative)
		grid.update()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_RIGHT:
			self.dragging = event.pressed
		if event.button_index == BUTTON_LEFT:
			self.placing = event.pressed
	if event is InputEventPanGesture:
		self.zoom -= zoom_amount * event.delta.y
	if event is InputEventMouse:
		_update_construct()


func _update_construct() -> void:
	construct.clear()
	var tile_coord: Vector2 = construct.world_to_map(get_local_mouse_position())
	if current_tile != null:
		var tile_id: int = current_tile.blueprint_placement.tile_id
		construct.set_cellv(tile_coord, tile_id)
		construct.update_bitmask_area(tile_coord)


func _set_placing(new_placing: bool) -> void:
	var tile_coord: Vector2 = construct.world_to_map(get_local_mouse_position())
	if current_tile != null:
		var tile_id: int = current_tile.blueprint_placement.tile_id
		var is_background: bool = current_tile.blueprint_placement.is_background
		if placing:
			if not new_placing:
				# User is releasing their mouse button.
				var tilemap: TileMap
				if current_tile.blueprint_placement.is_background:
					tilemap = background
				else:
					tilemap = objects
				tilemap.set_cellv(tile_coord, tile_id)
				tilemap.update_bitmask_area(tile_coord)
				
	placing = new_placing


func _set_zoom(new_zoom: float) -> void:
	zoom = clamp(new_zoom, min_zoom, max_zoom)
	var pre_mouse_pos := get_local_mouse_position()
	scale = Vector2(zoom, zoom)
	var post_mouse_pos := get_local_mouse_position()
	translate((post_mouse_pos - pre_mouse_pos) * scale)
	grid.update()
