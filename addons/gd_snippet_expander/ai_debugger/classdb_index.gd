# res://addons/gd_snippet_expander/ai_debugger/classdb_index.gd
@tool
class_name ClassDBIndex
extends RefCounted

## Builds a searchable index of Godot's runtime API from ClassDB.
##
## Part of the GD Snippet Expander mini AI debugger (v1.6).
## Walks every class Godot exposes, records its methods, properties,
## signals, and integer constants, and provides fast lookups so the
## classifier can verify "does this method exist on this node type?"
## without re-querying ClassDB on every check.
##
## Build once at plugin load:
##   var idx := ClassDBIndex.new()
##   idx.build()
##
## Then query cheaply:
##   idx.has_method_on_class("CharacterBody3D", "move_and_slide")  # true
##   idx.has_property_on_class("Node2D", "position")               # true
##   idx.is_type_name("int")                                       # true
##   idx.is_type_name("Sprite2D")                                  # true
##   idx.is_type_name("Flibble")                                   # false
##
## Memory: roughly 1-2 MB for the full ClassDB surface. Startup cost
## is reported by self_test() (typically 30-80ms).

# --- constants ----------------------------------------------------------

## Built-in Variant types. These are not classes — they are value
## types the type system knows about. Hardcoded because ClassDB does
## not expose them and the list is stable across Godot 4.x versions.
const VARIANT_TYPES := {
	"bool": true, "int": true, "float": true, "String": true,
	"StringName": true, "NodePath": true, "RID": true, "Object": true,
	"Callable": true, "Signal": true, "Dictionary": true, "Array": true,
	"PackedByteArray": true, "PackedInt32Array": true,
	"PackedInt64Array": true, "PackedFloat32Array": true,
	"PackedFloat64Array": true, "PackedStringArray": true,
	"PackedVector2Array": true, "PackedVector3Array": true,
	"PackedColorArray": true,
	"Vector2": true, "Vector2i": true, "Rect2": true, "Rect2i": true,
	"Vector3": true, "Vector3i": true, "Transform2D": true,
	"Vector4": true, "Vector4i": true, "Plane": true, "Quaternion": true,
	"AABB": true, "Basis": true, "Transform3D": true, "Projection": true,
	"Color": true,
	"Variant": true, "void": true,
}

# --- internal state -----------------------------------------------------

var _by_class: Dictionary = {}          # cls -> {parent, methods, properties, signals, constants}
var _method_owner: Dictionary = {}      # method -> Array[cls where declared]
var _property_owner: Dictionary = {}    # property -> Array[cls]
var _signal_owner: Dictionary = {}      # signal -> Array[cls]
var _constant_owner: Dictionary = {}    # constant -> Array[cls]
var _built := false

# --- build --------------------------------------------------------------

## Walks ClassDB and populates the index. Safe to call more than once;
## the second call rebuilds from scratch. Typically 30-80ms.
func build() -> void:
	_by_class = {}
	_method_owner = {}
	_property_owner = {}
	_signal_owner = {}
	_constant_owner = {}

	var names: PackedStringArray = ClassDB.get_class_list()
	for cname_p in names:
		var cname: String = cname_p
		var entry := {
			"parent": "",
			"methods": [],
			"properties": [],
			"signals": [],
			"constants": [],
		}
		var parent_str := String(ClassDB.get_parent_class(cname))
		if parent_str != "":
			entry["parent"] = parent_str

		# Methods declared on this class only (no_inheritance = true).
		for m in ClassDB.class_get_method_list(cname, true):
			var mname: String = m.get("name", "")
			if mname == "":
				continue
			entry["methods"].append(mname)
			_append_owner(_method_owner, mname, cname)

		# Properties declared on this class only.
		for p in ClassDB.class_get_property_list(cname, true):
			var pname: String = p.get("name", "")
			if pname == "":
				continue
			entry["properties"].append(pname)
			_append_owner(_property_owner, pname, cname)

		# Signals declared on this class only.
		for s in ClassDB.class_get_signal_list(cname, true):
			var sname: String = s.get("name", "")
			if sname == "":
				continue
			entry["signals"].append(sname)
			_append_owner(_signal_owner, sname, cname)

		# Integer constants (enum values and const-exposed ints).
		for k in ClassDB.class_get_integer_constant_list(cname, true):
			var kname: String = k
			entry["constants"].append(kname)
			_append_owner(_constant_owner, kname, cname)

		_by_class[cname] = entry

	_built = true


func _append_owner(map: Dictionary, key: String, owner: String) -> void:
	if not map.has(key):
		map[key] = []
	map[key].append(owner)


func is_built() -> bool:
	return _built


func class_count() -> int:
	return _by_class.size()

# --- basic queries ------------------------------------------------------

## True if `cls` is a Godot engine class (Node, Sprite2D, ...).
## Named `has_class` to avoid clashing with Object.is_class.
func has_class(cls: String) -> bool:
	return _by_class.has(cls)


func is_variant_type(tname: String) -> bool:
	return VARIANT_TYPES.has(tname)


## True if `tname` is either a Godot class or a built-in Variant type.
## Use this to decide whether a type annotation refers to something real.
func is_type_name(tname: String) -> bool:
	return has_class(tname) or is_variant_type(tname)


func get_parent(cls: String) -> String:
	if not _by_class.has(cls):
		return ""
	return _by_class[cls]["parent"]


## Returns the chain from cls upward. If `include_object` is true
## (the default) the chain ends with "Object". Otherwise the chain
## stops at the last class before Object.
func get_inheritance_chain(cls: String, include_object: bool = true) -> Array:
	var chain: Array = []
	var cur := cls
	while cur != "":
		if cur == "Object" and not include_object:
			break
		chain.append(cur)
		cur = get_parent(cur)
	return chain

# --- method lookups -----------------------------------------------------

## True if `method_name` is declared on `cls` or any ancestor.
func has_method_on_class(cls: String, method_name: String, include_inherited: bool = true) -> bool:
	if not include_inherited:
		return _declares(_by_class, cls, "methods", method_name)
	for c in get_inheritance_chain(cls):
		if _declares(_by_class, c, "methods", method_name):
			return true
	return false


func has_property_on_class(cls: String, prop_name: String, include_inherited: bool = true) -> bool:
	if not include_inherited:
		return _declares(_by_class, cls, "properties", prop_name)
	for c in get_inheritance_chain(cls):
		if _declares(_by_class, c, "properties", prop_name):
			return true
	return false


func has_signal_on_class(cls: String, sig_name: String, include_inherited: bool = true) -> bool:
	if not include_inherited:
		return _declares(_by_class, cls, "signals", sig_name)
	for c in get_inheritance_chain(cls):
		if _declares(_by_class, c, "signals", sig_name):
			return true
	return false


func has_constant_on_class(cls: String, const_name: String, include_inherited: bool = true) -> bool:
	if not include_inherited:
		return _declares(_by_class, cls, "constants", const_name)
	for c in get_inheritance_chain(cls):
		if _declares(_by_class, c, "constants", const_name):
			return true
	return false


func _declares(by_class: Dictionary, cls: String, key: String, item: String) -> bool:
	if not by_class.has(cls):
		return false
	return item in by_class[cls][key]


## Classes that declare `method_name` in their own definition (not
## inherited). Useful for "which class owns this method?"
func classes_declaring_method(method_name: String) -> Array:
	return _method_owner.get(method_name, [])


func classes_declaring_property(prop_name: String) -> Array:
	return _property_owner.get(prop_name, [])


func classes_declaring_signal(sig_name: String) -> Array:
	return _signal_owner.get(sig_name, [])


## True if any class declares this name as method, property, signal,
## or integer constant. Cheap "does this API name exist in Godot?"
func api_name_exists(n: String) -> bool:
	return _method_owner.has(n) \
		or _property_owner.has(n) \
		or _signal_owner.has(n) \
		or _constant_owner.has(n)

# --- bulk accessors -----------------------------------------------------

func get_declared_methods(cls: String) -> Array:
	if not _by_class.has(cls):
		return []
	return _by_class[cls]["methods"].duplicate()


func get_declared_properties(cls: String) -> Array:
	if not _by_class.has(cls):
		return []
	return _by_class[cls]["properties"].duplicate()


func get_declared_signals(cls: String) -> Array:
	if not _by_class.has(cls):
		return []
	return _by_class[cls]["signals"].duplicate()


## Every method reachable on `cls`, inherited included. Walks the
## whole ancestor chain and de-duplicates.
func get_all_methods(cls: String) -> Array:
	var seen := {}
	var out: Array = []
	for c in get_inheritance_chain(cls):
		if not _by_class.has(c):
			continue
		for m in _by_class[c]["methods"]:
			if not seen.has(m):
				seen[m] = true
				out.append(m)
	return out


func get_all_properties(cls: String) -> Array:
	var seen := {}
	var out: Array = []
	for c in get_inheritance_chain(cls):
		if not _by_class.has(c):
			continue
		for p in _by_class[c]["properties"]:
			if not seen.has(p):
				seen[p] = true
				out.append(p)
	return out

# --- debug helpers ------------------------------------------------------

## Prints a one-line summary of what was indexed.
func dump_summary() -> void:
	print("ClassDBIndex summary:")
	print("  classes:    %d" % _by_class.size())
	print("  methods:    %d unique names" % _method_owner.size())
	print("  properties: %d unique names" % _property_owner.size())
	print("  signals:    %d unique names" % _signal_owner.size())
	print("  constants:  %d unique names" % _constant_owner.size())

# --- self-test ----------------------------------------------------------

## A handful of assertions to confirm the index is built correctly.
## Pass condition: prints "OK" and returns true.
static func self_test() -> bool:
	print("=== ClassDBIndex self-test ===")
	var idx := ClassDBIndex.new()
	var t0 := Time.get_ticks_msec()
	idx.build()
	var dt := Time.get_ticks_msec() - t0
	print("built in %d ms" % dt)
	idx.dump_summary()
	print("")

	var failures: Array[String] = []

	# Classes that must exist in every Godot 4.x.
	var must_have_classes := [
		"Node", "Node2D", "Node3D", "CanvasItem", "Object",
		"CharacterBody2D", "CharacterBody3D",
		"Sprite2D", "Camera2D", "Camera3D",
		"RigidBody3D", "Area2D", "Area3D",
		"Label", "Button", "Control",
		"Resource", "Timer", "Tween",
	]
	for c in must_have_classes:
		if not idx.has_class(c):
			failures.append("expected class missing: " + c)

	# Variant types.
	var must_have_variants := [
		"int", "float", "String", "bool",
		"Vector2", "Vector3", "Vector2i", "Vector3i",
		"Color", "Array", "Dictionary",
		"Transform2D", "Transform3D", "Quaternion", "Basis",
	]
	for t in must_have_variants:
		if not idx.is_variant_type(t):
			failures.append("expected variant type missing: " + t)

	# Nonsense should not be a type.
	if idx.is_type_name("FlibbleWibble"):
		failures.append("nonsense type reported as real")

	# Inheritance chain sanity.
	var chain := idx.get_inheritance_chain("CharacterBody3D")
	for expected in ["CharacterBody3D", "PhysicsBody3D", "CollisionObject3D", "Node3D", "Node", "Object"]:
		if not (expected in chain):
			failures.append("CharacterBody3D chain missing: " + expected)

	var chain_no_obj := idx.get_inheritance_chain("CharacterBody3D", false)
	if "Object" in chain_no_obj:
		failures.append("include_object=false still returned Object")

	# Method lookups with inheritance.
	if not idx.has_method_on_class("CharacterBody3D", "move_and_slide"):
		failures.append("CharacterBody3D missing move_and_slide (declared on self)")
	if not idx.has_method_on_class("Node2D", "queue_free"):
		failures.append("Node2D missing queue_free (inherited from Object)")
	if not idx.has_method_on_class("Node", "get_node"):
		failures.append("Node missing get_node")
	if idx.has_method_on_class("Node2D", "flibble_wibble"):
		failures.append("Node2D falsely has flibble_wibble")

	# Property lookups with inheritance.
	if not idx.has_property_on_class("Node2D", "position"):
		failures.append("Node2D missing position")
	if not idx.has_property_on_class("Node2D", "visible"):
		failures.append("Node2D missing visible (inherited from CanvasItem)")
	if idx.has_property_on_class("Node2D", "yolo"):
		failures.append("Node2D falsely has yolo")

	# Signal lookups.
	if not idx.has_signal_on_class("Timer", "timeout"):
		failures.append("Timer missing timeout")
	if not idx.has_signal_on_class("Node", "ready"):
		failures.append("Node missing ready")

	# Declared-only lookups.
	if idx.has_method_on_class("Node2D", "queue_free", false):
		failures.append("Node2D should not declare queue_free directly (only inherits)")
	if not idx.has_method_on_class("CharacterBody3D", "move_and_slide", false):
		failures.append("CharacterBody3D should declare move_and_slide directly")

	# Owner lookups.
	var owners := idx.classes_declaring_method("move_and_slide")
	if owners.is_empty():
		failures.append("move_and_slide owner lookup returned empty")
	elif not ("CharacterBody3D" in owners):
		failures.append("move_and_slide should be declared on CharacterBody3D")

	# api_name_exists.
	if not idx.api_name_exists("queue_free"):
		failures.append("api_name_exists missed queue_free")
	if idx.api_name_exists("flibble_wibble"):
		failures.append("api_name_exists falsely found flibble_wibble")

	# Bulk accessors.
	var all_node2d_methods := idx.get_all_methods("Node2D")
	if all_node2d_methods.is_empty():
		failures.append("get_all_methods(Node2D) returned empty")
	elif not ("queue_free" in all_node2d_methods):
		failures.append("get_all_methods(Node2D) missing inherited queue_free")

	if failures.is_empty():
		print("OK — all assertions passed")
		return true
	print("FAILED — %d issues:" % failures.size())
	for f in failures:
		print("  " + f)
	return false
