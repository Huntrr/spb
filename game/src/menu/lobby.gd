extends WindowDialog

const GameList: PackedScene = preload("res://scenes/menu/game_list.tscn")
const GameLobby: PackedScene = preload("res://scenes/menu/game_lobby.tscn")

var _content: Control

onready var create_dialog: AcceptDialog = $CreateDialog
onready var create_crew: AcceptDialog = $CreateCrew
onready var join_dialog: AcceptDialog = $JoinDialog

func _ready():
	popup()
	assert(self.connect("hide", self, "queue_free") == OK)
	
	_content = GameList.instance()
	assert(_content.connect(
		"pressed_new_game", create_dialog, "popup_centered") == OK)
	add_child(_content)
