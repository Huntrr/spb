extends WindowDialog


func _ready():
	popup()
	self.connect("hide", self, "queue_free")
	
	$GameList.show()
