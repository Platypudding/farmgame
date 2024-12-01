extends CharacterBody2D
var is_reachable = false
var fishonline = false
var isfishing = true
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
			$Timer.stop()
			fishonline = false
			Dialogic.VAR.fishname = randomfish
			Global.timeline = "res://Dialog/Fishing/fishcaught.dtl"
			Global.talking(_event)
			
			
				
		elif isfishing:
			$Timer.stop()
			print("timer stopped")
			Global.isOccupied = false
			isfishing = false
func fishing():	
	rng.randomize()
	fishnumber = rng.randi_range(2,4) #the current fish item numbers range from 2 to 4. this picks one of their item numbers.
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

func _on_timer_timeout() -> void:
	if !fishonline:
		$Timer.start(0.5)
		fishonline = true
		$AudioStreamPlayer.play()
	
	elif fishonline:
		print("missed your window buster")
		fishonline = false
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
