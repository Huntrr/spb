extends Node2D

var flip_h = false setget set_flip_h

enum Anim {IDLE, SIT, WALK_FORWARD, WALK_BACK}
var anim = Anim.IDLE

enum Action {NONE, ROLL}
var action = Action.NONE

const IDLE_FRAME_INTERVAL := 0.25
var timer := 0.0

func _ready() -> void:
	animate_idle()
	
	for child in get_children():
		child.material = child.material.duplicate()
	
func _process(delta) -> void:
	timer += delta
	if anim == Anim.IDLE and timer > IDLE_FRAME_INTERVAL:
		timer = 0.0
		# Randomly shift the frame forward or back, or stay still
		var anim_dir = randi() % 3 - 1
		for child in get_children():
			child.frame += 0 #anim_dir

func set_mask(mask: Texture, cell_size: float) -> void:
	for child in get_children():
		child.material.set_shader_param("alpha_mask", mask)
		child.material.set_shader_param("cell_size", 1.0)
		child.material.set_shader_param(
			"mask_ratio",
			child.frames.get_frame("idle", 0).get_size() / mask.get_size())

func set_mask_offset(offset: Vector2) -> void:
	for child in get_children():
		child.material.set_shader_param("mask_offset", offset)

func set_outfit(outfit: Dictionary) -> void:
	for child in get_children():
		child.index = outfit[child.name.to_lower()]

func set_flip_h(flip_h_: bool) -> void:
	if flip_h == flip_h_:
		return
	
	flip_h = flip_h_
	for child in get_children():
		child.flip_h = flip_h

func animate_walking(forward: bool) -> void:
	if action != Action.NONE:
		return
	
	var new_anim = Anim.WALK_FORWARD if forward else Anim.WALK_BACK
	if anim == new_anim:
		return
	anim = new_anim
	
	for child in get_children():
		child.play("walk", not forward)
		child.speed_scale = 2.0
		child.stop()
		child.frame = 0

func animate_idle() -> void:
	if action != Action.NONE:
		return
	
	if anim == Anim.IDLE:
		return
	anim = Anim.IDLE
	
	for child in get_children():
		child.animation = "idle"
		child.stop()
		child.frame = 0
