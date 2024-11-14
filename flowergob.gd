extends CharacterBody2D

var is_reachable = false
var timeline = ""

func _on_area_2d_body_entered(body):
	if body.name == "Player":
		is_reachable = true
		print("Is reachable!")
	
func _on_area_2d_body_exited(_body):
	is_reachable = false
	print("Is not reachable!")


func _input(_event):
	if Global.isTalking == false: 
		
		if _event.is_action_pressed("Action Butt") and Global.flowers > 0 and is_reachable:
			Global.shmoney = Global.shmoney + Global.flowers * 10
			Global.flowers = 0
			Global.timeline = "res://Dialog/Characters/flowergob/flowergobSelling.dtl"
			Global.talking(_event)
		
		elif _event.is_action_pressed("Action Butt") and Global.shmoney > 0 and is_reachable: 
			Global.seeds = Global.seeds + Global.shmoney / 5
			Global.shmoney = 0
			Global.timeline = "res://Dialog/Characters/flowergob/flowergobBuying.dtl"
			Global.talking(_event)
	
		elif _event.is_action_pressed("Action Butt") and is_reachable and Dialogic.VAR.tutorialized == false:
			Global.timeline = "res://Dialog/Characters/flowergob/flowergobTutorial.dtl"
			Global.talking(_event)
	
		elif _event.is_action_pressed("Action Butt") and is_reachable:	
			Global.timeline = "res://Dialog/Characters/flowergob/flowergobDefault.dtl"
			Global.talking(_event)
