# res://addons/gd_snippet_expander/ai_debugger/fix_library_data_e.gd
@tool
class_name FixLibraryDataE
extends RefCounted

## Fix records, volume E: syntax pitfalls and Godot 3->4 migration.
##
## Part of the GD Snippet Expander mini AI debugger (v1.6).
## Twenty-four curated records covering GDScript syntax traps and
## the API renames that trip up anyone bringing Godot 3 code
## forward into Godot 4.
##
## Usage from the plugin loader:
##   var lib := FixLibrary.new()
##   lib.load_all()
##   FixLibraryDataA.register_into(lib)
##   FixLibraryDataB.register_into(lib)
##   FixLibraryDataC.register_into(lib)
##   FixLibraryDataD.register_into(lib)
##   FixLibraryDataE.register_into(lib)   # this file

# --- public entry points -----------------------------------------------

static func register_into(lib: FixLibrary) -> int:
	return lib.register_records(records())


static func records() -> Array:
	var out: Array = []

	# ===================================================================
	# SYNTAX (10)
	# ===================================================================

	out.append({
		"id": "syntax_missing_colon",
		"title": "Missing colon after if / for / while / func",
		"category": "syntax",
		"phrases": [
			"missing colon",
			"expected colon",
			"syntax error after if",
			"parse error colon",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "if"},
			{"kind": "substring", "value": ":"}
		],
		"candidates": [{
			"code": "if condition:\n\tpass\n\nfor i in range(10):\n\tpass\n\nwhile running:\n\tpass\n\nfunc do_thing() -> void:\n\tpass\n",
			"description": "Every block-opening statement needs a colon before the body: if, elif, else, for, while, match, func, class, and match's case patterns.",
			"confidence": 0.85,
		}],
	})

	out.append({
		"id": "syntax_indentation_mixed",
		"title": "Mixed tabs and spaces cause indentation errors",
		"category": "syntax",
		"phrases": [
			"unexpected indent",
			"inconsistent indentation",
			"tabs vs spaces",
			"indentation error",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "indent"}
		],
		"candidates": [{
			"code": "# GDScript 4 accepts EITHER tabs OR spaces, not both.\n# In Editor Settings -> Text Editor -> Indent:\n#   Type: Tabs\n#   Size: 4\n# Then re-indent the whole file with Ctrl+Shift+I (or Cmd on Mac).\n",
			"description": "Mixing tabs and spaces on the same line or across a block throws a parse error. Pick one and stick with it. Godot's default is tabs.",
			"confidence": 0.82,
		}],
	})

	out.append({
		"id": "syntax_string_concat_types",
		"title": "Concatenating a string with a non-string errors",
		"category": "syntax",
		"phrases": [
			"can't concatenate string",
			"string plus int",
			"string concatenation error",
			"invalid operands string",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "str("},
			{"kind": "substring", "value": "+", "negate": false},
		],
		"candidates": [{
			"code": "var count: int = 5\n# Wrong:\n# var s: String = \"Count: \" + count\n# Right:\nvar s: String = \"Count: \" + str(count)\n# Or use format:\nvar s2: String = \"Count: %d\" % count\n",
			"description": "GDScript 4 doesn't auto-coerce int/float to String in a + expression. Wrap the value in str() or use % formatting.",
			"confidence": 0.80,
		}],
	})

	out.append({
		"id": "syntax_int_division",
		"title": "Integer division truncates",
		"category": "syntax",
		"phrases": [
			"division gives wrong result",
			"5 divided by 2 is 2",
			"integer division",
			"loses decimal",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "/"}
		],
		"candidates": [{
			"code": "# In GDScript, int / int = int (truncated):\nvar half_wrong: int = 5 / 2       # == 2\n# Cast to float first for a decimal result:\nvar half_right: float = 5.0 / 2.0 # == 2.5\nvar half_alt: float = float(5) / 2.0\n",
			"description": "int / int does integer division. If you need a decimal result, make one of the operands a float.",
			"confidence": 0.78,
		}],
	})

	out.append({
		"id": "syntax_array_dict_literal",
		"title": "Array and Dictionary literal syntax",
		"category": "syntax",
		"phrases": [
			"array syntax",
			"dictionary syntax",
			"dict literal",
			"array literal",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "[]"},
			{"kind": "identifier", "value": "{}"},
		],
		"candidates": [{
			"code": "var arr: Array = [1, 2, 3]\nvar dict: Dictionary = {\"key\": \"value\", \"count\": 5}\nvar nested: Dictionary = {\n\t\"player\": {\"hp\": 100, \"name\": \"Hero\"},\n\t\"enemies\": [\"goblin\", \"orc\"],\n}\n",
			"description": "Square brackets for arrays, curly braces for dictionaries. Trailing commas are allowed and encouraged for multi-line literals.",
			"confidence": 0.75,
		}],
	})

	out.append({
		"id": "syntax_for_loop_modification",
		"title": "Modifying an array while iterating it",
		"category": "syntax",
		"phrases": [
			"modify array in loop",
			"remove in for loop",
			"iterator invalidated",
			"skip elements in loop",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "for"},
			{"kind": "identifier", "value": "remove_at"},
		],
		"candidates": [{
			"code": "# Don't remove during iteration — skip elements get skipped.\n# Iterate backwards:\nfor i in range(arr.size() - 1, -1, -1):\n\tif arr[i].should_remove:\n\t\tarr.remove_at(i)\n# Or collect then remove:\nvar to_remove: Array = []\nfor item in arr:\n\tif item.should_remove:\n\t\tto_remove.append(item)\nfor item in to_remove:\n\tarr.erase(item)\n",
			"description": "Modifying an array during a for loop shifts indices and can skip elements. Iterate backwards or collect removals first.",
			"confidence": 0.75,
		}],
	})

	out.append({
		"id": "syntax_match_wildcard",
		"title": "match with no wildcard falls through silently",
		"category": "syntax",
		"phrases": [
			"match no case matched",
			"match does nothing",
			"missing wildcard",
			"match exhaustiveness",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "match"},
			{"kind": "identifier", "value": "_", "negate": true},
		],
		"candidates": [{
			"code": "match state:\n\tState.IDLE:\n\t\tpass\n\tState.WALK:\n\t\tpass\n\t_:\n\t\tpush_warning(\"unexpected state: %s\" % state)\n",
			"description": "If nothing matches and there's no `_:` wildcard, the match block does nothing. Add a wildcard case to catch unexpected values.",
			"confidence": 0.72,
		}],
	})

	out.append({
		"id": "syntax_unreachable_after_return",
		"title": "Code after return is unreachable",
		"category": "syntax",
		"phrases": [
			"unreachable code",
			"code after return",
			"function returns early",
			"dead code after return",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "return"}
		],
		"candidates": [{
			"code": "func do_thing() -> int:\n\tif condition:\n\t\treturn 1\n\treturn 2   # this line is fine — the if returns early\n\n# NOT:\n# return 1\n# print(\"never runs\")   # unreachable\n",
			"description": "Anything after an unconditional return in the same block never runs. Move it before the return or restructure the logic.",
			"confidence": 0.72,
		}],
	})

	out.append({
		"id": "syntax_function_no_return",
		"title": "Function declared to return a value but doesn't",
		"category": "syntax",
		"phrases": [
			"function missing return",
			"return type but no return",
			"not all paths return",
			"missing return statement",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "->"},
		],
		"candidates": [{
			"code": "func get_value() -> int:\n\tif ready:\n\t\treturn cached_value\n\treturn 0   # default fallback\n",
			"description": "If a function declares a return type, every code path must return a value. Add a fallback return at the end.",
			"confidence": 0.78,
		}],
	})

	out.append({
		"id": "syntax_parentheses_required",
		"title": "Function call needs parentheses",
		"category": "syntax",
		"phrases": [
			"call function no parens",
			"missing parentheses",
			"function call syntax",
			"call method",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "func"}
		],
		"candidates": [{
			"code": "# Wrong:\n# reset_position\n# Right:\nreset_position()\n\n# Calling without parens passes the method as a Callable, which is\n# rarely what beginners want:\nvar method_ref: Callable = reset_position   # no call\n",
			"description": "A bare identifier that names a method is a Callable reference. Add () to actually call it.",
			"confidence": 0.75,
		}],
	})

	# ===================================================================
	# MISC (14) — Godot 3 -> 4 migration and API renames
	# ===================================================================

	out.append({
		"id": "misc_godot4_signal_connect_string",
		"title": "Old string-based signal connect no longer works",
		"category": "misc",
		"phrases": [
			"connect with string",
			"old connect syntax",
			"signal connect string form",
			"godot 3 connect",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "connect"},
			{"kind": "substring", "value": "\"", "negate": false},
		],
		"candidates": [{
			"code": "# Wrong (Godot 3):\n# button.connect(\"pressed\", self, \"_on_pressed\")\n# Right (Godot 4):\nbutton.pressed.connect(_on_pressed)\n",
			"description": "Godot 4 signals are first-class objects. Use signal_name.connect(callable) instead of the old string-based form.",
			"confidence": 0.85,
		}],
	})

	out.append({
		"id": "misc_godot4_instance_renamed",
		"title": "instance() renamed to instantiate()",
		"category": "misc",
		"phrases": [
			"instance not found",
			"instance method missing",
			"packed scene instance",
			"godot 3 instance",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "instance"},
		],
		"candidates": [{
			"code": "# Wrong (Godot 3):\n# var node = scene.instance()\n# Right (Godot 4):\nvar node: Node = scene.instantiate()\n",
			"description": "PackedScene.instance() was renamed to instantiate() in Godot 4. All call sites need the rename.",
			"confidence": 0.82,
		}],
	})

	out.append({
		"id": "misc_godot4_yield_to_await",
		"title": "yield() replaced with await",
		"category": "misc",
		"phrases": [
			"yield deprecated",
			"yield not found",
			"old yield syntax",
			"godot 3 yield",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "yield"},
		],
		"candidates": [{
			"code": "# Wrong (Godot 3):\n# yield(get_tree().create_timer(1.0), \"timeout\")\n# Right (Godot 4):\nawait get_tree().create_timer(1.0).timeout\n",
			"description": "yield() was replaced by await. The new form is `await signal` or `await signal_object.signal_name`.",
			"confidence": 0.85,
		}],
	})

	out.append({
		"id": "misc_godot4_export_syntax",
		"title": "export keyword replaced with @export annotation",
		"category": "misc",
		"phrases": [
			"export syntax changed",
			"old export",
			"godot 3 export",
			"export variable error",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "export"}
		],
		"candidates": [{
			"code": "# Wrong (Godot 3):\n# export(int) var hp\n# export(float, 0, 100) var ratio\n# Right (Godot 4):\n@export var hp: int\n@export_range(0.0, 100.0) var ratio: float\n",
			"description": "Godot 4 uses @export annotations with type hints on the variable itself. The old export(type, ...) parenthesized form is gone.",
			"confidence": 0.85,
		}],
	})

	out.append({
		"id": "misc_godot4_onready_syntax",
		"title": "onready keyword replaced with @onready annotation",
		"category": "misc",
		"phrases": [
			"onready syntax changed",
			"old onready",
			"godot 3 onready",
			"onready error",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "onready"}
		],
		"candidates": [{
			"code": "# Wrong (Godot 3):\n# onready var sprite = $Sprite\n# Right (Godot 4):\n@onready var sprite: Sprite2D = $Sprite\n",
			"description": "onready is an annotation in Godot 4. Prefix with @. Combine with a type hint for better autocomplete.",
			"confidence": 0.82,
		}],
	})

	out.append({
		"id": "misc_godot4_kinematicbody_renamed",
		"title": "KinematicBody2D -> CharacterBody2D, KinematicBody3D -> CharacterBody3D",
		"category": "misc",
		"phrases": [
			"kinematicbody missing",
			"character body renamed",
			"kinematic body error",
			"godot 3 kinematic body",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "KinematicBody"},
		],
		"candidates": [{
			"code": "# KinematicBody2D -> CharacterBody2D\n# KinematicBody3D -> CharacterBody3D\n# KinematicBody   -> CharacterBody3D (Godot 3 named 3D version without the 3D)\n",
			"description": "Godot 4 renamed KinematicBody to CharacterBody for consistency with RigidBody and StaticBody.",
			"confidence": 0.85,
		}],
	})

	out.append({
		"id": "misc_godot4_spatial_renamed",
		"title": "Spatial -> Node3D",
		"category": "misc",
		"phrases": [
			"spatial not found",
			"spatial node missing",
			"godot 3 spatial",
			"spatial renamed",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "Spatial"},
		],
		"candidates": [{
			"code": "# Spatial      -> Node3D\n# SpatialMaterial -> StandardMaterial3D\n# EditorSpatialGizmo -> EditorNode3DGizmo\n",
			"description": "Godot 4 renamed Spatial to Node3D and SpatialMaterial to StandardMaterial3D. Almost every 3D class lost the word 'Spatial'.",
			"confidence": 0.85,
		}],
	})

	out.append({
		"id": "misc_godot4_signal_declaration",
		"title": "Signal declaration syntax changed",
		"category": "misc",
		"phrases": [
			"signal declaration changed",
			"signal syntax",
			"godot 3 signal",
			"signal declare error",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "signal"}
		],
		"candidates": [{
			"code": "# Godot 3:\n# signal my_signal(arg1, arg2)\n# Godot 4 (same, but types are now allowed):\nsignal my_signal(arg1: int, arg2: String)\n",
			"description": "Signal declaration is compatible, but Godot 4 lets you (and should) add types to the arguments. Emitting without matching args is a runtime error.",
			"confidence": 0.75,
		}],
	})

	out.append({
		"id": "misc_godot4_emit_signal",
		"title": "emit_signal() replaced with signal.emit()",
		"category": "misc",
		"phrases": [
			"emit_signal syntax",
			"emit signal changed",
			"godot 3 emit",
			"signal.emit",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "emit_signal"},
		],
		"candidates": [{
			"code": "# Godot 3:\n# emit_signal(\"health_changed\", 50)\n# Godot 4 (preferred):\nhealth_changed.emit(50)\n# Godot 4 (still works but discouraged):\n# emit_signal(\"health_changed\", 50)\n",
			"description": "Both forms work in Godot 4, but signal.emit() is the modern idiom and gets full autocomplete + argument checking.",
			"confidence": 0.78,
		}],
	})

	out.append({
		"id": "misc_godot4_property_renames",
		"title": "Common property renames from Godot 3 to 4",
		"category": "misc",
		"phrases": [
			"property renamed",
			"godot 3 property",
			"missing property",
			"property not found godot 4",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "linear_velocity"},
		],
		"candidates": [{
			"code": "# Common renames:\n#   translation       -> position\n#   transform.origin  -> position  (in code)\n#   linear_velocity   -> velocity\n#   margin            -> constant\n#   rect_position     -> position\n#   rect_size         -> size\n#   theme_override    -> add_theme_*_override()\n",
			"description": "Godot 4 renamed many 3D and 2D properties for consistency. Check the class docs for the specific property — the upgrade guide lists them all.",
			"confidence": 0.72,
		}],
	})

	out.append({
		"id": "misc_godot4_rect2_rect",
		"title": "Rect2 property renames in Control nodes",
		"category": "misc",
		"phrases": [
			"rect_position missing",
			"rect_size missing",
			"rect_min_size",
			"control rect renamed",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "rect_position"},
		],
		"candidates": [{
			"code": "# Godot 3 Control      -> Godot 4 Control\n#   rect_position      -> position\n#   rect_size          -> size\n#   rect_min_size      -> custom_minimum_size\n#   rect_rotation      -> rotation\n#   rect_scale         -> scale\n#   rect_pivot_offset  -> pivot_offset\n",
			"description": "Every Control property that used to start with rect_ dropped the prefix in Godot 4. The remaining name usually still makes sense.",
			"confidence": 0.78,
		}],
	})

	out.append({
		"id": "misc_godot4_tween_api",
		"title": "Tween is now a node, created via create_tween()",
		"category": "misc",
		"phrases": [
			"tween changed",
			"godot 3 tween",
			"tween deprecated",
			"create_tween",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "Tween"},
		],
		"candidates": [{
			"code": "# Godot 4:\nvar t: Tween = create_tween()\nt.tween_property($Sprite, \"position\", Vector2(100, 100), 0.5)\n# Or a standalone Tween node:\nvar t2: Tween = Tween.new()\nadd_child(t2)\nt2.tween_property(...)\n",
			"description": "Tween was a SceneTree-derived object in Godot 3, now it's a node. Use create_tween() from any node in the tree to get a bound Tween.",
			"confidence": 0.82,
		}],
	})

	out.append({
		"id": "misc_godot4_setget",
		"title": "setget replaced with property setters and getters",
		"category": "misc",
		"phrases": [
			"setget deprecated",
			"godot 3 setget",
			"property setter",
			"getter setter",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "setget"},
		],
		"candidates": [{
			"code": "var health: int = 100:\n\tset(value):\n\t\thealth = clamp(value, 0, max_health)\n\t\thealth_changed.emit(health)\n\tget:\n\t\treturn health\n",
			"description": "Godot 4 replaced the setget keyword with inline set/get blocks on the variable. The setter sees `value` (the incoming) and the variable name (the current).",
			"confidence": 0.82,
		}],
	})

	out.append({
		"id": "misc_godot4_call_deferred",
		"title": "call_deferred takes a Callable or a method name",
		"category": "misc",
		"phrases": [
			"call_deferred syntax",
			"godot 3 call_deferred",
			"deferred call",
			"call_deferred changed",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "call_deferred"},
		],
		"candidates": [{
			"code": "# Godot 4 accepts both forms:\ncall_deferred(\"do_thing\", arg1, arg2)\ndo_thing.call_deferred(arg1, arg2)   # preferred\n",
			"description": "The string form still works in Godot 4 but the Callable form is preferred — it gets checked at parse time.",
			"confidence": 0.72,
		}],
	})

	return out


# --- self-test ----------------------------------------------------------

static func self_test() -> void:
	print("=== FixLibraryDataE self-test ===")
	var failures: Array[String] = []

	var arr: Array = records()

	var lib: FixLibrary = FixLibrary.new()
	lib.load_all()
	var added: int = register_into(lib)
	if added != arr.size():
		failures.append("register_into accepted %d of %d" % [added, arr.size()])
	if not lib.reject_log().is_empty():
		failures.append("%d rejects during registration" % lib.reject_log().size())

	var actual: Dictionary = {}
	var i: int = 0
	while i < arr.size():
		var rec: Dictionary = arr[i]
		var cat: String = str(rec.get("category", ""))
		actual[cat] = int(actual.get(cat, 0)) + 1
		i += 1

	var expected: Dictionary = {
		"syntax": 10,
		"misc": 14,
	}

	var expected_total: int = 0
	var ekeys: Array = expected.keys()
	i = 0
	while i < ekeys.size():
		expected_total += int(expected[ekeys[i]])
		i += 1

	if arr.size() != expected_total:
		failures.append("total records: expected %d, got %d" % [expected_total, arr.size()])

	i = 0
	while i < ekeys.size():
		var k: String = str(ekeys[i])
		var want: int = int(expected[k])
		var got: int = int(actual.get(k, 0))
		if want != got:
			failures.append("category '%s' expected %d, got %d" % [k, want, got])
		i += 1

	var seen: Dictionary = {}
	i = 0
	while i < arr.size():
		var id: String = str(arr[i].get("id", ""))
		if seen.has(id):
			failures.append("duplicate id '%s'" % id)
		seen[id] = true
		i += 1

	# Cross-check against every prior ID. Full list through volume D.
	var prior_ids: Array = [
		# Starter
		"is_on_floor_missing", "gravity_not_applied", "delta_not_used",
		"input_map_missing", "input_get_action_strength",
		"get_node_returns_null", "node_path_wrong",
		"signal_wrong_signature", "await_signal_never_fires",
		"wrong_node_type", "queue_free_after_use",
		"rigidbody_moved_directly", "collision_layer_mismatch",
		"missing_type_hint", "godot3_to_godot4_rename",
		# A
		"coyote_time_2d", "jump_buffer_2d", "variable_jump_height",
		"air_control_2d", "wall_slide_2d", "wall_jump_2d",
		"dash_2d", "dash_air_2d", "sprint_toggle", "crouch_2d",
		"slope_slide_2d", "max_fall_speed", "jump_velocity_setup",
		"double_jump_2d", "jump_cut_on_release", "jump_particles_land",
		"jump_particles_takeoff", "jump_sound_pitch_variation",
		"landing_recovery_time", "dash_iframes", "dash_direction_8way",
		"dash_cancel_into_attack", "camera_follow_smooth",
		"camera_deadzone", "camera_lookahead", "camera_shake",
		"camera_limits_2d", "camera_zoom_smooth", "camera_mouse_look_3d",
		"camera_smooth_3d", "dash_camera_zoom", "input_deadzone_analog",
		"input_remap_runtime", "input_controller_detection",
		"input_touch_button_2d", "input_hold_vs_press", "input_double_tap",
		"dash_cooldown_ui", "dash_trail",
		# B
		"null_after_free", "null_signal_arg", "null_typed_var",
		"get_node_or_null_returns_null", "instantiate_returns_null",
		"owner_is_null", "get_first_node_in_group_empty", "dict_key_missing",
		"resource_load_failed", "get_parent_at_root", "autoload_not_registered",
		"await_result_null", "null_typed_array_access", "assert_condition_false",
		"signal_not_emitted", "signal_connect_failed",
		"signal_emitted_before_connect", "signal_arg_type_mismatch",
		"signal_one_shot", "signal_await_timeout", "signal_callable_bind",
		"signal_typed_params", "signal_duplicate_connection",
		"signal_disconnect_during_emit", "signal_emit_in_ready",
		"signal_custom_no_params", "signal_wrong_arg_count",
		"ready_not_called", "process_not_called", "node_added_to_wrong_parent",
		"node_name_collision", "node_order_in_scene", "ready_vs_enter_tree",
		"remove_child_vs_queue_free", "node_visibility", "node_processing_disabled",
		"z_index_wrong", "node_duplicate", "node_reparent",
		"_ready_called_before_parent_ready", "call_deferred_pattern",
		# C
		"physics_process_vs_process", "body_type_selection",
		"move_and_slide_vs_move_and_collide", "raycast_ignore_self",
		"raycast_target_to_global", "area_monitoring_disabled",
		"area_body_entered_signal", "continuous_collision_detection",
		"rigidbody_sleep_issue", "physics_material_bounce",
		"one_way_collision_3d", "get_slide_collision_info",
		"is_on_wall_only_checks", "max_slides_exhausted",
		"collision_layer_vs_mask", "collision_shape_missing",
		"collision_shape_scale_issue", "collision_shape_2d_vs_3d",
		"one_way_collision_2d", "collision_debug_visible",
		"area_signals_setup", "collision_shape_rotation",
		"rigidbody_disable_collision", "character_body_floor_snap",
		"animation_player_vs_tree", "animation_tree_parameters",
		"animation_state_transition", "animation_blend_2d",
		"animation_method_call", "sprite_frames_timing",
		"animation_not_playing", "animation_looping_setup",
		"tween_vs_animation_player", "animation_speed_scale",
		"add_to_group_basics", "get_nodes_in_group",
		"node_added_signal_tree", "group_typo_issue",
		"remove_from_group", "group_cleanup_on_free",
		# D
		"ui_control_anchor_basics", "ui_container_vs_manual_position",
		"ui_button_signal", "ui_health_bar_value", "ui_tween_fade",
		"ui_pause_menu", "ui_scale_with_screen", "ui_mouse_filter",
		"ui_focus_neighbors", "ui_line_edit_text_submitted",
		"ui_scroll_container", "ui_rich_text_bbcode",
		"ui_custom_font_size", "ui_show_hide_instantly",
		"health_damage_signature", "health_death_signal",
		"health_invulnerability_frames", "health_heal_clamp",
		"health_negative_values", "health_signal_on_change",
		"health_regen_over_time", "health_damage_numbers",
		"health_bar_follow", "health_low_warning", "health_hearts_ui",
		"health_respawn", "health_max_min",
		"misc_print_debug", "misc_assert_vs_push_error",
		"misc_string_format", "misc_signal_disconnect_safety",
		"misc_export_annotation", "misc_onready_annotation",
		"misc_static_typing", "misc_enum_values", "misc_array_shuffle",
		"misc_time_ticks", "misc_file_path", "misc_pause_game",
		"misc_random_seed", "misc_lambda_capture",
	]
	i = 0
	while i < prior_ids.size():
		var pid: String = str(prior_ids[i])
		if seen.has(pid):
			failures.append("id '%s' collides with prior volume" % pid)
		i += 1

	if not lib.has_record("syntax_missing_colon"):
		failures.append("syntax_missing_colon missing")
	if not lib.has_record("misc_godot4_yield_to_await"):
		failures.append("misc_godot4_yield_to_await missing")
	if not lib.has_record("misc_godot4_setget"):
		failures.append("misc_godot4_setget missing")

	var m1: Array = lib.records_matching_tokens(["yield"])
	if m1.is_empty():
		failures.append("'yield' token should match records")
	var m2: Array = lib.records_matching_tokens(["indentation"])
	if m2.is_empty():
		failures.append("'indentation' token should match records")

	print("")
	if failures.is_empty():
		print("OK — all assertions passed (%d records, %d categories)" % [arr.size(), actual.size()])
	else:
		print("FAILED — %d issues:" % failures.size())
		i = 0
		while i < failures.size():
			print("  " + failures[i])
			i += 1
