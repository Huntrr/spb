extends Node2D

func set_outfit(outfit: Dictionary) -> void:
	for child in get_children():
		child.index = outfit[child.name.to_lower()]
