extends Node
# Helps KeyListeners know when they should be active.

var _current_id := ""
var _current_priority := 0.0

func release_active(id: String) -> void:
	if _current_id == id:
		_current_id = ""
		_current_priority = 0

func attempt_active(id: String, priority: int) -> bool:
	if _current_id.empty() or id == _current_id:
		_current_id = id
		_current_priority = priority
		return true
	if priority < _current_priority:
		_current_id = id
		_current_priority = priority
		return true
	return false
