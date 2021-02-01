extends Node2D

export(PackedScene) var _DownView
export(PackedScene) var _LeftView
export(PackedScene) var _UpView
export(PackedScene) var _RightView

var rot setget _set_rot

var _node: Node2D

func _get_configuration_warning() -> String:
	if _coalesce([_DownView, _LeftView, _UpView, _RightView]) == null:
		return "At least one directional view must be specified."
	return ""


func _ready() -> void:
	self.rot = rot


func _set_rot(rot_: int) -> void:
	rot = rot_
	
	if _node != null:
		_node.queue_free()
	
	var flip_h: bool
	var scene: PackedScene
	match rot:
		Rotation.DOWN:
			scene = _coalesce([_DownView, _UpView, _RightView, _LeftView])
		
		Rotation.LEFT:
			if _LeftView:
				scene = _LeftView
			elif _RightView:
				scene = _RightView
				flip_h = true
			else:
				scene = _coalesce([_DownView, _UpView])
			
		Rotation.UP:
			scene = _coalesce([_UpView, _DownView, _LeftView, _RightView])
		
		Rotation.RIGHT:
			if _RightView:
				scene = _RightView
			elif _LeftView:
				scene = _LeftView
				flip_h = true
			else:
				scene = _coalesce([_DownView, _UpView])
	
	_node = scene.instance()
	if flip_h:
		_node.scale = Vector2(-1, 1)
	elif scene == _DownView:
		rotation = Rotation.get_yaw(rot)
	add_child(_node)


func _coalesce(views: Array) -> PackedScene:
	# Returns the first non-null view from |views|
	for view in views:
		if view != null:
			return view
	return null
