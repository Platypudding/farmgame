#script is placed on the root player CharacterBody2D node

extends CharacterBody2D
@export var speed = 100
var sprintSpeed = speed * 2
@onready var tilemap = get_parent().get_node("TileMap")
@onready var gal = $PlayerSprite
var playerLocation = self.global_position
var baseLayer = 1
var highLayer = 128
var flipHorizontal


		
		
func get_input():
	var input_direction = Input.get_vector("MoveLeft", "MoveRight", "MoveUp", "MoveDown")
	velocity = input_direction * speed
	
	if Input.is_action_pressed("Sprint"):
		speed = sprintSpeed
		if velocity.x or velocity.y:
			gal.speed_scale = 2
		
		
	else:
		speed = sprintSpeed / 2
		gal.speed_scale = 1

	if velocity.x > 0:
		gal.play("walkinright")
		flipHorizontal = false
		
	elif velocity.x < 0:
		gal.play("walkinleft")
		flipHorizontal = true
		
	elif velocity.y:
		if !flipHorizontal:
			gal.play("walkinright")
		else:
			gal.play("walkinleft")
	
	else:
		if flipHorizontal:
			gal.play("idleright")
			gal.speed_scale = 1
		else:
			gal.play("idleleft")
			gal.speed_scale = 1


func elevate():
	
	playerLocation = self.global_position
	var tileLocation : Vector2i = tilemap.local_to_map(playerLocation)
	var tileData : TileData = tilemap.get_cell_tile_data(2, tileLocation)
	
	if tileData:
		
		if tileData.get_custom_data("elevated") == true:
			self.set_collision_layer(highLayer)
			self.set_collision_mask(highLayer)

		else:
			self.set_collision_layer(baseLayer)
			self.set_collision_mask(baseLayer)

func _physics_process(_delta):
	if Global.isTalking == true:
		if flipHorizontal:
			gal.play("idleright")
			gal.speed_scale = 1
		else:
			gal.play("idleleft")
			gal.speed_scale = 1

	if Global.isTalking == false:
		get_input()
		move_and_slide()
		elevate()
	

	
	
	
	
	
