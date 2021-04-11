class_name PlayerPhysics
extends Resource
# Encodes current player physics state and computes updates to the state given
# input state.

export(float) var _ACCEL = 300
export(float) var _MAX_VELOCITY = 30
export(float) var _FRICTION = 100
export(float) var _MIN_VELOCITY = 0.1

var velocity := Vector2(0, 0)

func to_dict() -> Dictionary:
	return {
		"velocity": velocity,
	}
func from_dict(dict: Dictionary):
	velocity = dict.velocity
	return self

func get_movement(delta: float, input: Dictionary) -> Vector2:
	if input.down:
		velocity.y = min(max(0, velocity.y) + _ACCEL * delta, _MAX_VELOCITY)
	if input.up:
		velocity.y = max(min(0, velocity.y) - _ACCEL * delta, -_MAX_VELOCITY)
	if input.right:
		velocity.x = min(max(0, velocity.x) + _ACCEL * delta, _MAX_VELOCITY)
	if input.left:
		velocity.x = max(min(0, velocity.x) - _ACCEL * delta, -_MAX_VELOCITY)
	
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
	
	var move_vector := velocity * delta
	return move_vector
