tool
class_name Outfits
extends Resource

export(Array, Texture) var bases
export(Array, Texture) var pants
export(Array, Texture) var shirts
export(Array, Texture) var eyes

const _SPRITE_HEIGHT = 32
const _SPRITE_WIDTH = 32

const _ANIMS := [
	["idle", 5, 0, true],
	["sit", 2, 0, true],
	["walk", 4, 10, true],
	["roll", 7, 14, false],
]

var _SPRITE_FRAMES := {}

func get_component(component: String) -> Array:
	match component:
		"base":
			return bases
		"pants":
			return pants
		"shirt":
			return shirts
		"eyes":
			return eyes
	push_error("Invalid component: %s" % component)
	return []

func get_sprite_frames(component: String, index: int) -> SpriteFrames:
	if not (component in _SPRITE_FRAMES):
		_SPRITE_FRAMES[component] = {}
	if index in _SPRITE_FRAMES[component]:
		return _SPRITE_FRAMES[component][index]
	
	var frames := SpriteFrames.new()
	var anim_row := 0
	for anim in _ANIMS:
		var anim_name: String = anim[0]
		var anim_columns: int = anim[1]
		frames.add_animation(anim_name)
		frames.set_animation_speed(anim_name, anim[2])
		frames.set_animation_loop(anim_name, anim[3])
		var y := _SPRITE_HEIGHT * anim_row
		for i in range(anim_columns):
			var texture := AtlasTexture.new()
			texture.atlas = get_component(component)[index - 1]
			var x := _SPRITE_WIDTH * i
			texture.region = Rect2(x, y, _SPRITE_WIDTH, _SPRITE_HEIGHT)
			frames.add_frame(anim_name, texture)
		anim_row += 1
	frames.remove_animation("default")
	_SPRITE_FRAMES[component][index] = frames
	return frames
