extends Node
class_name NPCScheduler

# Schedule entry: {time_hour: int, time_minute: int, location: Vector2, speed: float}
@export var daily_schedule: Array[Dictionary] = []
@export var movement_speed: float = 50.0
@export var tolerance_distance: float = 5.0  # How close to target before "arriving"

# Obstacle avoidance settings
@export var obstacle_detection_distance: float = 10.0  # How far ahead to check for obstacles
@export var stuck_time_threshold: float = 5.0  # How long stuck before trying alternate route
@export var max_detour_attempts: int = 3  # How many detour attempts before giving up
@export var give_up_threshold: float = 10.0  # How long to try before giving up completely
@export var smart_mode_duration: float = 5.0  # How long to be smart after getting stuck
@export var debug_draw: bool = false  # Draw debug lines for obstacle detection

enum MovementPriority {
	HORIZONTAL_FIRST,  # Move horizontally first, then vertically
	VERTICAL_FIRST,    # Move vertically first, then horizontally
	SHORTEST_FIRST     # Move along the shortest axis first
}
@export var movement_priority: MovementPriority = MovementPriority.SHORTEST_FIRST

var npc_body: CharacterBody2D
var current_target: Vector2
var is_moving: bool = false
var current_schedule_index: int = 0

# Obstacle avoidance state
var is_stuck: bool = false
var stuck_timer: float = 0.0
var last_position: Vector2
var position_check_timer: float = 0.0
var detour_attempts: int = 0
var is_detouring: bool = false
var detour_target: Vector2

# Smart/Dumb mode cycling
var is_smart_mode: bool = false
var smart_mode_timer: float = 0.0
var smart_override_direction: Vector2 = Vector2.ZERO
var smart_override_timer: float = 0.0
var smart_override_duration: float = 1.0  # How long to stick with alternate direction

signal arrived_at_location(location: Vector2)
signal schedule_changed(old_index: int, new_index: int)
signal gave_up_on_destination(target: Vector2, reason: String)
signal started_detour(original_target: Vector2, detour_target: Vector2)

func _ready():
	# Get the parent CharacterBody2D
	npc_body = get_parent() as CharacterBody2D
	if not npc_body:
		push_error("NPCScheduler must be child of CharacterBody2D")
		return
	
	# Connect to Global time system
	Global.time_changed.connect(_on_time_changed)
	
	# Set initial position based on current time
	_update_schedule_for_current_time()

func _physics_process(delta: float):
	if is_moving and npc_body:
		_move_towards_target(delta)

func _move_towards_target(delta: float):
	var effective_target = detour_target if is_detouring else current_target
	var distance_to_target = npc_body.global_position.distance_to(effective_target)
	
	# Check if we've reached our target (main or detour)
	if distance_to_target <= tolerance_distance:
		if is_detouring:
			# Finished detour, go back to main target
			_finish_detour()
		else:
			# Arrived at final destination
			_arrive_at_destination()
		return
	
	# Check if we're stuck (but not in smart mode - smart NPCs don't get "stuck")
	if not is_smart_mode:
		_update_stuck_detection(delta)
		
		# Update stuck timer
		if is_stuck:
			stuck_timer += delta
	
	# Handle smart mode timer and override direction timer
	if is_smart_mode:
		smart_mode_timer += delta
		
		# Update override direction timer
		if smart_override_direction != Vector2.ZERO:
			smart_override_timer += delta
			if smart_override_timer >= smart_override_duration:
				smart_override_direction = Vector2.ZERO
				smart_override_timer = 0.0
		
		# Switch back to dumb mode after smart duration
		if smart_mode_timer >= smart_mode_duration:
			_switch_to_dumb_mode()
	
	# If we've been stuck too long in current session, give up
	if is_stuck and stuck_timer > give_up_threshold:
		_give_up("stuck_too_long")
		return
	
	# Calculate movement direction
	var direction = _calculate_movement_direction(effective_target)
	
	# If stuck long enough, try a detour (this triggers smart mode)
	if is_stuck and stuck_timer > stuck_time_threshold and detour_attempts < max_detour_attempts:
		_attempt_detour()
		return
	
	# Smart mode: check for obstacles ahead and avoid them immediately
	if is_smart_mode:
		# If we have an override direction active, use that instead
		if smart_override_direction != Vector2.ZERO:
			direction = smart_override_direction
			print("Smart mode: using override direction=", direction, " pos=", npc_body.global_position)
		elif direction != Vector2.ZERO:
			var obstacle_detected = _check_obstacle_ahead(direction)
			print("Smart mode: dir=", direction, " obstacle=", obstacle_detected, " pos=", npc_body.global_position)
			if obstacle_detected:
				print("Smart NPC detected obstacle ahead!")
				# In smart mode, immediately find alternate direction when obstacle detected
				var alternate_direction = _find_alternate_direction()
				if alternate_direction != Vector2.ZERO:
					direction = alternate_direction
					smart_override_direction = alternate_direction
					smart_override_timer = 0.0
					print("Smart NPC avoiding obstacle, new direction: ", direction, " (locked for ", smart_override_duration, "s)")
				else:
					# No alternate direction found, maybe try a detour point
					print("Smart NPC couldn't find alternate direction, trying detour")
		else:
			print("Smart NPC has no direction - might be at destination")
	
	# Move with the calculated direction
	npc_body.velocity = direction * movement_speed
	npc_body.move_and_slide()

func _calculate_movement_direction(target: Vector2) -> Vector2:
	var current_pos = npc_body.global_position
	var direction = Vector2.ZERO
	
	# Calculate horizontal and vertical distances
	var horizontal_distance = abs(target.x - current_pos.x)
	var vertical_distance = abs(target.y - current_pos.y)
	
	match movement_priority:
		MovementPriority.HORIZONTAL_FIRST:
			if horizontal_distance > tolerance_distance:
				direction.x = sign(target.x - current_pos.x)
			elif vertical_distance > tolerance_distance:
				direction.y = sign(target.y - current_pos.y)
		
		MovementPriority.VERTICAL_FIRST:
			if vertical_distance > tolerance_distance:
				direction.y = sign(target.y - current_pos.y)
			elif horizontal_distance > tolerance_distance:
				direction.x = sign(target.x - current_pos.x)
		
		MovementPriority.SHORTEST_FIRST:
			if horizontal_distance > tolerance_distance and vertical_distance > tolerance_distance:
				if horizontal_distance < vertical_distance:
					direction.x = sign(target.x - current_pos.x)
				else:
					direction.y = sign(target.y - current_pos.y)
			elif horizontal_distance > tolerance_distance:
				direction.x = sign(target.x - current_pos.x)
			elif vertical_distance > tolerance_distance:
				direction.y = sign(target.y - current_pos.y)
	
	return direction

func _check_obstacle_ahead(direction: Vector2) -> bool:
	if direction == Vector2.ZERO:
		return false
	
	var space_state = npc_body.get_world_2d().direct_space_state
	var from = npc_body.global_position
	var effective_target = detour_target if is_detouring else current_target
	
	# Smart mode: always use full obstacle detection distance for immediate obstacle avoidance
	var ray_distance = obstacle_detection_distance
	if not is_smart_mode:
		# Dumb mode: limit raycast to not go beyond target (prevents detecting destination as obstacle)
		var distance_to_target = from.distance_to(effective_target)
		ray_distance = min(obstacle_detection_distance, distance_to_target - tolerance_distance)
		
		# If we're very close to target in dumb mode, don't check for obstacles
		if ray_distance <= 0:
			return false
	
	var to = from + direction * ray_distance
	
	# Cast a ray to detect obstacles
	var query = PhysicsRayQueryParameters2D.create(from, to)
	query.exclude = [npc_body]  # Don't detect self
	
	var result = space_state.intersect_ray(query)
	return result != {}

func _update_stuck_detection(delta: float):
	position_check_timer += delta
	
	# Check position every 0.5 seconds
	if position_check_timer >= 0.5:
		var current_pos = npc_body.global_position
		var effective_target = detour_target if is_detouring else current_target
		var distance_to_target = current_pos.distance_to(effective_target)
		
		# Don't check for stuck if we're close to our destination - we're supposed to stop there!
		if distance_to_target <= tolerance_distance * 2:  # Give some buffer
			_reset_stuck_state()
			last_position = current_pos
			position_check_timer = 0.0
			return
		
		var distance_moved = current_pos.distance_to(last_position)
		
		# If barely moved, we might be stuck (more forgiving threshold)
		if distance_moved < 1.0:  # Less than 1 pixel moved - really stuck!
			if not is_stuck:
				_start_stuck_timer()
		else:
			_reset_stuck_state()
		
		last_position = current_pos
		position_check_timer = 0.0

func _start_stuck_timer():
	is_stuck = true
	stuck_timer = 0.0
	print("NPC getting stuck, starting timer")

func _reset_stuck_state():
	is_stuck = false
	stuck_timer = 0.0

func _attempt_detour():
	detour_attempts += 1
	print("NPC attempting detour #", detour_attempts, " - entering smart mode!")
	
	# Enter smart mode when attempting detour
	_switch_to_smart_mode()
	
	# Try to find a detour point
	var detour = _find_detour_point()
	if detour != Vector2.ZERO:
		is_detouring = true
		detour_target = detour
		started_detour.emit(current_target, detour_target)
		_reset_stuck_state()
	else:
		# No viable detour found
		if detour_attempts >= max_detour_attempts:
			_give_up("no_viable_detour")

func _find_detour_point() -> Vector2:
	var current_pos = npc_body.global_position
	var target = current_target
	
	# Try detour points in orthogonal directions
	var detour_distance = 15.0
	var potential_detours = [
		current_pos + Vector2(detour_distance, 0),   # Right
		current_pos + Vector2(-detour_distance, 0),  # Left
		current_pos + Vector2(0, detour_distance),   # Down
		current_pos + Vector2(0, -detour_distance)   # Up
	]
	
	# Test each potential detour point
	for detour_point in potential_detours:
		if not _check_obstacle_ahead((detour_point - current_pos).normalized()):
			# Path to detour is clear, choose this one
			return detour_point
	
	return Vector2.ZERO  # No clear detour found

func _finish_detour():
	is_detouring = false
	detour_target = Vector2.ZERO
	print("NPC finished detour, returning to main target")

func _arrive_at_destination():
	is_moving = false
	_reset_all_avoidance_state()
	arrived_at_location.emit(current_target)
	print("NPC arrived at destination: ", current_target)

func _give_up(reason: String):
	is_moving = false
	_reset_all_avoidance_state()
	gave_up_on_destination.emit(current_target, reason)
	print("NPC gave up on destination: ", current_target, " (", reason, ")")

func _reset_all_avoidance_state():
	is_stuck = false
	stuck_timer = 0.0
	detour_attempts = 0
	is_detouring = false
	detour_target = Vector2.ZERO
	is_smart_mode = false
	smart_mode_timer = 0.0
	smart_override_direction = Vector2.ZERO
	smart_override_timer = 0.0

func _switch_to_smart_mode():
	is_smart_mode = true
	smart_mode_timer = 0.0
	print("NPC entering smart mode for ", smart_mode_duration, " seconds")

func _switch_to_dumb_mode():
	is_smart_mode = false
	smart_mode_timer = 0.0
	smart_override_direction = Vector2.ZERO
	smart_override_timer = 0.0
	print("NPC returning to dumb mode")

func _find_alternate_direction() -> Vector2:
	var current_pos = npc_body.global_position
	var effective_target = detour_target if is_detouring else current_target
	
	# Calculate which directions would help us get closer to target
	var to_target = effective_target - current_pos
	var beneficial_directions = []
	var other_directions = []
	
	# All cardinal directions
	var all_directions = [
		Vector2(1, 0),   # Right
		Vector2(-1, 0),  # Left  
		Vector2(0, 1),   # Down
		Vector2(0, -1)   # Up
	]
	
	# Separate directions that move toward target vs away from target
	for direction in all_directions:
		if direction.dot(to_target) > 0:  # Moving toward target
			beneficial_directions.append(direction)
		else:
			other_directions.append(direction)
	
	# Try beneficial directions first (toward target)
	for test_direction in beneficial_directions:
		if not _check_obstacle_ahead(test_direction):
			print("Smart NPC found beneficial direction: ", test_direction)
			return test_direction
	
	# If no beneficial directions work, try other directions
	for test_direction in other_directions:
		if not _check_obstacle_ahead(test_direction):
			print("Smart NPC found alternate direction: ", test_direction)
			return test_direction
	
	print("Smart NPC found no clear directions!")
	return Vector2.ZERO  # No clear direction found

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
	current_target = entry.location
	
	# Override movement speed if specified in schedule entry
	if entry.has("speed"):
		movement_speed = entry.speed
	
	is_moving = true
	print("NPC moving to: ", current_target, " (", entry.time_hour, ":", entry.time_minute, ")")

func add_schedule_entry(hour: int, minute: int, location: Vector2, speed: float = -1):
	var entry = {
		"time_hour": hour,
		"time_minute": minute,
		"location": location
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