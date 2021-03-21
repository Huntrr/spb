extends Node
# Holds server address constants for various client requests.

const SHIP_PORT: int = 31201

onready var Log := Logger.new(self)

var environment = "PROD"
onready var Request = get_node("/root/Request")

const dict = {
	"PROD": {
		"auth": "http://0.0.0.0:30202",
		"gateway": "http://0.0.0.0:30201"
	}
}
const SESSION_PATH = "user://session.dat"

var _session_jwt: String = ""
var session_user: Dictionary = {}

func addresses() -> Dictionary:
	return dict[environment]


func _ready() -> void:
	var file = File.new()
	if file.open(SESSION_PATH, File.READ) == OK:
		var text = file.get_as_text()
		if text.empty():
			_session_jwt = ""
			session_user = {}
		else:
			assert(set_session(file.get_as_text()).ok())
		file.close()


func logged_in() -> bool:
	return not session_user.empty()


func log_out(status: Status = Status.new()) -> Status:
	clear_session()
	SceneManager.goto("res://scenes/menu/login.tscn")
	if not status.ok():
		Dialog.show_error(status)
	return status


func clear_session() -> void:
	_session_jwt = ""
	session_user = {}
	
	var file = File.new()
	file.open(SESSION_PATH, File.WRITE)
	file.store_string("")
	file.close()


func set_session(jwt: String) -> Status:
	_session_jwt = jwt
	var encoded_user: String = jwt.split('.')[1]
	var str_user: String = Base64Url.base64url_to_utf8(encoded_user)
	var json_user: JSONParseResult = JSON.parse(str_user)
	if json_user.error != OK:
		return Status.new(Status.INTERNAL, "Unable to parse JWT")
	
	session_user = json_user.result
	
	if session_user.type == "player":
		var file = File.new()
		file.open(SESSION_PATH, File.WRITE)
		file.store_string(jwt)
		file.close()

	return Status.new()


func ws_connect(service: String, uri: String) -> StatusOr:
	var full_uri: String = "%s/%s" % [addresses()[service], uri]
	full_uri = full_uri.replace("http://", "ws://").replace("https://", "ws://")
	Log.info(full_uri)
	var client = WebSocketClient.new()
	var headers = PoolStringArray()
	if logged_in():
		headers.append("Authorization: JWT %s" % _session_jwt)
	
	var err = client.connect_to_url(full_uri, PoolStringArray(), false, headers)
	if err != OK:
		return StatusOr.new().from_status(Status.new(
			Status.UNKNOWN, "Error establishing WebSocket connection"))
	
	return StatusOr.new().from_value(client)


func request(
		service: String, uri: String, method: int, body: Dictionary) -> StatusOr:
	var full_uri: String = "%s/%s" % [addresses()[service], uri]
	var headers: Array = []
	if logged_in():
		headers.append("Authorization: JWT %s" % _session_jwt)
	var response_status: StatusOr = yield(
		Request.request(full_uri, headers, method, body), "completed")
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
			code = response.data.spb_code
		
		if code == Status.UNAUTHENTICATED:
			# Log out if the current token is bad.
			return StatusOr.new().from_status(
				log_out(Status.new(code, message)))
		
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
	
	return set_session(data.jwt)


func login_user(email: String, password: String) -> Status:
	var data_status: StatusOr = yield(request(
		"auth", "login/spb", HTTPClient.METHOD_POST, {
			"email": email,
			"password": password,
		}), "completed")
	if not data_status.ok():
		return data_status.status
	var data: Dictionary = data_status.value
	
	return set_session(data.jwt)


func login_server(auth_key: String) -> Status:
	var data_status: StatusOr = yield(request(
		"auth", "login/server", HTTPClient.METHOD_POST, {
			"auth_key": auth_key,
		}), "completed")
	if not data_status.ok():
		return data_status.status
	var data: Dictionary = data_status.value
	
	return set_session(data.jwt)


func register_user(email: String, name: String, password: String) -> Status:
	var data_status: StatusOr = yield(request(
		"auth", "register/spb", HTTPClient.METHOD_POST, {
			"email": email,
			"name": name,
			"password": password,
		}), "completed")
	if not data_status.ok():
		return data_status.status
	return Status.new()
