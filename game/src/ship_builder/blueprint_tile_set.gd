extends TileSet
# Hacky TileSet extension to allow doors to tile with wall boundaries.

# Script does nothing unless this is active.
var active: bool = false

# Point to a Tile resource to use as the door tile.
var door_tile: Tile

# Position of the sideways subtile in the door tile's autotile.
var sideways_tile_coord: Vector2

# Set to the background tilemap.
var background: TileMap


func _forward_subtile_selection(autotile_id, _bitmask, _tilemap, coord):
	if not active:
		return null
	
	if autotile_id == door_tile.blueprint_placement.tile_id:
		var has_up: bool = (
			background.get_cellv(coord + Vector2.UP) != TileMap.INVALID_CELL)
		var has_left: bool = (
			background.get_cellv(coord + Vector2.LEFT) != TileMap.INVALID_CELL)
		var has_down: bool = (
			background.get_cellv(coord + Vector2.DOWN) != TileMap.INVALID_CELL)
		var has_right: bool = (
			background.get_cellv(coord + Vector2.RIGHT) != TileMap.INVALID_CELL)
		if (not has_left or not has_right) and (has_up and has_down):
			return sideways_tile_coord
			
	return null
