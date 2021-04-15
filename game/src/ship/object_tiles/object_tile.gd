class_name ObjectTile
extends Node2D
# Base type for all placeable ship Object Tiles.

var _rot: int
export(String, "IN", "UP", "OUT") var placement_type

# Width and height in tile units.
var width := 1
var height := 1

# Directions around this tile that have background tiles.
var bg_dirs := []

# Relevant pixel offsets for specific placement configurations.
const _UP_OFFSET = -8

const _OUT_OFFSET = -16
const _OUT_BORDER = 5

onready var _offset = $Offset
onready var rotation_view_manager = $Offset/RotationViewManager

var ship: Node


func init(ship_: Node, rot_: int, placement_type_: String, width_ := 1, height_ := 1,
		bg_dirs_ := []):
	ship = ship_
	_rot = rot_
	placement_type = placement_type_
	width = width_
	height = height_
	bg_dirs = bg_dirs_
	return self


func _ready() -> void:
	rotation_view_manager.rot = _rot
	
	if placement_type == "OUT":
		set_mount_dir(-Rotation.get_dir(_rot))
	elif placement_type == "UP":
		_offset.position = Vector2.DOWN * _UP_OFFSET


func set_mount_dir(dir: Vector2) -> void:
	if dir == Vector2.DOWN:
		_offset.position = Vector2.DOWN * _OUT_OFFSET + -dir * _OUT_BORDER
	elif dir == Vector2.LEFT or dir == Vector2.RIGHT:
		_offset.position = Vector2.DOWN * _UP_OFFSET + -dir * _OUT_BORDER
	else:
		_offset.position = -dir * _OUT_BORDER
