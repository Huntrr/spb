extends Node2D
# Controller for the Blueprint node.

# Emitted when an error tile is highlighted.
signal is_error_highlighted(position)

const TILE_SIZE: int = 16

export(float) var zoom_amount = 1
export(float) var min_zoom = 0.5
export(float) var max_zoom = 10
# When we center the ship, this is how much padding we will
# give the sides, in pixels.
export(float) var center_zoom_padding = 50

export(Resource) var door_tile
export(Vector2) var sideways_tile_coord

onready var grid = $Grid
onready var background = $Layers/Background
onready var objects = $Layers/Objects
onready var construct = $Layers/Construct
onready var errors = $Layers/Errors

var dragging := false setget _set_dragging
var placing := false setget _set_placing
var placing_coord: Vector2
var placing_rotation: int

var zoom := 3.0 setget _set_zoom
var current_tile: Tile = null
var current_tile_rotation: int

var drag_did_move := false

var error_locations := [] setget show_errors


func _get_configuration_warning() -> String:
	if not (door_tile is Tile):
		return "door_tile is not a Tile"
	return ""


func _ready() -> void:
	zoom = scale.x
	objects.tile_set.background = background
	objects.tile_set.door_tile = door_tile
	objects.tile_set.sideways_tile_coord = sideways_tile_coord
	objects.tile_set.active = true


func _input(event: InputEvent) -> void:
	if dragging and event is InputEventMouseMotion:
		translate(event.relative)
		drag_did_move = true
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
		_on_mouse_move()


func highlight_error(position: Vector2) -> void:
	# Highlights the error tile at |position|.
	var error_id: int = errors.tile_set.find_tile_by_name("error")
	var error_hover_id: int = errors.tile_set.find_tile_by_name("error_hover")
	for pos in error_locations:
		if pos == position:
			errors.set_cellv(pos, error_hover_id)
		else:
			errors.set_cellv(pos, error_id)


func focus_tile(coord: Vector2) -> void:
	# Focuses on a specific tile |coord|
	zoom = 3
	scale = Vector2(zoom, zoom)
	
	var position: Vector2 = construct.map_to_world(coord)
	var viewport_center: Vector2 = get_viewport().size / 2
	global_position = (
		viewport_center - position * scale +
		Vector2.UP * center_zoom_padding / 2)
	grid.update()
	_update_construct()


func show_errors(error_locations_: Array) -> void:
	error_locations = error_locations_
	
	# Highlights each error location in red.
	errors.clear()
	var error_id: int = errors.tile_set.find_tile_by_name("error")
	for pos in error_locations:
		errors.set_cellv(pos, error_id)


func center() -> void:
	# Centers the current blueprint on screen.
	var used_rect: Rect2 = background.get_used_rect()
	var used_rect_obj: Rect2 = objects.get_used_rect()
	if used_rect_obj.size != Vector2.ZERO:
		used_rect = used_rect.merge(used_rect_obj)
	var padding: Vector2 = Vector2(2, 2) * center_zoom_padding
	var ship_size: Vector2 = used_rect.size * 16 + padding
	var viewport_size: Vector2 = get_viewport().size
	
	zoom = min(
		 viewport_size.x / ship_size.x, viewport_size.y / ship_size.y)
	scale = Vector2(zoom, zoom)
	
	var start: Vector2 = construct.map_to_world(used_rect.position)
	var end: Vector2 = construct.map_to_world(used_rect.end)
	var ship_center: Vector2 = (start + end) / 2
	var viewport_center: Vector2 = viewport_size / 2
	global_position = (
		viewport_center - ship_center * scale +
		Vector2.UP * center_zoom_padding / 2)
	grid.update()
	_update_construct()
	errors.clear()


func place_tile(tilemap: TileMap, coord: Vector2, tile: Tile, rot: int):
	var id = tile.blueprint_placement.tile_id
	
	
	var flip_x: bool = rot == Rotation.LEFT or rot == Rotation.UP
	var flip_y: bool = rot == Rotation.UP or rot == Rotation.RIGHT
	var transpose: bool = rot == Rotation.LEFT or rot == Rotation.RIGHT
	
	if id == -1 and tilemap != construct:
		for tm in [background, objects]:
			tm.set_cellv(coord, -1)
	else:
		tilemap.set_cellv(coord, id, flip_x, flip_y, transpose)
	
	for tm in [background, objects, construct]:
		tm.update_bitmask_region(coord - Vector2(1, 1), coord + Vector2(1, 1))


func _update_construct() -> void:
	construct.clear()
	var mouse_coord: Vector2 = (
		construct.world_to_map(get_local_mouse_position()))
	var tile_coord: Vector2
	var tile_rotation: int
	
	if current_tile != null:
		if placing and current_tile.rotatable:
			if mouse_coord.x == placing_coord.x:
				if mouse_coord.y > placing_coord.y:
					if not current_tile.prohibited_rots.has(Rotation.DOWN):
						placing_rotation = Rotation.DOWN
				elif mouse_coord.y < placing_coord.y:
					if not current_tile.prohibited_rots.has(Rotation.UP):
						placing_rotation = Rotation.UP
			elif mouse_coord.y == placing_coord.y:
				if mouse_coord.x > placing_coord.x:
					if not current_tile.prohibited_rots.has(Rotation.RIGHT):
						placing_rotation = Rotation.RIGHT
				elif mouse_coord.x < placing_coord.x:
					if not current_tile.prohibited_rots.has(Rotation.LEFT):
						placing_rotation = Rotation.LEFT
		
		if placing and not current_tile.is_background():
			tile_rotation = placing_rotation
			if not current_tile.is_background():
				tile_coord = placing_coord
		else:
			tile_coord = mouse_coord
			tile_rotation = current_tile_rotation
			
		_place_tile(construct, tile_coord, tile_rotation)

func _on_mouse_move() -> void:
	var tile_coord: Vector2 = construct.world_to_map(get_local_mouse_position())
	if placing and current_tile != null:
		if current_tile.is_background():
			_place_tile(background, tile_coord, placing_rotation)
	if errors.get_cellv(tile_coord) == errors.tile_set.find_tile_by_name("error"):
		emit_signal("is_error_highlighted", tile_coord)


func _set_placing(new_placing: bool) -> void:
	if current_tile != null:
		if not current_tile.is_background():
			if not placing and new_placing:
				# User is pressing their mouse button.
				placing_coord = construct.world_to_map(get_local_mouse_position())
				placing_rotation = current_tile_rotation
			elif placing and not new_placing:
				# User is releasing their mouse button.
				_place_tile(objects, placing_coord, placing_rotation)
		else:
			if not placing and new_placing:
				placing_rotation = current_tile_rotation
			
	placing = new_placing


func _place_tile(tilemap: TileMap, coord: Vector2, rot: int):
	place_tile(tilemap, coord, current_tile, rot)


func _remove_tile(tilemap: TileMap, coord: Vector2):
	tilemap.set_cellv(coord, -1)
	
	for tm in [background, objects, construct]:
		tm.update_bitmask_region(coord - Vector2(1, 1), coord + Vector2(1, 1))


func _set_zoom(new_zoom: float) -> void:
	zoom = clamp(new_zoom, min_zoom, max_zoom)
	var pre_mouse_pos := get_local_mouse_position()
	scale = Vector2(zoom, zoom)
	var post_mouse_pos := get_local_mouse_position()
	translate((post_mouse_pos - pre_mouse_pos) * scale)
	grid.update()


func _set_dragging(new_dragging: bool) -> void:
	if not dragging and new_dragging:
		drag_did_move = false
	elif dragging and not new_dragging:
		if not drag_did_move:
			var coord: Vector2 = (
				construct.world_to_map(get_local_mouse_position()))
			_remove_tile(objects, coord)
	dragging = new_dragging
