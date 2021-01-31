extends Node

onready var tile_selector = $UI/TileSelector
onready var blueprint = $Blueprint

onready var save_dialog = $UI/SaveDialog
onready var load_dialog = $UI/LoadDialog
onready var validation_errors = $UI/ValidationErrors

onready var run_button = (
	$UI/CenterContainer/MarginContainer/HBoxContainer/PlayButton)

func _ready() -> void:
	tile_selector.connect("tile_selected", self, "_on_tile_selected")
	
	save_dialog.connect("file_selected", self, "_on_save_blueprint")
	load_dialog.connect("file_selected", self, "_on_load_blueprint")

	run_button.connect("pressed", self, "_on_run")
	
	validation_errors.connect(
		"is_highlighted", self, "_on_error_is_highlighted")
	blueprint.connect("is_error_highlighted", self, "_on_error_is_highlighted")

	validation_errors.connect("is_selected", self, "_on_error_is_selected")


func _on_tile_selected(tile: Tile, rotation: int) -> void:
	blueprint.current_tile = tile
	blueprint.current_tile_rotation = rotation


func _on_save_blueprint(file_path: String) -> void:
	var json: String = (
		SpaceshipBlueprint.new().from_blueprint(blueprint).to_string())
	var file = File.new()
	validation_errors.hide()
	file.open(file_path, File.WRITE)
	file.store_string(json)
	file.close()


func _on_load_blueprint(file_path: String) -> void:
	var file = File.new()
	file.open(file_path, File.READ)
	var json = file.get_as_text()
	file.close()
	validation_errors.hide()
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
		validation_errors.show_errors(errors)
	else:
		validation_errors.hide()
		print("RUN")


func _on_error_is_highlighted(position: Vector2) -> void:
	validation_errors.highlight(position)
	blueprint.highlight_error(position)


func _on_error_is_selected(position: Vector2) -> void:
	blueprint.focus_tile(position)
