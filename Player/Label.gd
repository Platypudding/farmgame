extends Label

func _process(_delta):
	set_text(str("seeds: ", Global.seeds, "!"))
	
