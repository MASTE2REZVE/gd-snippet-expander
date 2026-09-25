@tool
extends RefCounted


func get_data() -> Dictionary:
	return {
		"version": 2,
		"snippets": {
			"navigation_region_3d_setup": {
				"phrases": ["navigation region 3d", "nav region 3d", "bake navmesh 3d", "navmesh setup"],
				"code": """# NavigationRegion3D defines the walkable area for 3D AI.
#
# 1. Add a NavigationRegion3D node to your scene.
# 2. Move and resize it to cover your walkable area.
# 3. In the Inspector, click the Navigation Mesh slot -> New NavigationMesh.
# 4. Tune the NavigationMesh settings:
#    - Cell Size: 0.25 (lower = more accurate, slower bake)
#    - Cell Height: 0.25
#    - Agent Radius: match your widest character (0.5 for humans)
#    - Agent Height: character height (1.8 for humans)
#    - Agent Max Slope: 45 degrees
#    - Agent Max Climb: 0.3 (step height)
#    - Region Min Size: 2.0 (removes tiny isolated areas)
# 5. Click 'Bake Navigation Mesh' in the top toolbar.
# 6. Bake again whenever you move level geometry.
#
# For dynamic obstacles, use NavigationObstacle3D instead of rebaking.

extends NavigationRegion3D

@export var auto_bake_on_ready: bool = false

func _ready() -> void:
	if auto_bake_on_ready and Engine.is_editor_hint():
		bake_navigation_mesh()

func rebuild() -> void:
	if Engine.is_editor_hint():
		bake_navigation_mesh()

func get_walkable_distance(from: Vector3, to: Vector3) -> float:
	var map := get_navigation_map()
	if map.is_valid():
		var path := NavigationServer3D.map_get_path(map, from, to, true)
		return path.size()
	return 0.0
""",
				"params": ["auto_bake_on_ready"],
				"category": "navigation",
				"subcategory": "3d",
				"platforms": ["desktop", "mobile", "web"],
				"dimension": "3d",
				"difficulty": "intermediate",
				"param_info": {
					"auto_bake_on_ready": {
						"default": false,
						"range": [],
						"what": "Whether the navigation mesh bakes automatically in the editor.",
						"typical": "false for manual control / true for procedural scenes",
						"increase": "N/A",
						"decrease": "N/A"
					}
				},
				"details": {
					"what": "Sets up a NavigationRegion3D covering the walkable area of your level. AI characters path within this region.",
					"where": "Add as a child of the level root. Set the NavigationMesh in the Inspector, then bake from the toolbar.",
					"before": "Level geometry with floor collision (StaticBody3D or GridMap).",
					"after": "Every AI character needs a NavigationAgent3D child. See navigation_agent_3d snippet.",
					"why_optimized": "Baking is a one-time editor cost. Runtime pathfinding uses the baked mesh — very fast.",
					"mistakes": "Forgetting to rebake after moving geometry means AI paths through old walls. Rebake after every level edit.",
					"related": ["navigation_agent_3d", "navigation_obstacle_3d", "gridmap_navigation"]
				}
			},
			"navigation_obstacle_3d": {
				"phrases": ["navigation obstacle 3d", "nav obstacle 3d", "dynamic obstacle", "moving obstacle nav"],
				"code": """extends NavigationObstacle3D

@export var radius: float = 1.0
@export var avoidance_enabled: bool = true

func _ready() -> void:
	radius = radius
	avoidance_enabled = avoidance_enabled

func set_radius(value: float) -> void:
	radius = maxf(value, 0.1)

# USAGE
# Add a NavigationObstacle3D as a child of a moving object
# (barrel, vehicle, moving platform). AI characters with avoidance
# enabled will path around it.
#
# Notes:
# - Obstacle only affects avoidance, not the baked navmesh.
# - The obstacle itself doesn't move in the navmesh — agents avoid
#   it dynamically.
# - For permanently-blocking obstacles, edit the level and rebake.
# - Avoidance is per-agent; agents that don't have avoidance_enabled
#   ignore this obstacle.
""",
				"params": ["radius", "avoidance_enabled"],
				"category": "navigation",
				"subcategory": "3d",
				"platforms": ["desktop", "mobile", "web"],
				"dimension": "3d",
				"difficulty": "intermediate",
				"param_info": {
					"radius": {
						"default": 1.0,
						"range": [0.1, 10.0],
						"what": "Avoidance radius in meters. Should match the obstacle's physical size.",
						"typical": "0.5 small prop / 1.0 barrel / 3.0 vehicle",
						"increase": "Larger avoidance zone.",
						"decrease": "Smaller."
					}
				},
				"details": {
					"what": "Dynamic obstacle that agents path around. Use for barrels, moving platforms, and vehicles.",
					"where": "Add as a child of the moving obstacle. Set the radius to match the object's footprint.",
					"before": "Agents with avoidance_enabled set to true.",
					"after": "For obstacles that stay in place but change between states (open/closed door), just toggle the obstacle node's enabled property.",
					"why_optimized": "Obstacles add a small per-frame cost to avoidance calculations. Keep active obstacles under ~20 for good performance.",
					"mistakes": "Forgetting to match the obstacle radius to the actual object size makes AI walk through the visual mesh.",
					"related": ["navigation_agent_3d", "navigation_region_3d_setup", "gridmap_navigation"]
				}
			},
			"navigation_agent_avoidance_3d": {
				"phrases": ["navigation avoidance", "nav avoidance 3d", "avoid other ai", "agent avoidance"],
				"code": """extends CharacterBody3D

@export var speed: float = 4.0
@export var avoidance_radius: float = 1.0
@export var neighbor_distance: float = 10.0
@export var max_neighbors: int = 8
@export var time_horizon: float = 1.5
@export var acceleration: float = 8.0

@onready var _agent: NavigationAgent3D = $NavigationAgent3D

func _ready() -> void:
	_agent.radius = avoidance_radius
	_agent.neighbor_distance = neighbor_distance
	_agent.max_neighbors = max_neighbors
	_agent.time_horizon_agents = time_horizon
	_agent.avoidance_enabled = true
	_agent.velocity_computed.connect(_on_velocity_computed)

func _physics_process(delta: float) -> void:
	if _agent.is_navigation_finished():
		return
	var next := _agent.get_next_path_position()
	var desired := (next - global_position).normalized() * speed
	_agent.velocity = desired
	# velocity_computed will fire with the avoidance-adjusted velocity

func _on_velocity_computed(safe_velocity: Vector3) -> void:
	velocity = safe_velocity
	move_and_slide()

func set_target(target: Vector3) -> void:
	_agent.target_position = target
""",
				"params": ["speed", "avoidance_radius", "neighbor_distance", "max_neighbors", "time_horizon"],
				"category": "navigation",
				"subcategory": "3d",
				"platforms": ["desktop", "mobile", "web"],
				"dimension": "3d",
				"difficulty": "advanced",
				"param_info": {
					"avoidance_radius": {
						"default": 1.0,
						"range": [0.2, 5.0],
						"what": "How close another agent can get before avoidance kicks in.",
						"typical": "0.5 small / 1.0 standard / 2.5+ large",
						"increase": "Agents keep more distance.",
						"decrease": "Closer crowding."
					},
					"neighbor_distance": {
						"default": 10.0,
						"range": [2.0, 50.0],
						"what": "How far to look for other agents to avoid.",
						"typical": "5 tight / 10 standard / 25 wide",
						"increase": "Looks further.",
						"decrease": "Only nearby agents."
					},
					"time_horizon": {
						"default": 1.5,
						"range": [0.5, 5.0],
						"what": "How far into the future to predict collisions.",
						"typical": "0.8 reactive / 1.5 standard / 3.0 foresighted",
						"increase": "Avoids collisions earlier.",
						"decrease": "More reactive."
					}
				},
				"details": {
					"what": "Agent with avoidance — steers around other agents and obstacles while following its path. Uses velocity_computed signal for collision-free movement.",
					"where": "Attach to a CharacterBody3D with a NavigationAgent3D child. Requires a NavigationRegion3D in the scene.",
					"before": "NavigationRegion3D baked. NavigationAgent3D child named 'NavigationAgent3D'.",
					"after": "Use set_target() to give the agent a destination. It will path there while avoiding other agents.",
					"why_optimized": "Avoidance uses reciprocal velocity obstacles — a well-established algorithm. Cost scales with max_neighbors.",
					"mistakes": "Calling move_and_slide() outside the velocity_computed callback means avoidance velocities are ignored.",
					"related": ["navigation_agent_3d", "navigation_obstacle_3d", "enemy_chaser_3d"]
				}
			},
			"patrol_waypoints_3d": {
				"phrases": ["patrol waypoints 3d", "3d patrol", "waypoint ai 3d", "3d patrol path"],
				"code": """extends CharacterBody3D

@export var speed: float = 3.0
@export var waypoint_group: String = "patrol_points"
@export var arrive_distance: float = 1.0
@export var wait_at_waypoint: float = 0.5
@export var loop_mode: String = "cycle"

@onready var _agent: NavigationAgent3D = get_node_or_null("NavigationAgent3D")

var _waypoints: Array[Node3D] = []
var _index: int = 0
var _direction: int = 1
var _waiting: float = 0.0

func _ready() -> void:
	for node in get_tree().get_nodes_in_group(waypoint_group):
		if node is Node3D:
			_waypoints.append(node as Node3D)
	_waypoints.sort_custom(func(a, b): return a.name < b.name)
	if _agent == null:
		push_warning("Patrol3D needs a NavigationAgent3D child.")

func _physics_process(delta: float) -> void:
	if _waypoints.is_empty() or _agent == null:
		return
	if _waiting > 0.0:
		_waiting -= delta
		velocity = Vector3.ZERO
		move_and_slide()
		return
	var target := _waypoints[_index].global_position
	_agent.target_position = target
	if _agent.is_navigation_finished() or global_position.distance_to(target) < arrive_distance:
		_advance_waypoint()
		return
	var next := _agent.get_next_path_position()
	var direction := (next - global_position).normalized()
	velocity = direction * speed
	move_and_slide()

func _advance_waypoint() -> void:
	_waiting = wait_at_waypoint
	match loop_mode:
		"cycle":
			_index = (_index + 1) % _waypoints.size()
		"pingpong":
			_index += _direction
			if _index >= _waypoints.size():
				_index = _waypoints.size() - 2
				_direction = -1
			elif _index < 0:
				_index = 1
				_direction = 1
		"once":
			if _index < _waypoints.size() - 1:
				_index += 1
""",
				"params": ["speed", "waypoint_group", "arrive_distance", "wait_at_waypoint", "loop_mode"],
				"category": "navigation",
				"subcategory": "3d",
				"platforms": ["desktop", "mobile", "web"],
				"dimension": "3d",
				"difficulty": "intermediate",
				"param_info": {
					"speed": {
						"default": 3.0,
						"range": [0.5, 15.0],
						"what": "Patrol speed in meters per second.",
						"typical": "1.5 slow guard / 3.0 standard / 6.0+ fast",
						"increase": "Faster.",
						"decrease": "Slower."
					},
					"waypoint_group": {
						"default": "patrol_points",
						"range": [],
						"what": "Node group whose members are the patrol waypoints.",
						"typical": "patrol_points / enemy_patrol / guard_route",
						"increase": "N/A",
						"decrease": "N/A"
					},
					"wait_at_waypoint": {
						"default": 0.5,
						"range": [0.0, 5.0],
						"what": "Seconds to pause at each waypoint.",
						"typical": "0.0 continuous / 0.5 standard / 2.0+ deliberate",
						"increase": "Longer pause.",
						"decrease": "Shorter."
					},
					"loop_mode": {
						"default": "cycle",
						"range": [],
						"what": "How to move between waypoints.",
						"typical": "cycle loops / pingpong back-and-forth / once stops at end",
						"increase": "N/A",
						"decrease": "N/A"
					}
				},
				"details": {
					"what": "AI that patrols between waypoints using navigation. Waypoints are picked from a group so you just place empty Node3D markers in the level.",
					"where": "Attach to a CharacterBody3D with a NavigationAgent3D child. Add Marker3D nodes to the waypoint group.",
					"before": "NavigationRegion3D baked. Waypoints placed in the scene and added to a group.",
					"after": "Combine with detection_area or look_for_player to switch from patrol to chase.",
					"why_optimized": "Waypoints are cached at _ready. Path is computed by the NavigationAgent3D per target.",
					"mistakes": "Waypoints not added to the group means no patrol. Check the Node tab's Groups button.",
					"related": ["enemy_patrol", "chase_player", "navigation_agent_3d", "detection_area"]
				}
			},
			"navigation_path_refresh_3d": {
				"phrases": ["path refresh 3d", "repath 3d", "update nav path", "refresh path"],
				"code": """extends CharacterBody3D

@export var speed: float = 4.0
@export var repath_interval: float = 0.5
@export var target_move_threshold: float = 1.0

@onready var _agent: NavigationAgent3D = get_node_or_null("NavigationAgent3D")
var _target: Node3D = null
var _repath_timer: float = 0.0
var _last_target_position: Vector3 = Vector3.ZERO

func set_target(target: Node3D) -> void:
	_target = target
	_last_target_position = Vector3.ZERO
	_repath_timer = 0.0

func _physics_process(delta: float) -> void:
	if _agent == null or _target == null or not is_instance_valid(_target):
		return
	_repath_timer -= delta
	var target_moved: float = global_position.distance_to(_last_target_position)
	if _repath_timer <= 0.0 or target_moved > target_move_threshold:
		_agent.target_position = _target.global_position
		_last_target_position = _target.global_position
		_repath_timer = repath_interval
	if _agent.is_navigation_finished():
		return
	var next := _agent.get_next_path_position()
	var direction := (next - global_position).normalized()
	velocity = direction * speed
	move_and_slide()

func force_repath() -> void:
	_repath_timer = 0.0
""",
				"params": ["speed", "repath_interval", "target_move_threshold"],
				"category": "navigation",
				"subcategory": "3d",
				"platforms": ["desktop", "mobile", "web"],
				"dimension": "3d",
				"difficulty": "intermediate",
				"param_info": {
					"repath_interval": {
						"default": 0.5,
						"range": [0.1, 3.0],
						"what": "Minimum seconds between path recomputations.",
						"typical": "0.2 reactive / 0.5 standard / 1.0+ lazy",
						"increase": "Less frequent repathing.",
						"decrease": "More frequent."
					},
					"target_move_threshold": {
						"default": 1.0,
						"range": [0.1, 5.0],
						"what": "How far the target must move before a new path is computed.",
						"typical": "0.5 tight / 1.0 standard / 3.0 lazy",
						"increase": "More tolerance for target movement.",
						"decrease": "Repaths sooner."
					}
				},
				"details": {
					"what": "Recomputes navigation paths periodically and when the target moves. Prevents chasing stale paths.",
					"where": "Attach to a CharacterBody3D with a NavigationAgent3D child. Call set_target(player) to begin chasing.",
					"before": "NavigationRegion3D baked. Target is a Node3D in the scene.",
					"after": "For very fast-moving targets, reduce repath_interval. For static, increase it.",
					"why_optimized": "Only repaths when the target has moved significantly or the timer expires. Cached last position avoids redundant work.",
					"mistakes": "Repathing every frame is wasteful. The interval and threshold balance responsiveness against CPU cost.",
					"related": ["navigation_agent_3d", "chase_player", "navigation_agent_avoidance_3d"]
				}
			},
			"navigation_link_3d": {
				"phrases": ["navigation link 3d", "nav link 3d", "jump link 3d", "off mesh link"],
				"code": """# NavigationLink3D connects two points that aren't connected by
# walkable ground — jumps, ladders, teleports, or drops.
#
# 1. Add a NavigationLink3D node to your scene.
# 2. In the Inspector, set:
#    - Start Position: beginning of the link (local coords)
#    - End Position: end of the link (local coords)
#    - Bidirectional: enable for two-way travel
#    - Navigation Layers: which layer this link is on
# 3. Position the NavigationLink3D node in the world to place the link.
#
# For jump links:
#   - Start Position: (0, 0, 0)
#   - End Position: (5, -2, 0) — 5 meters forward, 2 meters down
#   - Bidirectional: false (jumping down only)
#
# For ladders:
#   - Start Position: (0, 0, 0)
#   - End Position: (0, 4, 0) — straight up 4 meters
#   - Bidirectional: true
#
# The AI agent automatically uses links if they're within the
# navigation mesh's connected component.

extends NavigationLink3D

@export var debug_visualize: bool = false

func _ready() -> void:
	if debug_visualize:
		_build_debug_line()

func _build_debug_line() -> void:
	var line := MeshInstance3D.new()
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	mesh.surface_add_vertex(start_position)
	mesh.surface_add_vertex(end_position)
	mesh.surface_end()
	line.mesh = mesh
	add_child(line)

func setup(start: Vector3, end_pos: Vector3, two_way: bool = false) -> void:
	start_position = start
	end_position = end_pos
	bidirectional = two_way
""",
				"params": ["debug_visualize"],
				"category": "navigation",
				"subcategory": "3d",
				"platforms": ["desktop", "mobile", "web"],
				"dimension": "3d",
				"difficulty": "advanced",
				"param_info": {
					"debug_visualize": {
						"default": false,
						"range": [],
						"what": "Whether to draw a debug line showing the link.",
						"typical": "true during level design / false for shipping",
						"increase": "N/A",
						"decrease": "N/A"
					}
				},
				"details": {
					"what": "Connects two navigation mesh areas that aren't connected by walkable ground. AI can jump, climb, or teleport across the gap.",
					"where": "Place as a child of the level. Position and rotate the link node to define start and end points.",
					"before": "NavigationRegion3D baked. Two disconnected walkable areas that AI should traverse between.",
					"after": "Combine with animation — play a jump animation when the agent enters the link and a landing animation when it exits.",
					"why_optimized": "Links are baked into the navigation map at bake time — zero runtime cost.",
					"mistakes": "Links too far from the navigation mesh are ignored. Start and end positions must be on or very near walkable areas.",
					"related": ["navigation_agent_3d", "navigation_region_3d_setup", "navigation_agent_avoidance_3d"]
				}
			}
		}
	}
