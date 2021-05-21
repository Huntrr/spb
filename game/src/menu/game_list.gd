extends Node

signal pressed_new_game()

onready var Log := Logger.new(self)
const LobbyButton: PackedScene = preload("res://scenes/menu/lobby_button.tscn")

onready var _new_game_button = $MarginContainer/NewGame
onready var _container = $ScrollContainer/VBoxContainer

var _current_offset := 0
var _lobbies := []

func _ready():
	assert(_new_game_button.connect(
		"pressed", self, "emit_signal", ["pressed_new_game"]) == OK)
	
	var result = yield(Connection.request(
		"lobby", "list_games", HTTPClient.METHOD_GET, {
			"offset": _current_offset
		}), "completed").value_or_die()
	if not result:
		return
	_current_offset = result.next_offset
	_lobbies += result.lobbies
	Log.info("%s" % result)
