@tool
extends RefCounted


func get_data() -> Dictionary:
	return {
		"version": 2,
		"snippets": {
			"debug_overlay_2d": {
				"phrases": ["debug overlay 2d", "2d debug hud", "info overlay", "debug hud 2d"],
				"code": """extends CanvasLayer

@onready var _label: RichTextLabel = $Panel/Label

@export var show_fps: bool = true
@export var show_position: bool = true
@export var show_velocity: bool = true
@export var show_state: bool = true
@export var toggle_key: String = "ui_home"

var _target: CharacterBody2D = null

func _ready() -> void:
	layer = 128
	process_mode = Node.PROCESS_MODE_ALWAYS
	var players := get_tree().get_nodes_in_group("player")
	if not players.is_empty():
		_target = players[0] as CharacterBody2D

func _input(event: InputEvent) -> void:
	if event.is_action_pressed(toggle_key):
		visible = not visible

func _process(_delta: float) -> void:
	if not visible or _label == null:
		return
	var lines: Array = []
	if show_fps:
		lines.append("FPS: %d" % Engine.get_frames_per_second())
	if _target != null and is_instance_valid(_target):
		if show_position:
			lines.append("Pos: (%.0f, %.0f)" % [_target.global_position.x, _target.global_position.y])
		if show_velocity:
			lines.append("Vel: (%.0f, %.0f)" % [_target.velocity.x, _target.velocity.y])
		if show_state:
			lines.append("Floor: %s" % str(_target.is_on_floor()))
			lines.append("Wall: %s" % str(_target.is_on_wall()))
	_label.text = "\\n".join(lines)
""",
				"params": ["show_fps", "show_position", "show_velocity", "show_state", "toggle_key"],
				"category": "debug",
				"subcategory": "overlay",
				"platforms": ["desktop"],
				"dimension": "ui",
				"difficulty": "beginner",
				"param_info": {
					"toggle_key": {
						"default": "ui_home",
						"range": [],
						"what": "Input action that toggles the overlay visibility.",
						"typical": "ui_home / ui_end / or a custom debug_toggle action",
						"increase": "N/A",
						"decrease": "N/A"
					},
					"show_velocity": {
						"default": true,
						"range": [],
						"what": "Show player velocity in the overlay.",
						"typical": "true for platformers / false for static scenes",
						"increase": "N/A",
						"decrease": "N/A"
					}
				},
				"details": {
					"what": "Small overlay showing FPS, player position, velocity, and floor/wall state. Press the toggle key to show or hide.",
					"where": "Attach to a CanvasLayer at layer 128 with a Panel → RichTextLabel child named 'Label'.",
					"before": "Player in group 'player'. A toggle input action bound to a key.",
					"after": "For a shipping build, wrap in a debug flag. See debug_gate snippet for how.",
					"why_optimized": "Only updates the label when visible. Strings rebuild once per frame — negligible.",
					"mistakes": "Forgetting process_mode = ALWAYS means the overlay freezes when the game pauses.",
					"related": ["debug_overlay", "debug_gate", "debug_draw_collision"]
				}
			},
			"debug_draw_collision": {
				"phrases": ["debug draw collision", "collision visualizer 2d", "show collision shapes", "hitbox viewer"],
				"code": """extends Node2D

@export var draw_collision: bool = true
@export var draw_areas: bool = true
@export var draw_color: Color = Color(0, 1, 0, 0.5)
@export var area_color: Color = Color(1, 0.5, 0, 0.5)
@export var line_width: float = 1.0

func _draw() -> void:
	if draw_collision:
		_draw_all_shapes("CollisionShape2D", draw_color)
	if draw_areas:
		_draw_all_shapes("CollisionShape2D", area_color, true)

func _process(_delta: float) -> void:
	queue_redraw()

func _draw_all_shapes(class_filter: String, color: Color, only_areas: bool = false) -> void:
	for node in get_tree().get_nodes_in_group("debug_collision"):
		if not (node is CollisionShape2D):
			continue
		var shape_node := node as CollisionShape2D
		if only_areas and not _parent_is_area(shape_node):
			continue
		if not only_areas and _parent_is_area(shape_node):
			continue
		_draw_shape(shape_node, color)

func _draw_shape(shape_node: CollisionShape2D, color: Color) -> void:
	var shape := shape_node.shape
	if shape == null:
		return
	var offset := shape_node.global_position - global_position
	var rotation_amount := shape_node.global_rotation
	match shape.get_class():
		"RectangleShape2D":
			var rect := shape as RectangleShape2D
			var size := rect.size
			var points := PackedVector2Array([
				offset + Vector2(-size.x, -size.y).rotated(rotation_amount) * 0.5,
				offset + Vector2(size.x, -size.y).rotated(rotation_amount) * 0.5,
				offset + Vector2(size.x, size.y).rotated(rotation_amount) * 0.5,
				offset + Vector2(-size.x, size.y).rotated(rotation_amount) * 0.5,
				offset + Vector2(-size.x, -size.y).rotated(rotation_amount) * 0.5,
			])
			draw_polyline(points, color, line_width)
		"CircleShape2D":
			var circle := shape as CircleShape2D
			draw_arc(offset, circle.radius, 0, TAU, 32, color, line_width)
		"CapsuleShape2D":
			var capsule := shape as CapsuleShape2D
			draw_arc(offset + Vector2(0, -capsule.height * 0.5 + capsule.radius), capsule.radius, 0, TAU, 16, color, line_width)
			draw_arc(offset + Vector2(0, capsule.height * 0.5 - capsule.radius), capsule.radius, 0, TAU, 16, color, line_width)

func _parent_is_area(shape_node: CollisionShape2D) -> bool:
	var parent := shape_node.get_parent()
	return parent is Area2D

# Add collision shapes to the 'debug_collision' group in the Inspector.
# Enable Debug -> Visible Collision Shapes in the editor for a
# built-in version that works without this script.
""",
				"params": ["draw_collision", "draw_areas", "draw_color", "area_color", "line_width"],
				"category": "debug",
				"subcategory": "visualization",
				"platforms": ["desktop"],
				"dimension": "2d",
				"difficulty": "intermediate",
				"param_info": {
					"line_width": {
						"default": 1.0,
						"range": [0.5, 5.0],
						"what": "Thickness of the debug outlines.",
						"typical": "1 subtle / 2 clear / 3+ chunky",
						"increase": "Thicker outlines.",
						"decrease": "Thinner."
					},
					"draw_areas": {
						"default": true,
						"range": [],
						"what": "Draw collision shapes on Area2D nodes.",
						"typical": "true for full debug / false to hide trigger zones",
						"increase": "N/A",
						"decrease": "N/A"
					}
				},
				"details": {
					"what": "Custom collision shape drawing for tagged nodes. Different colors for solid bodies (green) vs trigger areas (orange).",
					"where": "Attach to a Node2D at the scene root. Add CollisionShape2D nodes to the group 'debug_collision'.",
					"before": "CollisionShape2D nodes in group 'debug_collision' via the Node panel's Groups tab.",
					"after": "For a simpler version, use Godot's built-in Debug → Visible Collision Shapes. This custom version adds color distinction.",
					"why_optimized": "Only redraws when needed. Group iteration is fast on small scenes.",
					"mistakes": "Forgetting to add nodes to the group means nothing draws. Check the Groups tab in the Inspector.",
					"related": ["debug_overlay_2d", "debug_grid_overlay", "debug_gate"]
				}
			},
			"debug_grid_overlay": {
				"phrases": ["grid overlay", "debug grid", "tile grid", "show tile grid"],
				"code": """extends Node2D

@export var tile_size: int = 16
@export var grid_color: Color = Color(1, 1, 1, 0.15)
@export var major_line_every: int = 8
@export var major_color: Color = Color(1, 1, 0.5, 0.3)
@export var line_width: float = 1.0
@export var camera_path: NodePath

@onready var _camera: Camera2D = get_node_or_null(camera_path)

func _draw() -> void:
	var viewport_size := get_viewport_rect().size
	var zoom := Vector2.ONE
	var top_left := Vector2.ZERO
	if _camera != null:
		zoom = _camera.zoom
		top_left = _camera.global_position - viewport_size * 0.5 / zoom
	var view_size := viewport_size / zoom
	var start_x := int(floor(top_left.x / tile_size)) * tile_size
	var start_y := int(floor(top_left.y / tile_size)) * tile_size
	var end_x := int(ceil((top_left.x + view_size.x) / tile_size)) * tile_size
	var end_y := int(ceil((top_left.y + view_size.y) / tile_size)) * tile_size
	for x in range(start_x, end_x + tile_size, tile_size):
		var is_major := (x / tile_size) % major_line_every == 0
		var color := major_color if is_major else grid_color
		draw_line(Vector2(x, start_y), Vector2(x, end_y), color, line_width)
	for y in range(start_y, end_y + tile_size, tile_size):
		var is_major := (y / tile_size) % major_line_every == 0
		var color := major_color if is_major else grid_color
		draw_line(Vector2(start_x, y), Vector2(end_x, y), color, line_width)

func _process(_delta: float) -> void:
	queue_redraw()
""",
				"params": ["tile_size", "grid_color", "major_line_every", "major_color", "camera_path"],
				"category": "debug",
				"subcategory": "visualization",
				"platforms": ["desktop"],
				"dimension": "2d",
				"difficulty": "beginner",
				"param_info": {
					"tile_size": {
						"default": 16,
						"range": [8, 128],
						"what": "Grid cell size in pixels. Match your TileMap cell size.",
						"typical": "16 classic / 32 modern / 48+ chunky",
						"increase": "Bigger cells.",
						"decrease": "Smaller."
					},
					"major_line_every": {
						"default": 8,
						"range": [2, 32],
						"what": "Every Nth line uses the major color for easier counting.",
						"typical": "4 dense / 8 standard / 16 sparse",
						"increase": "Fewer major lines.",
						"decrease": "More."
					}
				},
				"details": {
					"what": "Draws a grid aligned with your TileMap. Useful for placing objects at exact tile coordinates.",
					"where": "Attach to a Node2D above the world but below the UI. Set camera_path to your active camera so the grid follows the view.",
					"before": "TileMapLayer in the scene. Camera2D path set in the Inspector.",
					"after": "Toggle visibility from a debug overlay. See debug_gate.",
					"why_optimized": "Only draws lines within the visible viewport. Number of draw calls scales with screen size, not world size.",
					"mistakes": "Drawing the whole world's grid tanks performance on large maps. Always clip to the viewport.",
					"related": ["tilemap_layer_setup", "debug_overlay_2d", "debug_gate"]
				}
			},
			"debug_spawn_gizmos": {
				"phrases": ["spawn gizmos", "spawn point markers", "debug spawn", "player spawn marker"],
				"code": """@tool
extends Node2D

@export var gizmo_color: Color = Color(1, 0.3, 0.5, 0.8)
@export var gizmo_size: float = 16.0
@export var label_text: String = "SPAWN"
@export var draw_label: bool = true

func _draw() -> void:
	var half := gizmo_size * 0.5
	draw_line(Vector2(-half, 0), Vector2(half, 0), gizmo_color, 2.0)
	draw_line(Vector2(0, -half), Vector2(0, half), gizmo_color, 2.0)
	draw_arc(Vector2.ZERO, half * 0.7, 0, TAU, 24, gizmo_color, 1.5)
	if draw_label:
		var font := ThemeDB.fallback_font
		var font_size := 10
		var text_size := font.get_string_size(label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
		draw_string(font, Vector2(-text_size.x * 0.5, -half - 4.0), label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, gizmo_color)

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		queue_redraw()
""",
				"params": ["gizmo_color", "gizmo_size", "label_text", "draw_label"],
				"category": "debug",
				"subcategory": "visualization",
				"platforms": ["desktop"],
				"dimension": "2d",
				"difficulty": "beginner",
				"param_info": {
					"gizmo_color": {
						"default": [1, 0.3, 0.5, 0.8],
						"range": [],
						"what": "Color of the spawn gizmo.",
						"typical": "pink for player / yellow for enemies / cyan for items",
						"increase": "N/A",
						"decrease": "N/A"
					},
					"gizmo_size": {
						"default": 16.0,
						"range": [8.0, 64.0],
						"what": "Size of the gizmo graphic in pixels.",
						"typical": "16 small / 32 medium / 64 large",
						"increase": "Bigger gizmo.",
						"decrease": "Smaller."
					},
					"label_text": {
						"default": "SPAWN",
						"range": [],
						"what": "Text label shown below the gizmo.",
						"typical": "SPAWN / PLAYER / RESPAWN / BOSS",
						"increase": "N/A",
						"decrease": "N/A"
					}
				},
				"details": {
					"what": "Editor-visible gizmo marker for spawn points. Draws a crosshair and label that only show in the editor, not at runtime.",
					"where": "Attach to a Node2D positioned at the spawn point. Visible in the editor's 2D viewport. Does not render during gameplay.",
					"before": "None.",
					"after": "Use the same node as your spawn point — read its global_position in code to spawn the player.",
					"why_optimized": "Only redraws in the editor. Zero runtime cost.",
					"mistakes": "The @tool directive is required — without it, the gizmo doesn't draw in the editor.",
					"related": ["respawn", "checkpoint_2d", "debug_overlay_2d"]
				}
			},
			"debug_gate": {
				"phrases": ["debug gate", "disable debug build", "debug flag", "strip debug"],
				"code": """extends Node

# Autoload that centralizes debug toggles.
# On release builds, everything stays off with zero runtime cost.

var debug_enabled: bool = true
var show_debug_overlays: bool = false
var show_collision_shapes: bool = false
var show_grid: bool = false
var enable_cheats: bool = false
var invincible_player: bool = false
var one_hit_kill: bool = false

func _ready() -> void:
	debug_enabled = OS.is_debug_build()

func toggle_overlays() -> void:
	show_debug_overlays = not show_debug_overlays

func toggle_collision() -> void:
	show_collision_shapes = not show_collision_shapes
	var root := get_tree().current_scene
	if root == null:
		return
	var nodes := root.find_children("*", "Node2D", true, false)
	for node in nodes:
		if node.get_class() == "CollisionShape2D":
			(node as Node2D).visible = show_collision_shapes

func toggle_invincible() -> void:
	invincible_player = not invincible_player

func toggle_one_hit_kill() -> void:
	one_hit_kill = not one_hit_kill

func is_debug_enabled() -> bool:
	return debug_enabled

func apply_cheats_to_damage(amount: int) -> int:
	if one_hit_kill:
		return 99999
	if invincible_player:
		return 0
	return amount
""",
				"params": [],
				"category": "debug",
				"subcategory": "gating",
				"platforms": ["desktop"],
				"dimension": "any",
				"difficulty": "beginner",
				"details": {
					"what": "Central autoload for debug features. Auto-detects whether the game is running from an exported release or the editor. All debug code paths become no-ops in release.",
					"where": "Add as an autoload named 'Debug'. Call Debug.is_debug_enabled() before showing anything debug-related.",
					"before": "None.",
					"after": "In release builds, OS.is_debug_build() returns false and all debug toggles are inert. You can ship the code safely.",
					"why_optimized": "Debug checks are simple booleans. No allocations, no async, no side effects when disabled.",
					"mistakes": "Calling debug functions unconditionally pollutes release builds. Always gate with is_debug_enabled().",
					"related": ["debug_overlay_2d", "debug_draw_collision", "debug_print"]
				}
			}
		}
	}
