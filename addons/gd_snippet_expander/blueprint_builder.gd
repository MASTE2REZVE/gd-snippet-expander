@tool
extends Node

# Folder where generated blueprint scripts are written.
# Lives at project root. One script per blueprint ID.
const GENERATED_SCRIPT_DIR := "res://gdse_generated"


# =========================================================================
# Public API
# =========================================================================

func build(blueprint_id: String, library, editor_interface: EditorInterface) -> Dictionary:
	var bp: Dictionary = library.get_blueprint(blueprint_id)
	if bp.is_empty():
		return {"ok": false, "message": "Blueprint not found: " + blueprint_id}

	var scene_root: Node = editor_interface.get_edited_scene_root()
	if scene_root == null:
		return {"ok": false, "message": "No scene open. Open or create a scene first."}

	var parent: Node = _resolve_parent(editor_interface, scene_root)
	if parent == null or not is_instance_valid(parent):
		return {"ok": false, "message": "Parent node is no longer valid. Click the scene root in the Scene tree and try again."}
	if not parent.is_inside_tree():
		return {"ok": false, "message": "Parent node is not in the scene tree. Click the scene root and try again."}

	var root_spec: Dictionary = bp.get("root", {})
	if root_spec.is_empty():
		return {"ok": false, "message": "Blueprint has no root node defined."}

	var root: Node = _instantiate_node(root_spec)
	if root == null:
		return {"ok": false, "message": "Could not create root node: " + str(root_spec.get("type", ""))}

	var desired_name := str(root_spec.get("name", str(root_spec.get("type", "Node"))))
	root.name = _unique_name(parent, desired_name)

	var required: Array = bp.get("required_children", [])
	var required_count := 0
	for child_spec in required:
		var child: Node = _instantiate_node(child_spec)
		if child != null:
			root.add_child(child)
			required_count += 1

	var recommended: Array = bp.get("recommended_children", [])
	var rec_count := 0
	for child_spec in recommended:
		var child: Node = _instantiate_node(child_spec)
		if child != null:
			root.add_child(child)
			rec_count += 1

	var script_id := str(bp.get("script", ""))
	var script_status := ""
	if not script_id.is_empty():
		script_status = _attach_script(root, blueprint_id, script_id, library)

	var ur: EditorUndoRedoManager = editor_interface.get_editor_undo_redo()
	ur.create_action("Build Blueprint: " + blueprint_id)
	ur.add_do_method(parent, "add_child", root)
	ur.add_do_method(root, "set_owner", scene_root)
	for child in root.get_children():
		ur.add_do_method(child, "set_owner", scene_root)
	ur.add_do_reference(root)
	ur.add_undo_method(parent, "remove_child", root)
	ur.commit_action()

	var selection: EditorSelection = editor_interface.get_selection()
	if selection != null:
		selection.clear()
		selection.add_node(root)

	var msg := "Built %s (%s) with %d required, %d recommended children." % [
		root.name, root.get_class(), required_count, rec_count
	]
	if not script_status.is_empty():
		msg += " " + script_status
	return {"ok": true, "message": msg, "root": root}


# =========================================================================
# Parent resolution
# =========================================================================

func _resolve_parent(editor_interface: EditorInterface, scene_root: Node) -> Node:
	var selection: EditorSelection = editor_interface.get_selection()
	if selection != null:
		var selected := selection.get_selected_nodes()
		if not selected.is_empty():
			var candidate: Node = selected[0]
			if is_instance_valid(candidate) and candidate.is_inside_tree():
				return candidate
	return scene_root


# =========================================================================
# Node instantiation
# =========================================================================

func _instantiate_node(spec: Dictionary) -> Node:
	var type_name := str(spec.get("type", "Node"))
	var node := _create_node_of_type(type_name)
	if node == null:
		push_warning("BlueprintBuilder: unknown node type: " + type_name)
		return null
	node.name = str(spec.get("name", type_name))

	if node is CollisionShape3D and spec.has("shape"):
		var shape := _create_shape_3d(str(spec.shape))
		if shape != null:
			(node as CollisionShape3D).shape = shape
	elif node is CollisionShape2D and spec.has("shape"):
		var shape2d := _create_shape_2d(str(spec.shape))
		if shape2d != null:
			(node as CollisionShape2D).shape = shape2d

	if node is MeshInstance3D and spec.has("mesh"):
		var mesh := _create_mesh(str(spec.mesh))
		if mesh != null:
			(node as MeshInstance3D).mesh = mesh
			_configure_default_mesh(mesh)

	if spec.has("transform"):
		_apply_transform(node, spec.transform)

	if spec.has("properties"):
		_apply_properties(node, spec.properties)

	return node


func _create_node_of_type(type_name: String) -> Node:
	if not ClassDB.class_exists(type_name):
		return null
	var obj = ClassDB.instantiate(type_name)
	if obj == null or not (obj is Node):
		return null
	return obj as Node


# =========================================================================
# Shape / mesh factories
# =========================================================================

func _create_shape_3d(shape_name: String) -> Shape3D:
	match shape_name:
		"CapsuleShape3D": return CapsuleShape3D.new()
		"BoxShape3D": return BoxShape3D.new()
		"SphereShape3D": return SphereShape3D.new()
		"CylinderShape3D": return CylinderShape3D.new()
		_: return null


func _create_shape_2d(shape_name: String) -> Shape2D:
	match shape_name:
		"RectangleShape2D": return RectangleShape2D.new()
		"CircleShape2D": return CircleShape2D.new()
		"CapsuleShape2D": return CapsuleShape2D.new()
		_: return null


func _create_mesh(mesh_name: String) -> Mesh:
	match mesh_name:
		"BoxMesh": return BoxMesh.new()
		"PlaneMesh": return PlaneMesh.new()
		"SphereMesh": return SphereMesh.new()
		"CylinderMesh": return CylinderMesh.new()
		"QuadMesh": return QuadMesh.new()
		_: return null


func _configure_default_mesh(mesh: Mesh) -> void:
	if mesh is PlaneMesh:
		(mesh as PlaneMesh).size = Vector2(50, 50)
	elif mesh is BoxMesh:
		(mesh as BoxMesh).size = Vector3(1, 1, 1)


# =========================================================================
# Transform / property application
# =========================================================================

func _apply_transform(node: Node, t: Dictionary) -> void:
	if not t.has("position"):
		return
	var pos_arr: Array = t.position
	if node is Node3D and pos_arr.size() >= 3:
		(node as Node3D).position = Vector3(pos_arr[0], pos_arr[1], pos_arr[2])
	elif node is Node2D and pos_arr.size() >= 2:
		(node as Node2D).position = Vector2(pos_arr[0], pos_arr[1])


func _apply_properties(node: Node, props: Dictionary) -> void:
	for key in props.keys():
		var raw = props[key]
		var converted = _convert_property_value(str(key), raw)
		if converted != null:
			node.set(str(key), converted)


func _convert_property_value(key: String, value):
	if value is Array:
		var arr: Array = value
		if key == "color" and arr.size() >= 4:
			return Color(arr[0], arr[1], arr[2], arr[3])
		if arr.size() == 2:
			return Vector2(arr[0], arr[1])
		if arr.size() == 3:
			return Vector3(arr[0], arr[1], arr[2])
		if arr.size() == 4:
			return Color(arr[0], arr[1], arr[2], arr[3])
	return value


# =========================================================================
# Naming
# =========================================================================

func _unique_name(parent: Node, base: String) -> String:
	if base.is_empty():
		base = "Node"
	if not parent.has_node(base):
		return base
	var n := 2
	while parent.has_node(base + str(n)):
		n += 1
	return base + str(n)


# =========================================================================
# Script attachment
# =========================================================================

func _attach_script(root: Node, blueprint_id: String, snippet_id: String, library) -> String:
	var code: String = library.get_code(snippet_id)
	if code.is_empty():
		return "(no script attached: snippet '" + snippet_id + "' has no code)"
	_ensure_generated_dir()
	var path := GENERATED_SCRIPT_DIR + "/" + blueprint_id + ".gd"
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return "(script write failed)"
	file.store_string(code)
	file.close()
	var script = load(path)
	if script == null:
		return "(script written to " + path + " — refresh FileSystem panel to load it)"
	root.set_script(script)
	return "(script attached: " + path + ")"


func _ensure_generated_dir() -> void:
	if not DirAccess.dir_exists_absolute(GENERATED_SCRIPT_DIR):
		DirAccess.make_dir_recursive_absolute(GENERATED_SCRIPT_DIR)
