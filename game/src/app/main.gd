extends Node

onready var Log = Logger.new(self)

onready var _splash: Node = $Splash

func _ready():
	if "--server" in OS.get_cmdline_args() or OS.has_feature("Server"):
		Log.info("Starting SPB server")
		var auth_key: String = OS.get_environment("SPB_AUTH_KEY")
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
