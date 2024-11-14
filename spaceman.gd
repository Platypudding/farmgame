extends CharacterBody2D
var text = ""
var textSpeed = 0.125
var is_reachable = false
var voice = "SpaceMan"

var dialog = ["Please do not interrupt me at this time.",

"As you can see, I am doing a little dance at the moment.",

"I would appreciate privacy in this matter."]


func _on_area_2d_body_entered(body):
	if body.name == "Player":
		is_reachable = true
		print("Is reachable!")
	
func _on_area_2d_body_exited(_body):
	is_reachable = false
	print("Is not reachable!")

func _input(_event):
	if _event.is_action_pressed("Action Butt") and is_reachable:
		if Global.isTalking == false:
			Global.voice = voice
			Global.text_queue = dialog.duplicate()	
		Global.talking(_event)
