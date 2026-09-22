@tool
extends Node


func scan(editor_interface: EditorInterface) -> Array:
	var root: Node = editor_interface.get_edited_scene_root()
	if root == null:
		return []
	var issues: Array = []
	_walk(root, issues)
	return issues


func format(issues: Array) -> String:
	if issues.is_empty():
		return "No issues found. Your scene looks clean."
	var lines: Array = []
	lines.append("Found %d issue(s):" % issues.size())
	lines.append("")
	for issue in issues:
		var severity := str(issue.get("severity", "warning"))
		var marker := "[!] " if severity == "error" else "[?] "
		lines.append(marker + str(issue.get("node", "?")))
		lines.append("    " + str(issue.get("message", "")))
		lines.append("    Fix: " + str(issue.get("fix", "")))
		lines.append("")
	return "\n".join(lines)


func _walk(node: Node, out: Array) -> void:
	_check(node, out)
	for child in node.get_children():
		_walk(child, out)


func _check(node: Node, out: Array) -> void:
	var cls := node.get_class()

	if cls == "CharacterBody2D" and not _has_child_of_type(node, "CollisionShape2D") and not _has_child_of_type(node, "CollisionPolygon2D"):
		out.append({
			"severity": "error",
			"node": str(node.name),
			"message": "CharacterBody2D with no CollisionShape2D child. The character has no physical presence and will fall through floors.",
			"fix": "Add a CollisionShape2D as a child. Assign a CircleShape2D, RectangleShape2D, or CapsuleShape2D."
		})

	if cls == "CharacterBody3D" and not _has_child_of_type(node, "CollisionShape3D"):
		out.append({
			"severity": "error",
			"node": str(node.name),
			"message": "CharacterBody3D with no CollisionShape3D child. The character will fall through the floor.",
			"fix": "Add a CollisionShape3D as a child. CapsuleShape3D is standard for characters."
		})

	if cls == "StaticBody2D" and not _has_child_of_type(node, "CollisionShape2D") and not _has_child_of_type(node, "CollisionPolygon2D"):
		out.append({
			"severity": "error",
			"node": str(node.name),
			"message": "StaticBody2D with no CollisionShape2D child. Nothing can collide with it.",
			"fix": "Add a CollisionShape2D as a child and size it to match the visual."
		})

	if cls == "StaticBody3D" and not _has_child_of_type(node, "CollisionShape3D"):
		out.append({
			"severity": "error",
			"node": str(node.name),
			"message": "StaticBody3D with no CollisionShape3D child. Nothing can collide with it.",
			"fix": "Add a CollisionShape3D as a child."
		})

	if (cls == "Area2D" or cls == "Area3D") and not _has_child_of_type(node, "CollisionShape2D") and not _has_child_of_type(node, "CollisionShape3D") and not _has_child_of_type(node, "CollisionPolygon2D"):
		out.append({
			"severity": "warning",
			"node": str(node.name),
			"message": cls + " with no CollisionShape child. It can't detect anything.",
			"fix": "Add a CollisionShape2D (for 2D) or CollisionShape3D (for 3D) as a child."
		})

	if cls == "Camera2D" or cls == "Camera3D":
		var parent: Node = node.get_parent()
		if parent != null:
			var parent_cls := parent.get_class()
			if parent_cls == "CharacterBody2D" or parent_cls == "CharacterBody3D":
				out.append({
					"severity": "warning",
					"node": str(node.name),
					"message": "Camera is a direct child of a character. The camera will rotate with the character.",
					"fix": "Move the camera out from under the character, or add a Node3D pivot between them."
				})

	if cls == "CanvasLayer":
		var wants_pause := node.name.to_lower().contains("pause") or node.name.to_lower().contains("gameover") or node.name.to_lower().contains("menu")
		if wants_pause and node.process_mode != Node.PROCESS_MODE_ALWAYS:
			out.append({
				"severity": "warning",
				"node": str(node.name),
				"message": "Menu CanvasLayer has process_mode = INHERIT. It will freeze when the game pauses.",
				"fix": "Set process_mode = ALWAYS in the Inspector."
			})

	if cls == "CollisionShape2D" and node.shape == null:
		out.append({
			"severity": "error",
			"node": str(node.name),
			"message": "CollisionShape2D has no Shape resource assigned.",
			"fix": "In the Inspector, click the Shape slot and create a CircleShape2D, RectangleShape2D, or CapsuleShape2D."
		})

	if cls == "CollisionShape3D" and node.shape == null:
		out.append({
			"severity": "error",
			"node": str(node.name),
			"message": "CollisionShape3D has no Shape resource assigned.",
			"fix": "In the Inspector, click the Shape slot and create a BoxShape3D, CapsuleShape3D, or SphereShape3D."
		})

	if cls == "Timer" and not node.autostart and node.time_left <= 0.0:
		var p: Node = node.get_parent()
		if p != null and not _any_script_references(p, node.name):
			out.append({
				"severity": "warning",
				"node": str(node.name),
				"message": "Timer with autostart off and nothing starting it. It will never fire.",
				"fix": "Enable autostart in the Inspector, or call start() from code."
			})


func _has_child_of_type(node: Node, type_name: String) -> bool:
	for child in node.get_children():
		if child.get_class() == type_name:
			return true
	return false


func _any_script_references(node: Node, target_name: String) -> bool:
	var script = node.get_script()
	if script == null:
		return false
	var code := str(script.source_code) if script is GDScript else ""
	if code.is_empty():
		return false
	return code.contains(str(target_name))
