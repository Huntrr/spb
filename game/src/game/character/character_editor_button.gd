tool
extends Node

signal prev_pressed(type)
signal color_pressed(type)
signal next_pressed(type)

const outfits: Outfits = preload("res://data/character/outfits.tres")

export(bool) var colorable = false

onready var _prev: Node = $Prev/Button
onready var _color: Node = $Color/Button
onready var _next: Node = $Next/Button

func _ready():
	_color.text = name
	_color.disabled = not colorable
	
	if outfits.get_component(name.to_lower()).size() <= 1:
		_prev.disabled = true
		_next.disabled = true
	
	_prev.connect("pressed", self,
		"emit_signal", ["prev_pressed", name.to_lower()])
	_color.connect("pressed", self,
		"emit_signal", ["color_pressed", name.to_lower()])
	_next.connect("pressed", self,
		"emit_signal", ["next_pressed", name.to_lower()])
