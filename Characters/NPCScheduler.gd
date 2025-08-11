extends Node
class_name NPCScheduler

# Schedule entry: {time_hour: int, time_minute: int, location: Vector2i, speed: float}
@export var daily_schedule: Array[Dictionary] = []
@export var movement_speed: float = 100.0
@export var tile_snap_distance: float = 4.0  # How close to tile center before snapping

var npc_body: CharacterBody2D
var tilemap: TileMap
var current_target_tile: Vector2i
var current_target_world_pos: Vector2
var is_moving: bool = false
var current_schedule_index: int = 0

# Grid movement state
var current_axis_target: Vector2 = Vector2.ZERO
var moving_horizontally: bool = false

signal arrived_at_location(tile_coords: Vector2i)
signal schedule_changed(old_index: int, new_index: int)
signal movement_interrupted(reason: String)

func _ready():
	# Get the parent CharacterBody2D
	npc_body = get_parent() as CharacterBody2D
	if not npc_body:
		push_error("NPCScheduler must be child of CharacterBody2D")
		return
	
	# Find the TileMap in the scene
	tilemap = _find_tilemap()
	if not tilemap:
		push_error("NPCScheduler: No TileMap found in scene")
		return
	
	# Connect to Global time system
	Global.time_changed.connect(_on_time_changed)
	
	# Set initial position based on current time
	_update_schedule_for_current_time()

func _find_tilemap() -> TileMap:
	# Look for TileMap in scene tree
	var root = get_tree().current_scene
	var found_tilemap = _search_for_tilemap(root)
	return found_tilemap

func _search_for_tilemap(node: Node) -> TileMap:
	if node is TileMap:
		return node as TileMap
	
	for child in node.get_children():
		var result = _search_for_tilemap(child)
		if result:
			return result
	
	return null

func _physics_process(delta: float):
	if is_moving and npc_body and tilemap:
		_move_towards_target(delta)

func _move_towards_target(delta: float):
	# Calculate grid-based direction (horizontal or vertical only)
	var direction = _calculate_grid_direction()
	
	# Check if we should stop moving
	if direction == Vector2.ZERO:
		_arrive_at_tile()
		return
	
	npc_body.velocity = direction * movement_speed
	npc_body.move_and_slide()

func _calculate_grid_direction() -> Vector2:
	var current_pos = npc_body.global_position
	
	# Check if we've reached our current axis target
	var distance_to_axis_target = current_pos.distance_to(current_axis_target)
	
	if distance_to_axis_target <= tile_snap_distance:
		# Snap to axis target position to prevent drift
		npc_body.global_position = current_axis_target
		
		# We've completed movement on this axis
		if current_axis_target == current_target_world_pos:
			# We've reached the final target - let natural movement handle the final approach
			var distance_to_final = current_pos.distance_to(current_target_world_pos)
			if distance_to_final <= tile_snap_distance:
				return Vector2.ZERO  # Stop moving
			else:
				# Continue moving toward final target naturally
				var diff = current_target_world_pos - current_pos
				if abs(diff.x) > abs(diff.y):
					return Vector2(sign(diff.x), 0)
				else:
					return Vector2(0, sign(diff.y))
		else:
			# Switch to the other axis
			current_axis_target = current_target_world_pos
			moving_horizontally = !moving_horizontally
			print("NPC switching to ", "horizontal" if moving_horizontally else "vertical", " movement")
	
	# Move toward current axis target with pure cardinal direction
	var diff = current_axis_target - current_pos
	
	if abs(diff.x) > abs(diff.y):
		# Move horizontally only
		return Vector2(sign(diff.x), 0)
	else:
		# Move vertically only
		return Vector2(0, sign(diff.y))

func _arrive_at_tile():
	# Naturally stop at tile center (no snapping)
	npc_body.velocity = Vector2.ZERO
	is_moving = false
	
	arrived_at_location.emit(current_target_tile)
	print("NPC arrived at tile: ", current_target_tile)

func move_to_tile(target_tile: Vector2i):
	if not tilemap:
		push_error("Cannot move to tile: TileMap not found")
		return
	
	current_target_tile = target_tile
	current_target_world_pos = tilemap.map_to_local(target_tile)
	is_moving = true
	
	# Reset grid movement state and choose initial axis
	_choose_movement_axis()
	
	print("NPC moving to tile: ", target_tile, " (world pos: ", current_target_world_pos, ")")

func _choose_movement_axis():
	var current_tile = tilemap.local_to_map(npc_body.global_position)
	var target_tile = current_target_tile
	
	var horizontal_distance = abs(target_tile.x - current_tile.x)
	var vertical_distance = abs(target_tile.y - current_tile.y)
	
	# Choose the axis with greater distance
	if horizontal_distance > vertical_distance:
		moving_horizontally = true
		# Move to target X tile, keep current Y tile
		var intermediate_tile = Vector2i(target_tile.x, current_tile.y)
		current_axis_target = tilemap.map_to_local(intermediate_tile)
	else:
		moving_horizontally = false
		# Move to target Y tile, keep current X tile  
		var intermediate_tile = Vector2i(current_tile.x, target_tile.y)
		current_axis_target = tilemap.map_to_local(intermediate_tile)
	
	print("NPC choosing ", "horizontal" if moving_horizontally else "vertical", " movement first")

func get_current_tile() -> Vector2i:
	if not tilemap or not npc_body:
		return Vector2i.ZERO
	return tilemap.local_to_map(npc_body.global_position)

func stop_movement():
	is_moving = false
	npc_body.velocity = Vector2.ZERO
	movement_interrupted.emit("stopped_by_request")

func is_tile_occupied(tile_coords: Vector2i) -> bool:
	if not tilemap:
		return false
	
	# Check if there's a collision tile on physics layers
	for layer in range(tilemap.get_layers_count()):
		var tile_data = tilemap.get_cell_tile_data(layer, tile_coords)
		if tile_data and tile_data.get_collision_polygons_count(0) > 0:
			return true
	
	return false

func _on_time_changed(hour: int, minute: int):
	_check_schedule_update(hour, minute)

func _check_schedule_update(hour: int, minute: int):
	if daily_schedule.is_empty():
		return
	
	# Find the current schedule entry that should be active
	var target_index = -1
	var current_time_minutes = hour * 60 + minute
	
	# Find the latest schedule entry that has already passed
	for i in range(daily_schedule.size()):
		var entry = daily_schedule[i]
		var entry_time_minutes = entry.time_hour * 60 + entry.time_minute
		
		if entry_time_minutes <= current_time_minutes:
			target_index = i
		else:
			break
	
	# If no entry has passed yet today, use the last entry from "yesterday"
	if target_index == -1:
		target_index = daily_schedule.size() - 1
	
	# Update schedule if changed
	if target_index != current_schedule_index:
		var old_index = current_schedule_index
		current_schedule_index = target_index
		_move_to_scheduled_location()
		schedule_changed.emit(old_index, current_schedule_index)

func _update_schedule_for_current_time():
	_check_schedule_update(Global.current_hour, Global.current_minute)

func _move_to_scheduled_location():
	if daily_schedule.is_empty() or current_schedule_index >= daily_schedule.size():
		return
	
	var entry = daily_schedule[current_schedule_index]
	var target_tile: Vector2i = entry.location
	
	# Override movement speed if specified in schedule entry
	if entry.has("speed"):
		movement_speed = entry.speed
	
	move_to_tile(target_tile)
	print("NPC scheduled to move to tile: ", target_tile, " at ", entry.time_hour, ":", entry.time_minute)

func add_schedule_entry(hour: int, minute: int, tile_location: Vector2i, speed: float = -1):
	var entry = {
		"time_hour": hour,
		"time_minute": minute,
		"location": tile_location
	}
	
	if speed > 0:
		entry.speed = speed
	
	daily_schedule.append(entry)
	_sort_schedule()

func _sort_schedule():
	# Sort schedule by time (hour * 60 + minute)
	daily_schedule.sort_custom(func(a, b): 
		return (a.time_hour * 60 + a.time_minute) < (b.time_hour * 60 + b.time_minute)
	)

func get_current_scheduled_location() -> Vector2i:
	if daily_schedule.is_empty() or current_schedule_index >= daily_schedule.size():
		return Vector2i.ZERO
	return daily_schedule[current_schedule_index].location

func get_next_scheduled_time() -> Dictionary:
	if daily_schedule.is_empty():
		return {}
	
	var next_index = (current_schedule_index + 1) % daily_schedule.size()
	return daily_schedule[next_index]

