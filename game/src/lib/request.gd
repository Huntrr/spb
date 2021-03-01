extends Node
# Easy interface for submitting HTTP requests.

func request(uri: String, method: int, body: Dictionary) -> StatusOr:
	var http: HTTPRequest = HTTPRequest.new()
	add_child(http)
	var error = http.request(
		uri,
		["User-Agent: Godot", "Content-Type: application/json"],
		true,
		method, JSON.print(body))
	var response: Array = yield(http, "request_completed")
	if error != OK:
		return StatusOr.new().from_status(Status.new(Status.UNAVAILABLE,
			"Error submitting login request..."))
	
	if response[0] != HTTPRequest.RESULT_SUCCESS:
		return StatusOr.new().from_status(
			Status.new(Status.UNAVAILABLE, "Error submitting HTTP request."))
	
	var res := JSON.parse(response[3].get_string_from_utf8())
	var data: Dictionary = {}
	if res.error == OK:
		data = res.result
	elif response[1] == HTTPClient.RESPONSE_OK:
			return StatusOr.new().from_status(Status.new(
				Status.INTERNAL, "Error parsing HTTP response data."))
	
	return StatusOr.new().from_value(Response.new(
		response[1],
		response[2],
		data
	))
