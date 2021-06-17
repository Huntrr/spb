extends Node

signal pressed_new_game()
signal pressed_join_game(game_id, game_name, has_password)

onready var Log := Logger.new(self)
const LobbyButton: PackedScene = preload("res://scenes/menu/lobby_button.tscn")

onready var _new_game_button = $MarginContainer/NewGame
onready var _container = $ScrollContainer/VBoxContainer

var _current_offset := 0

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
	for lobby in result.lobbies:
		var player_count = lobby.uncrewed_users.size()
		for crew in lobby.crews:
			player_count += crew.crewmates.size()
		var lobby_button = LobbyButton.instance().init(
			lobby.id,
			lobby.name,
			lobby.host.display_name,
			player_count,
			lobby.time_limit,
			lobby.has_password)
		assert(lobby_button.connect("clicked", self, "_on_join_game",
			[lobby.name, lobby.has_password]) == OK)
		_container.add_child(lobby_button)

func _on_join_game(
		game_id: String, game_name: String, has_password: bool) -> void:
	emit_signal("pressed_join_game", game_id, game_name, has_password)
