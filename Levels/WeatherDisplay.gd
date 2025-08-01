extends Label

func _ready() -> void:
	Global.weather_changed.connect(_on_weather_changed)
	_update_weather_display()

func _update_weather_display() -> void:
	text = "%s: %s" % [Global.current_weather.capitalize(), Global.get_weather_description()]

func _on_weather_changed(_new_weather: String) -> void:
	_update_weather_display()