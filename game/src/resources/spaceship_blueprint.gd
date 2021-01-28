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
	
	var used_rect: Rect2 = blueprint.background.get_used_rect()
	var used_rect_obj: Rect2 = blueprint.objects.get_used_rect()
	if used_rect_obj.size != Vector2.ZERO:
		used_rect = used_rect.merge(used_rect_obj)
	
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
		blueprint.place_tile(tm, coord, tile, cell.rot)


func to_string() -> String:
	# Saves thie Spaceship into a JSON string.
	return JSON.print(cells)


func validate() -> Dictionary:
	# Returns a list of validation errors for this spaceship.
	var errors := {}
	var visited := {}
	var backgrounds := {}
	for cell in cells:
		var cell_errors := []
		var pos := Vector2(cell.x, cell.y)
		if visited.has(pos):
			continue
		visited[pos] = get_cellsv(pos)
		var num_backgrounds := 0
		var num_objects := 0
		var need_outside := false
		var need_inside := false
		var need_mount := Vector2.ZERO
		for layer in visited[pos]:
			var tile: Tile = tile_registry.by_id(layer.id)
			if tile.type == "BACKGROUND":
				num_backgrounds += 1
				backgrounds[pos] = false
			else:
				num_objects += 1
				if tile.type == "INSIDE":
					need_inside = true
				elif tile.type == "OUTSIDE":
					need_outside = true
				
				if tile.type == "OUTSIDE" or tile.type == "FLEX":
					if tile.mount_type == "BEHIND":
						need_mount = _behind(layer.rot)
			
			if (not tile.rotatable and
					layer.rot != tile.blueprint_placement.default_rotation):
				cell_errors.append("%s can't be rotated." % tile.pretty_name)
			elif tile.prohibited_rots.has(layer.rot):
				cell_errors.append(
					"%s can't be rotated that way." % tile.pretty_name)
		
		if num_backgrounds > 1:
			cell_errors.append("More than 1 background tile.")
		if num_objects > 1:
			cell_errors.append("More than 1 object tile.")
		
		if need_inside and num_backgrounds == 0:
			cell_errors.append("Object can only be placed inside.")
		if need_outside and num_backgrounds != 0:
			cell_errors.append("Object can only be placed outside.")
		
		if not need_inside and num_backgrounds == 0 and num_objects != 0:
			# Outside objects must be mounted to a wall.
			if need_mount != Vector2.ZERO:
				if not _has_background(pos + need_mount):
					cell_errors.append(
						"Object needs to be mounted on a wall.")
			else:
				var is_mounted := false
				for v in [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT]:
					if _has_background(pos + v):
						is_mounted = true
				if not is_mounted:
					cell_errors.append("Object needs to be next to a wall.")
		if not cell_errors.empty():
			errors[pos] = cell_errors
	if not _connected(backgrounds):
		if not errors.has(Vector2.ZERO):
			errors[Vector2.ZERO] = []
		errors[Vector2.ZERO].append("All floors must be connected.")
	return errors


func get_cellsv(pos: Vector2) -> Array:
	return get_cells(int(pos.x), int(pos.y))


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


func _has_background(pos: Vector2) -> bool:
	var layers: Array = get_cellsv(pos)
	for layer in layers:
		var tile: Tile = tile_registry.by_id(layer.id)
		if tile.type == "BACKGROUND":
			return true
	return false


func _behind(rot: int) -> Vector2:
	match rot:
		Rotation.UP:
			return Vector2.DOWN
		Rotation.RIGHT:
			return Vector2.LEFT
		Rotation.DOWN:
			return Vector2.UP
		Rotation.LEFT:
			return Vector2.RIGHT
	
	return Vector2.ZERO


func _connected(graph: Dictionary) -> bool:
	var stack := []
	if graph.empty():
		return true
	stack.push_back(graph.keys()[0])
	while not stack.empty():
		var pos: Vector2 = stack.pop_back()
		graph[pos] = true
		for v in [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT]:
			if graph.has(pos + v) and not graph[pos + v]:
				stack.push_back(pos + v)
	
	for value in graph.values():
		if not value:
			return false
			
	return true
