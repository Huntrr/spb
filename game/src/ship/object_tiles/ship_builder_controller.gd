extends Node

onready var Log := Logger.new(self)

func _ready():
	$"../KeyListener".connect("triggered", self, "_on_triggered")

func _on_triggered(node: Node) -> void:
	Log.info("TRIGGER")
