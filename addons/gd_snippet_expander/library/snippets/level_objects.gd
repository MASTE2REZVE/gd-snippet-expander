@tool
extends RefCounted


func get_data() -> Dictionary:
	return {
		"version": 2,
		"snippets": {
			"door_2d": {
				"phrases": ["door 2d", "interactable door", "open door", "door open close"],
				"code": """extends Area2D

signal door_opened
signal door_closed

@export var locked: bool = false
@export var required_key: String = ""
@export var open_duration: float = 0.4
@export var auto_close: bool = false

@onready var _sprite: Sprite2D = get_node_or_null("Sprite")

var _is_open: bool = false
var _player_in_range: bool = false
var _tween: Tween = null

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _unhandled_input(event: InputEvent) -> void:
	if _player_in_range and event.is_action_pressed("interact"):
		try_open()

func try_open() -> void:
	if _is_open:
		close()
		return
	if locked:
		if not _check_key():
			return
		locked = false
	open()

func open() -> void:
	if _is_open:
		return
	_is_open = true
	_run_animation(true)
	door_opened.emit()

func close() -> void:
	if not _is_open:
		return
	_is_open = false
	_run_animation(false)
	door_closed.emit()

func _run_animation(opening: bool) -> void:
	if _sprite == null:
		return
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	var target_modulate := Color(1, 1, 1, 0.3) if opening else Color.WHITE
	_tween.tween_property(_sprite, "modulate", target_modulate, open_duration)

func _check_key() -> bool:
	if required_key.is_empty():
		return true
	var inventory = get_tree().get_first_node_in_group("inventory")
	if inventory == null or not inventory.has_method("has_item"):
		return false
	if inventory.has_item(required_key, 1):
		inventory.remove_item(required_key, 1)
		return true
	return false

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_in_range = true

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_in_range = false
		if auto_close and _is_open:
			close()

func is_open() -> bool:
	return _is_open
""",
				"params": ["locked", "required_key", "open_duration", "auto_close"],
				"category": "level",
				"subcategory": "door",
				"platforms": ["desktop", "mobile", "web"],
				"dimension": "2d",
				"difficulty": "beginner",
				"required_actions": ["interact"],
				"param_info": {
					"locked": {
						"default": false,
						"range": [],
						"what": "Whether the door starts locked.",
						"typical": "false normal / true requires key",
						"increase": "N/A",
						"decrease": "N/A"
					},
					"required_key": {
						"default": "",
						"range": [],
						"what": "Item ID required to unlock. Empty means no key needed.",
						"typical": "iron_key / red_keycard / boss_key",
						"increase": "N/A",
						"decrease": "N/A"
					},
					"auto_close": {
						"default": false,
						"range": [],
						"what": "If true, the door closes when the player leaves.",
						"typical": "false for permanent / true for auto-doors",
						"increase": "N/A",
						"decrease": "N/A"
					}
				},
				"details": {
					"what": "An interactable door that opens and closes. Optionally requires a key from the inventory. Emits signals on state change.",
					"where": "Attach to an Area2D with a Sprite2D child. Add the player to group 'player'. Input action 'interact' must exist.",
					"before": "Create an input action 'interact' (E or Space). ItemData for the key if using one.",
					"after": "Replace the alpha fade with a proper door animation by calling AnimationPlayer instead of the tween.",
					"why_optimized": "Tween is cached and killed before reuse. Area detection uses body_entered signals — no polling.",
					"mistakes": "Forgetting to add the player to the 'player' group means interact input never triggers. Forgetting 'interact' action means nothing happens on key press.",
					"related": ["key_pickup", "checkpoint_2d", "switch_2d"]
				}
			},
			"key_pickup": {
				"phrases": ["key pickup", "key item", "collect key", "key drop"],
				"code": """extends Area2D

@export var key_id: String = "iron_key"
@export var unlock_doors_in_group: bool = true

signal key_collected(key_id: String)

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	# Bob the key visually
	var sprite := get_node_or_null("Sprite")
	if sprite != null:
		var t := create_tween().set_loops()
		t.tween_property(sprite, "position:y", -4.0, 0.6).as_relative()
		t.tween_property(sprite, "position:y", 4.0, 0.6).as_relative()

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	var inventory = get_tree().get_first_node_in_group("inventory")
	if inventory != null and inventory.has_method("add_item"):
		inventory.add_item(key_id, 1)
	key_collected.emit(key_id)
	if unlock_doors_in_group:
		_unlock_matching_doors()
	queue_free()

func _unlock_matching_doors() -> void:
	for node in get_tree().get_nodes_in_group("door"):
		if node.get("required_key") == key_id:
			node.set("locked", false)
""",
				"params": ["key_id", "unlock_doors_in_group"],
				"category": "level",
				"subcategory": "key",
				"platforms": ["desktop", "mobile", "web"],
				"dimension": "2d",
				"difficulty": "beginner",
				"param_info": {
					"key_id": {
						"default": "iron_key",
						"range": [],
						"what": "Item ID added to the inventory when picked up.",
						"typical": "iron_key / red_keycard / boss_key",
						"increase": "N/A",
						"decrease": "N/A"
					},
					"unlock_doors_in_group": {
						"default": true,
						"range": [],
						"what": "Automatically unlock all doors in group 'door' that require this key.",
						"typical": "true convenient / false requires manual unlock logic",
						"increase": "N/A",
						"decrease": "N/A"
					}
				},
				"details": {
					"what": "Pickup that adds a key to the inventory and optionally unlocks matching doors. Has a gentle bob animation.",
					"where": "Attach to an Area2D with a Sprite2D child. Add the player to group 'player'. Doors that use this key must be in group 'door'.",
					"before": "Register the key item with the inventory system. Add doors to the 'door' group in the Inspector.",
					"after": "Add a pickup sound and particle sparkle. See particle_sparkle for the effect.",
					"why_optimized": "Unlock scan is a single group iteration. Looping bob tween is created once and reused.",
					"mistakes": "Forgetting to add doors to the 'door' group means the auto-unlock doesn't find them.",
					"related": ["door_2d", "inventory_grid", "particle_sparkle"]
				}
			},
			"switch_2d": {
				"phrases": ["switch 2d", "lever", "toggle switch", "flip switch"],
				"code": """extends Area2D

signal switched_on
signal switched_off

@export var starts_on: bool = false
@export var toggle_cooldown: float = 0.3
@export var one_shot: bool = false

@onready var _sprite: Sprite2D = get_node_or_null("Sprite")

var _is_on: bool = false
var _player_in_range: bool = false
var _cooldown_timer: float = 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_is_on = starts_on
	_update_visual()

func _unhandled_input(event: InputEvent) -> void:
	if _player_in_range and event.is_action_pressed("interact"):
		toggle()

func _process(delta: float) -> void:
	if _cooldown_timer > 0.0:
		_cooldown_timer -= delta

func toggle() -> void:
	if _cooldown_timer > 0.0:
		return
	if one_shot and _is_on:
		return
	_cooldown_timer = toggle_cooldown
	_is_on = not _is_on
	_update_visual()
	if _is_on:
		switched_on.emit()
	else:
		switched_off.emit()

func _update_visual() -> void:
	if _sprite == null:
		return
	_sprite.modulate = Color(1.3, 1.3, 0.7) if _is_on else Color.WHITE

func is_on() -> bool:
	return _is_on

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_in_range = true

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_in_range = false
""",
				"params": ["starts_on", "toggle_cooldown", "one_shot"],
				"category": "level",
				"subcategory": "switch",
				"platforms": ["desktop", "mobile", "web"],
				"dimension": "2d",
				"difficulty": "beginner",
				"required_actions": ["interact"],
				"param_info": {
					"starts_on": {
						"default": false,
						"range": [],
						"what": "Whether the switch starts in the on position.",
						"typical": "false for 'find and flip' / true for already-active",
						"increase": "N/A",
						"decrease": "N/A"
					},
					"toggle_cooldown": {
						"default": 0.3,
						"range": [0.1, 2.0],
						"what": "Seconds before the switch can be flipped again.",
						"typical": "0.3 standard / 1.0 prevents spam",
						"increase": "Slower toggle.",
						"decrease": "Faster."
					},
					"one_shot": {
						"default": false,
						"range": [],
						"what": "True means the switch can only turn on, never off.",
						"typical": "false normal / true for puzzles that need permanent state",
						"increase": "N/A",
						"decrease": "N/A"
					}
				},
				"details": {
					"what": "Interactable switch or lever. Emits signals when toggled. Can connect to doors, platforms, or anything you want to activate.",
					"where": "Attach to an Area2D with a Sprite2D child. Add to group 'player' setup, and connect to whatever the switch controls.",
					"before": "Input action 'interact'. Player in group 'player'.",
					"after": "Connect switched_on to open a door, start a moving platform, or trigger a boss encounter.",
					"why_optimized": "Cooldown timer is a simple float. Signal emission means no per-frame checks on connected nodes.",
					"mistakes": "Forgetting the cooldown lets a player toggle the switch dozens of times per second.",
					"related": ["door_2d", "pressure_plate", "moving_platform"]
				}
			},
			"pressure_plate": {
				"phrases": ["pressure plate", "button plate", "step plate", "weight switch"],
				"code": """extends Area2D

signal plate_pressed
signal plate_released

@export var requires_weight: int = 1
@export var hold_time: float = 0.0

@onready var _sprite: Sprite2D = get_node_or_null("Sprite")

var _bodies_on_plate: Array = []
var _is_pressed: bool = false
var _release_timer: float = 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(delta: float) -> void:
	if _release_timer > 0.0:
		_release_timer -= delta
		if _release_timer <= 0.0:
			_check_release()

func _on_body_entered(body: Node2D) -> void:
	if not _bodies_on_plate.has(body):
		_bodies_on_plate.append(body)
	_check_press()

func _on_body_exited(body: Node2D) -> void:
	_bodies_on_plate.erase(body)
	if hold_time > 0.0:
		_release_timer = hold_time
	else:
		_check_release()

func _check_press() -> void:
	if _is_pressed:
		return
	if _bodies_on_plate.size() >= requires_weight:
		_is_pressed = true
		_update_visual()
		plate_pressed.emit()

func _check_release() -> void:
	if not _is_pressed:
		return
	if _bodies_on_plate.size() < requires_weight:
		_is_pressed = false
		_update_visual()
		plate_released.emit()

func _update_visual() -> void:
	if _sprite == null:
		return
	_sprite.position.y = 2.0 if _is_pressed else 0.0

func is_pressed() -> bool:
	return _is_pressed

func body_count() -> int:
	return _bodies_on_plate.size()
""",
				"params": ["requires_weight", "hold_time"],
				"category": "level",
				"subcategory": "switch",
				"platforms": ["desktop", "mobile", "web"],
				"dimension": "2d",
				"difficulty": "beginner",
				"param_info": {
					"requires_weight": {
						"default": 1,
						"range": [1, 10],
						"what": "How many bodies must be on the plate to trigger it.",
						"typical": "1 player / 2 player + crate / 5 group puzzle",
						"increase": "Needs more weight.",
						"decrease": "Easier to trigger."
					},
					"hold_time": {
						"default": 0.0,
						"range": [0.0, 10.0],
						"what": "Seconds the plate stays pressed after the body leaves.",
						"typical": "0.0 instant / 1.0 generous / 5.0+ puzzle timer",
						"increase": "Longer grace period.",
						"decrease": "Faster release."
					}
				},
				"details": {
					"what": "Area2D that presses when a body steps on it. Supports multiple required bodies for crate puzzles. Optional grace period before release.",
					"where": "Attach to an Area2D with a CollisionShape2D and optionally a Sprite2D child.",
					"before": "None.",
					"after": "Connect plate_pressed to open a door or activate a mechanism. Connect plate_released to close it.",
					"why_optimized": "Only checks state changes, not every frame. Body list is a plain Array.",
					"mistakes": "Not using a grace period means the plate releases the instant the player steps off, which feels glitchy for fast-paced puzzles.",
					"related": ["switch_2d", "door_2d", "moving_platform"]
				}
			},
			"checkpoint_2d": {
				"phrases": ["checkpoint", "checkpoint 2d", "save point", "respawn point"],
				"code": """extends Area2D

signal checkpoint_activated(position: Vector2)

@export var checkpoint_id: String = "checkpoint_1"
@export var respawn_offset: Vector2 = Vector2(0, -16)

@onready var _sprite: Sprite2D = get_node_or_null("Sprite")

var _activated: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	add_to_group("checkpoint")

func _on_body_entered(body: Node2D) -> void:
	if _activated:
		return
	if not body.is_in_group("player"):
		return
	_activated = true
	_update_visual()
	var save_position := global_position + respawn_offset
	checkpoint_activated.emit(save_position)
	_save_checkpoint(save_position)

func _save_checkpoint(save_position: Vector2) -> void:
	var checkpoint_manager = get_tree().get_first_node_in_group("checkpoint_manager")
	if checkpoint_manager != null and checkpoint_manager.has_method("set_respawn_point"):
		checkpoint_manager.set_respawn_point(checkpoint_id, save_position)
		return
	# Fallback: store on the player directly
	var player = get_tree().get_first_node_in_group("player")
	if player != null and player.has_method("set_respawn_point"):
		player.set_respawn_point(save_position)

func _update_visual() -> void:
	if _sprite == null:
		return
	_sprite.modulate = Color(0.5, 1.0, 0.5)

func is_activated() -> bool:
	return _activated

func force_activate() -> void:
	_activated = true
	_update_visual()
""",
				"params": ["checkpoint_id", "respawn_offset"],
				"category": "level",
				"subcategory": "checkpoint",
				"platforms": ["desktop", "mobile", "web"],
				"dimension": "2d",
				"difficulty": "beginner",
				"param_info": {
					"checkpoint_id": {
						"default": "checkpoint_1",
						"range": [],
						"what": "Unique identifier for this checkpoint, used in save files.",
						"typical": "level_1_start / boss_door / secret_room",
						"increase": "N/A",
						"decrease": "N/A"
					},
					"respawn_offset": {
						"default": [0, -16],
						"range": [],
						"what": "Offset from the checkpoint position where the player respawns.",
						"typical": "[0, -16] slightly above / [0, 0] exactly at position",
						"increase": "Higher respawn.",
						"decrease": "Lower."
					}
				},
				"details": {
					"what": "Checkpoint that updates the player's respawn position. Activates once and stays active. Can persist across saves.",
					"where": "Attach to an Area2D with a CollisionShape2D. Optional Sprite2D child changes color when activated.",
					"before": "Player in group 'player'. Optionally a checkpoint manager in group 'checkpoint_manager' that stores respawn points.",
					"after": "Combine with save_game to store activated checkpoints in the save file, and force_activate() on load to restore them.",
					"why_optimized": "Only fires once per checkpoint. Signal-based, no polling. add_to_group means the manager can find all checkpoints at load.",
					"mistakes": "Not storing checkpoints in the save file means the player respawns at the level start after loading. Call force_activate() on matching IDs during load.",
					"related": ["respawn", "save_game", "load_game", "checkpoint_manager"]
				}
			},
			"checkpoint_manager": {
				"phrases": ["checkpoint manager", "respawn manager", "checkpoint autoload", "save respawn"],
				"code": """extends Node

signal respawn_point_changed(checkpoint_id: String, position: Vector2)

var current_checkpoint_id: String = ""
var current_respawn_position: Vector2 = Vector2.ZERO
var activated_checkpoints: Dictionary = {}

func _ready() -> void:
	add_to_group("checkpoint_manager")

func set_respawn_point(checkpoint_id: String, position: Vector2) -> void:
	activated_checkpoints[checkpoint_id] = position
	current_checkpoint_id = checkpoint_id
	current_respawn_position = position
	respawn_point_changed.emit(checkpoint_id, position)
	save_to_config()

func get_respawn_position() -> Vector2:
	return current_respawn_position

func has_checkpoint() -> bool:
	return not current_checkpoint_id.is_empty()

func is_checkpoint_activated(checkpoint_id: String) -> bool:
	return activated_checkpoints.has(checkpoint_id)

func save_to_config() -> void:
	var cfg := ConfigFile.new()
	cfg.load("user://checkpoints.cfg")
	cfg.set_value("checkpoint", "current_id", current_checkpoint_id)
	cfg.set_value("checkpoint", "position", current_respawn_position)
	for id in activated_checkpoints.keys():
		cfg.set_value("activated", str(id), true)
	cfg.save("user://checkpoints.cfg")

func load_from_config() -> void:
	var cfg := ConfigFile.new()
	if cfg.load("user://checkpoints.cfg") != OK:
		return
	current_checkpoint_id = cfg.get_value("checkpoint", "current_id", "")
	current_respawn_position = cfg.get_value("checkpoint", "position", Vector2.ZERO)
	activated_checkpoints.clear()
	for key in cfg.get_section_keys("activated"):
		activated_checkpoints[key] = true

func clear_all() -> void:
	current_checkpoint_id = ""
	current_respawn_position = Vector2.ZERO
	activated_checkpoints.clear()
	var cfg := ConfigFile.new()
	cfg.save("user://checkpoints.cfg")
""",
				"params": [],
				"category": "level",
				"subcategory": "checkpoint",
				"platforms": ["desktop", "mobile", "web"],
				"dimension": "any",
				"difficulty": "intermediate",
				"details": {
					"what": "Autoload that tracks the player's current respawn point and which checkpoints have been activated. Persists to a config file.",
					"where": "Add as an autoload named 'CheckpointManager'. The checkpoint_2d snippet will find it automatically via the group.",
					"before": "None.",
					"after": "On game load, call load_from_config() to restore checkpoints, then call force_activate() on each restored checkpoint node.",
					"why_optimized": "ConfigFile is human-readable and typed. Only writes on change, not every frame.",
					"mistakes": "Forgetting to call load_from_config() at game start means checkpoints never restore from the save file.",
					"related": ["checkpoint_2d", "respawn", "save_game", "config_file"]
				}
			}
		}
	}
