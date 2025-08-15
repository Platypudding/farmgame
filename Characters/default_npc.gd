extends CharacterBody2D
var is_reachable = false
var player = null

@onready var scheduler = $NPCScheduler

func _ready():
	setup_schedule()

func setup_schedule():
	if scheduler:
		print("Default NPC schedule set up with ", scheduler.daily_schedule.size(), " entries")
		call_deferred("_trigger_initial_schedule_check")

func _trigger_initial_schedule_check():
	if scheduler:
		scheduler._update_schedule_for_current_time()
		print("Triggered initial schedule check for default NPC")

func _on_area_2d_body_entered(body):
	if body.name == "Player":
		player = body
		is_reachable = true

func _on_area_2d_body_exited(_body):
	is_reachable = false

func _input(_event):
	if _event.is_action_pressed("Action Butt") and Global.isOccupied == false and is_reachable:
		Global.timeline = ""
		Global.talking(_event)
		
