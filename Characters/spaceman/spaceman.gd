extends CharacterBody2D
var is_reachable = false
var player = null

func _on_area_2d_body_entered(body):
	if body.name == "Player":
		player = body
		is_reachable = true
	
	
func _on_area_2d_body_exited(_body):
	is_reachable = false

func _input(_event):
	
	if _event.is_action_pressed("Action Butt") and is_reachable:
		Global.timeline = "res://Dialog/Characters/spaceman/spacemanDefault.dtl"
		Global.talking(_event)
		
