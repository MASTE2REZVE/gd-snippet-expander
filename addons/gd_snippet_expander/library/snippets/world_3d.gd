@tool
extends RefCounted


func get_data() -> Dictionary:
	return {
		"version": 2,
		"snippets": {
			"world_environment_3d": {
				"phrases": ["world environment", "environment 3d", "sky 3d", "scene environment"],
				"code": """# WorldEnvironment sets the sky, ambient light, fog, and post-processing
# for a 3D scene. Only one per scene — add it as a child of the scene root.

# 1. Add a WorldEnvironment node.
# 2. In the Inspector, click the Environment slot -> New Environment.
# 3. Configure:
#    - Background Mode: Sky (procedural sky) / Color / Canvas / Keep
#    - Sky: New ProceduralSkyMaterial for a default sky
#    - Ambient Light: Sky or Color
#    - Tonemap: Filmic or ACES for cinematic look
#    - Glow: enable for bloom effects
#    - Fog: enable and set density for atmospheric depth

func configure_default_environment(env_node: WorldEnvironment) -> void:
	if env_node.environment == null:
		env_node.environment = Environment.new()
	var env := env_node.environment
	env.background_mode = Environment.BG_SKY
	var sky := ProceduralSkyMaterial.new()
	sky.sky_top_color = Color(0.4, 0.6, 0.9)
	sky.sky_horizon_color = Color(0.7, 0.75, 0.85)
	sky.ground_bottom_color = Color(0.3, 0.25, 0.2)
	var sky_resource := Sky.new()
	sky_resource.sky_material = sky
	env.sky = sky_resource
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 1.0
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC

func set_sky_color(env_node: WorldEnvironment, top: Color, horizon: Color) -> void:
	if env_node.environment == null or env_node.environment.sky == null:
		return
	var mat := env_node.environment.sky.sky_material
	if mat is ProceduralSkyMaterial:
		(mat as ProceduralSkyMaterial).sky_top_color = top
		(mat as ProceduralSkyMaterial).sky_horizon_color = horizon
""",
				"params": [],
				"category": "world",
				"subcategory": "environment",
				"platforms": ["desktop", "mobile", "web"],
				"dimension": "3d",
				"difficulty": "beginner",
				"details": {
					"what": "Sets up the sky, ambient light, and post-processing for a 3D scene. The 3D equivalent of CanvasModulate.",
					"where": "Add one WorldEnvironment as a child of your 3D scene root. Only one per scene.",
					"before": "A 3D scene with at least one light source.",
					"after": "Tune the sky colors, enable fog, or enable glow for atmosphere. All editable in the Inspector.",
					"why_optimized": "One environment resource per scene. The GPU applies all effects in a single pass.",
					"mistakes": "Multiple WorldEnvironment nodes fight each other — only one is active. Delete extras.",
					"related": ["directional_light_3d", "fog_3d", "day_night_3d"]
				}
			},
			"fog_3d": {
				"phrases": ["fog 3d", "atmospheric fog", "distance fog", "depth fog"],
				"code": """extends WorldEnvironment

@export var fog_enabled: bool = true
@export var fog_density: float = 0.02
@export var fog_color: Color = Color(0.7, 0.75, 0.85)
@export var fog_sun_scatter: float = 0.3
@export var aerial_perspective: float = 0.5

func _ready() -> void:
	_apply_fog()

func _apply_fog() -> void:
	if environment == null:
		environment = Environment.new()
	environment.fog_enabled = fog_enabled
	environment.fog_density = fog_density
	environment.fog_light_color = fog_color
	environment.fog_sun_scatter = fog_sun_scatter
	environment.fog_aerial_perspective = aerial_perspective

func set_fog_density(value: float) -> void:
	fog_density = clampf(value, 0.0, 0.1)
	_apply_fog()

func fade_fog_in(duration: float) -> void:
	var tween := create_tween()
	tween.tween_method(set_fog_density, 0.0, fog_density, duration)

func fade_fog_out(duration: float) -> void:
	var tween := create_tween()
	tween.tween_method(set_fog_density, fog_density, 0.0, duration)
""",
				"params": ["fog_enabled", "fog_density", "fog_color", "fog_sun_scatter", "aerial_perspective"],
				"category": "world",
				"subcategory": "fog",
				"platforms": ["desktop", "mobile", "web"],
				"dimension": "3d",
				"difficulty": "beginner",
				"param_info": {
					"fog_density": {
						"default": 0.02,
						"range": [0.001, 0.1],
						"what": "Thickness of the fog. Higher means you see less.",
						"typical": "0.005 subtle haze / 0.02 standard / 0.05 thick fog / 0.1+ can't see far",
						"increase": "Denser fog.",
						"decrease": "Clearer view."
					},
					"fog_color": {
						"default": [0.7, 0.75, 0.85, 1.0],
						"range": [],
						"what": "Color of the fog.",
						"typical": "grey overcast / white morning / blue night / brown dust storm",
						"increase": "N/A",
						"decrease": "N/A"
					},
					"fog_sun_scatter": {
						"default": 0.3,
						"range": [0.0, 1.0],
						"what": "How much the sun's light scatters through the fog (visible godrays).",
						"typical": "0.0 flat fog / 0.3 standard / 1.0 dramatic",
						"increase": "More visible light shafts.",
						"decrease": "Flat fog."
					}
				},
				"details": {
					"what": "Adds distance fog to a 3D scene. Objects fade to fog color as they get further away, creating depth.",
					"where": "Attach to a WorldEnvironment node. Or configure fog directly in the Environment resource without this script.",
					"before": "WorldEnvironment in the scene with an Environment resource.",
					"after": "For height fog (fog that only exists near the ground), use a fog volume shader instead.",
					"why_optimized": "Fog is a single-pass GPU effect. No per-object cost.",
					"mistakes": "Fog density above 0.1 makes the scene nearly unplayable. Keep under 0.05 unless doing a specific effect.",
					"related": ["world_environment_3d", "day_night_3d", "weather_3d"]
				}
			},
			"directional_light_3d": {
				"phrases": ["directional light 3d", "sun light 3d", "add sun 3d", "directional light"],
				"code": """# DirectionalLight3D simulates a sun — parallel rays coming from
# infinitely far away. Every 3D scene that's outside needs one.

# 1. Add a DirectionalLight3D node.
# 2. Rotate it in the editor to change the sun angle.
#    - X rotation: sun height (negative = from above)
#    - Y rotation: sun direction (compass)
# 3. In the Inspector:
#    - Shadow: enable for cast shadows
#    - Shadow Mode: PSSM 2 Splits for indoor, PSSM 4 Splits for outdoor
#    - Light Energy: 0.5 dim / 1.0 standard / 2.0 bright
#    - Light Color: warm yellow for sunset, white for noon

@export var day_color: Color = Color(1.0, 0.98, 0.9)
@export var sunset_color: Color = Color(1.0, 0.6, 0.3)
@export var night_color: Color = Color(0.4, 0.5, 0.8)

func set_light_color(light: DirectionalLight3D, color: Color) -> void:
	light.light_color = color

func set_light_angle(light: DirectionalLight3D, degrees_from_horizon: float) -> void:
	var radians: float = deg_to_rad(degrees_from_horizon)
	light.rotation.x = -radians

func enable_shadows(light: DirectionalLight3D, enabled: bool = true) -> void:
	light.shadow_enabled = enabled
	if enabled:
		light.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS

func set_energy(light: DirectionalLight3D, value: float) -> void:
	light.light_energy = clampf(value, 0.0, 5.0)
""",
				"params": [],
				"category": "world",
				"subcategory": "lighting",
				"platforms": ["desktop", "mobile", "web"],
				"dimension": "3d",
				"difficulty": "beginner",
				"details": {
					"what": "The sun for a 3D scene. Parallel rays, casts shadows, and works with the WorldEnvironment sky.",
					"where": "Add as a direct child of the scene root. Rotate it in the editor to set the sun angle.",
					"before": "WorldEnvironment recommended so the sky and sun match.",
					"after": "Use day_night_3d to rotate the sun over time. Use fog to make godrays visible.",
					"why_optimized": "Directional lights are the cheapest shadow-casting light type. Use them for outdoor sun.",
					"mistakes": "Forgetting to enable shadows means objects don't cast them. Sun energy above 3.0 washes everything out.",
					"related": ["world_environment_3d", "day_night_3d", "omni_light_3d"]
				}
			},
			"omni_light_3d": {
				"phrases": ["omni light 3d", "point light 3d", "lamp light 3d", "bulb light"],
				"code": """extends OmniLight3D

@export var base_energy: float = 1.5
@export var light_range: float = 8.0
@export var flicker_enabled: bool = false
@export var flicker_amount: float = 0.2
@export var flicker_speed: float = 8.0

var _time: float = 0.0

func _ready() -> void:
	omni_range = light_range
	light_energy = base_energy
	shadow_enabled = true

func _process(delta: float) -> void:
	if not flicker_enabled:
		return
	_time += delta * flicker_speed
	var noise := sin(_time) * 0.5 + sin(_time * 1.7) * 0.3 + sin(_time * 3.1) * 0.2
	light_energy = base_energy + noise * flicker_amount

func set_range(value: float) -> void:
	light_range = value
	omni_range = value

func toggle_shadows(enabled: bool) -> void:
	shadow_enabled = enabled
""",
				"params": ["base_energy", "light_range", "flicker_enabled", "flicker_amount", "flicker_speed"],
				"category": "world",
				"subcategory": "lighting",
				"platforms": ["desktop", "mobile", "web"],
				"dimension": "3d",
				"difficulty": "beginner",
				"param_info": {
					"base_energy": {
						"default": 1.5,
						"range": [0.0, 10.0],
						"what": "Brightness of the omni light.",
						"typical": "0.5 subtle / 1.5 standard lamp / 3.0+ bright",
						"increase": "Brighter.",
						"decrease": "Dimmer."
					},
					"light_range": {
						"default": 8.0,
						"range": [1.0, 50.0],
						"what": "Radius the light reaches, in meters.",
						"typical": "3 small / 8 standard room / 20 streetlight",
						"increase": "Bigger radius.",
						"decrease": "Smaller."
					},
					"flicker_amount": {
						"default": 0.2,
						"range": [0.0, 1.0],
						"what": "How much the light flickers when flicker_enabled is true.",
						"typical": "0.05 subtle / 0.2 torch / 0.5 fire",
						"increase": "More dramatic flicker.",
						"decrease": "Steadier."
					}
				},
				"details": {
					"what": "Point light for 3D scenes. Lights in all directions — lamps, torches, bulbs, glowing objects.",
					"where": "Attach directly to an OmniLight3D. Set the flicker properties in the Inspector for a fire effect.",
					"before": "WorldEnvironment in the scene with reduced ambient light, so the light is visible.",
					"after": "Add a MeshInstance3D with an emissive material nearby for a visible bulb.",
					"why_optimized": "Omni lights are cheap. Keep under ~20 active simultaneously for good performance.",
					"mistakes": "Enabling shadows on many omni lights tanks performance. Shadows are expensive per light.",
					"related": ["directional_light_3d", "spot_light_3d", "world_environment_3d"]
				}
			},
			"spot_light_3d": {
				"phrases": ["spot light 3d", "spotlight 3d", "flashlight 3d", "cone light 3d"],
				"code": """extends SpotLight3D

@export var light_range: float = 15.0
@export var cone_angle: float = 30.0
@export var base_energy: float = 2.0
@export var shadows_enabled: bool = true

func _ready() -> void:
	spot_range = light_range
	spot_angle = cone_angle
	light_energy = base_energy
	shadow_enabled = shadows_enabled

func aim_at(target_position: Vector3) -> void:
	look_at(target_position, Vector3.UP)

func set_cone_angle(degrees: float) -> void:
	cone_angle = clampf(degrees, 1.0, 90.0)
	spot_angle = cone_angle

func set_range(value: float) -> void:
	light_range = value
	spot_range = value
""",
				"params": ["light_range", "cone_angle", "base_energy", "shadows_enabled"],
				"category": "world",
				"subcategory": "lighting",
				"platforms": ["desktop", "mobile", "web"],
				"dimension": "3d",
				"difficulty": "beginner",
				"param_info": {
					"light_range": {
						"default": 15.0,
						"range": [1.0, 100.0],
						"what": "Distance the spotlight shines.",
						"typical": "5 flashlight / 15 headlight / 50+ searchlight",
						"increase": "Reaches further.",
						"decrease": "Shorter range."
					},
					"cone_angle": {
						"default": 30.0,
						"range": [1.0, 90.0],
						"what": "Width of the light cone in degrees.",
						"typical": "10 narrow beam / 30 standard / 60+ wide flood",
						"increase": "Wider cone.",
						"decrease": "Narrower."
					}
				},
				"details": {
					"what": "Cone-shaped 3D light. Flashlights, headlights, stage spotlights, searchlights.",
					"where": "Attach directly to a SpotLight3D. Point it at the target.",
					"before": "WorldEnvironment with reduced ambient light.",
					"after": "Parent the spotlight to the player for a flashlight. Call aim_at() each frame to point at the target.",
					"why_optimized": "Spotlight shadow casting is more expensive than omni but less than many small omnis. Use sparingly.",
					"mistakes": "Very narrow cones (under 5 degrees) look unnatural. Wide cones (over 60) lose the spotlight feel.",
					"related": ["omni_light_3d", "directional_light_3d", "first_person_movement"]
				}
			},
			"day_night_3d": {
				"phrases": ["day night 3d", "sun cycle 3d", "time of day 3d", "sun movement"],
				"code": """extends DirectionalLight3D

@export var day_duration_seconds: float = 180.0
@export var start_hour: float = 8.0

signal hour_changed(hour: float)

var time_of_day: float = 8.0

func _ready() -> void:
	time_of_day = start_hour
	_apply_sun()

func _process(delta: float) -> void:
	var prev_hour := time_of_day
	time_of_day += (delta / day_duration_seconds) * 24.0
	time_of_day = fmod(time_of_day, 24.0)
	if int(prev_hour) != int(time_of_day):
		hour_changed.emit(time_of_day)
	_apply_sun()

func _apply_sun() -> void:
	# Sun rises at 6, peaks at 12, sets at 18
	var sun_angle: float = ((time_of_day - 6.0) / 12.0) * 180.0
	rotation.x = -deg_to_rad(sun_angle)
	rotation.y = deg_to_rad(45.0)
	# Color: warm at dawn/dusk, white at noon, dark at night
	if time_of_day < 6.0 or time_of_day >= 20.0:
		light_color = Color(0.4, 0.5, 0.8)
		light_energy = 0.1
	elif time_of_day < 9.0:
		var t: float = (time_of_day - 6.0) / 3.0
		light_color = Color(1.0, 0.6, 0.3).lerp(Color(1.0, 0.98, 0.9), t)
		light_energy = lerp(0.5, 1.0, t)
	elif time_of_day < 17.0:
		light_color = Color(1.0, 0.98, 0.9)
		light_energy = 1.0
	elif time_of_day < 20.0:
		var t: float = (time_of_day - 17.0) / 3.0
		light_color = Color(1.0, 0.98, 0.9).lerp(Color(1.0, 0.5, 0.3), t)
		light_energy = lerp(1.0, 0.4, t)

func is_night() -> bool:
	return time_of_day < 6.0 or time_of_day >= 20.0

func set_hour(hour: float) -> void:
	time_of_day = fmod(hour, 24.0)
	_apply_sun()
""",
				"params": ["day_duration_seconds", "start_hour"],
				"category": "world",
				"subcategory": "time",
				"platforms": ["desktop", "mobile", "web"],
				"dimension": "3d",
				"difficulty": "intermediate",
				"param_info": {
					"day_duration_seconds": {
						"default": 180.0,
						"range": [30.0, 3600.0],
						"what": "Real-time seconds for one in-game day.",
						"typical": "60 fast / 180 standard / 600 slow",
						"increase": "Longer days.",
						"decrease": "Faster cycle."
					},
					"start_hour": {
						"default": 8.0,
						"range": [0.0, 24.0],
						"what": "Starting time of day in 24-hour format.",
						"typical": "6 sunrise / 12 noon / 18 sunset / 0 midnight",
						"increase": "Later start.",
						"decrease": "Earlier."
					}
				},
				"details": {
					"what": "Rotates a DirectionalLight3D through a sun arc and tints the color through dawn, noon, dusk, and night.",
					"where": "Attach directly to a DirectionalLight3D. The light must be a child of the scene root.",
					"before": "WorldEnvironment with a sky so the sky color also shifts.",
					"after": "Connect hour_changed to turn streetlights on at dusk, change ambient sound, or trigger events.",
					"why_optimized": "One rotation and one color lerp per frame. Signal fires only on hour boundaries.",
					"mistakes": "Not updating the WorldEnvironment ambient light color means the world stays lit at night.",
					"related": ["directional_light_3d", "world_environment_3d", "day_night_2d"]
				}
			}
		}
	}
