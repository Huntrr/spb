extends TabContainer
# Allows users to select from a collection of separate tiles.

signal tile_selected(tile, rotation)

export(Array) var tiles = [
	["Core", [
		preload("res://data/tiles/void.tres"),
		preload("res://data/tiles/floor.tres"),
		preload("res://data/tiles/main_thruster.tres"),
		preload("res://data/tiles/side_thruster.tres"),
		preload("res://data/tiles/camera.tres"),
		preload("res://data/tiles/generator.tres"),
		preload("res://data/tiles/spawn.tres"),
	]],
	["Battle Stations", [
		preload("res://data/tiles/helm.tres"),
		preload("res://data/tiles/turret.tres"),
		preload("res://data/tiles/teleporter.tres"),
		preload("res://data/tiles/radar.tres"),
		preload("res://data/tiles/shields.tres"),
		preload("res://data/tiles/security.tres"),
		preload("res://data/tiles/engineering.tres"),
	]],
	["Space Station", [
		preload("res://data/tiles/dressing_room.tres"),
		preload("res://data/tiles/ship_builder.tres"),
		preload("res://data/tiles/simulator.tres"),
	]],
]

const SelectTileButton := (
	preload("res://scenes/ship_builder/select_tile_button.tscn"))

const SUBCONTAINER_MARGIN_SIZE = 10

var _buttons := {}
var _selected_tile: Tile = null

func _get_configuration_warning():
	for section in tiles:
		if not (section[0] is String):
			return "tiles entry '{}' is not a String".format([section], "{}") 
		var vals = section[1]
		if not (vals is Array):
			return "tiles[{}] is not an Array".format([section], "{}")
		for val in vals:
			if not (val is Tile):
				return "tiles[{}] contains a non-Tile".format([section], "{}")


func _ready() -> void:
	for section in tiles:
		var section_title = section[0]
		var section_tiles = section[1]
		var section_container := _mk_section_container(self, section_title)
		for tile in section_tiles:
			var button = _mk_button(section_container, tile)
			_buttons[tile.id] = button
			button.connect("tile_selected", self, "_on_tile_selected")


func _on_tile_selected(tile: Tile, rotation: int) -> void:
	if _selected_tile != null:
		_buttons[_selected_tile.id].active = false
	_selected_tile = tile
	_buttons[_selected_tile.id].active = true
	emit_signal("tile_selected", tile, rotation)


func _mk_section_container(parent: Node, title: String) -> HBoxContainer:
	var container := HBoxContainer.new()
	container.name = title
	parent.add_child(container)
	return container


func _mk_button(parent: Node, tile: Tile) -> Node:
	var button = SelectTileButton.instance().init(tile)
	var subcontainer := _mk_section_subcontainer(parent)
	subcontainer.add_child(button)
	return button


func _mk_section_subcontainer(parent: Node) -> MarginContainer:
	var subcontainer := MarginContainer.new()
	subcontainer.set("custom_constants/margin_top", SUBCONTAINER_MARGIN_SIZE)
	subcontainer.set("custom_constants/margin_left", SUBCONTAINER_MARGIN_SIZE)
	subcontainer.set("custom_constants/margin_bottom", SUBCONTAINER_MARGIN_SIZE)
	subcontainer.set("custom_constants/margin_right", SUBCONTAINER_MARGIN_SIZE)
	parent.add_child(subcontainer)
	return subcontainer
