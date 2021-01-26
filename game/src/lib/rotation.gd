class_name Rotation
extends Object

const UP := 0
const RIGHT := 1
const DOWN := 2
const LEFT := 3

static func next(cur: int):
	return (cur + 1) % 4
