# res://addons/gd_snippet_expander/ai_debugger/error_library.gd
@tool
class_name ErrorLibrary
extends RefCounted

## Error pattern library for the Error Whisperer feature.
##
## Part of the GD Snippet Expander mini AI debugger (v1.7).
##
## Matches Godot Output panel error lines against a curated library
## of patterns. Returns a plain-English explanation and a suggested
## fix. No AI, no network -- pure regex lookup.
##
## Records are keyed by ID. Data files (error_library_data_*.gd)
## register their records at plugin load. This file ships a small
## STARTER SET so the chain runs end-to-end before any data file
## is added.
##
## RECORD SCHEMA:
##   {
##     "id":         String    unique, snake_case
##     "title":      String    short human-readable
##     "category":   String    see VALID_CATEGORIES
##     "pattern": {
##       "kind":     String    "regex" | "substring"
##       "value":    String
##     }
##     "example_error": String   a real line this pattern matches
##     "explains":   String      plain-English explanation
##     "causes":     Array       list of common causes (strings)
##     "fix": {
##       "code":        String    GDScript fix
##       "description": String    what the fix does
##     }
##     "related":    Array       (optional) other error or fix IDs
##   }

const VALID_CATEGORIES := [
	"null_safety", "type_error", "syntax", "node",
	"signal", "physics", "animation", "input",
	"migration", "misc",
]

const REQUIRED_KEYS := ["id", "title", "category", "pattern", "explains", "fix"]

# --- internal state -----------------------------------------------------

var _records: Dictionary = {}
var _by_category: Dictionary = {}
var _loaded: bool = false
var _reject_log: Array[String] = []
var _regex_cache: Dictionary = {}


# --- public API ---------------------------------------------------------

func reject_log() -> Array[String]:
	return _reject_log.duplicate()


func is_loaded() -> bool:
	return _loaded


func record_count() -> int:
	return _records.size()


func category_count() -> int:
	return _by_category.size()


func has_record(id: String) -> bool:
	return _records.has(id)


func get_record(id: String) -> Dictionary:
	if _records.has(id):
		return _records[id]
	return {}


func all_ids() -> Array:
	return _records.keys()


func ids_in_category(cat: String) -> Array:
	if _by_category.has(cat):
		return _by_category[cat].duplicate()
	return []


# --- loading ------------------------------------------------------------

func load_all() -> void:
	_records.clear()
	_by_category.clear()
	_reject_log.clear()
	_regex_cache.clear()
	_loaded = false

	var starter: Array = _build_starter_set()
	var i: int = 0
	while i < starter.size():
		register_record(starter[i])
		i += 1

	_loaded = true


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
	var pattern: Variant = rec["pattern"]
	if not (pattern is Dictionary):
		return "pattern not a Dictionary in '%s'" % id
	var pd: Dictionary = pattern
	if not pd.has("kind") or not pd.has("value"):
		return "pattern missing kind/value in '%s'" % id
	var kind: String = str(pd["kind"])
	if kind != "regex" and kind != "substring":
		return "unknown pattern kind '%s' in '%s'" % [kind, id]
	var fix: Variant = rec["fix"]
	if not (fix is Dictionary):
		return "fix not a Dictionary in '%s'" % id
	var fd: Dictionary = fix
	if not fd.has("code") or not fd.has("description"):
		return "fix missing code/description in '%s'" % id
	return ""


# --- matching -----------------------------------------------------------

func match_line(line: String) -> Dictionary:
	if not _loaded or line.strip_edges() == "":
		return {}

	var best: Dictionary = {}
	var best_specificity: int = -1

	var ids: Array = _records.keys()
	var i: int = 0
	while i < ids.size():
		var rid: String = str(ids[i])
		var rec: Dictionary = _records[rid]
		if _matches_record(rec, line):
			var spec: int = _specificity_of(rec)
			if spec > best_specificity:
				best_specificity = spec
				best = rec
		i += 1

	return best


func _matches_record(rec: Dictionary, line: String) -> bool:
	var pattern: Dictionary = rec["pattern"]
	var kind: String = str(pattern["kind"])
	var value: String = str(pattern["value"])
	if kind == "substring":
		return line.find(value) != -1
	if kind == "regex":
		var re: RegEx = _get_regex(value)
		if re == null:
			return false
		return re.search(line) != null
	return false


func _specificity_of(rec: Dictionary) -> int:
	var pattern: Dictionary = rec["pattern"]
	return str(pattern["value"]).length()


func _get_regex(pattern: String) -> RegEx:
	if _regex_cache.has(pattern):
		return _regex_cache[pattern]
	var re: RegEx = RegEx.new()
	var err: int = re.compile(pattern)
	if err != OK:
		_regex_cache[pattern] = null
		return null
	_regex_cache[pattern] = re
	return re


func extract_message(line: String) -> String:
	var stripped: String = line.strip_edges()
	if stripped.begins_with("ERROR: "):
		stripped = stripped.substr(7)
	elif stripped.begins_with("WARNING: "):
		stripped = stripped.substr(9)
	var dash: int = stripped.find(" - ")
	if dash > 0 and stripped.substr(0, dash).find("://") != -1:
		return stripped.substr(dash + 3)
	return stripped


# --- starter set --------------------------------------------------------

func _build_starter_set() -> Array:
	var out: Array = []

	out.append({
		"id": "null_instance_call",
		"title": "Calling a method on a null reference",
		"category": "null_safety",
		"pattern": {
			"kind": "regex",
			"value": "Invalid call\\. Nonexistent function .* in base 'Nil'"
		},
		"example_error": "ERROR: res://player.gd:42 - Invalid call. Nonexistent function 'jump' in base 'Nil'.",
		"explains": "You called a method on a variable that's null. The variable holds nothing, so Godot can't find the method on it.",
		"causes": [
			"get_node() returned null because the path was wrong",
			"A variable was declared but never assigned",
			"The node was queue_free()'d before this line ran",
		],
		"fix": {
			"code": "if target == null:\n\tpush_error(\"target is null\")\n\treturn\ntarget.do_thing()\n",
			"description": "Check for null before calling. Or use get_node_or_null() and check its return value."
		},
		"related": ["null_instance_index", "node_not_found"],
	})

	out.append({
		"id": "null_instance_index",
		"title": "Reading a property on a null reference",
		"category": "null_safety",
		"pattern": {
			"kind": "regex",
			"value": "Invalid get index .* \\(on base: 'Nil'\\)"
		},
		"example_error": "ERROR: res://player.gd:15 - Invalid get index 'health' (on base: 'Nil').",
		"explains": "You read a property from something that's null. The property name exists on real objects, but this one holds nothing.",
		"causes": [
			"get_node() returned null (bad path or timing)",
			"Accessing a node before _ready() runs",
			"Freeing a node and then reading from it",
		],
		"fix": {
			"code": "if target != null:\n\tvar value: Variant = target.health\n",
			"description": "Guard the read with a null check, or use @onready to defer the assignment until _ready."
		},
		"related": ["null_instance_call", "null_instance_set"],
	})

	out.append({
		"id": "null_instance_set",
		"title": "Writing a property on a null reference",
		"category": "null_safety",
		"pattern": {
			"kind": "regex",
			"value": "Invalid assignment of property or key .* on a base object of type 'Nil'"
		},
		"example_error": "ERROR: res://ui.gd:8 - Invalid assignment of property or key 'text' with value of type 'String' on a base object of type 'Nil'.",
		"explains": "You wrote to a property on something null. Assigning to it does nothing and throws.",
		"causes": [
			"A node reference is null when you try to update it",
			"A node was freed before this code ran",
			"An autoload wasn't registered yet",
		],
		"fix": {
			"code": "if target != null:\n\ttarget.text = \"Updated\"\n",
			"description": "Check the reference before assigning. If it's a node, verify it's in the scene tree with is_instance_valid()."
		},
		"related": ["null_instance_index", "null_instance_call"],
	})

	out.append({
		"id": "nonexistent_function",
		"title": "Method doesn't exist on this object type",
		"category": "node",
		"pattern": {
			"kind": "regex",
			"value": "Invalid call\\. Nonexistent function"
		},
		"example_error": "ERROR: res://player.gd:55 - Invalid call. Nonexistent function 'update_health' in base 'CharacterBody2D'.",
		"explains": "You called a method that doesn't exist on this node type. Godot checked every ancestor class and the method isn't there.",
		"causes": [
			"Typo in the method name",
			"Calling a method from a subclass on the wrong node type",
			"Godot 3 API name used in Godot 4",
		],
		"fix": {
			"code": "# Verify the method exists on the class:\nif target.has_method(\"update_health\"):\n\ttarget.update_health()\n",
			"description": "Check with has_method() first, or verify the class of the node matches what you expect."
		},
		"related": ["non_static_function", "identifier_not_declared"],
	})

	out.append({
		"id": "signal_wrong_arg_count",
		"title": "Signal handler argument count mismatch",
		"category": "signal",
		"pattern": {
			"kind": "regex",
			"value": "Method expected \\d+ arguments?, but called with \\d+"
		},
		"example_error": "ERROR: Error calling from signal 'pressed' to callable: 'Node2D(Button)::_on_pressed': Method expected 2 arguments, but called with 1.",
		"explains": "A signal handler is connected to a signal whose argument count doesn't match. The button emits no arguments, but the handler expects two.",
		"causes": [
			"The signal declaration doesn't match the handler signature",
			"Connecting to the wrong signal (button_down vs pressed)",
			"Assuming a signal passes data it doesn't",
		],
		"fix": {
			"code": "# Handler signature must match the signal exactly.\n# Button.pressed passes 0 args:\nfunc _on_pressed() -> void:\n\tpass\n\n# If you need extra data, use bind():\n# button.pressed.connect(_on_pressed.bind(42))\n# func _on_pressed(extra: int) -> void: pass\n",
			"description": "Match the handler argument list to the signal's declared arguments. Use Callable.bind() to pass extra values."
		},
		"related": ["null_instance_call"],
	})

	out.append({
		"id": "missing_input_action",
		"title": "Input action not defined in Project Settings",
		"category": "input",
		"pattern": {
			"kind": "regex",
			"value": "InputMap action .* (doesn't exist|does not exist)"
		},
		"example_error": "ERROR: The InputMap action \"jump\" doesn't exist.",
		"explains": "The action name in your code doesn't match any action defined in Project Settings, Input Map.",
		"causes": [
			"You forgot to add the action in Project Settings",
			"Typo in the action name (case matters)",
			"Action was added in a different project",
		],
		"fix": {
			"code": "# Open Project Settings, Input Map, Add New Action\n# Type the exact name used in your code (e.g. \"jump\"), then\n# assign a key or button to it.\n",
			"description": "Add the missing action to the Input Map. Names are case-sensitive strings."
		},
	})

	out.append({
		"id": "node_not_found",
		"title": "get_node() can't find the path",
		"category": "node",
		"pattern": {
			"kind": "substring",
			"value": "Node not found:"
		},
		"example_error": "ERROR: Node not found: \"Player\" (relative to \"/root/Main\").",
		"explains": "The node path you passed to get_node() doesn't match anything in the current scene tree.",
		"causes": [
			"Wrong relative path (../ vs ./ vs missing /)",
			"Node hasn't been added to the tree yet",
			"Node name mismatch (case matters)",
			"Node is in a different scene",
		],
		"fix": {
			"code": "var target: Node = get_node_or_null(\"../Player\")\nif target == null:\n\tpush_error(\"Player not found at ../Player\")\n\treturn\n",
			"description": "Use get_node_or_null() and print the actual path being checked. Open the Remote scene tree while running to verify the path."
		},
		"related": ["null_instance_call"],
	})

	out.append({
		"id": "type_mismatch_assign",
		"title": "Assigning the wrong type to a typed variable",
		"category": "type_error",
		"pattern": {
			"kind": "regex",
			"value": "Trying to assign value of type .* to a variable of type"
		},
		"example_error": "ERROR: res://player.gd:10 - Trying to assign value of type 'int' to a variable of type 'String'.",
		"explains": "You tried to store a value in a variable whose declared type doesn't accept it. GDScript won't auto-convert.",
		"causes": [
			"Missing str() or int() conversion",
			"Return type of a function doesn't match what you stored",
			"Assigning null to a typed variable",
		],
		"fix": {
			"code": "var label: String = str(42)  # convert explicitly\nvar count: int = int(3.7)      # 3\n",
			"description": "Convert explicitly with str(), int(), float(), or change the variable's type declaration to match."
		},
		"related": ["cannot_infer_type"],
	})

	out.append({
		"id": "cannot_infer_type",
		"title": "Cannot infer the type from null or untyped value",
		"category": "type_error",
		"pattern": {
			"kind": "substring",
			"value": "Cannot infer the type of"
		},
		"example_error": "ERROR: res://player.gd:5 - Cannot infer the type of \"x\" variable because the value doesn't have a set type.",
		"explains": "You used := to ask Godot to guess the type, but the right-hand side doesn't have a determinate type (usually null, or a Dictionary subscript).",
		"causes": [
			"var x := null (null has no type)",
			"var y := dict[\"key\"] (Dictionary access returns Variant)",
			"var z := array[0] (untyped Array returns Variant)",
		],
		"fix": {
			"code": "var x: Node = null\nvar y: int = my_dict.get(\"key\", 0)\nvar z: Variant = my_array[0]\n",
			"description": "Use an explicit type annotation (: Type = ...) instead of := when the right-hand side has no determinate type."
		},
		"related": ["type_mismatch_assign"],
	})

	out.append({
		"id": "division_by_zero",
		"title": "Division by zero",
		"category": "misc",
		"pattern": {
			"kind": "substring",
			"value": "Division by zero"
		},
		"example_error": "ERROR: Division by zero in operator '/'.",
		"explains": "You divided a number by zero. Integer division by zero is a runtime error; float division by zero produces inf or nan.",
		"causes": [
			"A denominator computed as 0 at runtime",
			"Loop index went out of expected range",
			"An empty array's size is 0",
		],
		"fix": {
			"code": "if denominator != 0:\n\tvar result: float = numerator / denominator\nelse:\n\tpush_warning(\"denominator was zero\")\n",
			"description": "Guard the division with a non-zero check. Verify the denominator before dividing."
		},
		"related": ["index_out_of_bounds"],
	})

	out.append({
		"id": "index_out_of_bounds",
		"title": "Array or string index out of bounds",
		"category": "misc",
		"pattern": {
			"kind": "regex",
			"value": "Index .* is out of bounds"
		},
		"example_error": "ERROR: scene/gui/text_edit.cpp:6564 - Index p_line = 6 is out of bounds (text.size() = 6).",
		"explains": "You read or wrote past the end of an array, string, or TextEdit buffer. Indexes are 0-based, so an array of size N has valid indexes 0 to N-1.",
		"causes": [
			"Loop went one too far: for i in range(arr.size() + 1)",
			"Array was smaller than expected at runtime",
			"Removing from an array while iterating",
		],
		"fix": {
			"code": "if index >= 0 and index < arr.size():\n\tvar item: Variant = arr[index]\nelse:\n\tpush_warning(\"index out of range: %d (size=%d)\" % [index, arr.size()])\n",
			"description": "Check bounds before subscripting. Iterate with 'for x in arr:' instead of by index when possible."
		},
		"related": ["division_by_zero"],
	})

	out.append({
		"id": "identifier_not_declared",
		"title": "Identifier used but not declared",
		"category": "syntax",
		"pattern": {
			"kind": "regex",
			"value": "Identifier .* not declared in the current scope"
		},
		"example_error": "ERROR: res://player.gd:3 - Identifier \"jump_velocity\" not declared in the current scope.",
		"explains": "You used a name that Godot doesn't recognize. It's not a variable, not a function, not an engine class.",
		"causes": [
			"Typo in the identifier",
			"Variable declared after the line that uses it",
			"Missing @onready on a $Node shortcut",
			"Class not registered via class_name",
		],
		"fix": {
			"code": "# Declare the variable before using it:\nvar jump_velocity: float = -400.0\n\n# Or use @onready for node shortcuts:\n@onready var sprite: Sprite2D = $Sprite2D\n",
			"description": "Declare the identifier at the top of the script, or use @onready to defer the assignment."
		},
		"related": ["nonexistent_function"],
	})

	out.append({
		"id": "non_static_function",
		"title": "Calling a non-static function on a class directly",
		"category": "syntax",
		"pattern": {
			"kind": "substring",
			"value": "Cannot call non-static function"
		},
		"example_error": "ERROR: res://main.gd:30 - Cannot call non-static function \"say_hello\" on the class \"MyClass\" directly. Make an instance instead.",
		"explains": "You called a function as if it were static, but it needs an instance of the class to run.",
		"causes": [
			"Calling MyClass.method() instead of instance.method()",
			"Not calling .new() first",
			"Forgetting to add 'static' to the function declaration",
		],
		"fix": {
			"code": "var instance: MyClass = MyClass.new()\ninstance.say_hello()\n# Or declare the function as static:\n# static func say_hello() -> void: pass\n",
			"description": "Instantiate the class before calling instance methods, or mark the function static if it doesn't use instance state."
		},
		"related": ["nonexistent_function", "identifier_not_declared"],
	})

	out.append({
		"id": "resource_not_found",
		"title": "Cannot open file - resource missing or path wrong",
		"category": "misc",
		"pattern": {
			"kind": "substring",
			"value": "Cannot open file"
		},
		"example_error": "ERROR: res://scene.tscn:3 - Cannot open file 'res://assets/missing.png'.",
		"explains": "A resource path points to a file that doesn't exist, or that Godot hasn't imported yet.",
		"causes": [
			"Typo in the path (case matters on Linux/Android)",
			"File was moved or renamed",
			"Asset hasn't been imported (open the project in the editor to trigger import)",
		],
		"fix": {
			"code": "if ResourceLoader.exists(\"res://assets/sprite.png\"):\n\tvar tex: Texture2D = load(\"res://assets/sprite.png\")\nelse:\n\tpush_error(\"sprite.png not found - check the path\")\n",
			"description": "Verify the path in the FileSystem dock. Paths are case-sensitive and relative to the project root."
		},
		"related": ["null_instance_call"],
	})

	out.append({
		"id": "parse_error_expected_expression",
		"title": "Parse error - expected an expression",
		"category": "syntax",
		"pattern": {
			"kind": "substring",
			"value": "Expected expression"
		},
		"example_error": "ERROR: res://test.gd:5 - Parse Error: Expected expression as the function argument.",
		"explains": "The parser expected a value, variable, or function call, but found something else. Often a missing comma, an empty argument, or a stray operator.",
		"causes": [
			"Empty argument in a function call: foo(,) or foo(a, )",
			"Trailing comma before a close paren without a value",
			"Missing operand in an expression: var x = 5 *",
			"Unclosed string or bracket on a previous line",
		],
		"fix": {
			"code": "# Read the line number in the error, then look at that\n# line AND the line above it.\n#\n# Check for:\n#   - missing values after commas\n#   - trailing operators (+ - * / =)\n#   - unclosed quotes or brackets on the line before",
			"description": "Fix the syntax at the line number shown. The parser points to where it got confused, which is often one line after the real mistake."
		},
		"related": ["parse_error_generic", "parse_error_unexpected_token"],
	})

	out.append({
		"id": "parse_error_unexpected_token",
		"title": "Parse error - unexpected token",
		"category": "syntax",
		"pattern": {
			"kind": "substring",
			"value": "Unexpected"
		},
		"example_error": "ERROR: res://test.gd:10 - Parse Error: Unexpected \"else\" in class body.",
		"explains": "The parser found a keyword, symbol, or identifier where it didn't expect one. Usually means a block wasn't closed properly, or a previous statement is incomplete.",
		"causes": [
			"Mismatched if/else: an 'else' with no matching 'if'",
			"Missing colon after a block opener",
			"Indentation mismatch - a block ended earlier than you thought",
			"Stray bracket or parenthesis left open",
		],
		"fix": {
			"code": "# Read the error line and the line ABOVE it.\n# The real problem is usually on the previous line:\n#   - a missing ':' after if/for/while\n#   - an indent that doesn't match\n#   - a leftover ')' from the previous statement",
			"description": "Look at the line above the reported error. That's where the mistake usually lives."
		},
		"related": ["parse_error_generic", "parse_error_expected_expression"],
	})

	out.append({
		"id": "parse_error_generic",
		"title": "Parse error - general",
		"category": "syntax",
		"pattern": {
			"kind": "substring",
			"value": "Parse Error:"
		},
		"example_error": "ERROR: res://test.gd:5 - Parse Error: Expected expression as the function argument.",
		"explains": "Godot can't parse this script. The text after 'Parse Error:' says what the parser was expecting. The line number points to where it got stuck - the real mistake is often one line above.",
		"causes": [
			"Missing colon, comma, parenthesis, or closing bracket",
			"Keyword in the wrong place",
			"Indentation that doesn't match a block",
			"Unclosed string",
		],
		"fix": {
			"code": "# 1. Note the line number in the error.\n# 2. Read that line AND the line above it.\n# 3. Check for missing :, ), ], }, or quotes.\n# 4. Re-indent the file if unsure: Ctrl+Shift+I in the editor.",
			"description": "Parse errors halt the script from loading. Fix the syntax and the error goes away. The reported line number is where the parser gave up, not necessarily where the bug is."
		},
		"related": ["parse_error_expected_expression", "parse_error_unexpected_token"],
	})

	return out


# --- self-test ----------------------------------------------------------

static func self_test() -> void:
	print("=== ErrorLibrary self-test ===")
	var failures: Array[String] = []

	var lib: ErrorLibrary = ErrorLibrary.new()
	lib.load_all()

	# 1. Starter set registered
	if lib.record_count() != 17:
		failures.append("1: expected 17 starter records, got %d" % lib.record_count())
	if lib.reject_log().size() != 0:
		failures.append("1: starter set produced %d rejects" % lib.reject_log().size())

	# 2. Categories populated
	for cat in ["null_safety", "node", "signal", "input", "type_error", "syntax", "misc"]:
		if lib.ids_in_category(cat).is_empty():
			failures.append("2: category '%s' has no records" % cat)

	# 3. Every record's example_error matches its own pattern
	var ids: Array = lib.all_ids()
	var i: int = 0
	while i < ids.size():
		var rid: String = str(ids[i])
		var rec: Dictionary = lib.get_record(rid)
		var example: String = str(rec.get("example_error", ""))
		if example != "":
			var hit: Dictionary = lib.match_line(example)
			if hit.is_empty():
				failures.append("3: '%s' pattern doesn't match its own example_error" % rid)
			elif str(hit.get("id", "")) != rid:
				var other: String = str(hit.get("id", "?"))
				var own_len: int = str(rec.get("pattern", {}).get("value", "")).length()
				var other_len: int = str(hit.get("pattern", {}).get("value", "")).length()
				if own_len >= other_len:
					failures.append("3: '%s' example matched '%s' instead (same or shorter length)" % [rid, other])
		i += 1

	# 4. Known real error strings match the right records
	var cases: Array = [
		["ERROR: res://player.gd:42 - Invalid call. Nonexistent function 'jump' in base 'Nil'.", "null_instance_call"],
		["ERROR: res://test.gd:5 - Parse Error: Expected expression as the function argument.", "parse_error_expected_expression"],
		["ERROR: res://player.gd:15 - Invalid get index 'health' (on base: 'Nil').", "null_instance_index"],
		["ERROR: res://ui.gd:8 - Invalid assignment of property or key 'text' with value of type 'String' on a base object of type 'Nil'.", "null_instance_set"],
		["ERROR: res://player.gd:5 - Cannot infer the type of \"x\" variable because the value doesn't have a set type.", "cannot_infer_type"],
		["ERROR: Node not found: \"Player\" (relative to \"/root/Main\").", "node_not_found"],
		["ERROR: Division by zero in operator '/'.", "division_by_zero"],
		["ERROR: res://scene.tscn:3 - Cannot open file 'res://assets/missing.png'.", "resource_not_found"],
	]
	i = 0
	while i < cases.size():
		var line: String = str(cases[i][0])
		var expected_id: String = str(cases[i][1])
		var hit: Dictionary = lib.match_line(line)
		if hit.is_empty():
			failures.append("4: '%s' matched nothing" % expected_id)
		elif str(hit.get("id", "")) != expected_id:
			failures.append("4: '%s' matched '%s' instead" % [expected_id, str(hit.get("id", "?"))])
		i += 1

	# 5. Non-error text matches nothing
	var non_matches: Array = [
		"",
		"Just a normal line",
		"print(\"hello\")",
		"func _ready() -> void:",
	]
	i = 0
	while i < non_matches.size():
		var h: Dictionary = lib.match_line(str(non_matches[i]))
		if not h.is_empty():
			failures.append("5: '%s' should not match anything" % str(non_matches[i]))
		i += 1

	# 6. extract_message strips prefix and file path
	var msg: String = lib.extract_message("ERROR: res://player.gd:42 - Invalid call. Nonexistent function 'jump' in base 'Nil'.")
	if msg != "Invalid call. Nonexistent function 'jump' in base 'Nil'.":
		failures.append("6: extract_message failed on engine path, got: " + msg)

	var msg2: String = lib.extract_message("ERROR: Division by zero in operator '/'.")
	if msg2 != "Division by zero in operator '/'.":
		failures.append("6: extract_message failed on plain error, got: " + msg2)

	# 7. Duplicate ID rejected
	var dupe: Dictionary = lib.get_record("null_instance_call")
	if lib.register_record(dupe):
		failures.append("7: duplicate id should be rejected")

	# 8. Bad record rejected
	var bad: Dictionary = {"id": "broken", "title": "x"}
	if lib.register_record(bad):
		failures.append("8: incomplete record should be rejected")

	# 9. Bulk register into a fresh library
	var lib2: ErrorLibrary = ErrorLibrary.new()
	lib2.load_all()
	var extra: Array = [{
		"id": "custom_error",
		"title": "Custom",
		"category": "misc",
		"pattern": {"kind": "substring", "value": "custom failure token"},
		"explains": "test",
		"fix": {"code": "pass\n", "description": "test"},
	}]
	var accepted: int = lib2.register_records(extra)
	if accepted != 1:
		failures.append("9: bulk register should accept 1, got %d" % accepted)

	# 10. Substring pattern kind works
	var hit10: Dictionary = lib2.match_line("Some prefix custom failure token and more")
	if hit10.is_empty() or str(hit10.get("id", "")) != "custom_error":
		failures.append("10: substring pattern should match mid-line")

	print("")
	if failures.is_empty():
		print("OK - all assertions passed")
	else:
		print("FAILED - %d issues:" % failures.size())
		i = 0
		while i < failures.size():
			print("  " + failures[i])
			i += 1
