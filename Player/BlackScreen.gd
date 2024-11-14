extends ColorRect
var tween
func maketween():
	tween = create_tween()
	
func fadein():
	maketween()
	tween.tween_property(self, "modulate:a", 1, 2)

func fadeout():
	maketween()
	tween.tween_property(self, "modulate:a", 0, 2)
