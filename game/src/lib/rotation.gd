class_name Rotation
extends Object

const UP := 0
const RIGHT := 1
const DOWN := 2
const LEFT := 3

static func next(cur: int):
	return (cur + 1) % 4

static func get_yaw(cur: int) -> float:
	match cur:
		DOWN:
			return 0.0
		RIGHT:
			return -PI / 2
		UP:
			return PI
		LEFT:
			return PI / 2
	return 0.0


static func get_dir(cur: int) -> Vector2:
	match cur:
		DOWN:
			return Vector2.DOWN
		RIGHT:
			return Vector2.RIGHT
		UP:
			return Vector2.UP
		LEFT:
			return Vector2.LEFT
	return Vector2.ZERO
