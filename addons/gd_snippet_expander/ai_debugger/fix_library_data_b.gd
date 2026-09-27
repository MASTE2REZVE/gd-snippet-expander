# res://addons/gd_snippet_expander/ai_debugger/fix_library_data_b.gd
@tool
class_name FixLibraryDataB
extends RefCounted

## Fix records, volume B: null safety, signals, nodes.
##
## Part of the GD Snippet Expander mini AI debugger (v1.6).
## Forty-one curated records covering null references, signal
## wiring mistakes, and node lifecycle confusion — the three
## categories where beginners lose the most time to silent failures.
##
## Usage from the plugin loader:
##   var lib := FixLibrary.new()
##   lib.load_all()
##   FixLibraryDataA.register_into(lib)
##   FixLibraryDataB.register_into(lib)   # this file
##
## Some records here ship with a `questions` array. The classifier
## uses them when its top candidate isn't clearly ahead: it asks the
## user the question whose answer best separates the candidates.

# --- public entry points -----------------------------------------------

static func register_into(lib: FixLibrary) -> int:
	return lib.register_records(records())


static func records() -> Array:
	var out: Array = []

	# ===================================================================
	# NULL SAFETY (14)
	# ===================================================================

	out.append({
		"id": "null_after_free",
		"title": "Using a node reference after it was freed",
		"category": "null_safety",
		"phrases": [
			"previously freed instance",
			"cannot call method on freed object",
			"freed object error",
			"is instance valid check",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "queue_free"},
			{"kind": "identifier", "value": "is_instance_valid", "negate": true},
		],
		"candidates": [{
			"code": "if is_instance_valid(target):\n\ttarget.do_something()\n",
			"description": "queue_free marks a node for deletion at end of frame. Any call to a method on the freed reference after that crashes. Wrap every call with is_instance_valid.",
			"confidence": 0.80,
		}],
	})

	out.append({
		"id": "null_signal_arg",
		"title": "Signal argument arrives as null",
		"category": "null_safety",
		"phrases": [
			"signal argument is null",
			"signal passes null",
			"connected function gets null",
			"signal parameter empty",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "connect"},
		],
		"candidates": [{
			"code": "func _on_health_changed(new_health: int) -> void:\n\tif new_health <= 0:\n\t\treturn\n\t# safe to use\n",
			"description": "Emitters can pass null. Either validate in the handler or guard at the emit site with `if value != null:` before emit_signal.",
			"confidence": 0.55,
		}],
	})

	out.append({
		"id": "null_typed_var",
		"title": "Typed variable holds null and crashes on use",
		"category": "null_safety",
		"phrases": [
			"typed variable is null",
			"var x null at runtime",
			"reference to null instance",
			"null variable error",
		],
		"code_patterns": [
			{"kind": "substring", "value": "= null"}
		],
		"candidates": [{
			"code": "var target: Node = null\n\nfunc do_thing() -> void:\n\tif target == null:\n\t\tpush_warning(\"target not set\")\n\t\treturn\n\ttarget.method()\n",
			"description": "Typed variables can still be null. Check before use, or initialize in _ready with @onready var.",
			"confidence": 0.70,
		}],
		"questions": [{
			"text": "Where does the null value come from?",
			"answers": [
				{"text": "From get_node() that couldn't find the path", "boosts": ["get_node_or_null_returns_null"]},
				{"text": "From a variable I set to null on purpose", "boosts": ["null_typed_var"]},
				{"text": "From a signal or await that returned nothing", "boosts": ["await_result_null"]},
			],
		}],
	})

	out.append({
		"id": "get_node_or_null_returns_null",
		"title": "get_node_or_null returns null when the path is wrong",
		"category": "null_safety",
		"phrases": [
			"get_node_or_null returns null",
			"path not found in get_node_or_null",
			"node path wrong"
		],
		"code_patterns": [
			{"kind": "identifier", "value": "get_node_or_null"},
			{"kind": "substring", "value": "if ", "negate": true},
		],
		"candidates": [{
			"code": "var target: Node = get_node_or_null(\"../Enemy\")\nif target == null:\n\tpush_error(\"Enemy not found at ../Enemy — check scene tree\")\n\treturn\n",
			"description": "get_node_or_null doesn't throw like get_node does — it silently returns null. Always check the result.",
			"confidence": 0.82,
		}],
	})

	out.append({
		"id": "instantiate_returns_null",
		"title": "instantiate() returns null on missing resource",
		"category": "null_safety",
		"phrases": [
			"instantiate returns null",
			"packed scene won't instantiate",
			"instantiated scene is null",
			"add_child null",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "instantiate"},
		],
		"candidates": [{
			"code": "var scene: PackedScene = load(\"res://enemy.tscn\") as PackedScene\nif scene == null:\n\tpush_error(\"Scene failed to load\")\n\treturn\nvar inst: Node = scene.instantiate()\nif inst == null:\n\tpush_error(\"instantiate failed\")\n\treturn\nadd_child(inst)\n",
			"description": "load() returns null for a missing path. instantiate() returns null for an invalid PackedScene. Check both.",
			"confidence": 0.75,
		}],
	})

	out.append({
		"id": "owner_is_null",
		"title": "owner is null outside the scene tree",
		"category": "null_safety",
		"phrases": [
			"owner is null",
			"can't get owner of node",
			"owner missing",
			"owner property null",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "owner"},
		],
		"candidates": [{
			"code": "# owner is only set on nodes saved as part of a scene.\n# If the node was created with .new() it has no owner.\n# If you need a reference to the containing scene, use:\nvar scene_root: Node = get_tree().current_scene\n",
			"description": "Nodes created at runtime via new() have owner == null. The owner property only points to the scene root for nodes that were serialized into a .tscn.",
			"confidence": 0.70,
		}],
	})

	out.append({
		"id": "get_first_node_in_group_empty",
		"title": "get_first_node_in_group returns null on empty group",
		"category": "null_safety",
		"phrases": [
			"group is empty",
			"no nodes in group",
			"get_first_node_in_group null",
			"first node in group missing",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "get_first_node_in_group"},
		],
		"candidates": [{
			"code": "var player: Node = get_tree().get_first_node_in_group(\"player\")\nif player == null:\n\tpush_error(\"No node in group 'player'\")\n\treturn\n",
			"description": "Groups can be empty at runtime — the player might not have spawned yet, or the group name is a typo. Always check for null.",
			"confidence": 0.75,
		}],
	})

	out.append({
		"id": "dict_key_missing",
		"title": "Dictionary subscript on a missing key throws",
		"category": "null_safety",
		"phrases": [
			"invalid index on dictionary",
			"key not found in dict",
			"dictionary access error",
			"dict get returns null",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "get"}
		],
		"candidates": [{
			"code": "var value: Variant = my_dict.get(\"key\", null)\nif value == null:\n\t# key was missing\n\treturn\n# safe to use value\n",
			"description": "dict[\"key\"] throws if the key doesn't exist. dict.get(\"key\", default) returns a default instead.",
			"confidence": 0.78,
		}],
	})

	out.append({
		"id": "resource_load_failed",
		"title": "load() returns null for a missing resource",
		"category": "null_safety",
		"phrases": [
			"resource load fails",
			"texture is null",
			"audio file not loading",
			"load() returns null"
		],
		"code_patterns": [
			{"kind": "identifier", "value": "load"}
		],
		"candidates": [{
			"code": "var texture: Texture2D = load(\"res://icon.svg\") as Texture2D\nif texture == null:\n\tpush_error(\"icon.svg not found — check path and import status\")\n\treturn\n",
			"description": "load() returns null if the path is wrong, the file hasn't been imported yet, or it's the wrong resource type. Use load with a type cast and check.",
			"confidence": 0.72,
		}],
	})

	out.append({
		"id": "get_parent_at_root",
		"title": "get_parent() is null on the scene root",
		"category": "null_safety",
		"phrases": [
			"get_parent returns null",
			"parent is null",
			"no parent node",
			"root has no parent",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "get_parent"},
		],
		"candidates": [{
			"code": "var p: Node = get_parent()\nif p == null:\n\t# We're the scene root — no parent above us\n\treturn\n",
			"description": "The scene tree root has no parent. If your node is the current scene root, get_parent() returns null.",
			"confidence": 0.80,
		}],
	})

	out.append({
		"id": "autoload_not_registered",
		"title": "Autoload singleton name used but not registered",
		"category": "null_safety",
		"phrases": [
			"autoload not found",
			"singleton missing",
			"global name not defined",
			"autoload script errors"
		],
		"code_patterns": [
			{"kind": "identifier", "value": "autoload"}
		],
		"candidates": [{
			"code": "# Project Settings -> Autoload -> Add the script with a name.\n# Then the name becomes a global identifier.\n# Autoloads are instantiated before any scene, so you can use\n# them from _ready() and later.\n",
			"description": "An autoload that isn't listed in Project Settings -> Autoload has no global name. Add it there, or the identifier won't resolve.",
			"confidence": 0.68,
		}],
	})

	out.append({
		"id": "await_result_null",
		"title": "await returns null instead of the expected value",
		"category": "null_safety",
		"phrases": [
			"await returns null",
			"await value is null",
			"await gives nothing",
			"await result is empty",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "await"},
		],
		"candidates": [{
			"code": "var result: Variant = await some_signal\nif result == null:\n\tpush_warning(\"await returned null\")\n\treturn\n",
			"description": "Signals that carry no arguments emit null. Signals that do carry arguments emit their argument. Use the signature to know what to expect.",
			"confidence": 0.60,
		}],
	})

	out.append({
		"id": "null_typed_array_access",
		"title": "Array subscript out of bounds returns null or throws",
		"category": "null_safety",
		"phrases": [
			"array index out of bounds",
			"array subscript error",
			"index out of range",
			"array access invalid",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "size"}
		],
		"candidates": [{
			"code": "if arr.size() > index and index >= 0:\n\tvar item: Variant = arr[index]\n\t# safe\n",
			"description": "Indexing an array beyond its length throws. Check size first, or use arr.front() / arr.back() for the common first/last cases.",
			"confidence": 0.72,
		}],
	})

	out.append({
		"id": "assert_condition_false",
		"title": "assert() aborts the game in debug builds",
		"category": "null_safety",
		"phrases": [
			"assert failed",
			"assertion error",
			"assert stops the game",
			"debug assert message",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "assert"}
		],
		"candidates": [{
			"code": "# assert() halts execution if its condition is false in debug builds.\n# In release builds, assert() is stripped out entirely.\n# If you want an in-game check that also runs in release, use:\nif not condition:\n\tpush_error(\"condition failed\")\n\treturn\n",
			"description": "assert is a development tool. It's compiled out of release builds. If you need runtime enforcement, use an explicit if + push_error.",
			"confidence": 0.65,
		}],
	})

	# ===================================================================
	# SIGNALS (13)
	# ===================================================================

	out.append({
		"id": "signal_not_emitted",
		"title": "Signal is connected but never fires",
		"category": "signals",
		"phrases": [
			"signal never fires",
			"signal doesn't trigger",
			"connected function never runs",
			"signal not emitting",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "connect"},
			{"kind": "identifier", "value": "emit", "negate": true},
		],
		"candidates": [{
			"code": "# In the class that declares the signal:\nsignal my_signal(value: int)\n\nfunc do_thing() -> void:\n\tmy_signal.emit(42)   # without this, nothing fires\n",
			"description": "A declared signal does nothing until something calls emit() on it. The signal declaration only creates the signal object.",
			"confidence": 0.78,
		}],
	})

	out.append({
		"id": "signal_connect_failed",
		"title": "connect() fails silently",
		"category": "signals",
		"phrases": [
			"connect fails",
			"signal connection error",
			"connect returns error",
			"callable not connected",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "connect"},
		],
		"candidates": [{
			"code": "var err: int = button.pressed.connect(_on_pressed)\nif err != OK:\n\tpush_error(\"connect failed: %d\" % err)\n",
			"description": "connect() returns an Error enum. Print it to see why the connection failed: wrong method name, wrong arg count, already connected, or the node was freed.",
			"confidence": 0.72,
		}],
		"questions": [{
			"text": "What does the Error value look like?",
			"answers": [
				{"text": "ERR_INVALID_PARAMETER (31)", "boosts": ["signal_wrong_arg_count"]},
				{"text": "ERR_ALREADY_EXISTS (30)", "boosts": ["signal_duplicate_connection"]},
				{"text": "It returns OK but nothing happens", "boosts": ["signal_emitted_before_connect"]},
			],
		}],
	})

	out.append({
		"id": "signal_emitted_before_connect",
		"title": "Signal fired before anything connected to it",
		"category": "signals",
		"phrases": [
			"signal already fired",
			"missed signal",
			"too late to connect",
			"signal fired in ready"
		],
		"code_patterns": [
			{"kind": "identifier", "value": "connect"},
		],
		"candidates": [{
			"code": "# If the signal fires in _ready() of the emitter, listeners\n# connected from the parent's _ready() might miss it if the\n# parent's _ready runs after the child's.\n#\n# Fix: connect in _enter_tree(), or have the emitter use\n# call_deferred to fire the signal on the next idle frame.\n",
			"description": "In Godot, _ready is called on children before parents. If a child emits in its _ready, listeners in the parent haven't connected yet.",
			"confidence": 0.58,
		}],
	})

	out.append({
		"id": "signal_arg_type_mismatch",
		"title": "Signal argument type doesn't match handler",
		"category": "signals",
		"phrases": [
			"signal type mismatch",
			"argument type wrong",
			"signal handler parameter wrong",
			"signal param type error"
		],
		"code_patterns": [
			{"kind": "identifier", "value": "connect"},
		],
		"candidates": [{
			"code": "signal value_changed(new_value: float)\n\nfunc _on_value_changed(new_value: float) -> void:\n\t# must match the signal's declared type exactly\n\tpass\n",
			"description": "The handler's parameter types must match the signal's declared types. int vs float is not auto-converted at connect time.",
			"confidence": 0.65,
		}],
	})

	out.append({
		"id": "signal_one_shot",
		"title": "Signal fires multiple times when only one was wanted",
		"category": "signals",
		"phrases": [
			"signal fires twice",
			"signal fires many times",
			"connected multiple times",
			"duplicate signal firing",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "connect"},
		],
		"candidates": [{
			"code": "var err: int = target.signal_name.connect(_on_signal, CONNECT_ONE_SHOT)\n",
			"description": "CONNECT_ONE_SHOT auto-disconnects after the first emission. Pass it as the third argument to connect().",
			"confidence": 0.70,
		}],
	})

	out.append({
		"id": "signal_await_timeout",
		"title": "awaiting a signal with no timeout",
		"category": "signals",
		"phrases": [
			"await hangs forever",
			"await never returns",
			"await stuck",
			"await timeout"
		],
		"code_patterns": [
			{"kind": "identifier", "value": "await"},
		],
		"candidates": [{
			"code": "var timer: SceneTreeTimer = get_tree().create_timer(5.0)\nvar timeout_result: Variant = await timer.timeout\n# or race the two awaits with a helper\n",
			"description": "await has no built-in timeout. If the awaited signal never fires, the coroutine suspends forever. Use create_timer as a watchdog, or emit a fallback signal.",
			"confidence": 0.60,
		}],
	})

	out.append({
		"id": "signal_callable_bind",
		"title": "Pass extra arguments to a signal handler with bind",
		"category": "signals",
		"phrases": [
			"pass extra args to signal",
			"signal handler with extra data",
			"bind signal args",
			"connect with bind",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "connect"},
		],
		"candidates": [{
			"code": "button.pressed.connect(_on_button_pressed.bind(\"jump\"))\n\nfunc _on_button_pressed(action: String) -> void:\n\t# action == \"jump\"\n\tpass\n",
			"description": "Callable.bind() prepends arguments to the handler's call. The bound args come after any signal-emitted args.",
			"confidence": 0.68,
		}],
	})

	out.append({
		"id": "signal_typed_params",
		"title": "Typed signal parameters",
		"category": "signals",
		"phrases": [
			"typed signal",
			"signal with types",
			"signal parameter type hints",
			"signal signature",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "signal"},
		],
		"candidates": [{
			"code": "signal health_changed(new_health: int, old_health: int)\nsignal died()\nsignal item_picked(item: Item)\n",
			"description": "Declare parameter types on signals just like functions. The editor and the type checker will then catch mismatched connect() calls.",
			"confidence": 0.62,
		}],
	})

	out.append({
		"id": "signal_duplicate_connection",
		"title": "Same handler connected twice",
		"category": "signals",
		"phrases": [
			"handler called twice",
			"connect called multiple times",
			"signal fires double",
			"duplicate connection error",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "connect"},
			{"kind": "identifier", "value": "is_connected", "negate": true},
		],
		"candidates": [{
			"code": "if not target.pressed.is_connected(_on_pressed):\n\ttarget.pressed.connect(_on_pressed)\n",
			"description": "Godot 4 allows the same Callable to connect multiple times. Guard with is_connected() before connecting.",
			"confidence": 0.72,
		}],
	})

	out.append({
		"id": "signal_disconnect_during_emit",
		"title": "Disconnecting a signal from inside its own handler",
		"category": "signals",
		"phrases": [
			"disconnect during emit",
			"signal handler disconnects itself",
			"cannot disconnect while emitting",
			"modify signal during emission",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "disconnect"},
		],
		"candidates": [{
			"code": "func _on_signal() -> void:\n\tsome_signal.disconnect(_on_signal)   # deferring is safer:\n\t# call_deferred(\"some_signal.disconnect\", _on_signal)\n",
			"description": "Modifying the connection list while a signal is being emitted can skip or double-fire handlers. Defer the disconnect to the next frame.",
			"confidence": 0.58,
		}],
	})

	out.append({
		"id": "signal_emit_in_ready",
		"title": "Emitting a signal from _ready() misses early listeners",
		"category": "signals",
		"phrases": [
			"signal emitted in ready",
			"signal from _ready not received",
			"connect after ready",
			"signal at startup",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "emit"},
			{"kind": "identifier", "value": "_ready"},
		],
		"candidates": [{
			"code": "func _ready() -> void:\n\t# Emitting here fires before parent nodes have connected.\n\t# Use call_deferred so it fires next idle frame:\n\tmy_signal.emit.call_deferred(initial_value)\n",
			"description": "In Godot, _ready runs children first, then parents. An emit in a child's _ready fires before the parent's _ready has connected listeners. call_deferred pushes the emission one frame later.",
			"confidence": 0.62,
		}],
	})

	out.append({
		"id": "signal_custom_no_params",
		"title": "Signal declared without parameters then emitted with arguments",
		"category": "signals",
		"phrases": [
			"signal wrong arg count",
			"emit too many args",
			"signal takes no parameters",
			"signal emits with args"
		],
		"code_patterns": [
			{"kind": "identifier", "value": "emit"},
		],
		"candidates": [{
			"code": "signal my_signal\n\nfunc do_thing() -> void:\n\tmy_signal.emit()   # no args — signal was declared bare\n",
			"description": "If the signal was declared with no parameters, emitting with args throws. Add parameter types to the declaration to carry data.",
			"confidence": 0.70,
		}],
	})

	out.append({
		"id": "signal_wrong_arg_count",
		"title": "Handler argument count doesn't match the signal",
		"category": "signals",
		"phrases": [
			"wrong number of arguments",
			"arg count mismatch",
			"signal connect fails with count",
			"handler too many parameters",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "connect"},
		],
		"candidates": [{
			"code": "# A signal declared as `signal hit(damage: int, source: Node)`\n# needs a handler that accepts exactly those arguments.\nfunc _on_hit(damage: int, source: Node) -> void:\n\tpass\n",
			"description": "Handlers must accept exactly as many arguments as the signal emits. Too few or too many throws ERR_INVALID_PARAMETER at connect time.",
			"confidence": 0.74,
		}],
	})

	# ===================================================================
	# NODES (14)
	# ===================================================================

	out.append({
		"id": "ready_not_called",
		"title": "_ready never fires on a node",
		"category": "nodes",
		"phrases": [
			"_ready not called",
			"ready doesn't run",
			"init code doesn't run",
			"node not initialized",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "_ready"},
		],
		"candidates": [{
			"code": "# _ready fires only after the node enters the tree.\n# If you never add_child(), _ready never runs.\n# If you override _ready, call super._ready() when extending.\nfunc _ready() -> void:\n\tsuper._ready()\n\t# your init here\n",
			"description": "Three common causes: (1) the node was created with .new() but never added to the tree, (2) a parent class overrode _ready without calling super, (3) the script isn't attached to the node.",
			"confidence": 0.70,
		}],
		"questions": [{
			"text": "How is this node created?",
			"answers": [
				{"text": "In the editor, added to the scene tree manually", "boosts": ["ready_vs_enter_tree"]},
				{"text": "At runtime via .new()", "boosts": ["ready_not_called"]},
				{"text": "At runtime via instantiate() from a .tscn", "boosts": ["node_added_to_wrong_parent"]},
			],
		}],
	})

	out.append({
		"id": "process_not_called",
		"title": "_process never runs",
		"category": "nodes",
		"phrases": [
			"_process not called",
			"process doesn't run",
			"node doesn't update",
			"my code in process never runs",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "_process"},
		],
		"candidates": [{
			"code": "# _process is called by default when the node is in the tree.\n# It will not run if:\n#  - set_process(false) was called\n#  - the node was removed from the tree\n#  - process_mode = PROCESS_MODE_DISABLED\n",
			"description": "Check set_process(false), process_mode, and whether the node is in the tree (is_inside_tree()).",
			"confidence": 0.65,
		}],
	})

	out.append({
		"id": "node_added_to_wrong_parent",
		"title": "Node added to the wrong parent so lookups fail",
		"category": "nodes",
		"phrases": [
			"node in wrong place",
			"add_child wrong parent",
			"node structure wrong",
			"get_node can't find instantiated node",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "add_child"},
		],
		"candidates": [{
			"code": "# add_child() places the node as a direct child of the caller.\n# If you want a grandchild relationship, add_child on the right parent:\n$EnemyHolder.add_child(enemy_instance)\n# NOT just add_child(enemy_instance) on self\n",
			"description": "add_child puts the node under the calling node. If your get_node path assumes a different parent, the lookup will fail.",
			"confidence": 0.68,
		}],
	})

	out.append({
		"id": "node_name_collision",
		"title": "Duplicate node names cause auto-renaming",
		"category": "nodes",
		"phrases": [
			"node renamed at runtime",
			"@2 added to node name",
			"duplicate node name",
			"node name changes",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "add_child"},
		],
		"candidates": [{
			"code": "inst.name = \"Enemy_%d\" % Time.get_ticks_msec()\nparent.add_child(inst)\n",
			"description": "Godot auto-renames siblings that share a name (adds @2, @3, etc.). If code looks up the node by name, it will fail after the second add. Give each instance a unique name or use a reference variable.",
			"confidence": 0.72,
		}],
	})

	out.append({
		"id": "node_order_in_scene",
		"title": "Child order matters for _ready timing",
		"category": "nodes",
		"phrases": [
			"child ready order",
			"ready called on children first",
			"parent ready after child",
			"_ready order wrong",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "_ready"},
		],
		"candidates": [{
			"code": "# _ready fires bottom-up: children before parents.\n# If a parent needs to initialize something BEFORE children use it,\n# do that init in _enter_tree (which fires top-down).\n",
			"description": "_enter_tree is called on parents first, then children. _ready is called on children first, then parents. Choose the callback based on direction.",
			"confidence": 0.62,
		}],
	})

	out.append({
		"id": "ready_vs_enter_tree",
		"title": "_ready vs _enter_tree timing",
		"category": "nodes",
		"phrases": [
			"ready vs enter tree",
			"when is ready called",
			"when is enter tree called",
			"init order",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "_ready"},
			{"kind": "identifier", "value": "_enter_tree", "negate": true},
		],
		"candidates": [{
			"code": "func _enter_tree() -> void:\n\t# node is in the tree, children may not be ready yet\n\tpass\n\nfunc _ready() -> void:\n\t# node and all children are fully initialized\n\tpass\n",
			"description": "_enter_tree: node is added to tree, ready to be queried. _ready: node AND all its children have entered the tree.",
			"confidence": 0.75,
		}],
	})

	out.append({
		"id": "remove_child_vs_queue_free",
		"title": "remove_child doesn't free the node",
		"category": "nodes",
		"phrases": [
			"remove_child memory leak",
			"removed node still exists",
			"queue_free vs remove_child",
			"node removed but visible"
		],
		"code_patterns": [
			{"kind": "identifier", "value": "remove_child"},
			{"kind": "identifier", "value": "queue_free", "negate": true},
		],
		"candidates": [{
			"code": "parent.remove_child(child)\nchild.queue_free()   # frees the node itself\n",
			"description": "remove_child only detaches from the tree — the node object still exists in memory. queue_free removes AND deletes.",
			"confidence": 0.78,
		}],
	})

	out.append({
		"id": "node_visibility",
		"title": "Node exists but is invisible",
		"category": "nodes",
		"phrases": [
			"node not showing",
			"sprite invisible",
			"node exists but can't see",
			"nothing renders",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "visible"},
		],
		"candidates": [{
			"code": "# Check these in order:\n#   visible (self)\n#   modulate.a (transparency)\n#   z_index / position (behind other nodes)\n#   parent's visible (hides children too)\n",
			"description": "A node is invisible if any of these are wrong: visible == false, modulate.a == 0, z_index is behind another node, or a parent is hidden.",
			"confidence": 0.62,
		}],
	})

	out.append({
		"id": "node_processing_disabled",
		"title": "Node processing disabled via process_mode",
		"category": "nodes",
		"phrases": [
			"node frozen",
			"physics paused",
			"processing stopped",
			"process_mode disabled"
		],
		"code_patterns": [
			{"kind": "identifier", "value": "process_mode"},
		],
		"candidates": [{
			"code": "# Check process_mode on this node AND its ancestors.\n# PROCESS_MODE_DISABLED stops processing.\n# PROCESS_MODE_WHEN_PAUSED only runs during pause.\n# PROCESS_MODE_ALWAYS ignores the tree's paused state.\n",
			"description": "process_mode on a parent affects all descendants. If the tree is paused and this node's mode doesn't include PROCESS_MODE_ALWAYS, it won't process.",
			"confidence": 0.65,
		}],
	})

	out.append({
		"id": "z_index_wrong",
		"title": "Node renders behind or in front of the wrong thing",
		"category": "nodes",
		"phrases": [
			"sprite behind background",
			"draw order wrong",
			"z_index doesn't work",
			"layer order wrong",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "z_index"},
		],
		"candidates": [{
			"code": "# z_index only matters within the same parent's draw order.\n# If a background and a sprite are siblings, use z_index:\n#   background.z_index = -1\n#   sprite.z_index = 0\n# If they're in different parents, sort the parents instead.\n",
			"description": "z_index applies within a parent. Sibling order and CanvasLayer placement also affect draw order.",
			"confidence": 0.60,
		}],
	})

	out.append({
		"id": "node_duplicate",
		"title": "Duplicate a node at runtime",
		"category": "nodes",
		"phrases": [
			"duplicate node",
			"clone node",
			"copy node at runtime",
			"instance duplicate",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "duplicate"},
		],
		"candidates": [{
			"code": "var copy: Node = original.duplicate()\nparent.add_child(copy)\ncopy.global_position = spawn_point\n",
			"description": "duplicate() deep-copies the node. Set its position and add it to the tree after duplicating.",
			"confidence": 0.68,
		}],
	})

	out.append({
		"id": "node_reparent",
		"title": "Reparent a node without losing its position",
		"category": "nodes",
		"phrases": [
			"move node to new parent",
			"reparent node",
			"change parent at runtime",
			"node jumps when reparented",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "reparent"},
		],
		"candidates": [{
			"code": "var world_pos: Vector2 = child.global_position\nchild.get_parent().remove_child(child)\nnew_parent.add_child(child)\nchild.global_position = world_pos\n",
			"description": "Godot 4.2+ has reparent(new_parent, keep_global_transform). Before that, remove then add and restore global_position manually.",
			"confidence": 0.62,
		}],
	})

	out.append({
		"id": "_ready_called_before_parent_ready",
		"title": "Child accesses parent before parent is ready",
		"category": "nodes",
		"phrases": [
			"parent not ready",
			"parent null in child ready",
			"get_parent in _ready fails",
			"parent properties missing",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "_ready"},
			{"kind": "identifier", "value": "get_parent"},
		],
		"candidates": [{
			"code": "# Children's _ready runs before parent's _ready.\n# If a child needs something the parent sets up in _ready,\n# move that init to _enter_tree, or use call_deferred\n# in the child:\nfunc _ready() -> void:\n\tcall_deferred(\"_do_deferred_init\")\n\nfunc _do_deferred_init() -> void:\n\t# parent is now fully ready\n\tpass\n",
			"description": "_ready fires bottom-up. To run code after the parent has initialized, defer it to the next idle frame.",
			"confidence": 0.62,
		}],
	})

	out.append({
		"id": "call_deferred_pattern",
		"title": "Defer a method call to the next idle frame",
		"category": "nodes",
		"phrases": [
			"call_deferred",
			"run code next frame",
			"defer method call",
			"can't modify during signal",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "call_deferred"},
		],
		"candidates": [{
			"code": "call_deferred(\"do_thing\", arg1, arg2)\n# or with a Callable in Godot 4:\ndo_thing.call_deferred(arg1, arg2)\n",
			"description": "call_deferred postpones execution to the end of the current frame. Fixes most \"can't modify tree during signal\" errors.",
			"confidence": 0.65,
		}],
	})

	return out


# --- self-test ----------------------------------------------------------

static func self_test() -> void:
	print("=== FixLibraryDataB self-test ===")
	var failures: Array[String] = []

	var arr: Array = records()
	if arr.size() != 41:
		failures.append("1: expected 41 records, got %d" % arr.size())

	var lib: FixLibrary = FixLibrary.new()
	lib.load_all()
	var added: int = register_into(lib)
	if added != arr.size():
		failures.append("2: register_into accepted %d of %d" % [added, arr.size()])
	if not lib.reject_log().is_empty():
		failures.append("2: %d rejects during registration" % lib.reject_log().size())

	var expected: Dictionary = {
		"null_safety": 14,
		"signals": 13,
		"nodes": 14,
	}
	var actual: Dictionary = {}
	var i: int = 0
	while i < arr.size():
		var rec: Dictionary = arr[i]
		var cat: String = str(rec.get("category", ""))
		actual[cat] = int(actual.get(cat, 0)) + 1
		i += 1

	var keys: Array = expected.keys()
	i = 0
	while i < keys.size():
		var k: String = str(keys[i])
		var want: int = int(expected[k])
		var got: int = int(actual.get(k, 0))
		if want != got:
			failures.append("3: category '%s' expected %d, got %d" % [k, want, got])
		i += 1

	var seen: Dictionary = {}
	i = 0
	while i < arr.size():
		var id: String = str(arr[i].get("id", ""))
		if seen.has(id):
			failures.append("4: duplicate id '%s'" % id)
		seen[id] = true
		i += 1

	# Cross-check that no IDs collide with the starter set.
	var starter_ids: Array = [
		"is_on_floor_missing", "gravity_not_applied", "delta_not_used",
		"input_map_missing", "input_get_action_strength",
		"get_node_returns_null", "node_path_wrong",
		"signal_wrong_signature", "await_signal_never_fires",
		"wrong_node_type", "queue_free_after_use",
		"rigidbody_moved_directly", "collision_layer_mismatch",
		"missing_type_hint", "godot3_to_godot4_rename",
	]
	i = 0
	while i < starter_ids.size():
		var sid: String = str(starter_ids[i])
		if seen.has(sid):
			failures.append("5: id '%s' collides with starter set" % sid)
		i += 1

	if not lib.has_record("signal_not_emitted"):
		failures.append("6: signal_not_emitted missing")
	if not lib.has_record("remove_child_vs_queue_free"):
		failures.append("6: remove_child_vs_queue_free missing")
	if not lib.has_record("null_after_free"):
		failures.append("6: null_after_free missing")

	var m1: Array = lib.records_matching_tokens(["signal"])
	if m1.is_empty():
		failures.append("7: 'signal' token should match records")
	var m2: Array = lib.records_matching_tokens(["null"])
	if m2.is_empty():
		failures.append("7: 'null' token should match records")

	# Verify questions field is well-formed where present.
	i = 0
	while i < arr.size():
		var rec2: Dictionary = arr[i]
		if rec2.has("questions"):
			var rid: String = str(rec2.get("id", "?"))
			var qs: Array = rec2["questions"]
			if qs.is_empty():
				failures.append("8: '%s' has empty questions array" % rid)
			var qi: int = 0
			while qi < qs.size():
				var q: Dictionary = qs[qi]
				if not q.has("text") or not q.has("answers"):
					failures.append("8: '%s' question missing text/answers" % rid)
					break
				if (q["answers"] as Array).is_empty():
					failures.append("8: '%s' question has no answers" % rid)
					break
				qi += 1
		i += 1

	print("")
	if failures.is_empty():
		print("OK — all assertions passed")
	else:
		print("FAILED — %d issues:" % failures.size())
		i = 0
		while i < failures.size():
			print("  " + failures[i])
			i += 1
