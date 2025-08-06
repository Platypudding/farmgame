extends CharacterBody2D
var is_reachable = false
var fishonline = false
var isfishing = true
var missedfish = false
var player = null
var fishnumber = null
var randomfish = null
var fishitem = null
var waitrarity = null
var waittime = null
var rng = RandomNumberGenerator.new()
var totaltuna = 0
var totaltrash = 0
var totalcatfish = 0
var totalzebrafish = 0
@export var location = ""


func _on_area_2d_body_entered(body):
	if body.name == "Player":
		player = body
		is_reachable = true
func _on_area_2d_body_exited(_body):
	is_reachable = false

func _input(_event):
	if _event.is_action_pressed("Action Butt") and Global.isOccupied == false and is_reachable: 
			fishing()
			
	
	elif _event.is_action_pressed("Action Butt") and is_reachable and !Global.speaking: 
		if fishonline:
			randomfish = Itemlist.listofitems.find_key(fishnumber) #gets the corresponding key for the value of the fish's item number
			fishitem = Itemlist.getItem(randomfish) #grabs the actual item corresponding to the fish key
			player.collect(fishitem, 1)
			Global.isOccupied = false
			Global.isFishing = false
			$Timer.stop()
			fishonline = false
			$Sprite.play("default")
			Dialogic.VAR.fishname = randomfish
			Global.timeline = "res://Dialog/Fishing/fishcaught.dtl"
			Global.talking(_event)
			missedfish = false
			
			
				
		elif isfishing:
			$Timer.stop()
			print("timer stopped")
			Global.isOccupied = false
			Global.isFishing = false
			isfishing = false
			$Sprite.play("default")
			missedfish = false

func fishing():	
	if !missedfish:
		$SplashSound.play()
	$Sprite.play("BobberFloat")
	rng.randomize()
	
	# Get available fish based on current weather and location
	var available_fish = get_available_fish()
	print("Current weather: ", Global.current_weather, " | Fishing location: ", location)
	print("Available fish IDs: ", available_fish)
	
	if available_fish.is_empty():
		# Fallback to trash if no fish available (shouldn't happen)
		fishnumber = 2
	else:
		fishnumber = available_fish[rng.randi() % available_fish.size()]
	#determines how long the player will wait before the fish bites
	waitrarity = rng.randi_range(0,100)
	if waitrarity == 1: #instant, 1 second or less
		waittime = rng.randf_range(0,1)
		print("instant wait")
	elif waitrarity >= 2 and waitrarity <= 11: #quick, 1 to 5 seconds
		waittime = rng.randf_range(1,5)
		print("quick wait")
	elif waitrarity >= 12 and waitrarity <= 78: #average, 5 to 10 seconds
		waittime = rng.randf_range(5, 10)
		print("average wait")
	elif waitrarity >= 79 and waitrarity <= 99: #slow, 10 to 30 seconds
		waittime = rng.randf_range(10,30)
		print("slow wait")
	elif waitrarity == 100: #glacial, 30 seconds to 90 seconds
		waittime = rng.randf_range(30,90)
		print("glacial wait")
	
	
		
	$Timer.start(waittime)
	isfishing = true
	Global.isOccupied = true
	Global.isFishing = true  # Allow time to continue during fishing

func _on_timer_timeout() -> void:
	if !fishonline:
		$Sprite.play("FishOnHook")
		$Timer.start(0.5)
		fishonline = true
		$AlertSound.play()
	
	elif fishonline:
		print("missed your window buster")
		fishonline = false
		missedfish = true
		fishing()
func waitraritytest(int):
	var instant = 0
	var quick = 0
	var average = 0
	var slow = 0
	var glacial = 0
	
	for x in int:
		waitrarity = rng.randi_range(0,100)
		if waitrarity == 1: #instant, 1 second or less
			waittime = rng.randf_range(0,1)
			instant = instant + 1
			
		elif waitrarity >= 2 and waitrarity <= 11: #quick, 1 to 5 seconds
			waittime = rng.randf_range(1,5)
			quick = quick + 1
			
		elif waitrarity >= 12 and waitrarity <= 78: #average, 5 to 10 seconds
			waittime = rng.randf_range(5, 10)
			average = average + 1
			
		elif waitrarity >= 79 and waitrarity <= 99: #slow, 10 to 30 seconds
			waittime = rng.randf_range(10,30)
			slow = slow + 1
			
		elif waitrarity == 100: #glacial, 30 seconds to 90 seconds
			waittime = rng.randf_range(30,90)
			glacial = glacial + 1
		x += 1
	print("Instant: ", instant)
	print("Quick: ", quick)
	print("Average: ", average)
	print("Slow: ", slow)
	print("Glacial: ", glacial)

func get_available_fish() -> Array[int]:
	var available_fish: Array[int] = []
	
	# Check each fish item (2-5 are fish items)
	for fish_id in range(2, 6):
		var fish_name = Itemlist.listofitems.find_key(fish_id)
		if fish_name != null:
			var fish_item = Itemlist.getItem(fish_name)
			print("Fish: ", fish_name, " (ID: ", fish_id, ") - Weather: ", fish_item.allowed_weather, " - Locations: ", fish_item.findable_location)
			
			# Check weather availability
			var weather_ok = fish_item.allowed_weather.is_empty() or Global.current_weather in fish_item.allowed_weather
			
			# Check location availability
			var location_ok = fish_item.findable_location.is_empty() or location in fish_item.findable_location
			
			# Fish is available if both weather and location conditions are met
			if weather_ok and location_ok:
				available_fish.append(fish_id)
				print("  -> AVAILABLE (weather: ", weather_ok, ", location: ", location_ok, ")")
			else:
				print("  -> NOT AVAILABLE (weather: ", weather_ok, ", location: ", location_ok, ")")
	
	return available_fish
