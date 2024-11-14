extends CharacterBody2D

var is_reachable = false


func _on_area_2d_body_entered(body):
	if body.name == "Player":
		is_reachable = true
		print("Is reachable!")
	
func _on_area_2d_body_exited(_body):
	is_reachable = false
	print("Is not reachable!")

func _input(_event):
		if _event.is_action_just_pressed("Action Butt") and is_reachable:
			Global.talkingWords = "placeholder"
			Global.talking(_event)
