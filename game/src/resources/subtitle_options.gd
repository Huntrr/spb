class_name SubtitleOptions
extends Resource

export(Array, String) var s = ["space"]
export(Array, String) var p = ["pirate"]
export(Array, String) var b = ["battle"]

func get_title(not_this: String) -> String:
	randomize()
	var title: String = _gen_title()
	var count: int = 0
	while title == not_this and count < 100:
		title = _gen_title()
		count += 1
	return title

func _gen_title() -> String:
	var s_ = s[randi() % s.size()]
	var p_ = p[randi() % p.size()]
	var b_ = b[randi() % b.size()]
	return "%s %s %s?!" % [s_, p_, b_]
