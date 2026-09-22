@tool
extends Node

const FORMAT_MARKER := "gd-snippet-expander-blueprints"
const FORMAT_VERSION := 1
const USER_PATH := "user://gd_snippet_expander/user_library.json"
const USER_DIR := "user://gd_snippet_expander"


# =========================================================================
# Export
# =========================================================================

func export_to_file(path: String) -> Dictionary:
	var user_data := _read_user_data()
	if user_data.is_empty():
		return {"ok": false, "message": "No user library file found. Save a blueprint first."}
	var blueprints: Dictionary = user_data.get("blueprints", {})
	if blueprints.is_empty():
		return {"ok": false, "message": "No custom blueprints to export. Save one first via Project → Tools → Save Selected Node as Blueprint."}

	var payload: Dictionary = {
		"format": FORMAT_MARKER,
		"version": FORMAT_VERSION,
		"count": blueprints.size(),
		"blueprints": blueprints
	}

	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return {"ok": false, "message": "Could not open file for writing: " + path}
	file.store_string(JSON.stringify(payload, "\t"))
	file.close()

	var count: int = blueprints.size()
	return {
		"ok": true,
		"message": "Exported %d blueprint(s) to %s." % [count, path],
		"count": count
	}


# =========================================================================
# Import
# =========================================================================

func import_from_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"ok": false, "message": "File not found: " + path}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"ok": false, "message": "Could not open file: " + path}
	var text := file.get_as_text()
	file.close()

	var json := JSON.new()
	if json.parse(text) != OK:
		return {"ok": false, "message": "Not valid JSON: " + json.get_error_message()}
	if typeof(json.data) != TYPE_DICTIONARY:
		return {"ok": false, "message": "File root is not a dictionary."}

	var data: Dictionary = json.data
	if str(data.get("format", "")) != FORMAT_MARKER:
		return {"ok": false, "message": "Not a GD Snippet Expander blueprint export."}

	var incoming: Dictionary = data.get("blueprints", {})
	if incoming.is_empty():
		return {"ok": false, "message": "File contains no blueprints."}

	var user_data := _read_user_data()
	if user_data.is_empty():
		user_data = {"version": 2, "snippets": {}, "blueprints": {}}
	if not user_data.has("blueprints"):
		user_data["blueprints"] = {}

	var added := 0
	var renamed := 0
	var skipped := 0

	for id in incoming.keys():
		var raw = incoming[id]
		if not (raw is Dictionary):
			skipped += 1
			continue
		var entry: Dictionary = raw
		if not entry.has("root") or not entry.has("phrases"):
			skipped += 1
			continue
		var final_id := str(id)
		if user_data.blueprints.has(final_id):
			final_id = _unique_import_id(user_data.blueprints, final_id)
			renamed += 1
		user_data.blueprints[final_id] = entry
		added += 1

	_ensure_user_dir()
	var out := FileAccess.open(USER_PATH, FileAccess.WRITE)
	if out == null:
		return {"ok": false, "message": "Could not write to user library."}
	out.store_string(JSON.stringify(user_data, "\t"))
	out.close()

	var msg := "Imported %d blueprint(s)." % added
	if renamed > 0:
		msg += " Renamed %d due to ID conflict." % renamed
	if skipped > 0:
		msg += " Skipped %d invalid entries." % skipped
	return {
		"ok": true,
		"message": msg,
		"added": added,
		"renamed": renamed,
		"skipped": skipped
	}


# =========================================================================
# Helpers
# =========================================================================

func _unique_import_id(existing: Dictionary, base: String) -> String:
	var candidate := base + "_imported"
	if not existing.has(candidate):
		return candidate
	var n := 2
	while existing.has(base + "_imported" + str(n)):
		n += 1
	return base + "_imported" + str(n)


func _read_user_data() -> Dictionary:
	if not FileAccess.file_exists(USER_PATH):
		return {}
	var file := FileAccess.open(USER_PATH, FileAccess.READ)
	if file == null:
		return {}
	var text := file.get_as_text()
	file.close()
	var json := JSON.new()
	if json.parse(text) != OK:
		return {}
	if typeof(json.data) != TYPE_DICTIONARY:
		return {}
	return json.data as Dictionary


func _ensure_user_dir() -> void:
	if not DirAccess.dir_exists_absolute(USER_DIR):
		DirAccess.make_dir_recursive_absolute(USER_DIR)
