extends KinematicBody2D

export(float) var _ACCEL = 5
export(float) var _MAX_VELOCITY = 10
export(float) var _FRICTION = 0.5
export(float) var _MIN_VELOCITY = 0.1

var _vy = 0
var _vx = 0

var _info: Dictionary
var _peer_id: int

onready var _character: Node = $Character

func init(peer_id_: int, player_info_: Dictionary):
	name = "%d" % peer_id_
	_peer_id = peer_id_
	_info = player_info_
	return self

func set_mask(mask: Texture, cell_size: float) -> void:
	_character.set_mask(mask, cell_size)

func _ready():
	_character.set_outfit(_info.outfit)
	
	if _peer_id == multiplayer.get_network_unique_id():
		$Camera2D.make_current()
	
	$"../../".add_node_to_group("players", self)

func _process(delta: float) -> void:
	var mouse_pos: Vector2 = get_local_mouse_position()
	if mouse_pos.x < 0:
		_character.flip_h = false
	else:
		_character.flip_h = true
	
	if _vy == 0 && _vx == 0:
		_character.animate_idle()
	else:
		var forward := true
		if _character.flip_h and _vx < 0:
			_character.animate_walking(false)
		elif not _character.flip_h and _vx > 0:
			_character.animate_walking(false)
		else:
			_character.animate_walking(true)
			
	_character.set_mask_offset(-position)

func _physics_process(delta: float) -> void:
	if Input.is_action_pressed("game_down"):
		_vy = min(max(0, _vy) + _ACCEL * delta, _MAX_VELOCITY)
	if Input.is_action_pressed("game_up"):
		_vy = max(min(0, _vy) - _ACCEL * delta, -_MAX_VELOCITY)
	if Input.is_action_pressed("game_right"):
		_vx = min(max(0, _vx) + _ACCEL * delta, _MAX_VELOCITY)
	if Input.is_action_pressed("game_left"):
		_vx = max(min(0, _vx) - _ACCEL * delta, -_MAX_VELOCITY)
	
	if _vy > 0:
		_vy = max(0, _vy - _FRICTION * delta)
	elif _vy < 0:
		_vy = min(0, _vy + _FRICTION * delta)
	if _vx > 0:
		_vx = max(0, _vx - _FRICTION * delta)
	elif _vx < 0:
		_vx = min(0, _vx + _FRICTION * delta)
	
	if abs(_vy) < _MIN_VELOCITY:
		_vy = 0
	if abs(_vx) < _MIN_VELOCITY:
		_vx = 0
	
	var move_vector := Vector2(_vx, _vy) * delta
	#move_and_collide(move_vector)
	position += move_vector
