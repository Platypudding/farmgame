extends Node

signal weather_changed(new_weather: String)

var day = 1
var flowers = 0
var shmoney = 0
var seeds = 0
var isOccupied = false
var callYN = false
var voice
var timeline = "test"
var speaking = false

# Weather system variables
var current_weather: String = "sunny"
var weather_types: Array[String] = ["sunny", "rainy"]
var last_weather_day: int = 0


func talking(_event):
	if !isOccupied:
		Dialogic.timeline_ended.connect(_on_timeline_ended)
		isOccupied = true
		speaking = true
		Dialogic.start(timeline)
		


func _on_timeline_ended():
	Dialogic.timeline_ended.disconnect(_on_timeline_ended)
	isOccupied = false
	speaking = false
	timeline = ""

#func _on_timeline_ended():
#	Dialogic.timeline_ended.disconnect(_on_timeline_ended)
#	isTalking = false
#	get_tree().paused = false
#	timeline = ""
#	print("talking end")

# Weather system functions
func update_weather():
	if day != last_weather_day:
		var old_weather = current_weather
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
		

func get_weather_effect(effect_type: String) -> float:
	# No gameplay effects - always return default growth rate
	return 1.0

func get_weather_description() -> String:
	match current_weather:
		"rainy":
			return "It's raining today"
		"sunny":
			return "The sun is shining"
		_:
			return "Weather conditions unknown"
