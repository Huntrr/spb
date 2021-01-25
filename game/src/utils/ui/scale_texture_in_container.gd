tool
extends TextureRect
# Hack to scale a texture horizontally to fit its container.

func _ready() -> void:
	call_deferred("_update_min_width")

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_RESIZED:
			call_deferred("_update_min_width")

func _update_min_width() -> void:
	var aspect_ratio = texture.get_size().aspect()
	rect_min_size.x = rect_size.y * aspect_ratio
