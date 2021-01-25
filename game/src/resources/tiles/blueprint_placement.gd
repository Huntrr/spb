class_name BlueprintPlacement
extends Resource
# Metadata about placing a tile into the blueprint view.

const tileset: TileSet = (
	preload("res://assets/tiles/blueprint/tileset.tres"))

export(String) var tile_name setget _set_tile_name
export(bool) var is_background

var tile_id: int
var tile_texture: Texture

func _set_tile_name(new_tile_name: String) -> void:
	tile_name = new_tile_name
	
	tile_id = tileset.find_tile_by_name(tile_name)
	
	tile_texture = AtlasTexture.new()
	tile_texture.set_atlas(tileset.tile_get_texture(tile_id))
	
	var tile_mode := tileset.tile_get_tile_mode(tile_id)
	if tile_mode == TileSet.AUTO_TILE:
		var icon_coord := tileset.autotile_get_icon_coordinate(tile_id)
		var origin := tileset.tile_get_region(tile_id).position
		var tile_size := tileset.autotile_get_size(tile_id)
		icon_coord.x *= tile_size.x
		icon_coord.y *= tile_size.y
		var icon_region := Rect2(origin + icon_coord, tile_size)
		tile_texture.set_region(icon_region)
	else:
		tile_texture.set_region(tileset.tile_get_region(tile_id))
