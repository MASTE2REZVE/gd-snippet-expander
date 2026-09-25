@tool
extends RefCounted


func get_data() -> Dictionary:
	return {
		"version": 2,
		"snippets": {
			"point_light_2d": {
				"phrases": ["point light 2d", "2d light", "add light 2d", "light source 2d"],
				"code": """@export var light_color: Color = Color(1.0, 0.9, 0.7)
@export var light_energy: float = 1.0
@export var light_range: float = 200.0

func _ready() -> void:
	var light := PointLight2D.new()
	light.color = light_color
	light.energy = light_energy
	light.texture_scale = light_range / 100.0
	add_child(light)

func set_energy(value: float) -> void:
	for child in get_children():
		if child is PointLight2D:
			child.energy = value

func pulse() -> void:
	var tween := create_tween()
	tween.set_loops()
	tween.tween_property(self, "modulate", Color(1, 1, 1, 0.7), 0.8)
	tween.tween_property(self, "modulate", Color(1, 1, 1, 1.0), 0.8)
""",
				"params": ["light_color", "light_energy", "light_range"],
				"category": "lighting",
				"subcategory": "2d",
				"dimension": "2d",
				"difficulty": "beginner",
				"param_info": {
					"light_color": {
						"default": [1.0, 0.9, 0.7, 1.0],
						"range": [],
						"what": "Color of the light. Warm yellow feels like fire, cool blue feels like moonlight.",
						"typical": "warm fire / cool moonlight / red danger / green poison",
						"increase": "N/A",
						"decrease": "N/A"
					},
					"light_energy": {
						"default": 1.0,
						"range": [0.0, 5.0],
						"what": "Brightness of the light.",
						"typical": "0.5 subtle / 1.0 standard / 2.0 bright / 3.0+ blown out",
						"increase": "Brighter.",
						"decrease": "Dimmer."
					},
					"light_range": {
						"default": 200.0,
						"range": [20.0, 2000.0],
						"what": "Approximate radius the light reaches, in pixels.",
						"typical": "80 torch / 200 lamp / 500 streetlight / 1000+ beacon",
						"increase": "Larger area lit.",
						"decrease": "Smaller area."
					}
				},
				"details": {
					"what": "Creates a 2D point light programmatically. Need a CanvasModulate in the scene to make the world dark — otherwise lights have nothing to affect.",
					"where": "Attach to a Node2D that should emit light. The scene must have a CanvasModulate node somewhere.",
					"before": "CanvasModulate with a dark color (e.g. Color(0.2, 0.2, 0.3)) covering the whole scene.",
					"after": "Assign a gradient texture to the light for softer falloff. The default radial texture is harsh.",
					"why_optimized": "PointLight2D is a single draw call per light. Keep active lights under ~30 for good performance.",
					"mistakes": "Without a CanvasModulate, PointLight2D does nothing visible — the world stays fully lit and the light adds a subtle glow.",
					"related": ["canvas_modulate", "light_occluder_2d", "flickering_light", "day_night_2d"]
				}
			},
			"canvas_modulate": {
				"phrases": ["canvas modulate", "darken scene", "night mode 2d", "2d ambient light"],
				"code": """extends CanvasModulate

@export var day_color: Color = Color(1.0, 1.0, 1.0)
@export var night_color: Color = Color(0.15, 0.15, 0.35)
@export var transition_time: float = 2.0

var _is_night: bool = false
var _transitioning: bool = false

func _ready() -> void:
	color = day_color

func toggle_day_night() -> void:
	if _transitioning:
		return
	_transitioning = true
	var target := night_color if not _is_night else day_color
	var tween := create_tween()
	tween.tween_property(self, "color", target, transition_time)
	await tween.finished
	_is_night = not _is_night
	_transitioning = false

func set_to_night(instant: bool = false) -> void:
	if instant:
		color = night_color
	else:
		var tween := create_tween()
		tween.tween_property(self, "color", night_color, transition_time)
	_is_night = true

func set_to_day(instant: bool = false) -> void:
	if instant:
		color = day_color
	else:
		var tween := create_tween()
		tween.tween_property(self, "color", day_color, transition_time)
	_is_night = false
""",
				"params": ["day_color", "night_color", "transition_time"],
				"category": "lighting",
				"subcategory": "2d",
				"dimension": "2d",
				"difficulty": "beginner",
				"param_info": {
					"day_color": {
						"default": [1, 1, 1, 1],
						"range": [],
						"what": "Color multiplied over the whole scene during day.",
						"typical": "white for no tint / slight warm for sunset",
						"increase": "N/A",
						"decrease": "N/A"
					},
					"night_color": {
						"default": [0.15, 0.15, 0.35, 1],
						"range": [],
						"what": "Color multiplied over the scene at night. Dark blue is classic.",
						"typical": "deep blue / purple twilight / dark grey overcast",
						"increase": "Brighter night.",
						"decrease": "Darker night."
					},
					"transition_time": {
						"default": 2.0,
						"range": [0.1, 30.0],
						"what": "Seconds for day-to-night or night-to-day transition.",
						"typical": "0.5 quick / 2.0 standard / 10.0+ cinematic sunrise",
						"increase": "Slower transition.",
						"decrease": "Faster."
					}
				},
				"details": {
					"what": "CanvasModulate tints the whole 2D scene. Combined with PointLight2D, it creates a proper 2D lighting setup.",
					"where": "Add as a single node in the scene, usually as a direct child of the level root. Only one per scene.",
					"before": "None. This is the starting point for 2D lighting.",
					"after": "Add PointLight2D nodes for torches, lamps, and glowing objects. They'll only be visible when the CanvasModulate is dark.",
					"why_optimized": "One modulate multiply per frame — trivial cost.",
					"mistakes": "Multiple CanvasModulate nodes fight each other. Only use one.",
					"related": ["point_light_2d", "day_night_2d", "flickering_light"]
				}
			},
			"flickering_light": {
				"phrases": ["flickering light", "torch flicker", "candle flicker", "fire light flicker"],
				"code": """extends PointLight2D

@export var base_energy: float = 1.0
@export var flicker_amount: float = 0.15
@export var flicker_speed: float = 8.0
@export var size_variance: float = 0.05

var _time: float = 0.0

func _ready() -> void:
	energy = base_energy

func _process(delta: float) -> void:
	_time += delta * flicker_speed
	var noise := sin(_time) * 0.5 + sin(_time * 1.7) * 0.3 + sin(_time * 3.1) * 0.2
	energy = base_energy + noise * flicker_amount
	texture_scale = 1.0 + noise * size_variance
""",
				"params": ["base_energy", "flicker_amount", "flicker_speed", "size_variance"],
				"category": "lighting",
				"subcategory": "2d",
				"dimension": "2d",
				"difficulty": "beginner",
				"param_info": {
					"base_energy": {
						"default": 1.0,
						"range": [0.0, 5.0],
						"what": "Center brightness around which the flicker oscillates.",
						"typical": "0.8 dim torch / 1.0 standard / 1.5 bright fire",
						"increase": "Brighter.",
						"decrease": "Dimmer."
					},
					"flicker_amount": {
						"default": 0.15,
						"range": [0.0, 1.0],
						"what": "How much the brightness varies up and down.",
						"typical": "0.05 subtle / 0.15 torch / 0.4 campfire",
						"increase": "More dramatic flicker.",
						"decrease": "Steadier."
					},
					"flicker_speed": {
						"default": 8.0,
						"range": [1.0, 30.0],
						"what": "How fast the flicker oscillates.",
						"typical": "4 slow / 8 standard / 15+ frantic",
						"increase": "Faster.",
						"decrease": "Slower, lazier."
					},
					"size_variance": {
						"default": 0.05,
						"range": [0.0, 0.2],
						"what": "How much the light's radius pulses.",
						"typical": "0.02 subtle / 0.05 standard / 0.1+ obvious",
						"increase": "Bigger size changes.",
						"decrease": "Steadier size."
					}
				},
				"details": {
					"what": "A PointLight2D that flickers with layered sine waves. Looks like fire, candle, or dying bulb.",
					"where": "Attach directly to a PointLight2D. Configure base_energy, flicker_amount, and speed in the Inspector.",
					"before": "CanvasModulate for the scene. PointLight2D with a texture assigned.",
					"after": "Vary flicker_amount per light so adjacent torches don't flicker in sync.",
					"why_optimized": "Three sin() calls per frame — negligible. No randomness so it's deterministic and tunable.",
					"mistakes": "Using randf() every frame makes the flicker jittery and harsh. Layered sine looks natural.",
					"related": ["point_light_2d", "canvas_modulate", "particle_sparkle"]
				}
			},
			"light_occluder_2d": {
				"phrases": ["light occluder 2d", "2d shadow", "block light 2d", "light shadow 2d"],
				"code": """# LightOccluder2D blocks PointLight2D. Combined with a CanvasModulate
# and PointLight2D, this creates dynamic 2D shadows.

# 1. Add a LightOccluder2D node as a child of a StaticBody2D or wall.
# 2. In the Inspector, click the Occluder slot -> New OccluderPolygon2D.
# 3. Edit the polygon in the 2D viewport to match the wall shape.
# 4. Make sure 'Closed' is checked.
# 5. Enable Debug -> Visible Light Occluders to see the polygons.

# For a tilemap, mark tiles as occluders directly:
# - In the TileSet, click 'Add Occlusion Layer'.
# - Switch the palette to 'Occlusion' mode.
# - Paint occlusion polygons on solid tiles.
# The TileMapLayer will automatically create occluders.

# Programmatic occluder:
func create_occluder(parent: Node2D, points: PackedVector2Array) -> LightOccluder2D:
	var polygon := OccluderPolygon2D.new()
	polygon.polygon = points
	polygon.closed = true
	var occluder := LightOccluder2D.new()
	occluder.occluder = polygon
	parent.add_child(occluder)
	return occluder
""",
				"params": [],
				"category": "lighting",
				"subcategory": "2d",
				"dimension": "2d",
				"difficulty": "intermediate",
				"details": {
					"what": "LightOccluder2D blocks 2D lights, casting shadows. Set up walls, trees, and rocks to block torch light.",
					"where": "Configure in the TileSet (for tile walls) or as standalone nodes on static objects.",
					"before": "CanvasModulate and at least one PointLight2D in the scene.",
					"after": "Enable Debug → Visible Light Occluders to verify shapes. The debug view is essential for setup.",
					"why_optimized": "Occluders are computed on the GPU. Hundreds can exist with negligible cost.",
					"mistakes": "Forgetting to close the polygon means no shadow. Self-intersecting polygons produce weird artifacts. Draw shapes counter-clockwise.",
					"related": ["point_light_2d", "canvas_modulate", "tilemap_autotile"]
				}
			},
			"day_night_2d": {
				"phrases": ["day night cycle 2d", "day night 2d", "sun cycle 2d", "time of day 2d"],
				"code": """extends CanvasModulate

@export var day_duration_seconds: float = 120.0
@export var dawn_color: Color = Color(1.0, 0.7, 0.5)
@export var noon_color: Color = Color(1.0, 1.0, 1.0)
@export var dusk_color: Color = Color(1.0, 0.4, 0.3)
@export var night_color: Color = Color(0.1, 0.1, 0.3)

signal hour_changed(hour: float)

var time_of_day: float = 8.0  # 0-24, starting at 8 AM

func _process(delta: float) -> void:
	var prev_hour := time_of_day
	time_of_day += (delta / day_duration_seconds) * 24.0
	time_of_day = fmod(time_of_day, 24.0)
	if int(prev_hour) != int(time_of_day):
		hour_changed.emit(time_of_day)
	color = _color_for_hour(time_of_day)

func _color_for_hour(hour: float) -> Color:
	# 0-6 night, 6-9 dawn, 9-17 day, 17-20 dusk, 20-24 night
	if hour < 6.0:
		return night_color
	elif hour < 9.0:
		return night_color.lerp(dawn_color, (hour - 6.0) / 3.0)
	elif hour < 12.0:
		return dawn_color.lerp(noon_color, (hour - 9.0) / 3.0)
	elif hour < 17.0:
		return noon_color
	elif hour < 20.0:
		return noon_color.lerp(dusk_color, (hour - 17.0) / 3.0)
	else:
		return dusk_color.lerp(night_color, (hour - 20.0) / 4.0)

func is_night() -> bool:
	return time_of_day < 6.0 or time_of_day >= 20.0

func set_hour(hour: float) -> void:
	time_of_day = fmod(hour, 24.0)
	color = _color_for_hour(time_of_day)
""",
				"params": ["day_duration_seconds", "dawn_color", "noon_color", "dusk_color", "night_color"],
				"category": "lighting",
				"subcategory": "2d",
				"dimension": "2d",
				"difficulty": "intermediate",
				"param_info": {
					"day_duration_seconds": {
						"default": 120.0,
						"range": [10.0, 3600.0],
						"what": "Real-time seconds for one in-game day.",
						"typical": "60 fast / 120 standard / 600 slow",
						"increase": "Longer days.",
						"decrease": "Faster cycle."
					},
					"dawn_color": {
						"default": [1.0, 0.7, 0.5, 1.0],
						"range": [],
						"what": "Color at sunrise.",
						"typical": "orange / pink / pale yellow",
						"increase": "N/A",
						"decrease": "N/A"
					},
					"noon_color": {
						"default": [1, 1, 1, 1],
						"range": [],
						"what": "Color at midday — usually pure white (no tint).",
						"typical": "white",
						"increase": "N/A",
						"decrease": "N/A"
					},
					"night_color": {
						"default": [0.1, 0.1, 0.3, 1],
						"range": [],
						"what": "Color at deep night.",
						"typical": "dark blue / deep purple",
						"increase": "Brighter night.",
						"decrease": "Darker."
					}
				},
				"details": {
					"what": "A full day/night cycle on CanvasModulate. Interpolates through dawn, noon, dusk, and night colors over a real-time duration.",
					"where": "Attach to a single CanvasModulate node in your scene.",
					"before": "CanvasModulate with default color. Add PointLight2D nodes for lights that turn on at night.",
					"after": "Use hour_changed signal to turn streetlamps on at 19:00 and off at 06:00.",
					"why_optimized": "One color interpolation per frame. Signal fires only on hour boundaries, not every frame.",
					"mistakes": "Not clamping hour with fmod means time_of_day runs past 24 and colors go wild.",
					"related": ["canvas_modulate", "point_light_2d", "flickering_light", "weather_2d"]
				}
			}
		}
	}
