extends Node2D
class_name Character

var flip_h = false setget set_flip_h

enum Anim {NONE, IDLE, SIT, WALK_FORWARD, WALK_BACK}
var anim = Anim.IDLE

enum Action {NONE, ROLL}
var action = Action.NONE

const IDLE_FRAME_INTERVAL := 0.25
const SIT_FRAME_INTERVAL := 0.50
var timer := 0.0

var _outfit: Dictionary

func _ready() -> void:
	animate_idle()
	
	for child in get_children():
		child.material = child.material.duplicate()
	
	assert($Base.connect("animation_finished", self, "_on_animation_finished") == OK)
	
func _process(delta) -> void:
	timer += delta
	var new_frame_idle: bool= anim == Anim.IDLE and timer > IDLE_FRAME_INTERVAL
	var new_frame_sit: bool = anim == Anim.SIT and timer > SIT_FRAME_INTERVAL
	if new_frame_idle or new_frame_sit:
		timer = 0.0
		# Randomly shift the frame forward or back, or stay still
		var anim_dir = randi() % 3 - 1
		for child in get_children():
			child.frame += anim_dir
		_update_texture_offset()

func set_mask(mask: Texture, cell_size: float) -> void:
	for child in get_children():
		child.material.set_shader_param("alpha_mask", mask)
		child.material.set_shader_param("cell_size", cell_size)
		child.material.set_shader_param(
			"mask_ratio",
			child.frames.get_frame("idle", 0).atlas.get_size() / mask.get_size())
		child.material.set_shader_param(
			"texture_size",
			child.frames.get_frame("idle", 0).get_size())

func set_mask_offset(offset: Vector2) -> void:
	for child in get_children():
		child.material.set_shader_param("mask_offset", offset + position)
	_update_texture_offset()

func set_outfit(outfit: Dictionary) -> void:
	for child in get_children():
		child.index = outfit[child.name.to_lower()]
		var color_key: String = "%s_color" % child.name.to_lower()
		if color_key in outfit:
			child.modulate = Color(outfit[color_key])
	_outfit = outfit

func get_outfit() -> Dictionary:
	return _outfit.duplicate()

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


func animate_sitting() -> void:
	if action != Action.NONE:
		return
	
	if anim == Anim.SIT:
		return
	anim = Anim.SIT
	
	for child in get_children():
		child.animation = "sit"
		child.stop()
		child.frame = 0

func animate_roll() -> void:
	if action == Action.ROLL:
		return
	action = Action.ROLL
	anim = Anim.NONE
	
	for child in get_children():
		child.play("roll")
		child.frame = 0

func _update_texture_offset() -> void:
	for child in get_children():
		var texture: AtlasTexture = child.frames.get_frame(
			child.animation, child.frame)
		child.material.set_shader_param(
			"texture_offset", texture.region.position)
		child.material.set_shader_param(
			"flip_h", flip_h)

func _on_animation_finished() -> void:
	action = Action.NONE
