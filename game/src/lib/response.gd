class_name Response
extends Resource
# Data class describing HTTP response data.

var code: int
var headers: PoolStringArray
var data: Dictionary

func _init(code_: int, headers_: PoolStringArray, data_: Dictionary) -> void:
	self.code = code_
	self.headers = headers_
	self.data = data_
