@tool
extends Node

const PROPERTY_WHITELIST := {
	"Control": ["anchors_preset", "offset_left", "offset_top", "offset_right", "offset_bottom", "size_flags_horizontal", "size_flags_vertical"],
	"ColorRect": ["color"],
	"Label": ["text", "horizontal_alignment", "autowrap_mode"],
	"Button": ["text", "toggle_mode"],
	"ProgressBar": ["max_value", "value", "show_percentage"],
	"LineEdit": ["placeholder_text"],
	"Camera3D": ["fov", "near", "far"],
	"Camera2D": ["zoom"],
	"Timer": ["wait_time", "autostart"],
	"Light3D": ["light_energy", "light_color"],
	"OmniLight3D": ["omni_range"],
	"SpotLight3D": ["spot_range", "spot_angle"],
	"AudioStreamPlayer": ["volume_db", "bus"],
	"AudioStreamPlayer3D": ["volume_db", "bus", "max_distance"]
}

const MESH_CLASSES := [
	"BoxMesh", "PlaneMesh", "SphereMesh", "CylinderMesh", "QuadMesh"
]


func serialize(node: Node) -> Dictionary:
	if node == null:
		return {}
	return _serialize_node(node)


func _serialize_node(node: Node) -> Dictionary:
	var spec: Dictionary = {
		"type": node.get_class(),
		"name": str(node.name)
	}

	var pos = _get_position(node)
	if pos != null:
		spec["transform"] = {"position": pos}

	if node is CollisionShape2D:
		var s2 = (node as CollisionShape2D).shape
		if s2 != null:
			spec["shape"] = s2.get_class()
	elif node is CollisionShape3D:
		var s3 = (node as CollisionShape3D).shape
		if s3 != null:
			spec["shape"] = s3.get_class()

	if node is MeshInstance3D:
		var m = (node as MeshInstance3D).mesh
		if m != null and m.get_class() in MESH_CLASSES:
			spec["mesh"] = m.get_class()

	var props := _collect_properties(node)
	if not props.is_empty():
		spec["properties"] = props

	var children: Array = []
	for child in node.get_children():
		if child is Node:
			children.append(_serialize_node(child))
	if not children.is_empty():
		spec["children"] = children

	return spec


func _get_position(node: Node):
	if node is Node3D:
		var p3: Vector3 = (node as Node3D).position
		return [p3.x, p3.y, p3.z]
	if node is Node2D:
		var p2: Vector2 = (node as Node2D).position
		return [p2.x, p2.y]
	return null


func _collect_properties(node: Node) -> Dictionary:
	var out: Dictionary = {}
	var seen: Dictionary = {}
	for wl_class in PROPERTY_WHITELIST.keys():
		if not node.is_class(str(wl_class)):
			continue
		for prop in PROPERTY_WHITELIST[wl_class]:
			var pname := str(prop)
			if seen.has(pname):
				continue
			seen[pname] = true
			var value = node.get(pname)
			if value == null:
				continue
			if _is_supported_type(value):
				out[pname] = _serialize_value(value)
	return out


func _is_supported_type(value) -> bool:
	return value is int or value is float or value is bool or value is String or value is Color or value is Vector2 or value is Vector3


func _serialize_value(value):
	if value is Color:
		return [value.r, value.g, value.b, value.a]
	if value is Vector2:
		return [value.x, value.y]
	if value is Vector3:
		return [value.x, value.y, value.z]
	return value
