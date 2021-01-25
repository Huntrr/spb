extends Node

onready var tile_selector = $UI/TileSelector
onready var blueprint = $Blueprint

func _ready() -> void:
	tile_selector.connect("tile_selected", self, "_on_tile_selected")

func _on_tile_selected(tile: Tile) -> void:
	blueprint.current_tile = tile
