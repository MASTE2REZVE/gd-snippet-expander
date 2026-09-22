@tool
extends RefCounted


func get_data() -> Dictionary:
	return {
		"version": 2,
		"snippets": {
			"play_sound": {
				"phrases": ["play sound", "sound effect", "sfx"],
				"code": """@export var sound: AudioStream
@onready var _player: AudioStreamPlayer = $AudioStreamPlayer

func play() -> void:
	if sound:
		_player.stream = sound
		_player.play()
""",
				"params": ["sound"],
				"category": "audio",
				"dimension": "any",
				"difficulty": "beginner",
				"param_info": {
					"sound": {
						"default": "",
						"range": [],
						"what": "The AudioStream asset to play.",
						"typical": "a .wav for short effects, .ogg for longer",
						"increase": "N/A",
						"decrease": "N/A"
					}
				},
				"details": {
					"what": "Plays an AudioStream through an AudioStreamPlayer child.",
					"where": "Attach to a node with an AudioStreamPlayer child named 'AudioStreamPlayer'.",
					"before": "Add an AudioStreamPlayer node as a child. Assign a stream in the Inspector.",
					"after": "For spatial (positional) sound in 3D, use sound_effect_3d instead.",
					"why_optimized": "if sound guard prevents an empty-play error.",
					"mistakes": "Playing an already-playing AudioStreamPlayer cuts off the previous sound. Add a second player for overlapping effects.",
					"related": ["play_music", "sound_effect_3d", "audio_bus_volume", "footstep_sound"]
				}
			},
			"play_music": {
				"phrases": ["play music", "background music", "bgm"],
				"code": """@export var music: AudioStream
@onready var _player: AudioStreamPlayer = $MusicPlayer

func _ready() -> void:
	if music:
		_player.stream = music
		_player.play()
""",
				"params": ["music"],
				"category": "audio",
				"dimension": "any",
				"difficulty": "beginner",
				"param_info": {
					"music": {
						"default": "",
						"range": [],
						"what": "The music AudioStream to loop.",
						"typical": ".ogg for long tracks — smaller than .wav",
						"increase": "N/A",
						"decrease": "N/A"
					}
				},
				"details": {
					"what": "Plays background music on _ready. Usually loops automatically.",
					"where": "Attach to a node with an AudioStreamPlayer child named 'MusicPlayer'.",
					"before": "In the stream's import settings, enable Loop.",
					"after": "For global music that persists across scenes, use an autoload instead.",
					"why_optimized": "Auto-plays on _ready, no manual trigger needed.",
					"mistakes": "Forgetting Loop in the .ogg import settings means the track plays once and stops.",
					"related": ["play_sound", "audio_fade", "options_menu"]
				}
			},
			"audio_bus_volume": {
				"phrases": ["audio bus volume", "volume control", "master volume"],
				"code": """func set_bus_volume(bus_name: String, linear_volume: float) -> void:
	var index := AudioServer.get_bus_index(bus_name)
	if index < 0:
		return
	AudioServer.set_bus_volume_db(index, linear_to_db(clamp(linear_volume, 0.0, 1.0)))
""",
				"params": ["bus_name", "linear_volume"],
				"category": "audio",
				"dimension": "any",
				"difficulty": "beginner",
				"param_info": {
					"bus_name": {
						"default": "",
						"range": [],
						"what": "Name of the audio bus. 'Master' is built in; add others in the Audio panel.",
						"typical": "Master, Music, SFX",
						"increase": "N/A",
						"decrease": "N/A"
					},
					"linear_volume": {
						"default": 1.0,
						"range": [0.0, 1.0],
						"what": "Slider value. 0 is silent, 1 is full volume.",
						"typical": "0.0 mute / 0.5 half / 1.0 max",
						"increase": "Louder.",
						"decrease": "Quieter."
					}
				},
				"details": {
					"what": "Sets an audio bus volume from a 0-1 slider value.",
					"where": "Call from your options menu slider's value_changed signal.",
					"before": "Add the bus in Godot's Audio panel (bottom of the editor).",
					"after": "Persist the value with settings_save so it reloads next run.",
					"why_optimized": "linear_to_db converts correctly; clamp prevents invalid input.",
					"mistakes": "Passing the linear value directly without linear_to_db produces a wrong-feeling curve.",
					"related": ["options_menu", "mute_toggle", "settings_save"]
				}
			},
			"sound_effect_3d": {
				"phrases": ["3d sound", "sound effect 3d", "spatial sound"],
				"code": """@export var sound: AudioStream
@onready var _player: AudioStreamPlayer3D = $AudioStreamPlayer3D

func play_3d() -> void:
	if sound:
		_player.stream = sound
		_player.play()
""",
				"params": ["sound"],
				"category": "audio",
				"dimension": "3d",
				"difficulty": "beginner",
				"param_info": {
					"sound": {
						"default": "",
						"range": [],
						"what": "The AudioStream to play in 3D space.",
						"typical": "a .wav for effects",
						"increase": "N/A",
						"decrease": "N/A"
					}
				},
				"details": {
					"what": "Plays a sound that attenuates with distance from the camera.",
					"where": "Attach to a Node3D with an AudioStreamPlayer3D child.",
					"before": "Add an AudioStreamPlayer3D child. Set max_distance and unit_size in the Inspector.",
					"after": "Adjust attenuation model for the desired falloff.",
					"why_optimized": "3D positioning handled by the engine, no manual volume math.",
					"mistakes": "Forgetting to set max_distance means the sound drops off too quickly or too slowly.",
					"related": ["play_sound", "footstep_sound", "first_person_movement"]
				}
			},
			"footstep_sound": {
				"phrases": ["footstep sound", "footsteps", "walk sound"],
				"code": """@export var footstep_interval: float = 0.4
@export var sounds: Array[AudioStream] = []

var _timer: float = 0.0

func _process(delta: float) -> void:
	if velocity.length() < 5.0:
		_timer = 0.0
		return
	_timer += delta
	if _timer >= footstep_interval:
		_timer = 0.0
		_play_random_footstep()

func _play_random_footstep() -> void:
	if sounds.is_empty():
		return
	var stream: AudioStream = sounds.pick_random()
	print("Play footstep: ", stream)
""",
				"params": ["footstep_interval", "sounds"],
				"category": "audio",
				"dimension": "any",
				"difficulty": "intermediate",
				"param_info": {
					"footstep_interval": {
						"default": 0.4,
						"range": [0.1, 1.0],
						"what": "Seconds between footstep sounds while moving.",
						"typical": "0.25 running / 0.4 walking / 0.7 slow",
						"increase": "Slower footsteps — feels more deliberate.",
						"decrease": "Faster — feels like running."
					},
					"sounds": {
						"default": [],
						"range": [],
						"what": "Array of footstep sounds. Pick a few variations to avoid repetition.",
						"typical": "3-5 short clips",
						"increase": "More variety, less noticeable repetition.",
						"decrease": "One sound — clearly loops."
					}
				},
				"details": {
					"what": "Plays a random footstep sound at intervals while the character is moving.",
					"where": "Attach to a CharacterBody2D or CharacterBody3D. Add multiple footstep AudioStreams in the Inspector.",
					"before": "Assign 2+ audio clips to the sounds array.",
					"after": "Replace the print() with your actual AudioStreamPlayer.play().",
					"why_optimized": "velocity.length() check is a single float op — cheap to test every frame.",
					"mistakes": "Using is_action_pressed means the sound plays even when walking against a wall.",
					"related": ["play_sound", "sound_effect_3d", "character_movement_2d"]
				}
			},
			"mute_toggle": {
				"phrases": ["mute toggle", "mute audio", "toggle mute"],
				"code": """func toggle_mute() -> void:
	var bus := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_mute(bus, not AudioServer.is_bus_mute(bus))
""",
				"params": [],
				"category": "audio",
				"dimension": "any",
				"difficulty": "beginner",
				"details": {
					"what": "Flips the mute state of the Master audio bus.",
					"where": "Attach to a settings manager. Call from a mute button.",
					"before": "None.",
					"after": "Read AudioServer.is_bus_mute to show the correct icon on the button.",
					"why_optimized": "Direct AudioServer call — no scene overhead.",
					"mistakes": "Setting the bus volume to 0 instead of muting means the player still hears the mix at volume 0.",
					"related": ["audio_bus_volume", "options_menu", "settings_save"]
				}
			},
			"audio_fade": {
				"phrases": ["audio fade", "fade audio", "fade music"],
				"code": """func fade_audio(player: AudioStreamPlayer, target_db: float, duration: float) -> void:
	var tween := create_tween()
	tween.tween_property(player, "volume_db", target_db, duration)
""",
				"params": ["player", "target_db", "duration"],
				"category": "audio",
				"dimension": "any",
				"difficulty": "beginner",
				"param_info": {
					"player": {
						"default": "",
						"range": [],
						"what": "The AudioStreamPlayer to fade.",
						"typical": "your music player",
						"increase": "N/A",
						"decrease": "N/A"
					},
					"target_db": {
						"default": 0.0,
						"range": [-80.0, 24.0],
						"what": "Target volume in decibels. -80 is effectively silent.",
						"typical": "-80 fade to silence / 0 full / -10 quieter",
						"increase": "Louder target.",
						"decrease": "Quieter target."
					},
					"duration": {
						"default": 1.0,
						"range": [0.1, 10.0],
						"what": "How long the fade takes, in seconds.",
						"typical": "0.3 quick / 1.0 standard / 3.0 cinematic",
						"increase": "Slower, more gradual fade.",
						"decrease": "Faster fade."
					}
				},
				"details": {
					"what": "Fades an AudioStreamPlayer from its current volume to a target over time.",
					"where": "Call from a game manager or from scene transitions.",
					"before": "None.",
					"after": "Chain with await to do something after the fade completes.",
					"why_optimized": "Tween handles interpolation — no _process needed.",
					"mistakes": "Fading to -80 then playing again at -80 means the new track is silent. Reset to 0 before playing.",
					"related": ["play_music", "transition_scene", "audio_bus_volume"]
				}
			}
		}
	}
