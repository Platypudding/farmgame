extends Node

signal weather_changed(new_weather: String)
signal time_changed(hour: int, minute: int)

var day = 1
var flowers = 0
var shmoney = 0
var seeds = 0
var isOccupied = false
var isFishing = false  # Track fishing separately from other occupying activities
var callYN = false
var voice
var timeline = "test"
var speaking = false

# Time system variables
var current_hour: int = 6
var current_minute: int = 0
var day_length_seconds: float = 480.0  # 8 minutes total
var time_elapsed: float = 0.0
var time_interval_minutes: int = 30  # Update every 30 minutes

# Weather system variables
var current_weather: String = "sunny"
var weather_types: Array[String] = ["sunny", "rainy"]
var last_weather_day: int = 0


func talking(_event):
	if !isOccupied:
		# One-shot connection - automatically disconnects after first call
		Dialogic.timeline_ended.connect(_on_timeline_ended, CONNECT_ONE_SHOT)
		isOccupied = true
		speaking = true
		Dialogic.start(timeline)
		


func _on_timeline_ended():
	# No manual disconnection needed - CONNECT_ONE_SHOT handles it automatically
	isOccupied = false
	speaking = false
	timeline = ""

# Weather system functions
func update_weather():
	if day != last_weather_day:
		var _old_weather = current_weather
		# 50/50 chance between sunny and rainy
		current_weather = "sunny" if randf() < 0.5 else "rainy"
		last_weather_day = day
		
		# Always emit weather signal and print weather status for each new day
		weather_changed.emit(current_weather)
		print("Day %d: Today's weather is %s" % [day, current_weather])

# Debug function to force weather change (useful for testing)
func force_weather(weather_type: String):
	if weather_type in weather_types:
		current_weather = weather_type
		weather_changed.emit(current_weather)
		print("DEBUG: Forced weather to %s" % current_weather)
		

func get_weather_description() -> String:
	match current_weather:
		"rainy":
			return "It's raining today"
		"sunny":
			return "The sun is shining"
		_:
			return "Weather conditions unknown"

# Time system functions
func _ready():
	reset_time_to_morning()

func _process(delta: float):
	# Advance time when not in dialogs/sleeping, but ALLOW time during fishing
	if !isOccupied or isFishing:
		advance_time(delta)

func advance_time(delta: float):
	time_elapsed += delta
	
	# Calculate how much real time = 30 in-game minutes
	# 8 minutes / 24 hours * 30 minutes = 8 * 60 / 1440 * 30 = 10 seconds per 30-minute interval
	var seconds_per_interval = day_length_seconds / 24.0 * (time_interval_minutes / 60.0)
	
	# Check if we should advance by 30 minutes
	if time_elapsed >= seconds_per_interval:
		time_elapsed -= seconds_per_interval
		current_minute += time_interval_minutes
		
		# Handle hour rollover
		if current_minute >= 60:
			current_minute = 0
			current_hour += 1
			
			# Handle day rollover - new day starts at 6:00 AM
			if current_hour >= 24:
				current_hour = 6  # Reset to 6:00 AM instead of midnight
				advance_day()
		
		# Emit time changed signal
		time_changed.emit(current_hour, current_minute)

func reset_time_to_morning():
	current_hour = 6
	current_minute = 0
	time_elapsed = 0.0
	time_changed.emit(current_hour, current_minute)

func advance_day():
	day += 1
	update_weather()
	print("Day %d begins at 6:00 AM!" % day)

func get_time_string() -> String:
	var hour_12 = current_hour
	var am_pm = "AM"
	
	# Convert to 12-hour format
	if current_hour == 0:
		hour_12 = 12
	elif current_hour > 12:
		hour_12 = current_hour - 12
		am_pm = "PM"
	elif current_hour == 12:
		am_pm = "PM"
	
	return "%d:%02d %s" % [hour_12, current_minute, am_pm]
