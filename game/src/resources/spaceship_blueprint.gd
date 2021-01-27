class_name SpaceshipBlueprint
extends Resource
# Utility for handling spaceship blueprints.

const tile_registry: TileRegistry = (
	preload("res://data/tiles/tile_registry.tres"))

var cells: Array

func from_blueprint(blueprint: Node) -> SpaceshipBlueprint:
	# Loads a Spaceship from blueprint tilemaps.
	blueprint.background.fix_invalid_tiles()
	blueprint.objects.fix_invalid_tiles()
	
	var used_rect_bg: Rect2 = blueprint.background.get_used_rect()
	var used_rect_obj: Rect2 = blueprint.objects.get_used_rect()
	var used_rect: Rect2 = used_rect_bg.merge(used_rect_obj)
	
	var cells_ := []
	for x in range(used_rect.size.x):
		for y in range(used_rect.size.y):
			var coord := used_rect.position + Vector2(x, y)
			for tm in [blueprint.background, blueprint.objects]:
				var tile: Tile = (
					tile_registry.by_blueprint_id(tm.get_cellv(coord))
				)
				if tile != null:
					var id: int = tile.id
					var rot: int
					if tm.is_cell_transposed(coord.x, coord.y):
						if tm.is_cell_x_flipped(coord.x, coord.y):
							rot = Rotation.LEFT
						else:
							rot = Rotation.RIGHT
					else:
						if tm.is_cell_y_flipped(coord.x, coord.y):
							rot = Rotation.UP
						else:
							rot = Rotation.DOWN
					cells_.append(_mk_cell(x, y, id, rot))
	cells = cells_
	return self


func from_string(json: String) -> SpaceshipBlueprint:
	# Loads a Spaceship from a JSON string.
	var json_result := JSON.parse(json)
	if json_result.error == OK:
		cells = json_result.result
	else:
		push_error(json_result.error_string)
		cells = []
	return self


func _init(cells_: Array = []) -> void:
	cells = cells_


func to_blueprint(blueprint: Node) -> void:
	# Loads this Spaceship into a Blueprint.
	blueprint.background.clear()
	blueprint.objects.clear()
	
	for cell in cells:
		var tile: Tile = tile_registry.by_id(cell.id)
		var tm: TileMap
		if tile.blueprint_placement.is_background:
			tm = blueprint.background
		else:
			tm = blueprint.objects
		var coord := Vector2(cell.x, cell.y)
		print(cell)
		print(tile.blueprint_placement.tile_id)
		blueprint.place_tile(tm, coord, tile, cell.rot)


func to_string() -> String:
	# Saves thie Spaceship into a JSON string.
	return JSON.print(cells)


func validate() -> Array:
	# Returns a list of validation errors for this spaceship.
	return []


func get_cells(x: int, y: int) -> Array:
	var result := []
	for cell in cells:
		if cell.x == x and cell.y == y:
			result.append(cell)
	return result

static func _mk_cell(x: int, y: int, id: int, rot: int) -> Dictionary:
	return {
		"x": x,
		"y": y,
		"id": id,
		"rot": rot,
	}
