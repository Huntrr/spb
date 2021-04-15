extends Node

const _COOLDOWN := 0.1

var sensed_bodies := []
var door: Node

var should_open := false
var is_open := false setget _set_is_open
var cooldown := 0.0

func _ready() -> void:
	var rotation_view_manager: Node = $"../Offset/RotationViewManager"
	assert(
		rotation_view_manager.connect("set_node", self, "_on_set_node") == OK)

func _physics_process(delta: float) -> void:
	if cooldown > 0:
		cooldown -= delta
		return
	if should_open != is_open:
		self.is_open = should_open
	
func _on_set_node(node: Node) -> void:
	door = node
	
	var collision_area: Area2D = door.collision_area
	sensed_bodies = []
	for body in collision_area.get_overlapping_bodies():
		if body.is_in_group("sensible"):
			sensed_bodies.append(body)
	
	assert(collision_area.connect(
		"body_entered", self, "_on_body_entered") == OK)
	assert(collision_area.connect(
		"body_exited", self, "_on_body_exited") == OK)
	_update_state()

func _on_body_entered(body: PhysicsBody2D) -> void:
	if not body:
		return
	if body.is_in_group("sensible"):
		sensed_bodies.append(body)
	_update_state()

func _on_body_exited(body: PhysicsBody2D) -> void:
	var idx: int = sensed_bodies.find(body)
	if idx >= 0:
		sensed_bodies.remove(idx)
	_update_state()

func _update_state() -> void:
	# Controls whether the door is opened or closed.
	if sensed_bodies.empty():
		should_open = false
	else:
		should_open = true

func _set_is_open(is_open_: bool) -> void:
	if is_open_ == is_open:
		return
	is_open = is_open_
	door.set_closed(not is_open)
