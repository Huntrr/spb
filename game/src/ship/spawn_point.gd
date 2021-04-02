extends Node

onready var object_tile: ObjectTile = $"../"

func _ready():
	object_tile.ship.add_node_to_group("spawn", self)
