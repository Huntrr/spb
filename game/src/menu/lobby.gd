extends WindowDialog

signal create_game(game_name, password)
signal join_game(game_id, password)

const GameList: PackedScene = preload("res://scenes/menu/game_list.tscn")
const GameLobby: PackedScene = preload("res://scenes/menu/game_lobby.tscn")

var _content: Control

onready var create_dialog: AcceptDialog = $CreateDialog
onready var create_crew: AcceptDialog = $CreateCrew
onready var join_dialog: AcceptDialog = $JoinDialog

func _ready():
	popup()
	assert(self.connect("hide", self, "queue_free") == OK)
	
	_show_game_list()

func _show_game_list() -> void:
	if _content:
		_content.queue_free()
	
	_content = GameList.instance()
	assert(_content.connect(
		"pressed_new_game", create_dialog, "popup_centered") == OK)
	assert(_content.connect(
		"pressed_join_game", self, "_on_pressed_join_game") == OK)
	assert(join_dialog.connect("join_game", self, "_on_join_game") == OK)
	add_child(_content)

func show_game_lobby(game_id: String) -> void:
	if _content:
		_content.queue_free()
	
	_content = GameLobby.instance().init(game_id)
	add_child(_content)

func _on_join_game(game_id: String, password: String) -> void:
	emit_signal("join_game", game_id, password)

func _on_pressed_join_game(
		game_id: String, game_name: String, has_password: bool) -> void:
	if not has_password:
		_on_join_game(game_id, "")
	else:
		join_dialog.popup_with(game_id, game_name)
