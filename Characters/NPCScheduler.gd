extends Node
class_name NPCScheduler

# Schedule entry: {time_hour: int, time_minute: int, location: Vector2/Vector2i, speed: float, route_type: String, waypoint_path: Array}
@export var daily_schedule: Array[Dictionary] = []
@export var movement_speed: float = 50.0

# Tile-based movement settings
@export var tile_size: float = 16.0  # Size of each tile in pixels
@export var axis_threshold: float = 4.0  # How close to axis before snapping to pure horizontal/vertical movement
var tilemap: TileMap  # Reference to the tilemap for coordinate conversion
var waypoint_manager: WaypointManager  # Reference to waypoint management system

var npc_body: CharacterBody2D
var current_target: Vector2
var is_moving: bool = false
var current_schedule_index: int = -1  # Start with no active schedule

# Tile-based movement state
var current_tile: Vector2i
var target_tile: Vector2i
var current_path: Array[Vector2i] = []
var path_index: int = 0

# Movement smoothing
var movement_epsilon: float = 8.0  # How close to tile center before considering "arrived"
var committed_axis: String = ""  # "horizontal", "vertical", or "" when not committed
var axis_commitment_threshold: float = 8.0  # How much closer before switching axis

signal arrived_at_location(location: Vector2)
signal schedule_changed(old_index: int, new_index: int)
signal path_completed(final_destination: Vector2i)

func _ready():
	# Get the parent CharacterBody2D
	npc_body = get_parent() as CharacterBody2D
	if not npc_body:
		push_error("NPCScheduler must be child of CharacterBody2D")
		return
	
	# Find tilemap and waypoint manager
	_find_tilemap_and_waypoint_manager()
	
	# Initialize current tile position and snap to tile center
	if tilemap:
		current_tile = tilemap.local_to_map(npc_body.global_position)
		# Snap NPC to the center of their starting tile
		var tile_center = tilemap.map_to_local(current_tile)
		npc_body.global_position = tile_center
		print("NPC initialized at tile ", current_tile, " world pos ", tile_center)
	
	# Connect to Global time system
	Global.time_changed.connect(_on_time_changed)
	
	# Note: Initial schedule check will be triggered after schedule entries are added

func _physics_process(delta: float):
	if is_moving and npc_body:
		_move_towards_target(delta)

func _find_tilemap_and_waypoint_manager():
	# Look for tilemap in scene tree
	var scene_root = get_tree().current_scene
	tilemap = _find_node_by_type(scene_root, TileMap)
	
	# Look for waypoint manager
	waypoint_manager = _find_node_by_type(scene_root, WaypointManager)
	
	if not tilemap:
		print("Warning: No TileMap found in scene for NPCScheduler")
	if not waypoint_manager:
		print("Warning: No WaypointManager found in scene for NPCScheduler")

func _find_node_by_type(node: Node, type) -> Node:
	if is_instance_of(node, type):
		return node
	
	for child in node.get_children():
		var result = _find_node_by_type(child, type)
		if result:
			return result
	
	return null

func _move_towards_target(delta: float):
	if current_path.is_empty():
		# No path to follow, stop moving
		is_moving = false
		npc_body.velocity = Vector2.ZERO
		npc_body.move_and_slide()
		return
	
	# Get current target tile from path
	var target_tile_pos = current_path[path_index]
	var target_world_pos = tilemap.map_to_local(target_tile_pos) if tilemap else Vector2(target_tile_pos * tile_size)
	
	# Check if we've reached the current waypoint
	var distance_to_target = npc_body.global_position.distance_to(target_world_pos)
	if distance_to_target <= movement_epsilon:
		# Snap to exact tile center
		npc_body.global_position = target_world_pos
		current_tile = target_tile_pos
		
		# Stop velocity briefly to ensure clean tile center positioning
		npc_body.velocity = Vector2.ZERO
		npc_body.move_and_slide()
		
		# Move to next waypoint in path
		path_index += 1
		if path_index >= current_path.size():
			# Reached final destination
			_arrive_at_destination()
			return
		else:
			# Continue to next waypoint - reset axis commitment for new path segment
			committed_axis = ""
			target_tile_pos = current_path[path_index]
			target_world_pos = tilemap.map_to_local(target_tile_pos) if tilemap else Vector2(target_tile_pos * tile_size)
			print("NPC reached waypoint ", path_index-1, ", moving to next: ", target_tile_pos)
	
	# Calculate movement direction (tile-constrained)
	var direction = _calculate_tile_movement_direction(target_world_pos)
	
	# Debug output when NPC stops moving
	if direction == Vector2.ZERO and is_moving:
		print("NPC stopped moving! Distance to target: ", distance_to_target, 
			  ", Target: ", target_world_pos, ", Current: ", npc_body.global_position,
			  ", Committed axis: ", committed_axis)
	
	# Move with the calculated direction
	npc_body.velocity = direction * movement_speed
	npc_body.move_and_slide()

func _calculate_tile_movement_direction(target_world_pos: Vector2) -> Vector2:
	var current_pos = npc_body.global_position
	var to_target = target_world_pos - current_pos
	var direction = Vector2.ZERO
	
	# Calculate horizontal and vertical distances
	var horizontal_distance = abs(to_target.x)
	var vertical_distance = abs(to_target.y)
	
	# If we're not committed to an axis yet, choose one
	if committed_axis == "":
		if horizontal_distance > vertical_distance and horizontal_distance > axis_threshold:
			committed_axis = "horizontal"
			print("Committing to horizontal axis (h_dist=", horizontal_distance, ", v_dist=", vertical_distance, ")")
		elif vertical_distance >= horizontal_distance and vertical_distance > axis_threshold:
			committed_axis = "vertical"
			print("Committing to vertical axis (h_dist=", horizontal_distance, ", v_dist=", vertical_distance, ")")
	
	# If we are committed to an axis, only switch when that axis is basically complete
	elif committed_axis == "horizontal":
		if horizontal_distance <= axis_threshold and vertical_distance > axis_threshold:
			committed_axis = "vertical"
	elif committed_axis == "vertical":
		if vertical_distance <= axis_threshold and horizontal_distance > axis_threshold:
			committed_axis = "horizontal"

	
	# Move based on committed axis
	if committed_axis == "horizontal" and horizontal_distance >= axis_threshold:
		direction.x = sign(to_target.x)
		direction.y = 0
	elif committed_axis == "vertical" and vertical_distance >= axis_threshold:
		direction.x = 0
		direction.y = sign(to_target.y)
	
# If committed axis is too small to move but the other axis is still large, release commitment
	if committed_axis == "horizontal" and horizontal_distance < axis_threshold and vertical_distance >= axis_threshold:
		committed_axis = "vertical"
	elif committed_axis == "vertical" and vertical_distance < axis_threshold and horizontal_distance >= axis_threshold:
		committed_axis = "horizontal"

# Fully reset commitment when close on both axes
	if horizontal_distance < axis_threshold and vertical_distance < axis_threshold:
		if committed_axis != "":
			print("Resetting axis commitment - close to target (h_dist=", horizontal_distance, ", v_dist=", vertical_distance, ")")
		committed_axis = ""


# Calculate total distance to target
	var total_distance = to_target.length()

# Stop moving naturally when close enough
	if total_distance <= movement_epsilon:
		if committed_axis != "":
			print("Resetting axis commitment - close to target (total_distance=", total_distance, ")")
		committed_axis = ""
		return Vector2.ZERO

	return direction

func move_to_tile(target_tile: Vector2i):
	
	if not tilemap:
		print("Warning: Cannot move to tile - no tilemap reference")
		return
	
	self.target_tile = target_tile
	current_path = [target_tile]
	path_index = 0
	committed_axis = ""  # Reset axis commitment for new movement
	is_moving = true
	
	print("NPC moving to tile: ", target_tile)

func move_along_path(waypoint_path: Array):
	
	if waypoint_path.is_empty():
		print("Warning: Empty waypoint path provided")
		return
	
	# Expand highways in the path if waypoint manager is available
	if waypoint_manager:
		current_path = _expand_highway_waypoints(waypoint_path)
	else:
		current_path = waypoint_path.duplicate()
	
	path_index = 0
	committed_axis = ""  # Reset axis commitment for new path
	is_moving = true
	
	print("NPC following path with ", current_path.size(), " waypoints: ", current_path)

func _expand_highway_waypoints(waypoint_path: Array) -> Array[Vector2i]:

	var expanded_path: Array[Vector2i] = []
	
	for i in range(waypoint_path.size()):
		var current_waypoint = waypoint_path[i]
		expanded_path.append(current_waypoint)
		
		# Check if this waypoint is a highway tile and we have a next waypoint
		if i < waypoint_path.size() - 1 and waypoint_manager.is_highway_tile(current_waypoint):
			var next_waypoint = waypoint_path[i + 1]
			
			# Get highway expansion from waypoint manager
			var highway_segment = waypoint_manager._find_highway_path(current_waypoint, next_waypoint)
			
			# Add intermediate highway waypoints (skip first as it's already added)
			for j in range(1, highway_segment.size()):
				expanded_path.append(highway_segment[j])
	
	return expanded_path

func _arrive_at_destination():
	is_moving = false
	npc_body.velocity = Vector2.ZERO
	npc_body.move_and_slide()
	
	# Emit signals before clearing path state
	if current_path.size() > 0:
		path_completed.emit(current_path[-1])
	arrived_at_location.emit(current_target)
	
	# Clear path state
	current_path.clear()
	path_index = 0
	
	print("NPC arrived at destination: ", current_target)

func _on_time_changed(hour: int, minute: int):
	print("NPCScheduler received time change: ", hour, ":", minute, " (schedule entries: ", daily_schedule.size(), ")")
	_check_schedule_update(hour, minute)

func _check_schedule_update(hour: int, minute: int):
	print("Checking schedule update for time ", hour, ":", minute)
	if daily_schedule.is_empty():
		print("Schedule is empty, returning")
		return
	
	# Find the current schedule entry that should be active
	var target_index = -1
	var current_time_minutes = hour * 60 + minute
	
	print("Current time in minutes: ", current_time_minutes)
	
	# Find the latest schedule entry that has already passed
	for i in range(daily_schedule.size()):
		var entry = daily_schedule[i]
		var entry_time_minutes = entry.time_hour * 60 + entry.time_minute
		print("Schedule entry ", i, ": ", entry.time_hour, ":", entry.time_minute, " (", entry_time_minutes, " minutes)")
		
		if entry_time_minutes <= current_time_minutes:
			target_index = i
			print("Entry ", i, " has passed (", entry_time_minutes, " <= ", current_time_minutes, ")")
		else:
			print("Entry ", i, " hasn't passed yet (", entry_time_minutes, " > ", current_time_minutes, ")")
			break
	
	print("Target index: ", target_index, ", Current index: ", current_schedule_index)
	
	# If no entry has passed yet today, don't move (stay where they are)
	if target_index == -1:
		print("No schedule entry active yet, staying put")
		return  # No schedule entry active yet, so don't change current position
	
	# Update schedule if changed
	if target_index != current_schedule_index:
		print("Schedule index changed from ", current_schedule_index, " to ", target_index)
		var old_index = current_schedule_index
		current_schedule_index = target_index
		_move_to_scheduled_location()
		schedule_changed.emit(old_index, current_schedule_index)
	else:
		print("Schedule index unchanged: ", current_schedule_index)

func _update_schedule_for_current_time():
	_check_schedule_update(Global.current_hour, Global.current_minute)

func _move_to_scheduled_location():
	if daily_schedule.is_empty() or current_schedule_index >= daily_schedule.size():
		return
	
	var entry = daily_schedule[current_schedule_index]
	
	# Handle both Vector2 (old) and Vector2i (new tile-based) locations
	if entry.location is Vector2i:
		current_target = tilemap.map_to_local(entry.location) if tilemap else Vector2(entry.location * tile_size)
	else:
		current_target = entry.location  # Legacy Vector2 support
	
	# Override movement speed if specified in schedule entry
	if entry.has("speed") and entry.speed > 0:
		movement_speed = entry.speed
	
	# Check if this entry has a custom waypoint path
	if entry.has("waypoint_path") and entry.waypoint_path is Array and not entry.waypoint_path.is_empty():
		move_along_path(entry.waypoint_path)
	elif entry.location is Vector2i:
		move_to_tile(entry.location)
	else:
		# Legacy movement for Vector2 locations
		is_moving = true
		print("NPC moving to legacy location: ", current_target)
	
	print("NPC moving to: ", entry.location, " (", entry.time_hour, ":", entry.time_minute, ")")

func add_schedule_entry(hour: int, minute: int, location, speed: float = -1):
	var entry = {
		"time_hour": hour,
		"time_minute": minute,
		"location": location
	}
	
	if speed > 0:
		entry.speed = speed
	
	daily_schedule.append(entry)
	_sort_schedule()

func add_schedule_entry_with_path(hour: int, minute: int, waypoint_path: Array, speed: float = -1):
	var entry = {
		"time_hour": hour,
		"time_minute": minute,
		"location": waypoint_path[-1],  # Final destination is the last waypoint
		"route_type": "manual_path",
		"waypoint_path": waypoint_path
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

func get_current_scheduled_location() -> Vector2:
	if daily_schedule.is_empty() or current_schedule_index >= daily_schedule.size():
		return Vector2.ZERO
	return daily_schedule[current_schedule_index].location

func get_next_scheduled_time() -> Dictionary:
	if daily_schedule.is_empty():
		return {}
	
	var next_index = (current_schedule_index + 1) % daily_schedule.size()
	return daily_schedule[next_index]
