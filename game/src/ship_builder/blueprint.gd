extends Node2D
# Controller for the Blueprint node.

export(float) var zoom_amount = 1
export(float) var min_zoom = 0.5
export(float) var max_zoom = 10

export(Resource) var door_tile
export(Vector2) var sideways_tile_coord

const DoorTileSet := preload("res://src/ship_builder/door_tile_set.gd")

onready var grid = $Grid
onready var background = $Layers/Background
onready var objects = $Layers/Objects
onready var construct = $Layers/Construct

var dragging := false
var placing := false setget _set_placing
var placing_coord: Vector2
var placing_rotation: int

var zoom := 3.0 setget _set_zoom
var current_tile: Tile = null
var current_tile_rotation: int


func _get_configuration_warning() -> String:
	if not (door_tile is Tile):
		return "door_tile is not a Tile"
	return ""


func _ready() -> void:
	zoom = scale.x
	objects.tile_set.set_script(
		DoorTileSet.new(door_tile, background, sideways_tile_coord))


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
		_on_mouse_move()


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
					placing_rotation = Rotation.DOWN
				elif mouse_coord.y < placing_coord.y:
					placing_rotation = Rotation.UP
			elif mouse_coord.y == placing_coord.y:
				if mouse_coord.x > placing_coord.x:
					placing_rotation = Rotation.RIGHT
				elif mouse_coord.x < placing_coord.x:
					placing_rotation = Rotation.LEFT
		
		if placing and not current_tile.blueprint_placement.is_background:
			tile_rotation = placing_rotation
			if not current_tile.blueprint_placement.is_background:
				tile_coord = placing_coord
		else:
			tile_coord = mouse_coord
			tile_rotation = current_tile_rotation
			
		_place_tile(construct, tile_coord, tile_rotation)

func _on_mouse_move() -> void:
	var tile_coord: Vector2 = construct.world_to_map(get_local_mouse_position())
	if placing and current_tile != null:
		if current_tile.blueprint_placement.is_background:
			_place_tile(background, tile_coord, placing_rotation)


func _set_placing(new_placing: bool) -> void:
	if current_tile != null:
		if not current_tile.blueprint_placement.is_background:
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
	var id = current_tile.blueprint_placement.tile_id
	
	var flip_x := rot == Rotation.LEFT or rot == Rotation.UP
	var flip_y := rot == Rotation.UP
	var transpose := rot == Rotation.LEFT or rot == Rotation.RIGHT
	tilemap.set_cellv(coord, id, flip_x, flip_y, transpose)
	tilemap.update_bitmask_area(coord)


func _set_zoom(new_zoom: float) -> void:
	zoom = clamp(new_zoom, min_zoom, max_zoom)
	var pre_mouse_pos := get_local_mouse_position()
	scale = Vector2(zoom, zoom)
	var post_mouse_pos := get_local_mouse_position()
	translate((post_mouse_pos - pre_mouse_pos) * scale)
	grid.update()
