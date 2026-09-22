@tool
class_name GDASELibrary
extends RefCounted

# --- Paths ---------------------------------------------------------------

const BUNDLED_PATH := "res://addons/gd_snippet_expander/library.json"
const LIBRARY_DIR := "res://addons/gd_snippet_expander/library/"
const USER_DIR := "user://gd_snippet_expander"
const USER_PATH := "user://gd_snippet_expander/user_library.json"
const SETTINGS_PATH := "user://gd_snippet_expander/settings.json"

# --- Modes ---------------------------------------------------------------

const MODE_CODE_ONLY := "code_only"
const MODE_CODE_DETAILS := "code_details"
const MODE_FULL_DETAILS := "full_details"
const DEFAULT_MODE := MODE_FULL_DETAILS

# --- Kinds ---------------------------------------------------------------

const KIND_SNIPPET := "snippet"
const KIND_BLUEPRINT := "blueprint"

# --- Limits --------------------------------------------------------------

const MAX_RECENTS := 20
const FUZZY_MAX_DISTANCE := 2
const FUZZY_MIN_LENGTH := 4
const TOKEN_MATCH_RATIO := 0.5

const SUGGESTION_PRIORITY := [
	"movement", "camera", "health", "combat", "ai",
	"pickup", "ui", "save", "audio", "scene", "utility"
]

# --- State ---------------------------------------------------------------

var _snippets: Dictionary = {}
var _phrase_index: Dictionary = {}
var _blueprints: Dictionary = {}
var _blueprint_phrase_index: Dictionary = {}
var _templates: Dictionary = {}
var _settings: Dictionary = {}
var _loaded: bool = false


# =========================================================================
# Loading
# =========================================================================

func load_all() -> void:
	_snippets.clear()
	_phrase_index.clear()
	_blueprints.clear()
	_blueprint_phrase_index.clear()
	_templates.clear()
	_merge_from_file(BUNDLED_PATH)
	_merge_library_folder()
	_merge_from_file(USER_PATH)
	_load_settings()
	_loaded = true


func reload() -> void:
	load_all()


func is_loaded() -> bool:
	return _loaded


# =========================================================================
# Counts
# =========================================================================

func snippet_count() -> int:
	return _snippets.size()


func phrase_count() -> int:
	return _phrase_index.size()


func blueprint_count() -> int:
	return _blueprints.size()


func total_count() -> int:
	return _snippets.size() + _blueprints.size()


# =========================================================================
# Snippet lookup
# =========================================================================

func find(query: String) -> Dictionary:
	var norm := _normalize(query)
	if norm.is_empty():
		return {"ok": false, "message": "Empty query."}
	if _phrase_index.has(norm):
		return _make_result(_phrase_index[norm], norm)
	for phrase in _phrase_index.keys():
		if norm.contains(phrase):
			return _make_result(_phrase_index[phrase], phrase)
	for phrase in _phrase_index.keys():
		if phrase.contains(norm):
			return _make_result(_phrase_index[phrase], phrase)
	var best_id := ""
	var best_phrase := ""
	var best_dist := FUZZY_MAX_DISTANCE + 1
	for phrase in _phrase_index.keys():
		if phrase.length() < FUZZY_MIN_LENGTH:
			continue
		var d := _edit_distance(norm, phrase)
		if d <= FUZZY_MAX_DISTANCE and d < best_dist:
			best_dist = d
			best_id = _phrase_index[phrase]
			best_phrase = phrase
	if best_id != "":
		return _make_result(best_id, best_phrase)
	for phrase in _phrase_index.keys():
		if _token_fuzzy_match(norm, phrase):
			return _make_result(_phrase_index[phrase], phrase)
	return {"ok": false, "message": "No match for \"" + query + "\"."}


func get_snippet(id: String) -> Dictionary:
	return _snippets.get(id, {})


func list_ids() -> Array:
	return _snippets.keys()


func phrases_for(id: String) -> Array:
	if not _snippets.has(id):
		return []
	return _snippets[id].get("phrases", [])


func has_snippet(id: String) -> bool:
	return _snippets.has(id)


# =========================================================================
# Blueprint lookup
# =========================================================================

func find_blueprint(query: String) -> Dictionary:
	var norm := _normalize(query)
	if norm.is_empty():
		return {"ok": false, "message": "Empty query."}
	if _blueprint_phrase_index.has(norm):
		return _make_blueprint_result(_blueprint_phrase_index[norm], norm)
	for phrase in _blueprint_phrase_index.keys():
		if norm.contains(phrase):
			return _make_blueprint_result(_blueprint_phrase_index[phrase], phrase)
	for phrase in _blueprint_phrase_index.keys():
		if phrase.contains(norm):
			return _make_blueprint_result(_blueprint_phrase_index[phrase], phrase)
	var best_id := ""
	var best_phrase := ""
	var best_dist := FUZZY_MAX_DISTANCE + 1
	for phrase in _blueprint_phrase_index.keys():
		if phrase.length() < FUZZY_MIN_LENGTH:
			continue
		var d := _edit_distance(norm, phrase)
		if d <= FUZZY_MAX_DISTANCE and d < best_dist:
			best_dist = d
			best_id = _blueprint_phrase_index[phrase]
			best_phrase = phrase
	if best_id != "":
		return _make_blueprint_result(best_id, best_phrase)
	for phrase in _blueprint_phrase_index.keys():
		if _token_fuzzy_match(norm, phrase):
			return _make_blueprint_result(_blueprint_phrase_index[phrase], phrase)
	return {"ok": false, "message": "No match for \"" + query + "\"."}


func get_blueprint(id: String) -> Dictionary:
	return _blueprints.get(id, {})


func list_blueprint_ids() -> Array:
	return _blueprints.keys()


func blueprint_phrases_for(id: String) -> Array:
	if not _blueprints.has(id):
		return []
	return _blueprints[id].get("phrases", [])


func has_blueprint(id: String) -> bool:
	return _blueprints.has(id)


# =========================================================================
# Unified search
# =========================================================================

func find_any(query: String) -> Dictionary:
	var s := find(query)
	if s.get("ok", false):
		return s
	var b := find_blueprint(query)
	if b.get("ok", false):
		return b
	return {"ok": false, "message": "No match for \"" + query + "\"."}


func search(query: String) -> Array:
	var norm := _normalize(query)
	if norm.is_empty():
		return []
	var results: Array = []
	_scan_into(results, norm, _phrase_index, KIND_SNIPPET)
	_scan_into(results, norm, _blueprint_phrase_index, KIND_BLUEPRINT)
	results.sort_custom(func(a, b):
		if a.score != b.score:
			return a.score > b.score
		return a.id < b.id
	)
	return results


func _scan_into(out: Array, norm: String, index: Dictionary, kind: String) -> void:
	for phrase in index.keys():
		var score := 0
		if phrase == norm:
			score = 100
		elif norm.contains(phrase):
			score = 80
		elif phrase.contains(norm):
			score = 60
		elif phrase.length() >= FUZZY_MIN_LENGTH and _edit_distance(norm, phrase) <= FUZZY_MAX_DISTANCE:
			score = 40
		elif _token_fuzzy_match(norm, phrase):
			score = 30
		if score > 0:
			out.append({
				"kind": kind,
				"id": index[phrase],
				"phrase_matched": phrase,
				"score": score,
			})


# =========================================================================
# Data accessors (snippets)
# =========================================================================

func get_code(id: String) -> String:
	if not _snippets.has(id):
		return ""
	return str(_snippets[id].get("code", ""))


func get_code_for_mode(id: String, mode: String) -> String:
	if not _snippets.has(id):
		return ""
	var s: Dictionary = _snippets[id]
	if mode == MODE_CODE_ONLY:
		return str(s.get("code", ""))
	if mode == MODE_FULL_DETAILS:
		return str(s.get("code", ""))
	if s.has("code_commented"):
		return str(s["code_commented"])
	return _generate_commented_code(id)


func get_details(id: String) -> Dictionary:
	if not _snippets.has(id):
		return {}
	return _snippets[id].get("details", {})


func get_param_info(id: String) -> Dictionary:
	if not _snippets.has(id):
		return {}
	return _snippets[id].get("param_info", {})


func get_params(id: String) -> Array:
	if not _snippets.has(id):
		return []
	return _snippets[id].get("params", [])


func get_required_actions(id: String) -> Array:
	if not _snippets.has(id):
		return []
	return _snippets[id].get("required_actions", [])


func get_category(id: String) -> String:
	if not _snippets.has(id):
		return ""
	return str(_snippets[id].get("category", ""))


func get_subcategory(id: String) -> String:
	if not _snippets.has(id):
		return ""
	return str(_snippets[id].get("subcategory", ""))


func get_dimension(id: String) -> String:
	if not _snippets.has(id):
		return ""
	return str(_snippets[id].get("dimension", ""))


func get_difficulty(id: String) -> String:
	if not _snippets.has(id):
		return ""
	return str(_snippets[id].get("difficulty", ""))


func get_scene_tree(id: String) -> Array:
	if not _snippets.has(id):
		return []
	return _snippets[id].get("scene_tree", [])


# =========================================================================
# Data accessors (blueprints)
# =========================================================================

func get_blueprint_required_actions(id: String) -> Array:
	if not _blueprints.has(id):
		return []
	return _blueprints[id].get("required_actions", [])


func get_blueprint_script(id: String) -> String:
	if not _blueprints.has(id):
		return ""
	return str(_blueprints[id].get("script", ""))


func get_blueprint_next_steps(id: String) -> Array:
	if not _blueprints.has(id):
		return []
	return _blueprints[id].get("next_steps", [])


func get_blueprint_mistakes(id: String) -> Array:
	if not _blueprints.has(id):
		return []
	return _blueprints[id].get("mistakes", [])


func get_blueprint_setup_notes(id: String) -> Array:
	if not _blueprints.has(id):
		return []
	return _blueprints[id].get("setup_notes", [])


func get_blueprint_category(id: String) -> String:
	if not _blueprints.has(id):
		return ""
	return str(_blueprints[id].get("category", ""))


func get_blueprint_subcategory(id: String) -> String:
	if not _blueprints.has(id):
		return ""
	return str(_blueprints[id].get("subcategory", ""))


# =========================================================================
# Category index (flat, backward compatible)
# =========================================================================

func get_category_index() -> Dictionary:
	var out: Dictionary = {}
	for id in _snippets.keys():
		var cat := get_category(id)
		if cat.is_empty():
			cat = "uncategorized"
		if not out.has(cat):
			out[cat] = {"snippets": [], "blueprints": []}
		out[cat].snippets.append(id)
	for id in _blueprints.keys():
		var cat := get_blueprint_category(id)
		if cat.is_empty():
			cat = "uncategorized"
		if not out.has(cat):
			out[cat] = {"snippets": [], "blueprints": []}
		out[cat].blueprints.append(id)
	return out


# =========================================================================
# Browse tree (two-tier)
# =========================================================================

func get_browse_tree() -> Dictionary:
	var out: Dictionary = {}
	for id in _snippets.keys():
		var cat := get_category(id)
		if cat.is_empty():
			cat = "uncategorized"
		var sub := get_subcategory(id)
		if sub.is_empty():
			sub = "_ungrouped"
		_ensure_bucket(out, cat, sub)
		out[cat][sub].snippets.append(id)
	for id in _blueprints.keys():
		var cat := get_blueprint_category(id)
		if cat.is_empty():
			cat = "uncategorized"
		var sub := get_blueprint_subcategory(id)
		if sub.is_empty():
			sub = "_ungrouped"
		_ensure_bucket(out, cat, sub)
		out[cat][sub].blueprints.append(id)
	for cat in out.keys():
		for sub in out[cat].keys():
			out[cat][sub].snippets.sort()
			out[cat][sub].blueprints.sort()
	return out


func _ensure_bucket(tree: Dictionary, cat: String, sub: String) -> void:
	if not tree.has(cat):
		tree[cat] = {}
	if not tree[cat].has(sub):
		tree[cat][sub] = {"snippets": [], "blueprints": []}


# =========================================================================
# Input action check
# =========================================================================

func check_required_actions(id: String) -> Array:
	var missing: Array = []
	for action in get_required_actions(id):
		if not InputMap.has_action(action):
			missing.append(action)
	return missing


func check_blueprint_required_actions(id: String) -> Array:
	var missing: Array = []
	for action in get_blueprint_required_actions(id):
		if not InputMap.has_action(action):
			missing.append(action)
	return missing


# =========================================================================
# Templates
# =========================================================================

func list_template_ids() -> Array:
	return _templates.keys()


func get_template(id: String) -> Dictionary:
	return _templates.get(id, {})


# =========================================================================
# Favorites
# =========================================================================

func get_favorites() -> Array:
	return _settings.get("favorites", [])


func is_favorite(id: String) -> bool:
	return get_favorites().has(id)


func toggle_favorite(id: String) -> void:
	var favs: Array = get_favorites()
	if favs.has(id):
		favs.erase(id)
	else:
		favs.append(id)
	_settings["favorites"] = favs
	save_settings()


# =========================================================================
# Recents
# =========================================================================

func get_recents() -> Array:
	return _settings.get("recents", [])


func add_recent(id: String) -> void:
	var recents: Array = get_recents()
	recents.erase(id)
	recents.push_front(id)
	while recents.size() > MAX_RECENTS:
		recents.pop_back()
	_settings["recents"] = recents
	save_settings()


# =========================================================================
# Suggestions
# =========================================================================

func get_suggestions(max_count: int = 3) -> Array:
	var recents: Array = get_recents()
	var used_categories: Dictionary = {}
	var used_ids: Dictionary = {}
	for uid in recents:
		var sid := str(uid)
		used_ids[sid] = true
		var cat := get_category(sid)
		if not cat.is_empty():
			used_categories[cat] = true

	var suggestions: Array = []
	for cat in SUGGESTION_PRIORITY:
		if used_categories.has(cat):
			continue
		var picked := ""
		for id in _snippets.keys():
			if used_ids.has(id):
				continue
			if get_category(str(id)) != cat:
				continue
			picked = str(id)
			break
		if not picked.is_empty():
			suggestions.append(picked)
		if suggestions.size() >= max_count:
			break
	return suggestions


# =========================================================================
# Settings
# =========================================================================

func get_mode() -> String:
	return str(_settings.get("mode", DEFAULT_MODE))


func set_mode(mode: String) -> void:
	if mode != MODE_CODE_ONLY and mode != MODE_CODE_DETAILS and mode != MODE_FULL_DETAILS:
		return
	_settings["mode"] = mode
	save_settings()


func get_setting(key: String, default_value: Variant = null) -> Variant:
	return _settings.get(key, default_value)


func set_setting(key: String, value: Variant) -> void:
	_settings[key] = value
	save_settings()


func save_settings() -> void:
	_ensure_user_dir()
	_write_json(SETTINGS_PATH, _settings)


func _load_settings() -> void:
	if FileAccess.file_exists(SETTINGS_PATH):
		_settings = _read_json(SETTINGS_PATH)
	else:
		_settings = {"mode": DEFAULT_MODE, "favorites": [], "recents": []}
	if not _settings.has("mode"):
		_settings["mode"] = DEFAULT_MODE
	if not _settings.has("favorites"):
		_settings["favorites"] = []
	if not _settings.has("recents"):
		_settings["recents"] = []


# =========================================================================
# User snippet CRUD
# =========================================================================

func add_phrase(id: String, phrase: String, code: String = "", params: Array = []) -> Dictionary:
	if id.strip_edges().is_empty() or phrase.strip_edges().is_empty():
		return {"ok": false, "message": "id and phrase are required."}
	var user_data := _read_json(USER_PATH)
	if user_data.is_empty():
		user_data = {"version": 2, "snippets": {}, "blueprints": {}}
	if not user_data.has("snippets"):
		user_data["snippets"] = {}
	var entry: Dictionary = user_data.snippets.get(id, {})
	if entry.is_empty():
		entry = {"phrases": [], "code": code, "params": params}
	if not entry.has("phrases"):
		entry["phrases"] = []
	if not entry.phrases.has(phrase):
		entry.phrases.append(phrase)
	if code != "":
		entry["code"] = code
	user_data.snippets[id] = entry
	_ensure_user_dir()
	if not _write_json(USER_PATH, user_data):
		return {"ok": false, "message": "Failed to write user library."}
	_merge_from_file(USER_PATH)
	return {"ok": true, "id": id, "phrase": phrase}


func remove_user_snippet(id: String) -> Dictionary:
	if not FileAccess.file_exists(USER_PATH):
		return {"ok": false, "message": "No user library file."}
	var user_data := _read_json(USER_PATH)
	if user_data.is_empty() or not user_data.has("snippets") or not user_data.snippets.has(id):
		return {"ok": false, "message": "Snippet not found in user library."}
	user_data.snippets.erase(id)
	if not _write_json(USER_PATH, user_data):
		return {"ok": false, "message": "Failed to write user library."}
	load_all()
	return {"ok": true, "id": id}


# =========================================================================
# User blueprint CRUD
# =========================================================================

func add_user_blueprint(id: String, data: Dictionary) -> Dictionary:
	if id.strip_edges().is_empty():
		return {"ok": false, "message": "id is required."}
	var user_data := _read_json(USER_PATH)
	if user_data.is_empty():
		user_data = {"version": 2, "snippets": {}, "blueprints": {}}
	if not user_data.has("blueprints"):
		user_data["blueprints"] = {}
	user_data.blueprints[id] = data
	_ensure_user_dir()
	if not _write_json(USER_PATH, user_data):
		return {"ok": false, "message": "Failed to write user library."}
	_merge_from_file(USER_PATH)
	return {"ok": true, "id": id}


func remove_user_blueprint(id: String) -> Dictionary:
	if not FileAccess.file_exists(USER_PATH):
		return {"ok": false, "message": "No user library file."}
	var user_data := _read_json(USER_PATH)
	if user_data.is_empty() or not user_data.has("blueprints") or not user_data.blueprints.has(id):
		return {"ok": false, "message": "Blueprint not found in user library."}
	user_data.blueprints.erase(id)
	if not _write_json(USER_PATH, user_data):
		return {"ok": false, "message": "Failed to write user library."}
	load_all()
	return {"ok": true, "id": id}


# =========================================================================
# Internal — normalization
# =========================================================================

static func _normalize(text: String) -> String:
	var s := text.to_lower().strip_edges()
	s = s.replace(".", "").replace(",", "").replace("!", "").replace("?", "")
	var out := ""
	var last_space := false
	for i in range(s.length()):
		var c := s[i]
		if c == " " or c == "\t" or c == "\n":
			if not last_space and out.length() > 0:
				out += " "
				last_space = true
		else:
			out += c
			last_space = false
	return out.strip_edges()


# =========================================================================
# Internal — result builders
# =========================================================================

func _make_result(id: String, phrase: String) -> Dictionary:
	var s: Dictionary = _snippets.get(id, {})
	return {
		"ok": true,
		"kind": KIND_SNIPPET,
		"id": id,
		"code": str(s.get("code", "")),
		"params": s.get("params", []),
		"param_info": s.get("param_info", {}),
		"details": s.get("details", {}),
		"required_actions": s.get("required_actions", []),
		"category": str(s.get("category", "")),
		"subcategory": str(s.get("subcategory", "")),
		"dimension": str(s.get("dimension", "")),
		"difficulty": str(s.get("difficulty", "")),
		"scene_tree": s.get("scene_tree", []),
		"phrase_matched": phrase,
	}


func _make_blueprint_result(id: String, phrase: String) -> Dictionary:
	var b: Dictionary = _blueprints.get(id, {})
	return {
		"ok": true,
		"kind": KIND_BLUEPRINT,
		"id": id,
		"title": str(b.get("title", id)),
		"root": b.get("root", {}),
		"required_children": b.get("required_children", []),
		"recommended_children": b.get("recommended_children", []),
		"script": str(b.get("script", "")),
		"required_actions": b.get("required_actions", []),
		"setup_notes": b.get("setup_notes", []),
		"next_steps": b.get("next_steps", []),
		"mistakes": b.get("mistakes", []),
		"category": str(b.get("category", "")),
		"subcategory": str(b.get("subcategory", "")),
		"dimension": str(b.get("dimension", "")),
		"difficulty": str(b.get("difficulty", "")),
		"phrase_matched": phrase,
	}


# =========================================================================
# Internal — merging
# =========================================================================

func _merge_from_file(path: String) -> void:
	var data := _read_json(path)
	_merge_dict(data)


func _merge_dict(data: Dictionary) -> void:
	if data.is_empty():
		return

	var snippets: Dictionary = data.get("snippets", {})
	for id in snippets.keys():
		var entry: Dictionary = snippets[id]
		if _snippets.has(id):
			var existing: Dictionary = _snippets[id]
			for key in entry.keys():
				existing[key] = entry[key]
			if entry.has("phrases"):
				for phrase in entry.phrases:
					var norm := _normalize(str(phrase))
					if not norm.is_empty():
						_phrase_index[norm] = id
		else:
			if not entry.has("phrases") or not entry.has("code"):
				continue
			_snippets[id] = entry
			for phrase in entry.phrases:
				var norm := _normalize(str(phrase))
				if not norm.is_empty():
					_phrase_index[norm] = id

	var blueprints: Dictionary = data.get("blueprints", {})
	for id in blueprints.keys():
		var entry: Dictionary = blueprints[id]
		if _blueprints.has(id):
			var existing: Dictionary = _blueprints[id]
			for key in entry.keys():
				existing[key] = entry[key]
			if entry.has("phrases"):
				for phrase in entry.phrases:
					var norm := _normalize(str(phrase))
					if not norm.is_empty():
						_blueprint_phrase_index[norm] = id
		else:
			if not entry.has("phrases") or not entry.has("root"):
				continue
			_blueprints[id] = entry
			for phrase in entry.phrases:
				var norm := _normalize(str(phrase))
				if not norm.is_empty():
					_blueprint_phrase_index[norm] = id

	var templates: Dictionary = data.get("templates", {})
	for id in templates.keys():
		_templates[id] = templates[id]


func _merge_library_folder() -> void:
	var dir := DirAccess.open(LIBRARY_DIR)
	if dir == null:
		return
	var files := dir.get_files()
	files.sort()
	for f in files:
		if f.ends_with(".gd"):
			_merge_library_script(LIBRARY_DIR + f)


func _merge_library_script(path: String) -> void:
	var script = load(path)
	if script == null or not (script is GDScript):
		push_warning("GDASELibrary: could not load library script: " + path)
		return
	var instance = script.new()
	if instance == null or not instance.has_method("get_data"):
		push_warning("GDASELibrary: library script has no get_data(): " + path)
		return
	var data: Dictionary = instance.get_data()
	_merge_dict(data)


# =========================================================================
# Internal — JSON IO
# =========================================================================

static func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var text := file.get_as_text()
	file.close()
	var json := JSON.new()
	if json.parse(text) != OK:
		push_warning("GDASELibrary: failed to parse " + path + ": " + json.get_error_message())
		return {}
	if typeof(json.data) != TYPE_DICTIONARY:
		return {}
	return json.data as Dictionary


static func _write_json(path: String, data: Dictionary) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_warning("GDASELibrary: failed to open for write: " + path)
		return false
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	return true


static func _ensure_user_dir() -> void:
	if not DirAccess.dir_exists_absolute(USER_DIR):
		DirAccess.make_dir_recursive_absolute(USER_DIR)


# =========================================================================
# Internal — fuzzy match
# =========================================================================

static func _fuzzy_match(a: String, b: String) -> bool:
	if a.length() < FUZZY_MIN_LENGTH or b.length() < FUZZY_MIN_LENGTH:
		return false
	return _edit_distance(a, b) <= FUZZY_MAX_DISTANCE


static func _edit_distance(a: String, b: String) -> int:
	var la := a.length()
	var lb := b.length()
	if la == 0:
		return lb
	if lb == 0:
		return la
	if la > lb:
		var tmp_str := a
		a = b
		b = tmp_str
		var tmp_len := la
		la = lb
		lb = tmp_len
	var prev: Array = []
	prev.resize(la + 1)
	for i in range(la + 1):
		prev[i] = i
	var curr: Array = []
	curr.resize(la + 1)
	for j in range(1, lb + 1):
		curr[0] = j
		for i in range(1, la + 1):
			var cost := 0 if a[i - 1] == b[j - 1] else 1
			var del: int = curr[i - 1] + 1
			var ins: int = prev[i] + 1
			var sub: int = prev[i - 1] + cost
			curr[i] = min(min(del, ins), sub)
		var swap: Array = prev
		prev = curr
		curr = swap
	return prev[la]


# =========================================================================
# Internal — token-level fuzzy
# =========================================================================

static func _token_fuzzy_match(query: String, phrase: String) -> bool:
	var q_tokens := query.split(" ", false)
	var p_tokens := phrase.split(" ", false)
	if q_tokens.is_empty() or p_tokens.is_empty():
		return false
	var matched := 0
	for qt in q_tokens:
		for pt in p_tokens:
			if _token_edit_match(qt, pt):
				matched += 1
				break
	var needed := int(ceil(q_tokens.size() * TOKEN_MATCH_RATIO))
	if needed < 1:
		needed = 1
	return matched >= needed


static func _token_edit_match(a: String, b: String) -> bool:
	if a == b:
		return true
	var min_len: int = min(a.length(), b.length())
	if min_len < 3:
		return false
	var threshold: int = max(1, min_len / 3)
	var d := _edit_distance(a, b)
	if d <= threshold:
		return true
	if _is_single_transposition(a, b):
		return true
	return false


static func _is_single_transposition(a: String, b: String) -> bool:
	if a.length() != b.length() or a.length() < 2:
		return false
	var diffs: Array = []
	for i in range(a.length()):
		if a[i] != b[i]:
			diffs.append(i)
			if diffs.size() > 2:
				return false
	if diffs.size() != 2:
		return false
	return a[diffs[0]] == b[diffs[1]] and a[diffs[1]] == b[diffs[0]]


# =========================================================================
# Internal — commented code generation
# =========================================================================

func _generate_commented_code(id: String) -> String:
	var s: Dictionary = _snippets.get(id, {})
	var code := str(s.get("code", ""))
	if code.is_empty():
		return ""
	var details: Dictionary = s.get("details", {})
	var param_info: Dictionary = s.get("param_info", {})
	var params: Array = s.get("params", [])
	var lines: Array = []
	var what := str(details.get("what", ""))
	if not what.is_empty():
		lines.append("# " + what)
		lines.append("#")
	var where := str(details.get("where", ""))
	if not where.is_empty():
		lines.append("# Where: " + where)
	var before := str(details.get("before", ""))
	if not before.is_empty():
		lines.append("# Before: " + before)
	var after := str(details.get("after", ""))
	if not after.is_empty():
		lines.append("# After: " + after)
	if not params.is_empty():
		lines.append("#")
		lines.append("# Tunable parameters:")
		for p in params:
			var pname := str(p)
			var info: Dictionary = param_info.get(pname, {})
			if info.is_empty():
				lines.append("#   " + pname)
				continue
			var default_value: Variant = info.get("default", null)
			var what_does := str(info.get("what", ""))
			var head := "#   " + pname
			if default_value != null:
				head += " (default " + str(default_value) + ")"
			if not what_does.is_empty():
				head += " — " + what_does
			lines.append(head)
			var typical := str(info.get("typical", ""))
			if not typical.is_empty():
				lines.append("#     Typical: " + typical)
			var increase := str(info.get("increase", ""))
			if not increase.is_empty():
				lines.append("#     Increase: " + increase)
			var decrease := str(info.get("decrease", ""))
			if not decrease.is_empty():
				lines.append("#     Decrease: " + decrease)
	var mistakes := str(details.get("mistakes", ""))
	if not mistakes.is_empty():
		lines.append("#")
		lines.append("# Common mistake: " + mistakes)
	if lines.is_empty():
		return code
	return "\n".join(lines) + "\n\n" + code
