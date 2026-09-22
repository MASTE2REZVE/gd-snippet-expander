@tool
extends RefCounted

const MIN_SUPPORTED_MAJOR := 4
const MIN_SUPPORTED_MINOR := 4
const MIN_SUPPORTED_PATCH := 0

const TESTED_MAJOR := 4
const TESTED_MINOR := 7
const TESTED_PATCH := 2


func get_engine_version_string() -> String:
	var v := Engine.get_version_info()
	return "%d.%d.%d" % [
		int(v.get("major", 0)),
		int(v.get("minor", 0)),
		int(v.get("patch", 0))
	]


func get_min_version_string() -> String:
	return "%d.%d.%d" % [MIN_SUPPORTED_MAJOR, MIN_SUPPORTED_MINOR, MIN_SUPPORTED_PATCH]


func get_tested_version_string() -> String:
	return "%d.%d.%d" % [TESTED_MAJOR, TESTED_MINOR, TESTED_PATCH]


func is_min_supported() -> bool:
	var v := Engine.get_version_info()
	var major: int = int(v.get("major", 0))
	var minor: int = int(v.get("minor", 0))
	var patch: int = int(v.get("patch", 0))
	if major > MIN_SUPPORTED_MAJOR:
		return true
	if major < MIN_SUPPORTED_MAJOR:
		return false
	if minor > MIN_SUPPORTED_MINOR:
		return true
	if minor < MIN_SUPPORTED_MINOR:
		return false
	return patch >= MIN_SUPPORTED_PATCH


func is_tested() -> bool:
	var v := Engine.get_version_info()
	return (
		int(v.get("major", 0)) == TESTED_MAJOR
		and int(v.get("minor", 0)) == TESTED_MINOR
		and int(v.get("patch", 0)) == TESTED_PATCH
	)


func get_status() -> Dictionary:
	if not is_min_supported():
		return {
			"level": "error",
			"message": "Godot %s is older than the minimum supported version (%s). Some features may not work." % [
				get_engine_version_string(), get_min_version_string()
			]
		}
	if is_tested():
		return {"level": "ok", "message": ""}
	return {
		"level": "warn",
		"message": "Godot %s is newer than the tested version (%s). If anything breaks, please report it." % [
			get_engine_version_string(), get_tested_version_string()
		]
	}


func should_show_warning() -> bool:
	return str(get_status().get("level", "ok")) != "ok"


func get_warning_message() -> String:
	return str(get_status().get("message", ""))


func get_warning_level() -> String:
	return str(get_status().get("level", "ok"))
