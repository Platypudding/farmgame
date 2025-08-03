extends ColorRect

var tween: Tween
var rain_dimming_opacity: float = 0.30

func _ready() -> void:
	# Connect to Global weather signal for dimming effects
	Global.weather_changed.connect(_on_weather_changed)
	
	# Set initial weather state
	_update_weather_dimming(Global.current_weather)

func maketween() -> void:
	if tween:
		tween.kill()
	tween = create_tween()
	
func fadein() -> void:
	maketween()
	tween.tween_property(self, "modulate:a", 1, 2)

func fadeout() -> void:
	maketween()
	tween.tween_property(self, "modulate:a", 0, 2)

func _on_weather_changed(new_weather: String) -> void:
	_update_weather_dimming(new_weather)

func _update_weather_dimming(weather: String) -> void:
	maketween()
	
	if weather == "rainy":
		# Dim the screen for overcast/rainy atmosphere
		tween.tween_property(self, "modulate:a", rain_dimming_opacity, 1.0)
	else:
		# Clear weather - no dimming
		tween.tween_property(self, "modulate:a", 0.0, 1.0)

# Debug input for testing weather dimming
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_R:
			Global.force_weather("rainy")
		elif event.keycode == KEY_S:
			Global.force_weather("sunny")
