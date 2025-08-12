extends Resource
class_name Waypoint

enum WaypointType {
	LOCAL,          # Small area navigation
	HIGHWAY,        # Main travel routes  
	CHECKPOINT,     # Story-critical locations
	CONNECTOR       # Links between highway segments
}

@export var position: Vector2i
@export var type: WaypointType = WaypointType.LOCAL
@export var connected_waypoints: Array[Vector2i] = []
@export var area_name: String = ""
@export var waypoint_id: String = ""

func _init(pos: Vector2i = Vector2i.ZERO, waypoint_type: WaypointType = WaypointType.LOCAL, area: String = "", id: String = ""):
	position = pos
	type = waypoint_type
	area_name = area
	waypoint_id = id