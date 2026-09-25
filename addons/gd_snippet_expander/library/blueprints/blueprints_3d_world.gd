@tool
extends RefCounted


func get_data() -> Dictionary:
	return {
		"version": 2,
		"blueprints": {
			"day_night_rig_3d": {
				"title": "Day/Night Cycle Rig (3D)",
				"phrases": ["day night rig 3d", "3d day night cycle", "sun cycle rig", "add day night 3d"],
				"category": "world",
				"subcategory": "time",
				"platforms": ["desktop", "mobile"],
				"dimension": "3d",
				"difficulty": "intermediate",
				"root": {
					"type": "Node3D",
					"name": "DayNightRig"
				},
				"required_children": [
					{"type": "WorldEnvironment", "name": "WorldEnvironment"},
					{"type": "DirectionalLight3D", "name": "Sun"},
					{"type": "DirectionalLight3D", "name": "Moon", "properties": {"light_energy": 0.15, "light_color": [0.4, 0.5, 0.9, 1.0]}}
				],
				"recommended_children": [],
				"script": "day_night_3d",
				"required_actions": [],
				"setup_notes": [
					"Note: the day_night_3d script was written for a single DirectionalLight3D. Extend it to also drive the Moon light's energy and rotation.",
					"Recommended structure:",
					"  DayNightRig (Node3D)",
					"    WorldEnvironment — Environment with ProceduralSkyMaterial",
					"    Sun (DirectionalLight3D) — main light, rotates across the sky",
					"    Moon (DirectionalLight3D) — opposite rotation, low energy",
					"Attach the day_night_3d script to the Sun. In addition, create a small script on the DayNightRig that mirrors the sun's rotation to the moon with a 180-degree offset.",
					"On the WorldEnvironment, edit the Environment resource:",
					"  - sky_material.sky_top_color and sky_horizon_color will change based on the sun",
					"  - ambient_light_energy multiplies with the sun's energy",
					"  - Enable fog with a color matching the sun's tint",
					"Configure the day duration:",
					"  - day_duration_seconds: 60 fast demo / 180 standard / 600 slow",
					"  - start_hour: 8.0 for morning start",
					"The Sun's light_color and light_energy are already driven by the script. The Moon should stay dim but tinted blue.",
					"Optional: add an AnimationPlayer to fade the Moon's light_color toward bright at night and dim at day."
				],
				"next_steps": [
					{"snippet": "day_night_3d", "why": "The sun rotation and color logic."},
					{"snippet": "day_night_2d", "why": "The 2D version if you're building 2D."},
					{"blueprint": "environment_rig_3d", "why": "Base environment setup."},
					{"snippet": "shadow_tuning_3d", "why": "Fix shadows during low sun angles."}
				],
				"mistakes": [
					"Forgetting to update the WorldEnvironment's sky colors means the sky stays bright while the sun goes dark. Script it or use a shader.",
					"Moon with high light_energy (over 0.3) means night looks as bright as day. Keep it under 0.2.",
					"Sun rotation of exactly 0 or 180 creates a straight down or straight up light — flat shading. Use 45+ for interesting shadows.",
					"Very short day cycles (under 30 seconds) make shadows flicker and cause visual jitter."
				]
			},
			"weather_rig_3d": {
				"title": "Weather Rig (3D)",
				"phrases": ["weather rig 3d", "3d weather system", "rain snow rig 3d", "add weather 3d"],
				"category": "world",
				"subcategory": "weather",
				"platforms": ["desktop", "mobile"],
				"dimension": "3d",
				"difficulty": "advanced",
				"root": {
					"type": "Node3D",
					"name": "WeatherRig"
				},
				"required_children": [
					{"type": "GPUParticles3D", "name": "RainParticles"},
					{"type": "GPUParticles3D", "name": "SnowParticles"},
					{"type": "AudioStreamPlayer", "name": "RainSound"}
				],
				"recommended_children": [
					{"type": "GPUParticles3D", "name": "FogParticles"}
				],
				"script": "",
				"required_actions": [],
				"setup_notes": [
					"Note: weather is complex. This rig provides the structure — you configure the particle systems and the state machine.",
					"Attach this script to the WeatherRig root:",
					"",
					"    extends Node3D",
					"",
					"    signal weather_changed(weather_type: String)",
					"",
					"    @export var world_environment_path: NodePath",
					"    @export var transition_time: float = 5.0",
					"",
					"    @onready var _env: WorldEnvironment = get_node_or_null(world_environment_path)",
					"    @onready var _rain: GPUParticles3D = $RainParticles",
					"    @onready var _snow: GPUParticles3D = $SnowParticles",
					"    @onready var _rain_sound: AudioStreamPlayer = $RainSound",
					"",
					"    var current_weather: String = \"clear\"",
					"",
					"    func set_weather(weather_type: String) -> void:",
					"        if current_weather == weather_type:",
					"            return",
					"        current_weather = weather_type",
					"        _rain.emitting = weather_type == \"rain\"",
					"        _snow.emitting = weather_type == \"snow\"",
					"        _rain_sound.playing = weather_type == \"rain\"",
					"        _apply_fog(weather_type)",
					"        weather_changed.emit(weather_type)",
					"",
					"    func _apply_fog(weather_type: String) -> void:",
					"        if _env == null or _env.environment == null:",
					"            return",
					"        var env := _env.environment",
					"        var tween := create_tween()",
					"        match weather_type:",
					"            \"rain\", \"snow\":",
					"                tween.tween_property(env, \"fog_density\", 0.04, transition_time)",
					"                tween.parallel().tween_property(env, \"fog_light_color\", Color(0.5, 0.55, 0.6), transition_time)",
					"            _:",
					"                tween.tween_property(env, \"fog_density\", 0.005, transition_time)",
					"                tween.parallel().tween_property(env, \"fog_light_color\", Color(0.7, 0.75, 0.85), transition_time)",
					"",
					"    func get_weather() -> String:",
					"        return current_weather",
					"",
					"CONFIGURE THE PARTICLES:",
					"Rain particles — GPUParticles3D positioned 20 meters above the camera:",
					"  - amount: 500, lifetime: 2.0, explosiveness: 0.0",
					"  - process_material.direction: (0, -1, 0)",
					"  - process_material.spread: 5.0",
					"  - process_material.initial_velocity: 20.0 to 25.0",
					"  - draw_pass_1: a small thin box mesh (0.02, 0.4, 0.02)",
					"  - Enable 'local_coords' off so particles fall in world space",
					"",
					"Snow particles — same setup but slower:",
					"  - initial_velocity: 1.0 to 2.0",
					"  - process_material.gravity: (0, -0.3, 0)",
					"  - draw_pass_1: small sphere or quad",
					"",
					"Attach the particles as children of the WeatherRig. Move the WeatherRig with the camera so particles always surround the player.",
					"Assign a looping rain ambient sound to RainSound. Autostart off.",
					"Call set_weather(\"rain\") / set_weather(\"snow\") / set_weather(\"clear\") from game code."
				],
				"next_steps": [
					{"snippet": "fog_3d", "why": "Fog tuning for weather."},
					{"snippet": "particles_3d", "why": "Particle setup."},
					{"blueprint": "day_night_rig_3d", "why": "Combine for atmospheric scenes."},
					{"snippet": "audio_fade", "why": "Smooth weather sound transitions."}
				],
				"mistakes": [
					"Rain particles following the camera exactly look fake. Offset them slightly ahead of the camera.",
					"Very high particle amounts (2000+) kill performance on mobile. Keep under 800 for rain, 400 for snow.",
					"Not offsetting particles vertically means they spawn right where the player is standing. Spawn them 20+ meters above.",
					"Fog transition too fast (under 2 seconds) looks like a glitch. Use 5+ seconds."
				]
			},
			"water_volume_3d": {
				"title": "Water Volume (3D)",
				"phrases": ["water volume 3d", "3d water body", "3d swim area", "add water 3d"],
				"category": "environment",
				"subcategory": "3d",
				"platforms": ["desktop", "mobile"],
				"dimension": "3d",
				"difficulty": "advanced",
				"root": {
					"type": "Node3D",
					"name": "WaterVolume"
				},
				"required_children": [
					{"type": "MeshInstance3D", "name": "WaterSurface", "mesh": "PlaneMesh"},
					{"type": "Area3D", "name": "SwimZone"},
					{"type": "CollisionShape3D", "name": "CollisionShape3D", "shape": "BoxShape3D"}
				],
				"recommended_children": [
					{"type": "OmniLight3D", "name": "UnderwaterGlow"}
				],
				"script": "water_zone_3d",
				"required_actions": ["left", "right", "forward", "back", "jump", "crouch"],
				"setup_notes": [
					"Note: re-parent the children after building. The tree should be:",
					"  WaterVolume (Node3D)",
					"    WaterSurface (MeshInstance3D, PlaneMesh) — visual only",
					"    SwimZone (Area3D) — the trigger volume",
					"      CollisionShape3D (BoxShape3D)",
					"    UnderwaterGlow (OmniLight3D) — optional tint light",
					"Attach the water_zone_3d script to the SwimZone Area3D, NOT to the WaterVolume root.",
					"CONFIGURE THE WATER SURFACE:",
					"  - PlaneMesh size: match the water body dimensions (e.g. 100x100 for a lake)",
					"  - Material: use a translucent blue StandardMaterial3D",
					"    - albedo_color: (0.1, 0.3, 0.6, 0.6)",
					"    - metallic: 0.3, roughness: 0.1",
					"    - transparency: ALPHA",
					"  - Optionally use shader_wave on the material for ripples",
					"CONFIGURE THE SWIM ZONE:",
					"  - CollisionShape3D BoxShape3D size: match the depth and width of the water body",
					"  - Set the collision mask to detect CharacterBody3D",
					"  - Position the box so it covers the underwater volume (not above the surface)",
					"  - On the water_zone_3d script:",
					"    - water_level_y: the Y coordinate of the water surface",
					"    - buoyancy: 15.0 for standard",
					"    - drag: 3.0",
					"    - swim_force: 15.0",
					"UNDERWATER EFFECTS:",
					"  - Add a WorldEnvironment with underwater fog",
					"  - When the player enters water, swap to a 'underwater' environment",
					"  - Add a blue tint ColorRect overlay on the HUD with low alpha",
					"  - Play underwater ambient sound when submerged"
				],
				"next_steps": [
					{"snippet": "water_zone_3d", "why": "The swim logic."},
					{"snippet": "shader_wave", "why": "Ripple effect on the surface."},
					{"snippet": "fog_3d", "why": "Underwater fog."},
					{"blueprint": "environment_rig_3d", "why": "Base environment to modify."}
				],
				"mistakes": [
					"Putting the swim zone ABOVE the water surface means the player starts swimming in the air. Position it under the surface mesh.",
					"Water surface mesh with opaque material hides everything below. Use transparency with alpha around 0.6.",
					"Not disabling the player's normal jump when in water means they can double-jump out of the water.",
					"Forgetting the OmniLight3D with a blue tint means underwater areas stay pitch black.",
					"Swim zone collision layer not matching the player means the water never triggers."
				]
			}
		}
	}
