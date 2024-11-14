extends AnimatedSprite2D


var localDays = Global.day
@export var phase = 1
var isReachable = false
var isHarvestable = false
var isSown = false

func _process(_delta):
	if (Global.day > localDays) and isSown:
		phase = phase + 1
		localDays = Global.day
	
	if(phase == 1):
		set_frame(0)
		
	if(phase == 2):
		set_frame(1)
		
	if(phase == 3):
		set_frame(2)
		
	if(phase == 4):
		set_frame(3)
		
	if(phase >= 5):
		set_frame(4)
		isHarvestable = true
		
		
func _on_area_2d_body_entered(body):
	if body.name == "Player":
			isReachable = true

func _on_area_2d_body_exited(body):
	if body.name == "Player":
			isReachable = false
			


func _input(event):
	if event.is_action_pressed("Action Butt") and isReachable and isSown == false and Global.seeds > 0:
		isSown = true
		Global.seeds = Global.seeds - 1
		phase = 2
		localDays = Global.day
	
	if event.is_action_pressed("Action Butt") and isReachable and isHarvestable:
			Global.flowers = Global.flowers + 1
			isHarvestable = false
			isSown = false
			phase = 1
			

