class_name TileRegistry
extends Resource
# A registry of all available tiles.

export(Array, Resource) var tiles

func by_id(id: int) -> Tile:
	for tile in tiles:
		if tile.id == id:
			return tile
	return null


func by_blueprint_id(bp_id: int) -> Tile:
	for tile in tiles:
		if tile.blueprint_placement.tile_id == bp_id:
			return tile
	return null
