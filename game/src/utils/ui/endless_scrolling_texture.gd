extends TextureRect
# Resizes a texture and manages its transform scroll endlessly.

export(Vector2) var cell_size = Vector2(16, 16)

var view_size: Vector2
var scale: Vector2


func _ready():
	get_tree().get_root().connect("size_changed", self, "update")
	update()


func update() -> void:
	_resize()
	_reposition()


func _reposition() -> void:
	var global_rect := get_global_rect()
	var screen_pos := global_rect.position
	var size := global_rect.size
	var left := screen_pos.x
	var right := screen_pos.x + rect_size.x * scale.x
	var top := screen_pos.y
	var bottom := screen_pos.y + rect_size.y * scale.y
	
	if left > 0:
		rect_position.x -= _round(left, view_size.x) / scale.x * rect_scale.x
	elif right < view_size.x:
		rect_position.x += (
			_round(-right, view_size.x) + view_size.x) / scale.x * rect_scale.x
	
	if top > 0:
		rect_position.y -= _round(top, view_size.y) / scale.y * rect_scale.y
	elif bottom < view_size.y:
		rect_position.y += (
			_round(-bottom, view_size.y) + view_size.y) / scale.y * rect_scale.y


func _resize():
	scale = get_global_transform().get_scale()
	view_size = get_viewport().size
	view_size.x = _round(view_size.x, cell_size.x * scale.x)
	view_size.y = _round(view_size.x, cell_size.x * scale.x)
	rect_size = 2 * view_size / scale
	

func _round(round_this: float, to_nearest_this: float) -> float:
	return ceil(round_this / to_nearest_this) * to_nearest_this
