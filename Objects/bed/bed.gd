extends CharacterBody2D

var is_reachable = false
var isSleeping = false

func _on_area_2d_body_entered(body):
	if body.name == "Player":
		is_reachable = true
		
	
func _on_area_2d_body_exited(_body):
	is_reachable = false
	

func _input(_event):
	
	if _event.is_action_pressed("Action Butt") and is_reachable and !isSleeping:
			print("gotobed")
			isSleeping = true
			get_node("/root/Level/Player/Camera2D/BlackScreen").fadein()
			$bedtimesong.play()
			Global.isOccupied = true
			print(Global.isOccupied)
			await get_tree().create_timer(5).timeout
			Global.day = Global.day + 1
			Global.update_weather()
			get_node("/root/Level/Player/Camera2D/BlackScreen").fadeout_to_weather()
			await get_tree().create_timer(2).timeout
			Global.isOccupied = false
			isSleeping = false
			
