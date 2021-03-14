class_name Logger
extends Node

var _res_label: String

func _init(res) -> void:
	var script_path_split: Array = res.get_script().get_path().split("/")
	_res_label = script_path_split[script_path_split.size() - 1]

func log_msg(type: String, msg: String) -> void:
	var time: Dictionary = OS.get_datetime()
	var time_string: String = "%04d%02d%02d %02d:%02d:%02d" % [time.year, time.month, time.day, time.hour, time.minute, time.second]
	print("%s%s %s] %s" % [type, time_string, _res_label, msg])

func info(msg: String) -> void:
	log_msg("I", msg)

func warning(msg: String) -> void:
	log_msg("W", msg)

func error(msg: String) -> void:
	log_msg("E", msg)
