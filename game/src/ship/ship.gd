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
onready var _l0: YSort = $Layer0
onready var _ceiling: TileMap = $Ceiling
onready var _l1: YSort = $Layer1

onready var _floor_id: int = _base.tile_set.find_tile_by_name(FLOOR_TILE_NAME)
onready var _wall_id: int = _base.tile_set.find_tile_by_name(WALL_TILE_NAME)

func load_from_spb(blueprint: SpaceshipBlueprint) -> void:
	for container in [_base, _l0, _ceiling, _l1]:
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
			var width := 1
			var height := 1
			
			var bg_dirs := []
			for v in [Vector2.DOWN, Vector2.UP, Vector2.RIGHT, Vector2.LEFT]:
				if blueprint.has_background(coord + v):
					bg_dirs.append(v)
			
			if tile.blueprint_placement.rotate_like_door:
				# Doors should be drawn as a single object.
				var next = Rotation.get_dir(rot).abs()
				if blueprint.has_id(coord - next, cell.id, rot):
					# This is not the first door tile for this door,
					# so skip it.
					continue
				var size := 0
				var local_coord: Vector2 = coord
				while blueprint.has_id(local_coord, cell.id, rot):
					size += 1
					local_coord += next
				if next.x > 0:
					width = size
				else:
					height = size 
				
			var has_l0 := false
			if (tile.ship_placement.object != null and
					blueprint.has_background(coord)):
				var type := "IN"
				var instance: ObjectTile = (
					tile.ship_placement.object.instance().init(
						rot, type, width, height, bg_dirs))
				instance.position = position
				_l0.add_child(instance)
				has_l0 = true
			
			if tile.ship_placement.exterior_object != null:
				var type := "UP" if blueprint.has_background(coord) else "OUT"
				var instance: ObjectTile = (
					tile.ship_placement.exterior_object.instance().init(
					rot, type, width, height, bg_dirs))
				instance.position = position
				
				var layer: YSort = _l1 if has_l0 else _l0
				layer.add_child(instance)
	for tm in [_base, _ceiling]:
		tm.update_bitmask_region()
