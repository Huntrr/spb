class_name Ship
extends Node2D

const CELL_SIZE := 32
const FLOOR_TILE_NAME := "floor_1"
const WALL_TILE_NAME := "wall_1"
const SURROUND_DIRS := [
	Vector2.DOWN, Vector2.LEFT, Vector2.UP, Vector2.RIGHT,
	Vector2.UP + Vector2.RIGHT, Vector2.UP + Vector2.LEFT,
	Vector2.DOWN + Vector2.RIGHT, Vector2.DOWN + Vector2.LEFT,
]

const tile_registry: TileRegistry = preload("res://data/tiles/tile_registry.tres")

onready var _base: TileMap = $Base
onready var _interior: YSort = $Interior
onready var _ceiling: TileMap = $Ceiling
onready var _exterior: YSort = $Exterior

onready var _floor_id: int = _base.tile_set.find_tile_by_name(FLOOR_TILE_NAME)
onready var _wall_id: int = _base.tile_set.find_tile_by_name(WALL_TILE_NAME)

func load_from_spb(blueprint: SpaceshipBlueprint) -> void:
	for container in [_base, _interior, _ceiling, _exterior]:
		for child in container.get_children():
			child.queue_free()
		if container is TileMap:
			container.clear()
	
	for cell in blueprint.cells:
		var coord := Vector2(cell.x, cell.y)
		var rot: int = cell.rot
		var tile: Tile = tile_registry.by_id(cell.id)
		
		if tile.is_background():
			_base.set_cellv(coord, _floor_id)
			
			for v in SURROUND_DIRS:
				if _base.get_cellv(coord + v) == TileMap.INVALID_CELL:
					_base.set_cellv(coord + v, _wall_id)
		
		if tile.ship_placement:
			var position: Vector2 = coord * CELL_SIZE + Vector2.ONE * CELL_SIZE / 2
			if tile.ship_placement.object != null:
				var type := "IN" if blueprint.has_background(coord) else "OUT"
				var instance: ObjectTile = (
					tile.ship_placement.object.instance().init(rot, type))
				instance.position = position
				_interior.add_child(instance)
			
			if tile.ship_placement.exterior_object != null:
				var type := "UP" if blueprint.has_background(coord) else "OUT"
				var instance: ObjectTile = (
					tile.ship_placement.exterior_object.instance().init(rot, type))
				instance.position = position
				_exterior.add_child(instance)
	for tm in [_base, _ceiling]:
		tm.update_bitmask_region()
