extends TileSet
# TileSet extension to allow doors to tile with wall boundaries.

var door_tile: Tile
var background: TileMap
var sideways_coord: Vector2 = Vector2(4, 0)

func _init(
	_door_tile: Tile, _background: TileMap, _sideways_coord: Vector2) -> void:
	door_tile = _door_tile
	background = _background
	sideways_coord = _sideways_coord
	print("GOTCHA")


func _forward_subtile_selection(autotile_id, bitmask, tilemap, coord):
	print("!")
	if autotile_id == door_tile.blueprint_placement.tile_id:
		var has_up: bool = (
			background.get_cellv(coord + Vector2.UP) != TileMap.INVALID_CELL)
		var has_left: bool = (
			background.get_cellv(coord + Vector2.LEFT) != TileMap.INVALID_CELL)
		var has_down: bool = (
			background.get_cellv(coord + Vector2.DOWN) != TileMap.INVALID_CELL)
		var has_right: bool = (
			background.get_cellv(coord + Vector2.RIGHT) != TileMap.INVALID_CELL)
		print("2")
		if (not has_left or not has_right) and (has_up and has_down):
			print("3")
			return sideways_coord
