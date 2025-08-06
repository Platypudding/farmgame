extends Label

func _ready():
	# Connect to Global's time signal
	Global.time_changed.connect(_on_time_changed)
	# Set initial time display
	_on_time_changed(Global.current_hour, Global.current_minute)

func _on_time_changed(hour: int, minute: int):
	text = Global.get_time_string()