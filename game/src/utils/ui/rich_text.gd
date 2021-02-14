extends RichTextLabel

func _ready():
	assert(connect("meta_clicked", self, "meta_clicked") == OK)


func meta_clicked(meta):
	OS.shell_open(meta)
