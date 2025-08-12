extends Node
class_name WaypointManager

signal waypoint_system_ready()

var waypoints: Dictionary = {}  # waypoint_id -> Waypoint
var area_definitions: Dictionary = {}
var highway_routes: Array[Array] = []

# Performance caches
var path_cache: Dictionary = {}
var area_cache: Dictionary = {}  # position -> area_name

func _ready():
	_setup_default_highways()
	waypoint_system_ready.emit()

func _setup_default_highways():
	# Bridge highway - connects areas across the river/gap
	define_highway_route([
		Vector2i(15, 12),  # Bridge west entrance
		Vector2i(25, 12)   # Bridge east entrance
	], "bridge_highway")
	
	print("Bridge highway set up from tile (16, 12) to (24, 12)")

# Area Management
func define_area(area_name: String, definition: Dictionary):
	"""
	Define an area with waypoints
	definition = {
		"local": [Vector2i(x,y), ...],           # Local area waypoints
		"highway_entrance": Vector2i(x,y),        # Connection to highway system
		"checkpoints": [Vector2i(x,y), ...]      # Story-critical locations
	}
	"""
	area_definitions[area_name] = definition
	
	# Create waypoints for local area
	if definition.has("local"):
		for local_pos in definition.local:
			var waypoint = Waypoint.new(local_pos, Waypoint.WaypointType.LOCAL, area_name, area_name + "_local_" + str(local_pos))
			waypoints[waypoint.waypoint_id] = waypoint
			area_cache[local_pos] = area_name
	
	# Create highway entrance waypoint
	if definition.has("highway_entrance"):
		var entrance_pos = definition.highway_entrance
		var waypoint = Waypoint.new(entrance_pos, Waypoint.WaypointType.CONNECTOR, area_name, area_name + "_highway_entrance")
		waypoints[waypoint.waypoint_id] = waypoint
		area_cache[entrance_pos] = area_name
	
	# Create checkpoint waypoints
	if definition.has("checkpoints"):
		for checkpoint_pos in definition.checkpoints:
			var waypoint = Waypoint.new(checkpoint_pos, Waypoint.WaypointType.CHECKPOINT, area_name, area_name + "_checkpoint_" + str(checkpoint_pos))
			waypoints[waypoint.waypoint_id] = waypoint
			area_cache[checkpoint_pos] = area_name

# Highway Management
func define_highway_route(route: Array[Vector2i], route_name: String):
	"""
	Define a highway route connecting areas
	route = [Vector2i(x1,y1), Vector2i(x2,y2), ...] - ordered list of highway tiles
	"""
	highway_routes.append(route)
	
	# Create highway waypoints
	for i in range(route.size()):
		var pos = route[i]
		var waypoint = Waypoint.new(pos, Waypoint.WaypointType.HIGHWAY, "", route_name + "_" + str(i))
		
		# Connect to previous and next highway waypoints
		if i > 0:
			waypoint.connected_waypoints.append(route[i-1])
		if i < route.size() - 1:
			waypoint.connected_waypoints.append(route[i+1])
		
		waypoints[waypoint.waypoint_id] = waypoint

# Individual Waypoint Management
func add_waypoint(position: Vector2i, type: Waypoint.WaypointType, area_name: String = "", waypoint_id: String = "") -> String:
	"""Add a single waypoint and return its ID"""
	if waypoint_id.is_empty():
		waypoint_id = "waypoint_" + str(position.x) + "_" + str(position.y)
	
	var waypoint = Waypoint.new(position, type, area_name, waypoint_id)
	waypoints[waypoint_id] = waypoint
	
	if not area_name.is_empty():
		area_cache[position] = area_name
	
	return waypoint_id

func remove_waypoint(waypoint_id: String):
	"""Remove a waypoint by ID"""
	if waypoints.has(waypoint_id):
		var waypoint = waypoints[waypoint_id]
		area_cache.erase(waypoint.position)
		waypoints.erase(waypoint_id)

# Pathfinding
func plan_journey(start: Vector2i, end: Vector2i, route_type: String = "auto", mandatory_waypoints: Array[Vector2i] = [], forbidden_waypoints: Array[Vector2i] = []) -> Array[Vector2i]:
	"""
	Plan a journey between two points
	route_type: "auto", "stealth", "public", "specific"
	"""
	# Check cache first
	var cache_key = str(start) + "->" + str(end) + "_" + route_type
	if path_cache.has(cache_key) and mandatory_waypoints.is_empty() and forbidden_waypoints.is_empty():
		return path_cache[cache_key]
	
	var journey: Array[Vector2i] = []
	
	match route_type:
		"auto":
			journey = _plan_automatic_journey(start, end)
		"stealth":
			journey = _plan_stealth_journey(start, end, forbidden_waypoints)
		"public":
			journey = _plan_public_journey(start, end)
		"specific":
			journey = _plan_specific_journey(start, end, mandatory_waypoints)
		_:
			journey = _plan_automatic_journey(start, end)
	
	# Cache result if no special constraints
	if mandatory_waypoints.is_empty() and forbidden_waypoints.is_empty():
		path_cache[cache_key] = journey
	
	return journey

func _plan_automatic_journey(start: Vector2i, end: Vector2i) -> Array[Vector2i]:
	var start_area = _get_area(start)
	var end_area = _get_area(end)
	
	if start_area == end_area and not start_area.is_empty():
		# Same area: direct local movement
		return [start, end]
	else:
		# Different areas or unknown areas: use highway system if available
		var start_highway = _find_area_highway_entrance(start_area)
		var end_highway = _find_area_highway_entrance(end_area)
		
		if start_highway != Vector2i.ZERO and end_highway != Vector2i.ZERO:
			var journey: Array[Vector2i] = []
			journey.append_array(_find_local_path(start, start_highway))
			journey.append_array(_find_highway_path(start_highway, end_highway))
			journey.append_array(_find_local_path(end_highway, end))
			return journey
		else:
			# No highway system available, direct path
			return [start, end]

func _plan_stealth_journey(start: Vector2i, end: Vector2i, forbidden_waypoints: Array[Vector2i]) -> Array[Vector2i]:
	# Simple stealth: avoid highways and forbidden waypoints
	var local_waypoints = _get_local_waypoints_between(start, end)
	var valid_path: Array[Vector2i] = [start]
	
	for waypoint_pos in local_waypoints:
		if waypoint_pos not in forbidden_waypoints:
			var waypoint = _get_waypoint_at(waypoint_pos)
			if waypoint and waypoint.type != Waypoint.WaypointType.HIGHWAY:
				valid_path.append(waypoint_pos)
	
	valid_path.append(end)
	return valid_path

func _plan_public_journey(start: Vector2i, end: Vector2i) -> Array[Vector2i]:
	# Force use of highways when possible
	var start_highway = _find_nearest_highway(start)
	var end_highway = _find_nearest_highway(end)
	
	if start_highway != Vector2i.ZERO and end_highway != Vector2i.ZERO:
		var journey: Array[Vector2i] = []
		journey.append_array(_find_local_path(start, start_highway))
		journey.append_array(_find_highway_path(start_highway, end_highway))
		journey.append_array(_find_local_path(end_highway, end))
		return journey
	else:
		# No highways available, fallback to direct
		return [start, end]

func _plan_specific_journey(start: Vector2i, end: Vector2i, mandatory_waypoints: Array[Vector2i]) -> Array[Vector2i]:
	# Must pass through specific waypoints
	var journey: Array[Vector2i] = [start]
	
	var current_pos = start
	for waypoint_pos in mandatory_waypoints:
		var segment = _plan_automatic_journey(current_pos, waypoint_pos)
		if segment.size() > 1:
			journey.append_array(segment.slice(1))  # Skip duplicate start position
		current_pos = waypoint_pos
	
	# Final segment to destination
	var final_segment = _plan_automatic_journey(current_pos, end)
	if final_segment.size() > 1:
		journey.append_array(final_segment.slice(1))
	
	return journey

# Helper functions
func _get_area(position: Vector2i) -> String:
	if area_cache.has(position):
		return area_cache[position]
	
	# Find closest area by checking distance to area waypoints
	var closest_area = ""
	var closest_distance = INF
	
	for area_name in area_definitions.keys():
		var area_waypoints = _get_area_waypoints(area_name)
		for waypoint_pos in area_waypoints:
			var distance = _manhattan_distance(position, waypoint_pos)
			if distance < closest_distance:
				closest_distance = distance
				closest_area = area_name
	
	if not closest_area.is_empty():
		area_cache[position] = closest_area
	return closest_area

func _find_area_highway_entrance(area_name: String) -> Vector2i:
	if area_definitions.has(area_name) and area_definitions[area_name].has("highway_entrance"):
		return area_definitions[area_name].highway_entrance
	return Vector2i.ZERO

func _find_nearest_highway(position: Vector2i) -> Vector2i:
	var closest_highway = Vector2i.ZERO
	var closest_distance = INF
	
	for waypoint in waypoints.values():
		if waypoint.type == Waypoint.WaypointType.HIGHWAY:
			var distance = _manhattan_distance(position, waypoint.position)
			if distance < closest_distance:
				closest_distance = distance
				closest_highway = waypoint.position
	
	return closest_highway

func _find_local_path(start: Vector2i, end: Vector2i) -> Array[Vector2i]:
	# Simple direct path - can be enhanced later
	return [start, end]

func _find_highway_path(start_highway: Vector2i, end_highway: Vector2i) -> Array[Vector2i]:
	# Find path along highway routes
	for route in highway_routes:
		var start_index = route.find(start_highway)
		var end_index = route.find(end_highway)
		
		if start_index != -1 and end_index != -1:
			# Both waypoints are on this route
			var path: Array[Vector2i] = []
			var step = 1 if end_index > start_index else -1
			
			for i in range(start_index, end_index + step, step):
				path.append(route[i])
			
			return path
	
	# No direct route found, return direct path
	return [start_highway, end_highway]

func _get_area_waypoints(area_name: String) -> Array[Vector2i]:
	var area_waypoints: Array[Vector2i] = []
	
	if not area_definitions.has(area_name):
		return area_waypoints
	
	var definition = area_definitions[area_name]
	
	if definition.has("local"):
		area_waypoints.append_array(definition.local)
	if definition.has("highway_entrance"):
		area_waypoints.append(definition.highway_entrance)
	if definition.has("checkpoints"):
		area_waypoints.append_array(definition.checkpoints)
	
	return area_waypoints

func _get_local_waypoints_between(start: Vector2i, end: Vector2i) -> Array[Vector2i]:
	var local_waypoints: Array[Vector2i] = []
	
	for waypoint in waypoints.values():
		if waypoint.type == Waypoint.WaypointType.LOCAL:
			# Simple filter: only include waypoints roughly between start and end
			if _is_waypoint_between(waypoint.position, start, end):
				local_waypoints.append(waypoint.position)
	
	return local_waypoints

func _is_waypoint_between(waypoint_pos: Vector2i, start: Vector2i, end: Vector2i) -> bool:
	# Simple check if waypoint is roughly between start and end
	var min_x = min(start.x, end.x)
	var max_x = max(start.x, end.x)
	var min_y = min(start.y, end.y)
	var max_y = max(start.y, end.y)
	
	return waypoint_pos.x >= min_x and waypoint_pos.x <= max_x and waypoint_pos.y >= min_y and waypoint_pos.y <= max_y

func _get_waypoint_at(position: Vector2i) -> Waypoint:
	for waypoint in waypoints.values():
		if waypoint.position == position:
			return waypoint
	return null

func _manhattan_distance(a: Vector2i, b: Vector2i) -> int:
	return abs(a.x - b.x) + abs(a.y - b.y)

# Utility functions
func clear_cache():
	path_cache.clear()

func get_waypoints_in_area(area_name: String) -> Array[Waypoint]:
	var area_waypoints: Array[Waypoint] = []
	
	for waypoint in waypoints.values():
		if waypoint.area_name == area_name:
			area_waypoints.append(waypoint)
	
	return area_waypoints

func is_highway_tile(position: Vector2i) -> bool:
	var waypoint = _get_waypoint_at(position)
	return waypoint != null and waypoint.type == Waypoint.WaypointType.HIGHWAY

func get_all_areas() -> Array[String]:
	return area_definitions.keys()

func get_all_highway_routes() -> Array[Array]:
	return highway_routes.duplicate()

func print_waypoint_info():
	print("=== Waypoint System Info ===")
	print("Areas: ", area_definitions.keys())
	print("Total waypoints: ", waypoints.size())
	print("Highway routes: ", highway_routes.size())
	for route in highway_routes:
		print("  Route with ", route.size(), " waypoints")