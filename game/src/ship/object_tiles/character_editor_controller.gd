extends Node


func _ready():
	get_parent().connect("created_overlay", self, "_on_created_overlay")

func _on_created_overlay(overlay: Node, user: Node) -> void:
	overlay.init(user.get_outfit())
