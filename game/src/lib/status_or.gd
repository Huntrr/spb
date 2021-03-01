class_name StatusOr
extends Resource
# Might be a Status or might be something else!

var status: Status = null
var value = null

func _init(
		status_: Status = Status.new(), value_ = null) -> void:
	self.status = status_
	self.value = value_

func from_status(status_: Status) -> StatusOr:
	self.status = status_
	self.value = null
	return self

func from_value(value_) -> StatusOr:
	self.status = Status.new()
	self.value = value_
	return self

func ok() -> bool:
	return self.status.ok()
