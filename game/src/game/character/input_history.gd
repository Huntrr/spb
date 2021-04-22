class_name InputHistory
extends Resource

const EMPTY_INPUT := {
	"up": false,
	"down": false,
	"left": false,
	"right": false,
	"roll": false,
	"roll_dir": Vector2.ZERO,
	"aim": Vector2.ZERO,
	"sitting": false,
}

var timestamps := []
var inputs := []

func add_input(timestamp: int, input: Dictionary) -> void:
	var index = timestamps.bsearch(timestamp)
	timestamps.insert(index, timestamp)
	inputs.insert(index, input)

func get_input(timestamp: int) -> Dictionary:
	if timestamps.empty():
		return EMPTY_INPUT
	var index = timestamps.bsearch(timestamp)
	if index < timestamps.size() and timestamps[index] == timestamp or index == 0:
		return inputs[index]
	return inputs[index - 1]

func get_min_timestamp() -> int:
	return OS.get_system_time_msecs() if timestamps.empty() else timestamps[0]

func clear_before(timestamp: int) -> void:
	while timestamps.size() > 1 and timestamps.front() < timestamp:
		timestamps.pop_front()
		inputs.pop_front()
