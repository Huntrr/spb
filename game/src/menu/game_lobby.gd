extends Node

onready var Log := Logger.new(self)

var _game_id: String

func init(game_id_: String):
	_game_id = game_id_
	return self

func _ready():
	var result = yield(Connection.request(
		"lobby", "get_game", HTTPClient.METHOD_GET, {
			"lobby_id": _game_id
		}), "completed").value_or_die()
	if not result:
		return
	Log.info("%s" % result)
