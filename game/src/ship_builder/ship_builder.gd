extends Node

onready var tile_selector = $UI/TileSelector
onready var blueprint = $Blueprint

onready var save_dialog = $UI/SaveDialog
onready var load_dialog = $UI/LoadDialog

onready var run_button = (
	$UI/CenterContainer/MarginContainer/HBoxContainer/PlayButton)

func _ready() -> void:
	tile_selector.connect("tile_selected", self, "_on_tile_selected")
	
	save_dialog.connect("file_selected", self, "_on_save_blueprint")
	load_dialog.connect("file_selected", self, "_on_load_blueprint")

	run_button.connect("pressed", self, "_on_run")


func _on_tile_selected(tile: Tile, rotation: int) -> void:
	blueprint.current_tile = tile
	blueprint.current_tile_rotation = rotation


func _on_save_blueprint(file_path: String) -> void:
	var json: String = (
		SpaceshipBlueprint.new().from_blueprint(blueprint).to_string())
	var file = File.new()
	file.open(file_path, File.WRITE)
	file.store_string(json)
	file.close()


func _on_load_blueprint(file_path: String) -> void:
	var file = File.new()
	file.open(file_path, File.READ)
	var json = file.get_as_text()
	file.close()
	SpaceshipBlueprint.new().from_string(json).to_blueprint(blueprint)
	blueprint.center()


func _on_run() -> void:
	var bp: SpaceshipBlueprint = (
		SpaceshipBlueprint.new().from_blueprint(blueprint))
	bp.to_blueprint(blueprint)
	blueprint.center()
	
	var errors = bp.validate()
	if not errors.empty():
		blueprint.show_errors(errors.keys())
		$UI/ValidationErrors.show_errors(errors)
	else:
		print("RUN")
