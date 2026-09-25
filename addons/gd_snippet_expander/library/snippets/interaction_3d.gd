@tool
extends RefCounted


func get_data() -> Dictionary:
	return {
		"version": 2,
		"snippets": {
			"raycast_interact_3d": {
				"phrases": ["raycast interact 3d", "interact 3d", "fps interact", "look at interact"],
				"code": """extends Camera3D

signal interactable_targeted(target: Node3D)
signal interactable_lost

@export var interact_range: float = 3.0
@export var interact_action: String = "interact"
@export var interaction_layers: int = 1

var _current_target: Node3D = null

func _physics_process(_delta: float) -> void:
	var target := _cast_for_interactable()
	if target != _current_target:
		if _current_target != null:
			interactable_lost.emit()
		_current_target = target
		if target != null:
			interactable_targeted.emit(target)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(interact_action) and _current_target != null:
		if _current_target.has_method("interact"):
			_current_target.interact(self)

func _cast_for_interactable() -> Node3D:
	var space := get_world_3d().direct_space_state
	var from := global_position
	var to := from + (-global_transform.basis.z) * interact_range
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = interaction_layers
	query.collide_with_areas = true
	query.collide_with_bodies = true
	var result := space.intersect_ray(query)
	if result.is_empty():
		return null
	var collider = result.get("collider")
	if collider is Node3D and collider.has_method("interact"):
		return collider as Node3D
	return null

func get_current_target() -> Node3D:
	return _current_target
""",
				"params": ["interact_range", "interact_action", "interaction_layers"],
				"category": "interaction",
				"subcategory": "3d",
				"platforms": ["desktop", "mobile", "web"],
				"dimension": "3d",
				"difficulty": "intermediate",
				"required_actions": ["interact"],
				"param_info": {
					"interact_range": {
						"default": 3.0,
						"range": [1.0, 10.0],
						"what": "How far the player can reach to interact, in meters.",
						"typical": "1.5 melee / 3.0 standard / 8.0+ long reach",
						"increase": "Reaches further.",
						"decrease": "Closer."
					},
					"interaction_layers": {
						"default": 1,
						"range": [],
						"what": "Collision layer mask for interactables.",
						"typical": "1 default / 2 interactable / 4 + 8 combos",
						"increase": "N/A",
						"decrease": "N/A"
					}
				},
				"details": {
					"what": "Raycast from the camera to find interactable objects. Emits signals when the target changes and calls interact() on key press.",
					"where": "Attach to the active Camera3D. Interactable objects need an interact() method and matching collision layer.",
					"before": "Input action 'interact'. Objects with interact() method and collision setup.",
					"after": "Show a crosshair change or a floating prompt when interactable_targeted fires.",
					"why_optimized": "Physics raycast runs once per frame. Uses collision layer filtering to keep the query cheap.",
					"mistakes": "Not setting collision layers on interactable objects means the ray never hits them. Verify masks match.",
					"related": ["interactable_3d", "interaction_prompt_3d", "first_person_movement"]
				}
			},
			"interactable_3d": {
				"phrases": ["interactable 3d", "3d interactable object", "base interactable 3d", "custom interact"],
				"code": """extends StaticBody3D

signal interacted(by: Node3D)

@export var interaction_name: String = "Interact"
@export var one_time: bool = false
@export var required_item: String = ""

var _has_been_used: bool = false

func interact(by: Node3D) -> void:
	if one_time and _has_been_used:
		return
	if not required_item.is_empty() and not _has_item(by, required_item):
		return
	_has_been_used = true
	_on_interact(by)
	interacted.emit(by)

func _on_interact(_by: Node3D) -> void:
	# Override this method in subclasses or via the editor
	print("Interacted with ", name)

func _has_item(by: Node3D, item_id: String) -> bool:
	if by.has_method("has_item"):
		return bool(by.call("has_item", item_id))
	var inventory = get_tree().get_first_node_in_group("inventory")
	if inventory != null and inventory.has_method("has_item"):
		return bool(inventory.call("has_item", item_id))
	return false

func get_interaction_name() -> String:
	return interaction_name

func can_interact() -> bool:
	return not (one_time and _has_been_used)

func was_used() -> bool:
	return _has_been_used
""",
				"params": ["interaction_name", "one_time", "required_item"],
				"category": "interaction",
				"subcategory": "3d",
				"platforms": ["desktop", "mobile", "web"],
				"dimension": "3d",
				"difficulty": "beginner",
				"param_info": {
					"interaction_name": {
						"default": "Interact",
						"range": [],
						"what": "Label shown in the interaction prompt.",
						"typical": "Open / Pick Up / Activate / Read / Pull Lever",
						"increase": "N/A",
						"decrease": "N/A"
					},
					"one_time": {
						"default": false,
						"range": [],
						"what": "If true, the object can only be used once.",
						"typical": "false for reusable / true for chests, cutscenes",
						"increase": "N/A",
						"decrease": "N/A"
					},
					"required_item": {
						"default": "",
						"range": [],
						"what": "Item ID required in inventory to interact. Empty means no requirement.",
						"typical": "iron_key / red_card / boss_sigil",
						"increase": "N/A",
						"decrease": "N/A"
					}
				},
				"details": {
					"what": "Base class for interactable 3D objects. Extend _on_interact() to define what happens when the player interacts.",
					"where": "Attach to a StaticBody3D or Area3D that has a collision shape and the interaction collision layer.",
					"before": "Interaction layer assigned. Player's raycast_interact_3d should target this layer.",
					"after": "Extend the class in a separate script: 'extends Interactable3D' or 'extends \"res://.../interactable_3d.gd\"'.",
					"why_optimized": "Single method call from the player's raycast. No per-frame processing.",
					"mistakes": "Not setting the object's collision layer to match the interact raycast means the ray passes through.",
					"related": ["raycast_interact_3d", "interaction_prompt_3d", "door_3d", "switch_3d"]
				}
			},
			"interaction_prompt_3d": {
				"phrases": ["interaction prompt 3d", "3d interact prompt", "show interact hint 3d", "3d prompt"],
				"code": """extends CanvasLayer

@onready var _label: Label = $Panel/Label

@export var prompt_offset: Vector3 = Vector3(0, 0.5, 0)

var _current_target: Node3D = null
var _camera: Camera3D = null

func _ready() -> void:
	visible = false
	_camera = get_viewport().get_camera_3d()

func show_prompt(target: Node3D, action_name: String) -> void:
	_current_target = target
	_label.text = "[" + InputMap.action_get_events("interact")[0].as_text() + "] " + action_name
	visible = true

func hide_prompt() -> void:
	_current_target = null
	visible = false

func _process(_delta: float) -> void:
	if _current_target == null or _camera == null:
		return
	if not is_instance_valid(_current_target):
		hide_prompt()
		return
	var world_pos: Vector3 = _current_target.global_position + prompt_offset
	if _camera.is_position_behind(world_pos):
		visible = false
		return
	visible = true
	var screen_pos := _camera.unproject_position(world_pos)
	$Panel.position = screen_pos - $Panel.size * 0.5
""",
				"params": ["prompt_offset"],
				"category": "interaction",
				"subcategory": "3d",
				"platforms": ["desktop", "mobile", "web"],
				"dimension": "ui",
				"difficulty": "intermediate",
				"param_info": {
					"prompt_offset": {
						"default": [0, 0.5, 0],
						"range": [],
						"what": "Offset from the interactable's origin to show the prompt.",
						"typical": "[0, 0.5, 0] above object / [0, 1.5, 0] high above",
						"increase": "Higher.",
						"decrease": "Lower."
					}
				},
				"details": {
					"what": "HUD prompt that follows the targeted interactable in screen space. Reads the interact input's action name.",
					"where": "Attach to a CanvasLayer with a Panel → Label child. Connect the raycast_interact_3d's signals to show_prompt / hide_prompt.",
					"before": "Panel and Label nodes in the CanvasLayer. Input action 'interact' exists.",
					"after": "Add a small bob or fade animation for polish. Use InputMap.action_get_events for the key hint.",
					"why_optimized": "Only processes when a target is set. Behind-camera check prevents offscreen prompts.",
					"mistakes": "Prompt shows through walls because there's no occlusion check. For a full solution, raycast back to the object.",
					"related": ["raycast_interact_3d", "interactable_3d", "topdown_interaction_prompt"]
				}
			},
			"door_3d": {
				"phrases": ["door 3d", "3d door", "interactable door 3d", "open door 3d"],
				"code": """extends Node3D

signal door_opened
signal door_closed

@export var locked: bool = false
@export var required_key: String = ""
@export var open_angle: float = 90.0
@export var open_duration: float = 0.6

@onready var _hinge: Node3D = get_node_or_null("Hinge")

var _is_open: bool = false

func interact(by: Node3D) -> void:
	if _is_open:
		_close()
		return
	if locked:
		if not _check_key(by):
			return
		locked = false
	_open()

func _open() -> void:
	if _is_open or _hinge == null:
		return
	_is_open = true
	var target := deg_to_rad(open_angle)
	var tween := create_tween()
	tween.tween_property(_hinge, "rotation:y", target, open_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	await tween.finished
	door_opened.emit()

func _close() -> void:
	if not _is_open or _hinge == null:
		return
	_is_open = false
	var tween := create_tween()
	tween.tween_property(_hinge, "rotation:y", 0.0, open_duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	await tween.finished
	door_closed.emit()

func _check_key(by: Node3D) -> bool:
	if required_key.is_empty():
		return true
	if by.has_method("has_item") and by.call("has_item", required_key):
		return true
	var inventory = get_tree().get_first_node_in_group("inventory")
	if inventory != null and inventory.has_method("has_item"):
		return bool(inventory.call("has_item", required_key))
	return false

func is_open() -> bool:
	return _is_open

# NODE SETUP
# Door (Node3D) — this script
#   Hinge (Node3D) — rotates
#     DoorMesh (MeshInstance3D)
#     CollisionBody (StaticBody3D)
#       CollisionShape3D
#
# The Hinge node should be positioned at the edge of the door so it
# swings from that point.
""",
				"params": ["locked", "required_key", "open_angle", "open_duration"],
				"category": "interaction",
				"subcategory": "3d",
				"platforms": ["desktop", "mobile", "web"],
				"dimension": "3d",
				"difficulty": "intermediate",
				"param_info": {
					"open_angle": {
						"default": 90.0,
						"range": [45.0, 180.0],
						"what": "How far the door swings, in degrees.",
						"typical": "90 standard / 180 wide arch / 45 partial",
						"increase": "Swing wider.",
						"decrease": "Swing less."
					},
					"open_duration": {
						"default": 0.6,
						"range": [0.1, 3.0],
						"what": "Seconds to open or close.",
						"typical": "0.3 quick / 0.6 standard / 1.5 heavy",
						"increase": "Slower.",
						"decrease": "Faster."
					}
				},
				"details": {
					"what": "Interactable 3D door that swings open. Supports locked state with a required key.",
					"where": "Attach to a Node3D with a Hinge Node3D child containing the mesh and collision. Player must have the raycast_interact_3d snippet.",
					"before": "Door mesh and collision under the Hinge node. Interaction collision layer set.",
					"after": "Add creaking sound and dust particles when the door opens.",
					"why_optimized": "Tween rotates the hinge. No physics — the door collision moves with the visual.",
					"mistakes": "Placing the Hinge at the door's center makes it spin in place instead of swinging from the edge.",
					"related": ["interactable_3d", "key_pickup", "raycast_interact_3d"]
				}
			},
			"switch_3d": {
				"phrases": ["switch 3d", "3d switch", "lever 3d", "button 3d"],
				"code": """extends Node3D

signal switched_on
signal switched_off

@export var starts_on: bool = false
@export var toggle_cooldown: float = 0.3
@export var one_shot: bool = false
@export var rotate_on_axis: Vector3 = Vector3(1, 0, 0)
@export var rotate_angle: float = 45.0

@onready var _handle: Node3D = get_node_or_null("Handle")

var _is_on: bool = false
var _cooldown_timer: float = 0.0
var _base_rotation: Vector3 = Vector3.ZERO

func _ready() -> void:
	_is_on = starts_on
	if _handle != null:
		_base_rotation = _handle.rotation
	_apply_visual()

func interact(_by: Node3D) -> void:
	if _cooldown_timer > 0.0:
		return
	if one_shot and _is_on:
		return
	_cooldown_timer = toggle_cooldown
	_is_on = not _is_on
	_apply_visual()
	if _is_on:
		switched_on.emit()
	else:
		switched_off.emit()

func _process(delta: float) -> void:
	if _cooldown_timer > 0.0:
		_cooldown_timer -= delta

func _apply_visual() -> void:
	if _handle == null:
		return
	var target := _base_rotation
	if _is_on:
		target += rotate_on_axis.normalized() * deg_to_rad(rotate_angle)
	var tween := create_tween()
	tween.tween_property(_handle, "rotation", target, 0.15).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func is_on() -> bool:
	return _is_on
""",
				"params": ["starts_on", "toggle_cooldown", "one_shot", "rotate_angle"],
				"category": "interaction",
				"subcategory": "3d",
				"platforms": ["desktop", "mobile", "web"],
				"dimension": "3d",
				"difficulty": "beginner",
				"param_info": {
					"starts_on": {
						"default": false,
						"range": [],
						"what": "Whether the switch starts in the on state.",
						"typical": "false normal / true already-active",
						"increase": "N/A",
						"decrease": "N/A"
					},
					"rotate_angle": {
						"default": 45.0,
						"range": [10.0, 90.0],
						"what": "Degrees the handle rotates when toggled.",
						"typical": "30 small lever / 45 standard / 90 large throw",
						"increase": "Bigger rotation.",
						"decrease": "Smaller."
					}
				},
				"details": {
					"what": "Interactable 3D switch or lever. Rotates the Handle child when toggled. Emits switched_on / switched_off signals.",
					"where": "Attach to a Node3D with a Handle Node3D child containing the visual. Player needs raycast_interact_3d.",
					"before": "Switch mesh under a Handle node. Interaction collision layer set.",
					"after": "Connect switched_on to doors, platforms, or lights.",
					"why_optimized": "Tween handles the rotation. Cooldown prevents spam-toggling.",
					"mistakes": "Forgetting to set the interaction collision layer means the raycast never finds the switch.",
					"related": ["interactable_3d", "door_3d", "raycast_interact_3d"]
				}
			}
		}
	}
