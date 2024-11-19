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
	if _event.is_action_pressed("Action Butt") and Global.isTalking == false and is_reachable: 
		var flowercheck = player.check(flower)
		var seedcheck = player.check(seed)

		if flowercheck[0] == true:
			
			Global.timeline = "res://Dialog/Characters/flowergob/flowergobSelling.dtl"
			player.remove(flower, flowercheck[1])
			Global.shmoney = Global.shmoney + flowercheck[1] * 10
			Global.talking(_event)
		
		elif Global.shmoney > 0: 
			Global.timeline = "res://Dialog/Characters/flowergob/flowergobBuying.dtl"
			Global.talking(_event)
			player.collect(seed, Global.shmoney / 5)
			Global.shmoney = 0
	
		elif Dialogic.VAR.tutorialized == false:
			Global.timeline = "res://Dialog/Characters/flowergob/flowergobTutorial.dtl"
			Global.talking(_event)
			player.collect(seed, 5)
	
		else:
			print(player.check(flower, 0))
			Global.timeline = "res://Dialog/Characters/flowergob/flowergobDefault.dtl"
			Global.talking(_event)
			
			
