extends CharacterBody2D
var is_reachable = false


func _on_area_2d_body_entered(body):
	if body.name == "Player":
		is_reachable = true
		print("reachable!")

func _on_area_2d_body_exited(_body):
	is_reachable = false

func _input(_event):
	
	if _event.is_action_pressed("Action Butt") and is_reachable:
		Global.timeline = ""
		Global.talking(_event)
		
