extends Node

onready var Log = Logger.new(self)

onready var _splash: Node = $Splash

func _ready():
	var arguments := {}
	for argument in OS.get_cmdline_args():
		if argument.find("=") > -1:
			var key_value = argument.split("=")
			arguments[key_value[0].lstrip("--")] = key_value[1]
		else:
			arguments[argument.lstrip("--")] = true

	if arguments.has("server") or OS.has_feature("Server"):
		Log.info("Starting SPB server")
		var auth_key: String = arguments["auth_key"]
		var status: Status = yield(Connection.login_server(auth_key), "completed")
		if not status.ok():
			Log.error("Error %d: %s" % [status.code, status.message])
			return
		SceneManager.goto("res://scenes/server.tscn")
	else:
		Log.info("Starting SPB client")
		_splash.hide()
		yield(get_tree().create_timer(1.0), "timeout")
		_splash.show()
		yield(get_tree().create_timer(2.0), "timeout")
		_splash.hide()
		yield(get_tree().create_timer(0.5), "timeout")
		SceneManager.goto("res://scenes/menu/login.tscn")
