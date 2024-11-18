extends CharacterBody2D
var is_reachable = false
var player = null
@export var seed: InvItem
@export var flower: InvItem

func _on_area_2d_body_entered(body):
	if body.name == "Player":
		player = body
		is_reachable = true

	
func _on_area_2d_body_exited(_body):
	is_reachable = false



func _input(_event):
	if Global.isTalking == false: 

		if _event.is_action_pressed("Action Butt") and Global.flowers > 0 and is_reachable:
			Global.shmoney = Global.shmoney + Global.flowers * 10
			Global.flowers = 0
			Global.timeline = "res://Dialog/Characters/flowergob/flowergobSelling.dtl"
			player.remove(flower, 1)
			Global.talking(_event)
		
		elif _event.is_action_pressed("Action Butt") and Global.shmoney > 0 and is_reachable: 
			Global.seeds = Global.seeds + 1
			Global.shmoney = Global.shmoney - 5
			Global.timeline = "res://Dialog/Characters/flowergob/flowergobBuying.dtl"
			Global.talking(_event)
			player.collect(seed, 1)
	
		elif _event.is_action_pressed("Action Butt") and is_reachable and Dialogic.VAR.tutorialized == false:
			player.itemcheck()
			Global.timeline = "res://Dialog/Characters/flowergob/flowergobTutorial.dtl"
			Global.talking(_event)
			player.collect(seed, 5)
			Global.seeds = Global.seeds + 5
	
		elif _event.is_action_pressed("Action Butt") and is_reachable:	
			Global.timeline = "res://Dialog/Characters/flowergob/flowergobDefault.dtl"
			Global.talking(_event)
			
