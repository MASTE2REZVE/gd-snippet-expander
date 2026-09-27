# res://addons/gd_snippet_expander/ai_debugger/fix_library.gd
@tool
class_name FixLibrary
extends RefCounted

## Curated fix records for the mini AI debugger.
##
## Part of the GD Snippet Expander mini AI debugger (v1.6).
##
## The library is a dictionary of fix records keyed by ID. Each
## record describes:
##   - an English-language description of a common problem
##   - the code patterns that tend to indicate that problem
##   - one or more candidate fixes with starting confidences
##   - optional disambiguating questions to narrow down the answer
##
## Data lives in sibling files (fix_library_data_*.gd). They call
## FixLibrary.register_records() at plugin load to add themselves.
## This file ships a small STARTER SET of the most universal records
## so the chain runs end-to-end before any data file is added.
##
## RECORD SCHEMA:
##   {
##     "id":        String    unique, snake_case
##     "title":     String    short, human-readable
##     "category":  String    movement|camera|input|null_safety|signals|
##                            nodes|physics|animation|ui|health|syntax|misc
##     "phrases":   Array     English strings the user might type
##     "code_patterns": Array of {
##         "kind":    String   "substring" | "regex" | "identifier"
##         "value":   String
##         "negate":  bool     optional, default false
##     }
##     "candidates": Array of {
##         "code":        String   GDScript fix to insert
##         "description": String   what the fix does
##         "confidence":  float    starting confidence [0, 1]
##     }
##     "questions": Array of {     (optional)
##         "text":    String
##         "answers": Array of {
##             "text":  String
##             "boosts": Array[String]   candidate IDs to boost
##         }
##     }
##     "related": Array[String]    (optional) other fix IDs
##   }
##
## Usage:
##   var lib := FixLibrary.new()
##   lib.load_all()                          # register starter set only
##   FixLibraryDataA.register_into(lib)      # hook in a data file
##   var rec := lib.get_record("is_on_floor_missing")

# --- constants ----------------------------------------------------------

const VALID_CATEGORIES := [
	"movement", "camera", "input", "null_safety", "signals",
	"nodes", "physics", "animation", "ui", "health", "syntax", "misc",
]

const REQUIRED_KEYS := ["id", "title", "category", "phrases", "candidates"]

# --- internal state -----------------------------------------------------

var _records: Dictionary = {}       # id -> record dict
var _by_category: Dictionary = {}   # category -> Array[id]
var _loaded: bool = false
var _reject_log: Array[String] = []

# --- public state -------------------------------------------------------

## Populated with any record that failed validation during load.
## Each entry is a one-line description of what was rejected and why.
func reject_log() -> Array[String]:
	return _reject_log.duplicate()


func is_loaded() -> bool:
	return _loaded


func record_count() -> int:
	return _records.size()


func category_count() -> int:
	return _by_category.size()

# --- loading ------------------------------------------------------------

## Registers the built-in starter set. Call this first, then hook in
## any external data files with their own register_into() methods.
func load_all() -> void:
	_records.clear()
	_by_category.clear()
	_reject_log.clear()
	_loaded = false

	# Starter set is defined inline below. Each record is validated
	# before being accepted; rejects are logged, not fatal.
	var starter: Array = _build_starter_set()
	var i: int = 0
	while i < starter.size():
		register_record(starter[i])
		i += 1

	_loaded = true


## Registers a single record. Returns true if accepted, false if the
## record was malformed. Rejects are logged in `reject_log()`.
func register_record(rec: Dictionary) -> bool:
	var v: String = _validate(rec)
	if v != "":
		_reject_log.append("rejected: " + v)
		return false
	var id: String = str(rec["id"])
	if _records.has(id):
		_reject_log.append("rejected: duplicate id '" + id + "'")
		return false
	_records[id] = rec
	var cat: String = str(rec["category"])
	if not _by_category.has(cat):
		_by_category[cat] = []
	_by_category[cat].append(id)
	return true


## Bulk register. Returns number of accepted records.
func register_records(arr: Array) -> int:
	var accepted: int = 0
	var i: int = 0
	while i < arr.size():
		if register_record(arr[i]):
			accepted += 1
		i += 1
	return accepted


func _validate(rec: Dictionary) -> String:
	var i: int = 0
	while i < REQUIRED_KEYS.size():
		var k: String = REQUIRED_KEYS[i]
		if not rec.has(k):
			return "missing key '%s'" % k
		i += 1
	var id: String = str(rec["id"])
	if id == "":
		return "empty id"
	var cat: String = str(rec["category"])
	if not (cat in VALID_CATEGORIES):
		return "unknown category '%s' in '%s'" % [cat, id]
	var phrases: Array = rec["phrases"]
	if phrases.is_empty():
		return "empty phrases in '%s'" % id
	var candidates: Array = rec["candidates"]
	if candidates.is_empty():
		return "empty candidates in '%s'" % id
	var j: int = 0
	while j < candidates.size():
		var c: Variant = candidates[j]
		if not (c is Dictionary):
			return "candidate %d in '%s' is not a Dictionary" % [j, id]
		var cd: Dictionary = c
		if not cd.has("code") or not cd.has("description"):
			return "candidate %d in '%s' missing code/description" % [j, id]
		j += 1
	return ""

# --- lookups ------------------------------------------------------------

func has_record(id: String) -> bool:
	return _records.has(id)


func get_record(id: String) -> Dictionary:
	if _records.has(id):
		return _records[id]
	return {}


## Returns every record ID in a given category. Empty array if the
## category has no records.
func ids_in_category(cat: String) -> Array:
	if _by_category.has(cat):
		return _by_category[cat].duplicate()
	return []


func all_ids() -> Array:
	return _records.keys()


## Returns every record whose phrase list contains a phrase that
## shares a token with `query_tokens`. Used as a cheap first pass
## before the classifier runs. Case-insensitive on the phrase side.
func records_matching_tokens(query_tokens: Array) -> Array:
	var out: Array = []
	var lookup: Dictionary = {}
	var q: int = 0
	while q < query_tokens.size():
		lookup[str(query_tokens[q]).to_lower()] = true
		q += 1
	var ids: Array = _records.keys()
	var i: int = 0
	while i < ids.size():
		var rid: String = str(ids[i])
		var rec: Dictionary = _records[rid]
		var phrases: Array = rec["phrases"]
		var p: int = 0
		while p < phrases.size():
			var phrase: String = str(phrases[p]).to_lower()
			for word in phrase.split(" ", false):
				if lookup.has(word):
					out.append(rid)
					p = phrases.size()   # break inner
					break
			p += 1
		i += 1
	return out

# --- starter set --------------------------------------------------------

## Fifteen records covering the most universal beginner mistakes.
## The bulk of the library lives in fix_library_data_*.gd files.
func _build_starter_set() -> Array:
	var out: Array = []

	# --- movement --------------------------------------------------------
	out.append({
		"id": "is_on_floor_missing",
		"title": "move_and_slide without is_on_floor check",
		"category": "movement",
		"phrases": [
			"character won't jump",
			"jump doesn't work",
			"player can't jump",
			"my jump is broken",
			"jump does nothing",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "move_and_slide"},
			{"kind": "substring", "value": "is_on_floor", "negate": true},
		],
		"candidates": [{
			"code": "if Input.is_action_just_pressed(\"jump\") and is_on_floor():\n\tvelocity.y = jump_velocity\n",
			"description": "Only set upward velocity when the body is actually on the floor. Without this check the jump fires in mid-air and either does nothing visible or stacks with gravity.",
			"confidence": 0.72,
		}],
		"related": ["gravity_not_applied", "jump_velocity_missing"],
	})

	out.append({
		"id": "gravity_not_applied",
		"title": "gravity never applied to velocity.y",
		"category": "movement",
		"phrases": [
			"player floats",
			"character doesn't fall",
			"gravity not working",
			"my player is stuck in the air",
			"no gravity",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "CharacterBody3D"},
			{"kind": "substring", "value": "velocity.y", "negate": true},
		],
		"candidates": [{
			"code": "if not is_on_floor():\n\tvelocity.y -= gravity * delta\nelse:\n\tvelocity.y = 0.0\n",
			"description": "Apply gravity every frame while airborne, and reset to zero when grounded. Without this the body never accumulates downward velocity.",
			"confidence": 0.78,
		}],
	})

	out.append({
		"id": "delta_not_used",
		"title": "movement not multiplied by delta",
		"category": "movement",
		"phrases": [
			"movement speed changes",
			"my player moves faster on some computers",
			"movement depends on framerate",
			"speed changes with fps",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "velocity.x"},
			{"kind": "substring", "value": "* delta", "negate": true},
		],
		"candidates": [{
			"code": "velocity.x = direction * speed\n",
			"description": "Multiply by delta so speed is per-second rather than per-frame. Replace `direction * speed` with `direction * speed` where speed is already in units per second and you also multiply the whole expression by delta.",
			"confidence": 0.55,
		}],
	})

	# --- input -----------------------------------------------------------
	out.append({
		"id": "input_map_missing",
		"title": "input action not defined in project settings",
		"category": "input",
		"phrases": [
			"input action doesn't work",
			"jump action missing",
			"is_action_pressed returns false",
			"my input does nothing",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "is_action_pressed"},
		],
		"candidates": [{
			"code": "# Open Project Settings -> Input Map and add an action named \"jump\".\n# Then the code will fire when the bound keys are pressed.\n",
			"description": "Godot only knows about input actions that are declared in the project's Input Map. If the action name in code doesn't match one in Project Settings, the check silently returns false.",
			"confidence": 0.68,
		}],
	})

	out.append({
		"id": "input_get_action_strength",
		"title": "digital action used for analog movement",
		"category": "input",
		"phrases": [
			"movement is jerky",
			"player snaps left and right",
			"no smooth movement",
			"movement feels digital",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "is_action_pressed"},
			{"kind": "identifier", "value": "Input.get_axis", "negate": true},
		],
		"candidates": [{
			"code": "var direction := Input.get_axis(\"move_left\", \"move_right\")\n",
			"description": "get_axis returns -1..1 and supports analog sticks and smooth interpolation. is_action_pressed only returns true/false, which gives jerky movement.",
			"confidence": 0.60,
		}],
	})

	# --- null safety -----------------------------------------------------
	out.append({
		"id": "get_node_returns_null",
		"title": "get_node returns null and crashes",
		"category": "null_safety",
		"phrases": [
			"null instance error",
			"cannot call method on null",
			"get_node returns null",
			"invalid get index on null instance",
			"null reference",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "get_node"},
			{"kind": "substring", "value": "if ", "negate": true},
		],
		"candidates": [{
			"code": "var target: Node = get_node_or_null(\"../Target\")\nif target == null:\n\tpush_warning(\"Target node not found\")\n\treturn\ntarget.do_something()\n",
			"description": "get_node throws if the path is wrong. get_node_or_null returns null instead and lets you check before using the reference.",
			"confidence": 0.80,
		}],
	})

	out.append({
		"id": "node_path_wrong",
		"title": "node path doesn't match scene tree",
		"category": "null_safety",
		"phrases": [
			"node not found",
			"get_node can't find node",
			"parent path is wrong",
			"scene tree path error",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "get_node"},
			{"kind": "substring", "value": "$", "negate": true},
		],
		"candidates": [{
			"code": "var target: Node = get_node(\"../Sibling\")\n# Or use the $ shorthand if the node is a direct child of self:\nvar child: Node = $Child\n",
			"description": "Node paths are case-sensitive and relative to the calling node. `../` goes up one level, `/root` starts from the scene root.",
			"confidence": 0.55,
		}],
	})

	# --- signals ---------------------------------------------------------
	out.append({
		"id": "signal_wrong_signature",
		"title": "signal connected with wrong argument count",
		"category": "signals",
		"phrases": [
			"signal argument mismatch",
			"connect fails",
			"wrong number of arguments",
			"signal fires with wrong args",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "connect"},
		],
		"candidates": [{
			"code": "target.health_changed.connect(_on_health_changed)\n\nfunc _on_health_changed(new_health: int) -> void:\n\t# must match the signal's parameter list exactly\n\tpass\n",
			"description": "Signal handlers must accept exactly the arguments the signal emits. Godot 4 doesn't silently drop or pad extra arguments.",
			"confidence": 0.62,
		}],
	})

	out.append({
		"id": "await_signal_never_fires",
		"title": "await on a signal that never fires",
		"category": "signals",
		"phrases": [
			"await never returns",
			"code stops at await",
			"function hangs on await",
			"await blocks forever",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "await"},
		],
		"candidates": [{
			"code": "# If the awaited signal never emits, the function stays suspended.\n# Add a timeout as a safety net:\nvar timer := get_tree().create_timer(5.0)\nvar result = await timer.timeout\n",
			"description": "await suspends the function until the signal fires. If the source object is freed or the signal never emits, the function never resumes.",
			"confidence": 0.50,
		}],
	})

	# --- nodes -----------------------------------------------------------
	out.append({
		"id": "wrong_node_type",
		"title": "node type doesn't have the method being called",
		"category": "nodes",
		"phrases": [
			"method doesn't exist",
			"invalid call nonexistent function",
			"node has no method",
			"unexpected method name",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "call"},
		],
		"candidates": [{
			"code": "# Check the class of the node before calling:\nif node is CharacterBody3D:\n\tnode.move_and_slide()\n",
			"description": "Not every node type has every method. A plain Node has no position, a Node2D has no global_transform. Use `is` to check before calling.",
			"confidence": 0.48,
		}],
	})

	out.append({
		"id": "queue_free_after_use",
		"title": "using a node after queue_free",
		"category": "nodes",
		"phrases": [
			"freed instance",
			"previously freed",
			"node is already freed",
			"calling on freed object",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "queue_free"},
		],
		"candidates": [{
			"code": "if is_instance_valid(target):\n\ttarget.do_something()\n",
			"description": "queue_free marks a node for deletion at the end of the frame. Any reference to it afterwards is invalid. is_instance_valid checks before using.",
			"confidence": 0.72,
		}],
	})

	# --- physics ---------------------------------------------------------
	out.append({
		"id": "rigidbody_moved_directly",
		"title": "RigidBody moved directly instead of with forces",
		"category": "physics",
		"phrases": [
			"rigidbody jitters",
			"rigidbody teleports",
			"physics body fights me",
			"rigidbody position doesn't stick",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "RigidBody3D"},
			{"kind": "substring", "value": ".position =", "negate": false},
		],
		"candidates": [{
			"code": "# For a RigidBody, use forces instead of setting position:\napply_central_force(direction * force_strength)\n# Or switch the node to a CharacterBody3D if you want to control it directly.\n",
			"description": "RigidBody is simulated by the physics engine. Setting position directly conflicts with the simulation. Use apply_force, apply_impulse, or linear_velocity instead.",
			"confidence": 0.65,
		}],
	})

	out.append({
		"id": "collision_layer_mismatch",
		"title": "collision layers don't match so bodies pass through",
		"category": "physics",
		"phrases": [
			"player falls through floor",
			"collision doesn't work",
			"bodies pass through each other",
			"no collision detected",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "collision_layer"},
		],
		"candidates": [{
			"code": "# Set the floor's collision_layer to bit 1:\n#   collision_layer = 1\n# Set the player's collision_mask to include bit 1:\n#   collision_mask = 1\n# Two bodies only collide if one's mask includes the other's layer.\n",
			"description": "Layers are 'who I am', masks are 'who I detect'. Two objects only interact when at least one's mask includes the other's layer.",
			"confidence": 0.68,
		}],
	})

	# --- syntax ----------------------------------------------------------
	out.append({
		"id": "missing_type_hint",
		"title": "inferred type from null literal fails at runtime",
		"category": "syntax",
		"phrases": [
			"cannot infer type",
			"can't infer the type",
			"var with null fails",
			"type inference error",
		],
		"code_patterns": [
			{"kind": "substring", "value": ":= null"},
		],
		"candidates": [{
			"code": "var target: Node = null\n",
			"description": "`:=` asks GDScript to infer the type from the right-hand side. `null` has no type, so inference fails. Use an explicit type annotation instead.",
			"confidence": 0.85,
		}],
	})

	# --- misc ------------------------------------------------------------
	out.append({
		"id": "godot3_to_godot4_rename",
		"title": "Godot 3 API name used in Godot 4",
		"category": "misc",
		"phrases": [
			"function not found",
			"nonexistent function",
			"method missing after upgrading",
			"godot 3 code doesn't work",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "KinematicBody"},
		],
		"candidates": [{
			"code": "# Godot 3 -> Godot 4 renames:\n#   KinematicBody     -> CharacterBody3D\n#   KinematicBody2D   -> CharacterBody2D\n#   Spatial           -> Node3D\n#   SpatialMaterial   -> StandardMaterial3D\n#   instance()        -> instantiate()\n#   OS.get_ticks_msec() is unchanged\n",
			"description": "Godot 4 renamed many core classes. See the official upgrade guide for the full table.",
			"confidence": 0.55,
		}],
	})

	return out

# --- self-test ----------------------------------------------------------

## Verifies the loader, registry, and lookups work. Pass condition:
## "OK" printed at the end.
static func self_test() -> void:
	print("=== FixLibrary self-test ===")
	var failures: Array[String] = []

	var lib: FixLibrary = FixLibrary.new()
	lib.load_all()

	# --- 1. Starter set registered ---
	if lib.record_count() != 15:
		failures.append("1: expected 15 starter records, got %d" % lib.record_count())
	if lib.reject_log().size() != 0:
		failures.append("1: starter set produced %d rejects" % lib.reject_log().size())

	# --- 2. Categories populated ---
	for cat in ["movement", "input", "null_safety", "signals", "nodes", "physics", "syntax", "misc"]:
		if lib.ids_in_category(cat).is_empty():
			failures.append("2: category '%s' has no records" % cat)

	# --- 3. Lookup by id ---
	if not lib.has_record("is_on_floor_missing"):
		failures.append("3: missing is_on_floor_missing record")
	var rec: Dictionary = lib.get_record("is_on_floor_missing")
	if rec.get("title", "") != "move_and_slide without is_on_floor check":
		failures.append("3: wrong title on is_on_floor_missing")

	# --- 4. Unknown id returns empty ---
	if not lib.get_record("nope_not_here").is_empty():
		failures.append("4: unknown id should return empty dict")

	# --- 5. Token match ---
	var matches: Array = lib.records_matching_tokens(["jump"])
	if matches.is_empty():
		failures.append("5: token 'jump' should match at least one record")
	if not ("is_on_floor_missing" in matches):
		failures.append("5: token 'jump' should match is_on_floor_missing")

	# --- 6. Registering a bad record is rejected ---
	var bad: Dictionary = {"id": "broken", "title": "x"}
	if lib.register_record(bad):
		failures.append("6: incomplete record should be rejected")
	if lib.has_record("broken"):
		failures.append("6: rejected record should not be stored")
	if lib.reject_log().size() == 0:
		failures.append("6: reject_log should have an entry")

	# --- 7. Duplicate id rejected ---
	var dupe: Dictionary = lib.get_record("is_on_floor_missing")
	if lib.register_record(dupe):
		failures.append("7: duplicate id should be rejected")

	# --- 8. register_records bulk API ---
	var lib2: FixLibrary = FixLibrary.new()
	lib2.load_all()
	var extra: Array = [{
		"id": "custom_one",
		"title": "Custom",
		"category": "misc",
		"phrases": ["custom phrase"],
		"candidates": [{"code": "pass\n", "description": "do nothing", "confidence": 0.5}],
	}]
	var accepted: int = lib2.register_records(extra)
	if accepted != 1:
		failures.append("8: register_records should accept 1, got %d" % accepted)
	if not lib2.has_record("custom_one"):
		failures.append("8: custom_one should exist after bulk register")

	# --- 9. Validation: bad category ---
	var bad_cat: Dictionary = {
		"id": "x", "title": "x", "category": "not_a_category",
		"phrases": ["x"], "candidates": [{"code": "pass", "description": "x"}],
	}
	var lib3: FixLibrary = FixLibrary.new()
	lib3.load_all()
	if lib3.register_record(bad_cat):
		failures.append("9: invalid category should be rejected")

	# --- 10. Empty phrases rejected ---
	var no_phrases: Dictionary = {
		"id": "x", "title": "x", "category": "misc",
		"phrases": [], "candidates": [{"code": "pass", "description": "x"}],
	}
	if lib3.register_record(no_phrases):
		failures.append("10: empty phrases should be rejected")

	# --- 11. Candidates must be dicts with code+description ---
	var bad_cand: Dictionary = {
		"id": "x", "title": "x", "category": "misc",
		"phrases": ["y"], "candidates": ["not a dict"],
	}
	if lib3.register_record(bad_cand):
		failures.append("11: non-dict candidate should be rejected")

	# --- 12. all_ids returns everything ---
	if lib.all_ids().size() != 15:
		failures.append("12: all_ids should return 15")

	print("")
	if failures.is_empty():
		print("OK — all assertions passed")
	else:
		print("FAILED — %d issues:" % failures.size())
		var i: int = 0
		while i < failures.size():
			print("  " + failures[i])
			i += 1
