@tool
extends RefCounted


func get_data() -> Dictionary:
	return {
		"version": 2,
		"snippets": {
			"camera_look_at_mouse": {"category": "camera", "subcategory": "2d"}
		}
	}
