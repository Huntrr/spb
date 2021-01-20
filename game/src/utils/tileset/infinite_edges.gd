tool
extends TileSet
# Simple utility that causes autotiles to tile with the empty
# tile. Useful for autotiling at the edges of a map.

export(Array, int) var affected_tiles = []

func _is_tile_bound(drawn_id: int, neighbor_id: int) -> bool:
	if affected_tiles.empty() or affected_tiles.count(drawn_id) > 0:
		return neighbor_id == TileMap.INVALID_CELL
	return false
