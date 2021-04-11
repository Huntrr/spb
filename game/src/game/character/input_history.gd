class_name InputHistory
extends Resource

var timestamps := []
var inputs := []

func add_input(timestamp: float, input: Dictionary) -> void:
	var index = timestamps.bsearch(timestamp)
	timestamps.insert(index, timestamp)
	inputs.insert(index, input)

func get_input(timestamp: float) -> Dictionary:
	var index = timestamps.bsearch(timestamp)
	if index < timestamps.size() and (timestamps[index] == timestamp or index == 0):
		return inputs[index]
	return inputs[index - 1]

func clear_before(timestamp: float) -> void:
	while not timestamps.empty() and timestamps.front() < timestamp:
		timestamps.pop_front()
