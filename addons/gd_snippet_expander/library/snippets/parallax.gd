@tool
extends RefCounted


func get_data() -> Dictionary:
	return {
		"version": 2,
		"snippets": {
			"parallax_background": {
				"phrases": ["parallax background", "parallax layer", "scrolling background", "parallax scroll"],
				"code": """# Standard ParallaxBackground setup.
#
# Node structure:
#   ParallaxBackground
#     ParallaxLayer  (motion_scale = Vector2(0.2, 0.2))  -- far mountains
#       Sprite2D (texture = mountains.png)
#     ParallaxLayer  (motion_scale = Vector2(0.5, 0.5))  -- mid hills
#       Sprite2D (texture = hills.png)
#     ParallaxLayer  (motion_scale = Vector2(1.0, 1.0))  -- near trees
#       Sprite2D (texture = trees.png)
#
# motion_scale controls how fast the layer moves relative to the camera.
# 0.0 = doesn't move (locked to screen)
# 0.5 = moves at half camera speed
# 1.0 = moves with the world (no parallax)
#
# motion_mirroring is the key property for infinite scroll:
# set it to the size of the tile texture (in pixels) so the layer
# seamlessly repeats.

func setup_layer(layer: ParallaxLayer, texture_size: Vector2) -> void:
	layer.motion_mirroring = texture_size

func set_scroll_speed(layer: ParallaxLayer, speed: float) -> void:
	layer.motion_scale = Vector2(speed, speed)
""",
				"params": [],
				"category": "parallax",
				"subcategory": "setup",
				"dimension": "2d",
				"difficulty": "beginner",
				"details": {
					"what": "Classic multi-layer parallax background. Distant layers move slowly, near layers move fast, creating depth.",
					"where": "Add a ParallaxBackground at the scene root, as a sibling of the player and camera.",
					"before": "Background textures — usually 3 layers, each a wide repeating image.",
					"after": "Set motion_mirroring to the texture's pixel width so it repeats infinitely as the camera scrolls.",
					"why_optimized": "ParallaxBackground handles all the math in C++. No per-frame script needed.",
					"mistakes": "Forgetting motion_mirroring means the layer runs out and shows empty space. Match it to the texture width exactly.",
					"related": ["parallax_infinite", "parallax_manual", "camera_follow_2d"]
				}
			},
			"parallax_infinite": {
				"phrases": ["infinite parallax", "parallax repeat", "looping background", "seamless parallax"],
				"code": """extends ParallaxBackground

@export var base_scroll_speed: float = 20.0
@export var auto_scroll: bool = true

func _process(delta: float) -> void:
	if not auto_scroll:
		return
	scroll_offset.x += base_scroll_speed * delta

func set_auto_scroll(enabled: bool) -> void:
	auto_scroll = enabled

func set_scroll_speed(speed: float) -> void:
	base_scroll_speed = speed

func jump_to(offset: Vector2) -> void:
	scroll_offset = offset
""",
				"params": ["base_scroll_speed", "auto_scroll"],
				"category": "parallax",
				"subcategory": "scroll",
				"dimension": "2d",
				"difficulty": "beginner",
				"param_info": {
					"base_scroll_speed": {
						"default": 20.0,
						"range": [0.0, 200.0],
						"what": "Pixels per second of automatic horizontal scroll.",
						"typical": "10 slow / 20 standard / 50 fast / 100+ racing",
						"increase": "Faster scroll.",
						"decrease": "Slower. Zero stops scrolling."
					},
					"auto_scroll": {
						"default": true,
						"range": [],
						"what": "Whether to scroll automatically. Turn off for player-driven parallax.",
						"typical": "true for menus / false for levels where the camera moves",
						"increase": "N/A",
						"decrease": "N/A"
					}
				},
				"details": {
					"what": "ParallaxBackground that auto-scrolls horizontally. Good for menu backgrounds and cutscenes.",
					"where": "Attach to a ParallaxBackground. Set auto_scroll to false for levels where the camera drives the scroll.",
					"before": "ParallaxBackground with ParallaxLayers as children. Each layer's motion_mirroring set to its texture size.",
					"after": "Adjust base_scroll_speed per scene — a menu should be slower than a gameplay intro.",
					"why_optimized": "Single delta multiply per frame. No node traversal.",
					"mistakes": "Combining this auto-scroll with a moving camera causes double-speed scrolling. Pick one or the other per scene.",
					"related": ["parallax_background", "parallax_manual", "main_menu"]
				}
			},
			"parallax_manual": {
				"phrases": ["manual parallax", "camera parallax", "parallax camera", "parallax without node"],
				"code": """# ParallaxBackground auto-syncs to the active Camera2D.
# If you want manual control, use this pattern on the layers directly.

@export var layers: Array[NodePath] = []
@export var camera_path: NodePath

@onready var _camera: Camera2D = get_node_or_null(camera_path)
var _base_positions: Array = []

func _ready() -> void:
	for path in layers:
		var layer := get_node_or_null(path)
		if layer is Sprite2D or layer is TextureRect:
			_base_positions.append(layer.position)

func _process(_delta: float) -> void:
	if _camera == null:
		return
	var cam_offset := _camera.global_position
	for i in range(layers.size()):
		var layer := get_node_or_null(layers[i])
		if layer == null:
			continue
		var parallax_factor := 0.2 + i * 0.3
		layer.position = _base_positions[i] - cam_offset * parallax_factor
""",
				"params": ["layers", "camera_path"],
				"category": "parallax",
				"subcategory": "manual",
				"dimension": "2d",
				"difficulty": "intermediate",
				"param_info": {
					"layers": {
						"default": [],
						"range": [],
						"what": "Array of NodePaths to the layers you want to move.",
						"typical": "2-4 layers, from far background to near foreground",
						"increase": "More depth.",
						"decrease": "Simpler."
					},
					"camera_path": {
						"default": "",
						"range": [],
						"what": "Path to the Camera2D that drives the parallax.",
						"typical": "the active camera in your scene",
						"increase": "N/A",
						"decrease": "N/A"
					}
				},
				"details": {
					"what": "Manual parallax implementation using Sprite2D nodes instead of ParallaxBackground. Useful when you need precise control or non-standard scroll behavior.",
					"where": "Attach to a Node2D that contains the layer sprites. Set camera_path to your active Camera2D.",
					"before": "Camera2D in the scene. Layer sprites as children of this node.",
					"after": "Tweak the parallax_factor per layer: 0.2 for far, 0.5 for mid, 0.8 for near.",
					"why_optimized": "Simple multiply-subtract per layer. No ParallaxBackground overhead. Good for 2-3 layers.",
					"mistakes": "Not caching the base positions means layers drift on the first frame. The _ready caches them.",
					"related": ["parallax_background", "parallax_infinite", "camera_follow_2d"]
				}
			},
			"parallax_vertical": {
				"phrases": ["vertical parallax", "parallax vertical scroll", "up down parallax"],
				"code": """extends ParallaxBackground

# Vertical parallax for top-down or flight games.
# Set each ParallaxLayer's motion_scale.y separately:
# - Far sky: motion_scale = Vector2(0.5, 0.1)
# - Clouds: motion_scale = Vector2(0.7, 0.3)
# - Distant terrain: motion_scale = Vector2(0.9, 0.6)

func configure_layer(layer: ParallaxLayer, speed_x: float, speed_y: float) -> void:
	layer.motion_scale = Vector2(speed_x, speed_y)

# For infinite vertical scroll, set motion_mirroring to the vertical size
# of the tile texture, and make sure the sprite is tall enough.
func set_vertical_mirror(layer: ParallaxLayer, texture_height: float) -> void:
	var current := layer.motion_mirroring
	layer.motion_mirroring = Vector2(current.x, texture_height)
""",
				"params": [],
				"category": "parallax",
				"subcategory": "vertical",
				"dimension": "2d",
				"difficulty": "beginner",
				"details": {
					"what": "Vertical parallax for top-down games, flight shooters, or endless climbers.",
					"where": "On a ParallaxBackground whose layers scroll vertically with the camera.",
					"before": "Camera2D that moves vertically. Layer textures sized for vertical tiling.",
					"after": "Combine with horizontal parallax for full 2D depth. Set motion_scale.x and .y separately.",
					"why_optimized": "Same engine-driven math as horizontal. Adding vertical costs nothing.",
					"mistakes": "Setting motion_mirroring.y without matching the texture height means vertical seams appear.",
					"related": ["parallax_background", "parallax_infinite", "topdown_movement_2d"]
				}
			},
			"parallax_fade": {
				"phrases": ["parallax fade", "fade layer", "parallax blend", "distance fade"],
				"code": """extends ParallaxLayer

@export var fade_with_camera: bool = true
@export var max_opacity: float = 1.0
@export var min_opacity: float = 0.3
@export var fade_range: float = 800.0

@onready var _sprite: Node2D = get_child(0) if get_child_count() > 0 else null

func _process(_delta: float) -> void:
	if not fade_with_camera or _sprite == null:
		return
	var camera := get_viewport().get_camera_2d()
	if camera == null:
		return
	var dist := camera.global_position.distance_to(global_position)
	var t: float = clamp(dist / fade_range, 0.0, 1.0)
	var alpha: float = lerp(max_opacity, min_opacity, t)
	_sprite.modulate.a = alpha
""",
				"params": ["fade_with_camera", "max_opacity", "min_opacity", "fade_range"],
				"category": "parallax",
				"subcategory": "effects",
				"dimension": "2d",
				"difficulty": "intermediate",
				"param_info": {
					"max_opacity": {
						"default": 1.0,
						"range": [0.0, 1.0],
						"what": "Alpha when the camera is close.",
						"typical": "1.0 fully visible",
						"increase": "N/A",
						"decrease": "N/A"
					},
					"min_opacity": {
						"default": 0.3,
						"range": [0.0, 1.0],
						"what": "Alpha when the camera is far.",
						"typical": "0.2 subtle / 0.5 obvious / 0.0 invisible",
						"increase": "Layer stays more visible at distance.",
						"decrease": "Fades more with distance."
					},
					"fade_range": {
						"default": 800.0,
						"range": [100.0, 5000.0],
						"what": "Distance over which the fade happens.",
						"typical": "200 tight / 800 standard / 2000+ slow fade",
						"increase": "Slower fade over longer distance.",
						"decrease": "Sharper fade."
					}
				},
				"details": {
					"what": "Fades a parallax layer based on camera distance. Useful for atmospheric depth or reveal effects.",
					"where": "Attach to a ParallaxLayer with a Sprite2D child.",
					"before": "Camera2D in the scene. Layer with a sprite.",
					"after": "For a fog-of-war effect, combine with a black ColorRect overlay and modulate.",
					"why_optimized": "One distance calculation and lerp per frame per layer. Negligible for a handful of layers.",
					"mistakes": "Modulating the ParallaxLayer itself instead of the sprite child can affect other children unexpectedly. Target the sprite directly.",
					"related": ["parallax_background", "fade_in_ui", "canvas_modulate"]
				}
			}
		}
	}
