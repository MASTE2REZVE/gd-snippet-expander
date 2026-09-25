@tool
extends RefCounted


func get_data() -> Dictionary:
	return {
		"version": 2,
		"snippets": {
			"debug_overlay_3d": {
				"phrases": ["debug overlay 3d", "3d debug hud", "3d info overlay", "debug hud 3d"],
				"code": """extends CanvasLayer

@onready var _label: RichTextLabel = $Panel/Label

@export var show_fps: bool = true
@export var show_position: bool = true
@export var show_velocity: bool = true
@export var show_ground_state: bool = true
@export var toggle_key: String = "ui_home"

var _target: CharacterBody3D = null

func _ready() -> void:
	layer = 128
	process_mode = Node.PROCESS_MODE_ALWAYS
	var players := get_tree().get_nodes_in_group("player")
	if not players.is_empty():
		_target = players[0] as CharacterBody3D

func _input(event: InputEvent) -> void:
	if event.is_action_pressed(toggle_key):
		visible = not visible

func _process(_delta: float) -> void:
	if not visible or _label == null:
		return
	var lines: Array = []
	if show_fps:
		lines.append("FPS: %d" % Engine.get_frames_per_second())
		lines.append("Draws: %d" % Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	if _target != null and is_instance_valid(_target):
		if show_position:
			lines.append("Pos: (%.2f, %.2f, %.2f)" % [
				_target.global_position.x,
				_target.global_position.y,
				_target.global_position.z
			])
		if show_velocity:
			lines.append("Vel: (%.2f, %.2f, %.2f)" % [
				_target.velocity.x,
				_target.velocity.y,
				_target.velocity.z
			])
			lines.append("Speed: %.2f" % _target.velocity.length())
		if show_ground_state:
			lines.append("Floor: %s" % str(_target.is_on_floor()))
			lines.append("Wall: %s" % str(_target.is_on_wall()))
	_label.text = "\\n".join(lines)
""",
				"params": ["show_fps", "show_position", "show_velocity", "show_ground_state", "toggle_key"],
				"category": "debug",
				"subcategory": "3d",
				"platforms": ["desktop"],
				"dimension": "ui",
				"difficulty": "beginner",
				"param_info": {
					"toggle_key": {
						"default": "ui_home",
						"range": [],
						"what": "Input action that toggles the overlay.",
						"typical": "ui_home / ui_end / custom debug_toggle",
						"increase": "N/A",
						"decrease": "N/A"
					}
				},
				"details": {
					"what": "HUD overlay showing FPS, draw calls, player position, velocity, and floor/wall state.",
					"where": "Attach to a CanvasLayer at layer 128 with a Panel → RichTextLabel child named 'Label'.",
					"before": "Player in group 'player'.",
					"after": "Add custom metrics — current state, health, AI target — via additional lines.",
					"why_optimized": "Only builds the string when visible. process_mode = ALWAYS keeps it running when paused.",
					"mistakes": "Forgetting process_mode = ALWAYS means the overlay freezes when the game pauses.",
					"related": ["debug_overlay_2d", "debug_gate", "debug_draw_collision_3d"]
				}
			},
			"debug_draw_collision_3d": {
				"phrases": ["debug draw collision 3d", "3d collision visualizer", "show collision 3d", "hitbox viewer 3d"],
				"code": """extends Node3D

@export var draw_color: Color = Color(0, 1, 0, 0.5)
@export var line_width: float = 2.0

func _ready() -> void:
	# Enable Godot's built-in collision shape debug drawing
	get_tree().debug_collisions_hint = true
	# Also enable navigation debug for navmesh visualization
	get_tree().debug_navigation_hint = true

func _exit_tree() -> void:
	get_tree().debug_collisions_hint = false
	get_tree().debug_navigation_hint = false

func toggle_collision_shapes() -> void:
	get_tree().debug_collisions_hint = not get_tree().debug_collisions_hint

func toggle_navigation() -> void:
	get_tree().debug_navigation_hint = not get_tree().debug_navigation_hint

# USAGE
# In the Godot editor, use Debug -> Visible Collision Shapes (toggle in
# the running game via the same menu) for a built-in solution that
# requires no code.
#
# For a scripted version (e.g. toggled from a dev menu), attach this
# script to any node and call the toggle methods.
#
# Custom 3D collision drawing:
#   - For custom shapes that Godot can't visualize, use ImmediateMesh
#     to draw wireframes.
#   - For complex debug visualization (rays, query results), use
#     MeshInstance3D with an ImmediateMesh and draw lines.
""",
				"params": ["draw_color", "line_width"],
				"category": "debug",
				"subcategory": "3d",
				"platforms": ["desktop"],
				"dimension": "3d",
				"difficulty": "beginner",
				"details": {
					"what": "Toggle Godot's built-in collision and navigation shape visualization from script.",
					"where": "Attach to a Debug node. Toggle from a dev menu or hotkey.",
					"before": "Physics bodies in the scene.",
					"after": "In the editor, Debug → Visible Collision Shapes works without this script. This is for runtime toggling.",
					"why_optimized": "Uses the engine's built-in debug rendering. Zero overhead when disabled.",
					"mistakes": "Leaving debug shapes enabled in a release build wastes performance. Disable before shipping.",
					"related": ["debug_overlay_3d", "debug_gate", "navigation_region_3d_setup"]
				}
			},
			"debug_ray_3d": {
				"phrases": ["debug ray 3d", "raycast visualizer", "3d ray debug", "ray debug draw"],
				"code": """extends MeshInstance3D

@export var max_rays: int = 16
@export var ray_color: Color = Color(1, 0.5, 0, 0.8)

var _mesh: ImmediateMesh = null

func _ready() -> void:
	_mesh = ImmediateMesh.new()
	mesh = _mesh
	top_level = true

func clear() -> void:
	if _mesh != null:
		_mesh.clear_surfaces()

func draw_ray(from: Vector3, to: Vector3, hit: bool = false) -> void:
	if _mesh == null:
		return
	var color := Color(1, 0.2, 0.2, 0.8) if hit else ray_color
	_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	_mesh.surface_set_color(color)
	_mesh.surface_add_vertex(from)
	_mesh.surface_add_vertex(to)
	_mesh.surface_end()

func draw_ray_query(from: Vector3, direction: Vector3, length: float) -> bool:
	var space := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(from, from + direction.normalized() * length)
	var result := space.intersect_ray(query)
	if result.is_empty():
		draw_ray(from, from + direction.normalized() * length, false)
		return false
	draw_ray(from, result.get("position", from), true)
	return true

func _process(_delta: float) -> void:
	clear()

# USAGE
# Attach to a MeshInstance3D. Call draw_ray(from, to) or
# draw_ray_query(from, direction, length) each frame.
#
# The script clears the mesh in _process, so rays are redrawn every
# frame. Add your ray calls after _process or in _physics_process.
#
# Common uses:
# - Visualize gun aiming rays
# - Debug AI vision raycasts
# - Show interaction raycast in third-person games
# - Trace physics query results
""",
				"params": ["max_rays", "ray_color"],
				"category": "debug",
				"subcategory": "3d",
				"platforms": ["desktop"],
				"dimension": "3d",
				"difficulty": "intermediate",
				"details": {
					"what": "Draw debug rays using ImmediateMesh. Green for misses, red for hits.",
					"where": "Attach to a MeshInstance3D. Set top_level = true so it draws in world space.",
					"before": "A MeshInstance3D node in the scene.",
					"after": "Wrap in a debug flag so rays only draw during development.",
					"why_optimized": "ImmediateMesh clears and rebuilds each frame — cheap for a handful of rays.",
					"mistakes": "Drawing thousands of rays per frame tanks performance. Keep under ~50 debug rays active.",
					"related": ["raycast_3d", "raycast_interact_3d", "debug_gate"]
				}
			},
			"debug_camera_3d": {
				"phrases": ["debug camera 3d", "free camera 3d", "spectator camera 3d", "noclip camera"],
				"code": """extends Camera3D

@export var speed: float = 10.0
@export var fast_multiplier: float = 4.0
@export var mouse_sensitivity: float = 0.003

var _yaw: float = 0.0
var _pitch: float = 0.0
var _active: bool = true

func _ready() -> void:
	current = true

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_F1:
		_active = not _active
		if _active:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		else:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _unhandled_input(event: InputEvent) -> void:
	if not _active:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_yaw -= event.relative.x * mouse_sensitivity
		_pitch = clampf(_pitch - event.relative.y * mouse_sensitivity, -1.5, 1.5)

func _process(delta: float) -> void:
	if not _active:
		return
	rotation = Vector3(_pitch, _yaw, 0)
	var input_dir := Input.get_vector("left", "right", "forward", "back")
	var vertical: float = Input.get_axis("crouch", "jump")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	direction.y += vertical
	var current_speed: float = speed * (fast_multiplier if Input.is_action_pressed("sprint") else 1.0)
	global_position += direction * current_speed * delta

# USAGE
# Attach to a Camera3D that's a direct child of the scene root.
# Press F1 to toggle mouse capture on/off.
#
# Controls:
#   WASD — move horizontally
#   Space / Ctrl — move up / down
#   Shift — speed boost
#   Mouse — look around
#   F1 — toggle active
#
# Useful for:
# - Inspecting a level without walking through it
# - Testing positions for spawn points and cutscenes
# - Debugging collision and geometry issues
""",
				"params": ["speed", "fast_multiplier", "mouse_sensitivity"],
				"category": "debug",
				"subcategory": "3d",
				"platforms": ["desktop"],
				"dimension": "3d",
				"difficulty": "intermediate",
				"required_actions": ["left", "right", "forward", "back", "jump", "crouch", "sprint"],
				"param_info": {
					"speed": {
						"default": 10.0,
						"range": [1.0, 100.0],
						"what": "Camera movement speed in meters per second.",
						"typical": "5 slow / 10 standard / 50 fast inspect",
						"increase": "Faster.",
						"decrease": "Slower."
					},
					"fast_multiplier": {
						"default": 4.0,
						"range": [2.0, 20.0],
						"what": "Speed multiplier when shift is held.",
						"typical": "3 standard / 5+ very fast",
						"increase": "Faster sprint.",
						"decrease": "Slower."
					}
				},
				"details": {
					"what": "Free-fly debug camera. WASD to move, mouse to look, Shift to sprint, Space/Ctrl for vertical.",
					"where": "Attach to a Camera3D that's a direct child of the scene root. Only works in debug builds.",
					"before": "Input actions left, right, forward, back, jump, crouch, sprint.",
					"after": "Use F1 to toggle off and return control to the player's camera.",
					"why_optimized": "Only runs when active. Zero cost when disabled.",
					"mistakes": "Shipping with F1 enabled lets players break the game. Gate behind a debug flag.",
					"related": ["debug_overlay_3d", "debug_gate", "first_person_camera_3d"]
				}
			},
			"debug_grid_3d": {
				"phrases": ["debug grid 3d", "3d grid", "grid overlay 3d", "show grid 3d"],
				"code": """extends MeshInstance3D

@export var grid_size: float = 100.0
@export var cell_size: float = 1.0
@export var grid_color: Color = Color(1, 1, 1, 0.15)
@export var major_color: Color = Color(1, 1, 0.5, 0.3)
@export var major_every: int = 10
@export var height_offset: float = 0.01

func _ready() -> void:
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	var cells: int = int(grid_size / cell_size)
	var half: int = cells / 2
	for i in range(-half, half + 1):
		var is_major: bool = i % major_every == 0
		mesh.surface_set_color(major_color if is_major else grid_color)
		var x: float = i * cell_size
		mesh.surface_add_vertex(Vector3(x, height_offset, -grid_size * 0.5))
		mesh.surface_add_vertex(Vector3(x, height_offset, grid_size * 0.5))
		var z: float = i * cell_size
		mesh.surface_add_vertex(Vector3(-grid_size * 0.5, height_offset, z))
		mesh.surface_add_vertex(Vector3(grid_size * 0.5, height_offset, z))
	mesh.surface_end()
	self.mesh = mesh
	# Material for the mesh
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.no_depth_test = false
	material_override = mat

# USAGE
# Attach to a MeshInstance3D. The grid is drawn on the XZ plane at the
# node's Y position.
#
# For level design, position at Y = 0 (ground level).
# For elevated grids, position the node higher.
#
# Ideal for:
# - Aligning objects to a grid during development
# - Visualizing world scale
# - Debugging placement at specific coordinates
#
# To toggle visibility, just set the node's .visible property.
""",
				"params": ["grid_size", "cell_size", "grid_color", "major_every", "height_offset"],
				"category": "debug",
				"subcategory": "3d",
				"platforms": ["desktop", "mobile"],
				"dimension": "3d",
				"difficulty": "beginner",
				"param_info": {
					"grid_size": {
						"default": 100.0,
						"range": [10.0, 1000.0],
						"what": "Total grid extent in meters.",
						"typical": "20 small room / 100 standard level / 500+ open world",
						"increase": "Bigger grid.",
						"decrease": "Smaller."
					},
					"cell_size": {
						"default": 1.0,
						"range": [0.1, 10.0],
						"what": "Size of each grid square in meters.",
						"typical": "0.5 fine detail / 1.0 standard / 5.0+ coarse",
						"increase": "Bigger cells.",
						"decrease": "Smaller."
					}
				},
				"details": {
					"what": "Debug grid overlay on the XZ plane. Align objects visually during development.",
					"where": "Attach to a MeshInstance3D at the scene root. Position at ground level.",
					"before": "None.",
					"after": "Toggle node visibility to show/hide the grid.",
					"why_optimized": "Single ImmediateMesh drawn once. Zero per-frame cost.",
					"mistakes": "Very dense grids (cell_size under 0.2) on a large area create too many lines. Keep total lines under 2000.",
					"related": ["debug_grid_overlay", "debug_overlay_3d", "gridmap_setup"]
				}
			}
		}
	}
