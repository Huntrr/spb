extends Control

signal clicked(game_id)

var _pressed := false

func init(game_id: String, game_name: String, host: String, player_count: int,
		time_sec: int, password: bool) -> void:
	name = game_id
	var minutes: int = time_sec / 60
	var seconds: int = time_sec % 60
	$HBoxContainer/GameName.text = game_name
	$HBoxContainer/Host.text = host
	$HBoxContainer/PlayerCount.text = '%s' % player_count
	$HBoxContainer/Time.text = '%02d:%02d' % [minutes, seconds]
	$HBoxContainer/PW.text = 'x' if password else ''

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_pos: Vector2 = get_local_mouse_position()
		var inside := Rect2(Vector2.ZERO, rect_size).has_point(mouse_pos)
		if event.button_index == BUTTON_LEFT:
			if event.is_pressed():
				if inside:
					_pressed = true
			else:
				if _pressed and inside:
					emit_signal("clicked", name)
				_pressed = false
