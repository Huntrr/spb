class_name SpaceshipBlueprint
extends Resource
# Utility for handling spaceship blueprints.

const tile_registry: TileRegistry = (
	preload("res://data/tiles/tile_registry.tres"))

var cells: Array = []

var cells_cache: Dictionary = {}
var has_bg_cache: Dictionary = {}

func from_blueprint(blueprint: Node) -> SpaceshipBlueprint:
	# Loads a Spaceship from blueprint tilemaps.
	cells_cache.clear()
	has_bg_cache.clear()
	
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
					if tile.blueprint_placement.rotate_like_door:
						var auto_coord: Vector2 = (
							tm.get_cell_autotile_coord(coord.x, coord.y))
						if tile.blueprint_placement.door_vertical_tiles.has(
								auto_coord):
							rot = Rotation.DOWN
						else:
							rot = Rotation.LEFT
					cells_.append(_mk_cell(x, y, id, rot))
	cells = cells_
	return self


func from_string(json: String) -> SpaceshipBlueprint:
	# Loads a Spaceship from a JSON string.
	cells_cache.clear()
	has_bg_cache.clear()
	
	var json_result := JSON.parse(json)
	if json_result.error == OK:
		cells = json_result.result
	else:
		push_error(json_result.error_string)
		cells = []
	return self


func _init(cells_: Array = []) -> void:
	cells = cells_


func is_empty(pos: Vector2, allow_background: bool = false) -> bool:
	# Returns true if the given tile is empty (or if it's background and
	# |allow_background|).
	var cells_ = get_cellsv(pos)
	if not cells_.empty() and not allow_background:
		return false
	
	for cell in cells_:
		var tile: Tile = tile_registry.by_id(cell.id)
		if not tile.is_background():
			return false
	
	return true

func has_background(pos: Vector2) -> bool:
	if has_bg_cache.has(pos):
		return has_bg_cache[pos]
		
	var layers: Array = get_cellsv(pos)
	for layer in layers:
		var tile: Tile = tile_registry.by_id(layer.id)
		if tile.is_background():
			has_bg_cache[pos] = true
			return true
	has_bg_cache[pos] = false
	return false


func get_bounds() -> Rect2:
	if cells.size() == 0:
		return Rect2(0, 0, 0, 0)
	
	var begin := Vector2(cells[0].x, cells[0].y)
	var end := Vector2(cells[0].x, cells[0].y)
	
	for cell in cells:
		begin.x = min(begin.x, cell.x)
		begin.y = min(begin.y, cell.y)
		end.x = max(end.x, cell.x)
		end.y = max(end.y, cell.y)
	
	return Rect2(begin, end - begin)


func to_blueprint(blueprint: Node) -> void:
	# Loads this Spaceship into a Blueprint.
	blueprint.background.clear()
	blueprint.objects.clear()
	
	for cell in cells:
		var tile: Tile = tile_registry.by_id(cell.id)
		var tm: TileMap
		if tile.is_background():
			tm = blueprint.background
		else:
			tm = blueprint.objects
		var coord := Vector2(cell.x, cell.y)
		var rot: int = cell.rot
		if tile.blueprint_placement.rotate_like_door:
			rot = tile.blueprint_placement.default_rotation
		blueprint.place_tile(tm, coord, tile, rot)


func to_ship(ship) -> void:
	ship.load_from_spb(self)


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
				
				for i in range(tile.clearance_tiles):
					var check_pos: Vector2 = (
						pos + Rotation.get_dir(layer.rot) * (i + 1))
					if not is_empty(check_pos, has_background(pos)):
						cell_errors.append(
							"%s needs at least %d tile%s of clearance" % [
								tile.pretty_name, tile.clearance_tiles,
								"s" if tile.clearance_tiles != 1 else ""])
						break
			
			if tile.blueprint_placement.rotate_like_door:
				for i in [-1, 1]:
					var check_pos: Vector2 = pos + i * Rotation.get_dir(layer.rot)
					if (has_background(check_pos) and
						not _has_id(check_pos, layer.id, layer.rot)):
						cell_errors.append("Doors must connect 2 walls.")
						break
			elif (not tile.rotatable and
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
				if not has_background(pos + need_mount):
					cell_errors.append(
						"Object needs to be mounted on a wall.")
			else:
				var is_mounted := false
				for v in [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT]:
					if has_background(pos + v):
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
	if cells_cache.has(Vector2(x, y)):
		return cells_cache[Vector2(x, y)]
		
	var result := []
	for cell in cells:
		if cell.x == x and cell.y == y:
			result.append(cell)
	cells_cache[Vector2(x, y)] = result
	return result


func _has_id(pos: Vector2, id: int, rot: int) -> bool:
	# Returns true if cell at |pos| contains a tile with id |id|.
	var cells_: Array = get_cellsv(pos)
	for cell in cells_:
		if cell.id == id and cell.rot == rot:
			return true
	return false

static func _mk_cell(x: int, y: int, id: int, rot: int) -> Dictionary:
	return {
		"x": x,
		"y": y,
		"id": id,
		"rot": rot,
	}


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
