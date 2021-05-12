extends OverlayManager

func _ready():
	connect("created_overlay", self, "_on_created_overlay")

func _on_created_overlay(overlay: Node, user: Player) -> void:
	pass
