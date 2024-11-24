extends CharacterBody2D
var is_reachable = false
@export var tuna: InvItem
@export var catfish: InvItem
@export var trash: InvItem
var rng = RandomNumberGenerator.new()
var fishnumber = null
var fishfinder = null
var finalfish = [tuna, catfish, trash]

func _on_area_2d_body_entered(body):
	if body.name == "Player":
		is_reachable = true
		rng.randomize()
		fishnumber = rng.randi_range(200,202)
		if finalfish[1].name == "Catfish":
			print("catfish")
			
		else: 
			print("not catfish")

		#	fishfinder += 1
		#	if fishfinder == fishnumber:
		#		print (fishfinder)
		

func _on_area_2d_body_exited(_body):
	is_reachable = false

func _input(_event):
	
	if _event.is_action_pressed("Action Butt") and is_reachable:
		Global.timeline = ""
		Global.talking(_event)
		
