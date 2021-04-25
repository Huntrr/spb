class_name PlayerPhysics
extends Resource
# Encodes current player physics state and computes updates to the state given
# input state.

export(float) var _ACCEL = 300
export(float) var _MAX_VELOCITY = 30
export(float) var _FRICTION = 100
export(float) var _MIN_VELOCITY = 0.1

export(float) var _ROLL_VELOCITY = 120
export(float) var _ROLL_TIME = 0.4
export(float) var _ROLL_GAP = 0.15
export(float) var _ROLL_COOLDOWN = 1.0
export(int) var _ROLL_CONSECUTIVE = 3

var velocity := Vector2.ZERO
var sitting := false
var roll := Vector2.ZERO
var roll_timer := 0.0
var roll_count := 0
var roll_up := true  # User can't roll by holding space continuously.

func to_dict() -> Dictionary:
	return {
		"velocity": velocity,
		"sitting": sitting,
		"roll": roll,
		"roll_timer": roll_timer,
		"roll_count": roll_count,
		"roll_up": roll_up,
	}
func from_dict(dict: Dictionary):
	velocity = dict.velocity
	sitting = dict.sitting
	roll = dict.roll
	roll_timer = dict.roll_timer
	roll_count = dict.roll_count
	roll_up = dict.roll_up
	return self

func get_movement(delta: float, input: Dictionary) -> Vector2:
	if roll_timer < -_ROLL_GAP:
		if input.down:
			velocity.y = min(max(0, velocity.y) + _ACCEL * delta, _MAX_VELOCITY)
		if input.up:
			velocity.y = max(min(0, velocity.y) - _ACCEL * delta, -_MAX_VELOCITY)
		if input.right:
			velocity.x = min(max(0, velocity.x) + _ACCEL * delta, _MAX_VELOCITY)
		if input.left:
			velocity.x = max(min(0, velocity.x) - _ACCEL * delta, -_MAX_VELOCITY)
	
	if roll_timer < -_ROLL_COOLDOWN:
		roll_count = 0
	else:
		roll_timer -= delta
	
	if roll == Vector2.ZERO and input.roll_dir != Vector2.ZERO and roll_up:
		if roll_count < _ROLL_CONSECUTIVE and roll_timer < -_ROLL_GAP:
			roll_count += 1
			roll = input.roll_dir.normalized() * _ROLL_VELOCITY
			roll_timer = _ROLL_TIME
			roll_up = false
	
	if roll != Vector2.ZERO:
		velocity = roll
		if roll_timer < 0:
			roll = Vector2.ZERO
			velocity = Vector2.ZERO
	else:
		if not input.roll:
			roll_up = true
		if velocity.y > 0:
			velocity.y = max(0, velocity.y - _FRICTION * delta)
		elif velocity.y < 0:
			velocity.y = min(0, velocity.y + _FRICTION * delta)
		if velocity.x > 0:
			velocity.x = max(0, velocity.x - _FRICTION * delta)
		elif velocity.x < 0:
			velocity.x = min(0, velocity.x + _FRICTION * delta)
	
	if abs(velocity.y) < _MIN_VELOCITY:
		velocity.y = 0
	if abs(velocity.x) < _MIN_VELOCITY:
		velocity.x = 0
	
	if sitting:
		velocity = Vector2.ZERO
	
	var move_vector := velocity * delta
	return move_vector
