class_name Ship
extends Node2D

signal spawned_self(player)

onready var Log := Logger.new(self)

const Player: PackedScene = preload("res://scenes/character/player.tscn")

const CELL_SIZE := 32
const FLOOR_TILE_NAME := "floor_1"
const WALL_TILE_NAME := "wall_1"
const SURROUND_DIRS := [
	Vector2.DOWN, Vector2.LEFT, Vector2.UP, Vector2.RIGHT,
	Vector2.UP + Vector2.RIGHT, Vector2.UP + Vector2.LEFT,
	Vector2.DOWN + Vector2.RIGHT, Vector2.DOWN + Vector2.LEFT,
]

const tile_registry: TileRegistry = preload("res://data/tiles/tile_registry.tres")

onready var _base: TileMap = $Base
onready var _in: YSort = $In
onready var _wrap: Sprite = $Wrap
onready var _up: YSort = $Up
onready var _out: YSort = $Out

onready var _floor_id: int = _base.tile_set.find_tile_by_name(FLOOR_TILE_NAME)
onready var _wall_id: int = _base.tile_set.find_tile_by_name(WALL_TILE_NAME)

enum MaskType {
	FULL,
	HALF,
}

var mask: Texture = ImageTexture.new()

var node_groups := {}

func add_node_to_group(group: String, node: Node) -> void:
	# Adds a node a node to an object group.
	if not (group in node_groups):
		node_groups[group] = []
	node_groups[group].append(node)

func get_nodes_in_group(group: String) -> Array:
	if not (group in node_groups):
		return []
	var nodes := []
	for node in node_groups[group]:
		if node:
			nodes.append(node)
	node_groups[group] = nodes
	return node_groups[group]

func introduce_player(peer_id: int) -> void:
	# Sends a new player all the current players on this ship.
	var players: Array = get_nodes_in_group("players")
	for player in players:
		rpc_id(peer_id, "create_player",
			player.peer_id, player.info, player.position)

func spawn_player(peer_id: int, player_info: Dictionary) -> void:
	var spawns: Array = get_nodes_in_group("spawn")
	if spawns.empty():
		push_error("No spawns on ship!")
		return
	var spawn: Node2D = spawns[randi() % spawns.size()]
	var spawn_pos: Vector2 = (
		get_global_transform().inverse() * spawn.get_global_transform()).get_origin()
	
	rpc("create_player", peer_id, player_info, spawn_pos)
	create_player(peer_id, player_info, spawn_pos)

puppet func create_player(
		peer_id: int, player_info: Dictionary, location: Vector2) -> void:
	var player: KinematicBody2D = Player.instance().init(peer_id, player_info)
	player.position = location
	_in.add_child(player)
	player.set_mask(mask, float(CELL_SIZE / 2.0))

puppet func remove_player(peer_id: int) -> void:
	var node: Node = get_node("In/%d" % peer_id)
	if node:
		get_node("In/%d" % peer_id).queue_free()


#############
# LOAD SHIP #
#############
func load_from_spb(blueprint: SpaceshipBlueprint) -> void:
	for container in [_base, _in, _wrap, _up, _out]:
		for child in container.get_children():
			child.queue_free()
		if container is TileMap:
			container.clear()
	
	var max_x := 0
	var max_y := 0
	var mask_cells := {}
	
	for cell in blueprint.cells:
		max_x = int(max(max_x, cell.x + 1))
		max_y = int(max(max_y, cell.y + 1))
		var coord := Vector2(cell.x, cell.y)
		var rot: int = cell.rot
		var tile: Tile = tile_registry.by_id(cell.id)
		
		if tile.is_background():
			_base.set_cellv(coord, _floor_id)
			mask_cells[coord] = MaskType.FULL
			if not mask_cells.has(coord + Vector2.UP):
				mask_cells[coord + Vector2.UP] = MaskType.HALF
			
			for v in SURROUND_DIRS:
				if _base.get_cellv(coord + v) == TileMap.INVALID_CELL:
					_base.set_cellv(coord + v, _wall_id)
		
		if tile.ship_placement:
			var position: Vector2 = coord * CELL_SIZE + Vector2.ONE * CELL_SIZE / 2
			var width := 1
			var height := 1
			
			var bg_dirs := []
			for v in [Vector2.DOWN, Vector2.UP, Vector2.RIGHT, Vector2.LEFT]:
				if blueprint.has_background(coord + v):
					bg_dirs.append(v)
			
			if tile.blueprint_placement.rotate_like_door:
				# Doors should be drawn as a single object.
				var next = Rotation.get_dir(rot).abs()
				if blueprint.has_id(coord - next, cell.id, rot):
					# This is not the first door tile for this door,
					# so skip it.
					continue
				var size := 0
				var local_coord: Vector2 = coord
				while blueprint.has_id(local_coord, cell.id, rot):
					size += 1
					local_coord += next
				if next.x > 0:
					width = size
				else:
					height = size 
				
			if (tile.ship_placement.object != null and
					blueprint.has_background(coord)):
				var type := "IN"
				var instance: ObjectTile = (
					tile.ship_placement.object.instance().init(
						self, rot, type, width, height, bg_dirs))
				instance.position = position
				instance.name = "%s-%s_%s-%s" % [type, cell.id, cell.x, cell.y]
				_in.add_child(instance)
			
			if tile.ship_placement.exterior_object != null:
				var type := "UP" if blueprint.has_background(coord) else "OUT"
				var instance: ObjectTile = (
					tile.ship_placement.exterior_object.instance().init(
						self, rot, type, width, height, bg_dirs))
				instance.position = position
				
				var layer: YSort = _up if type == "UP" else _out
				instance.name = "%s-%s_%s-%s" % [type, cell.id, cell.x, cell.y]
				layer.add_child(instance)
	
	_base.update_bitmask_region()
	
	# Build the full interior mask for this ship.
	var mask_image: Image = Image.new()
	mask_image.create(max_x * 2 + 4, max_y * 2 + 6, false, Image.FORMAT_RGBA8)
	mask_image.lock()
	for x in range(max_x):
		for y in range(max_y + 1):
			if mask_cells.has(Vector2(x, y - 1)):
				match mask_cells[Vector2(x, y - 1)]:
					MaskType.FULL:
						mask_image.set_pixel(x * 2 + 2, y * 2 + 2, Color.black)
						mask_image.set_pixel(x * 2 + 3, y * 2 + 2, Color.black)
						mask_image.set_pixel(x * 2 + 2, y * 2 + 3, Color.black)
						mask_image.set_pixel(x * 2 + 3, y * 2 + 3, Color.black)
					
					MaskType.HALF:
						mask_image.set_pixel(x * 2 + 2, y * 2 + 3, Color.black)
						mask_image.set_pixel(x * 2 + 3, y * 2 + 3, Color.black)
	mask_image.unlock()
	
	mask.create_from_image(mask_image, 0)
	var mask_ratio: Vector2 = _wrap.texture.get_size() / mask.get_size();
	
	_wrap.region_rect.end = Vector2(max_x + 2, max_y + 2) * CELL_SIZE
	_wrap.position = Vector2(-1, -1) * CELL_SIZE
	_wrap.material.set_shader_param("alpha_mask", mask)
	_wrap.material.set_shader_param("mask_offset", Vector2(0, -1) * CELL_SIZE)
	_wrap.material.set_shader_param("cell_size", float(CELL_SIZE / 2.0))
	_wrap.material.set_shader_param("mask_ratio", mask_ratio)
	
	for player in get_nodes_in_group("players"):
		player.set_mask(mask, float(CELL_SIZE / 2.0))
