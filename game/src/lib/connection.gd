extends Node
# Holds server address constants for various client requests.

var environment = "PROD"
onready var Request = get_node("/root/Request")

const dict = {
	"PROD": {
		"auth": "http://0.0.0.0:30202"
	}
}

func addresses() -> Dictionary:
	return dict[environment]


func request(
		service: String, uri: String, method: int, body: Dictionary) -> StatusOr:
	var full_uri: String = "%s/%s" % [addresses()[service], uri]
	var response_status: StatusOr = yield(
		Request.request(full_uri, method, body), "completed")
	if not response_status.ok():
		return response_status
	
	var response: Response = response_status.value
	
	if response.code != HTTPClient.RESPONSE_OK:
		var message: String = (
			"Unknown SPB error.\nHTTP Error %d" % response.code)
		if "spb_error" in response.data:
			message = (
				"HTTP Error %d\n%s" % [response.code, response.data.spb_error])
		
		var code: int = Status.from_http_code(response.code)
		if "spb_code" in response.data:
			code = response.data.code
		
		return StatusOr.new().from_status(
			Status.new(code, message))
	
	return StatusOr.new().from_value(response.data)


func login_guest(name: String) -> Status:
	var data_status: StatusOr = yield(request(
		"auth", "login/guest", HTTPClient.METHOD_POST, {
			"name": name,
		}), "completed")
	if not data_status.ok():
		return data_status.status
	var data: Dictionary = data_status.value
	
	print(data)
	return Status.new()


func login_user(email: String, password: String) -> Status:
	var data_status: StatusOr = yield(request(
		"auth", "login/spb", HTTPClient.METHOD_POST, {
			"email": email,
			"password": password,
		}), "completed")
	if not data_status.ok():
		return data_status.status
	var data: Dictionary = data_status.value
	
	print(data)
	return Status.new()
