class_name ObjectTile
extends Node2D
# Base type for all placeable ship Object Tiles.

export(int) var _rot
export(String, "IN", "UP", "OUT") var _placement_type

# Width and height in tile units.
export(int) var width = 1
export(int) var height = 1

# Relevant pixel offsets for specific placement configurations.
const _UP_OFFSET = -8

const _OUT_OFFSET = -16
const _OUT_BORDER = 5

onready var _offset = $Offset
onready var _rotation_view_manager = $Offset/RotationViewManager


func init(rot_: int, placement_type_: String, width_ := 1, height_ := 1):
	_rot = rot_
	_placement_type = placement_type_
	width = width_
	height = height_
	return self


func _ready() -> void:
	_rotation_view_manager.rot = _rot
	
	if _placement_type == "OUT":
		if _rot == Rotation.UP:
			_offset.translate(Vector2.DOWN * _OUT_OFFSET)
		elif _rot == Rotation.LEFT or _rot == Rotation.RIGHT:
			_offset.translate(Vector2.DOWN * _UP_OFFSET)
		
		_offset.translate(Rotation.get_dir(_rot) * _OUT_BORDER)
	elif _placement_type == "UP":
		_offset.translate(Vector2.DOWN * _UP_OFFSET)
