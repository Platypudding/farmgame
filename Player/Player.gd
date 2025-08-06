#script is placed on the root player CharacterBody2D node

extends CharacterBody2D
@export var base_speed: int = 100
@export var inv: Inv
var sprint_multiplier: float = 2.0
var current_speed: int
@onready var tilemap = get_parent().get_node("TileMap")
@onready var gal = $PlayerSprite
var playerLocation = self.global_position
var baseLayer = 1
var highLayer = 128
var flipHorizontal

func _ready():
	current_speed = base_speed

func get_input():
	var input_direction = Input.get_vector("MoveLeft", "MoveRight", "MoveUp", "MoveDown")
	
	# Calculate current speed without modifying the export variable
	current_speed = base_speed * sprint_multiplier if Input.is_action_pressed("Sprint") else base_speed
	velocity = input_direction * current_speed
	
	# Handle animation speed
	if Input.is_action_pressed("Sprint") and (velocity.x or velocity.y):
		gal.speed_scale = 2.0
	else:
		gal.speed_scale = 1.0
	
	if Input.is_action_just_pressed("plus"):
		Global.day += 1
			
	if Input.is_action_just_pressed("minus"):
		Global.day -= 1


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
	if Global.isOccupied == true:
		if flipHorizontal:
			gal.play("idleright")
			gal.speed_scale = 1
		else:
			gal.play("idleleft")
			gal.speed_scale = 1

	if Global.isOccupied == false:
		get_input()
		move_and_slide()
		elevate()

func collect(item, amount):
	inv.insert(item, amount)
	
func remove(item, amount) -> bool:
	return inv.remove(item, amount)
	
func check(item):
	return inv.check(item)
