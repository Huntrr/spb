tool
extends AnimatedSprite

export(int) var index = 1 setget set_index 

const outfits: Outfits = preload("res://data/character/outfits.tres")

func _ready():
	set_index(index)

func set_index(index_: int) -> void:
	index = index_
	self.frames = outfits.get_sprite_frames(self.name.to_lower(), index)
