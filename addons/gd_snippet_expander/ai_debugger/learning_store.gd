# res://addons/gd_snippet_expander/ai_debugger/learning_store.gd
@tool
class_name LearningStore
extends RefCounted

## Persistent record of which fixes the user has applied or declined.
##
## Part of the GD Snippet Expander mini AI debugger (v1.6).
##
## Every time the panel shows a fix and the user either inserts it or
## dismisses it, that choice is recorded. Over time, the store learns
## which fixes tend to be useful for which query patterns, and can
## bias future rankings toward the user's habits.
##
## STORAGE FORMAT (JSON, user://gd_snippet_expander/fix_history.json):
##   {
##     "version": 1,
##     "fixes": {
##       "is_on_floor_missing": {
##         "applied": 3,
##         "declined": 1,
##         "last_applied": 1727200000,
##         "tokens": ["jump", "player", "cant"]
##       }
##     }
##   }
##
## BOOST FORMULA:
##   applied_score   = min(1.0, applied / 3.0)      saturates at 3 applies
##   decline_penalty = min(0.5, declined * 0.1)     each decline costs 0.1
##   token_match     = fraction of current query tokens present in tokens
##                     (0.0 if either side has no tokens)
##   raw_boost       = 0.7 * token_match + 0.3 * applied_score
##   final_boost     = max(0.0, raw_boost - decline_penalty)
##
## The final boost is in [0, 1]. apply_boosts multiplies confidence by
## (1.0 + boost * BOOST_STRENGTH) with BOOST_STRENGTH = 0.5.
##
## Usage:
##   var ls := LearningStore.new()
##   ls.try_load_default()
##   ls.record_apply("is_on_floor_missing", ["jump", "player"])
##   var boosted := ls.apply_boosts(results, ["jump", "player"])

const VERSION := 1
const DEFAULT_PATH := "user://gd_snippet_expander/fix_history.json"
const BOOST_STRENGTH := 0.5
const MAX_FIXES := 500
const MAX_TOKENS_PER_FIX := 200

# --- public state -------------------------------------------------------

var loaded: bool = false
var load_error: String = ""
var store_path: String = DEFAULT_PATH

# --- internal -----------------------------------------------------------

# fix_id -> {
#   "applied": int,
#   "declined": int,
#   "last_applied": int (unix seconds),
#   "tokens": {token: true, ...}   (set)
# }
var _fixes: Dictionary = {}


# --- loading / saving ---------------------------------------------------

func try_load_default() -> bool:
	return load_from_path(DEFAULT_PATH)


## Load the history file. Silently starts empty if the file doesn't
## exist yet — that's the normal case on first run.
func load_from_path(path: String) -> bool:
	store_path = path
	loaded = false
	load_error = ""
	_fixes = {}

	if not FileAccess.file_exists(path):
		loaded = true
		return true

	var f: FileAccess = FileAccess.open(path, FileAccess.READ)
	if f == null:
		load_error = "cannot open: " + path
		return false
	var text: String = f.get_as_text()
	f.close()

	if text.strip_edges() == "":
		loaded = true
		return true

	# Use the instance form of the JSON parser. JSON.parse_string()
	# prints an engine error on invalid input; JSON.new().parse()
	# returns the error silently.
	var parser: JSON = JSON.new()
	var err: int = parser.parse(text)
	if err != OK:
		load_error = "invalid JSON in %s (line %d): %s" % [
			path, parser.get_error_line(), parser.get_error_message()
		]
		return false
	var parsed: Variant = parser.data
	if not (parsed is Dictionary):
		load_error = "root JSON value is not an object"
		return false
	var root: Dictionary = parsed

	var ver: int = int(root.get("version", 0))
	if ver != VERSION:
		load_error = "unsupported version %d (expected %d)" % [ver, VERSION]
		return false

	var fixes_raw: Variant = root.get("fixes", {})
	if not (fixes_raw is Dictionary):
		load_error = "'fixes' is not an object"
		return false
	var fixes_dict: Dictionary = fixes_raw

	var ids: Array = fixes_dict.keys()
	var i: int = 0
	while i < ids.size():
		var fid: String = str(ids[i])
		var raw_entry: Variant = fixes_dict[fid]
		if raw_entry is Dictionary:
			var raw_dict: Dictionary = raw_entry
			var applied: int = int(raw_dict.get("applied", 0))
			var declined: int = int(raw_dict.get("declined", 0))
			var last_applied: int = int(raw_dict.get("last_applied", 0))
			var tokens_list: Array = raw_dict.get("tokens", [])
			var token_set: Dictionary = {}
			var ti: int = 0
			while ti < tokens_list.size():
				var tok: String = str(tokens_list[ti])
				if tok != "":
					token_set[tok] = true
				ti += 1
			var entry: Dictionary = {
				"applied": applied,
				"declined": declined,
				"last_applied": last_applied,
				"tokens": token_set,
			}
			_fixes[fid] = entry
		i += 1

	loaded = true
	return true


func save_to_path(path: String = "") -> bool:
	var target: String = path
	if target == "":
		target = store_path
	var dir: String = target.get_base_dir()
	if dir != "" and not DirAccess.dir_exists_absolute(dir):
		DirAccess.make_dir_recursive_absolute(dir)

	var out_fixes: Dictionary = {}
	var ids: Array = _fixes.keys()
	ids.sort()
	var i: int = 0
	while i < ids.size():
		var fid: String = str(ids[i])
		var entry: Dictionary = _fixes[fid]
		var token_set: Dictionary = entry.get("tokens", {})
		var token_keys: Array = token_set.keys()
		token_keys.sort()
		var token_arr: Array = []
		var ti: int = 0
		while ti < token_keys.size():
			token_arr.append(str(token_keys[ti]))
			ti += 1
		var serialized: Dictionary = {
			"applied": int(entry.get("applied", 0)),
			"declined": int(entry.get("declined", 0)),
			"last_applied": int(entry.get("last_applied", 0)),
			"tokens": token_arr,
		}
		out_fixes[fid] = serialized
		i += 1

	var root: Dictionary = {
		"version": VERSION,
		"fixes": out_fixes,
	}
	var text: String = JSON.stringify(root, "\t")

	var f: FileAccess = FileAccess.open(target, FileAccess.WRITE)
	if f == null:
		load_error = "cannot write: " + target
		return false
	f.store_string(text)
	f.close()
	return true


func clear() -> void:
	_fixes = {}
	if FileAccess.file_exists(store_path):
		DirAccess.remove_absolute(store_path)


# --- recording ----------------------------------------------------------

func record_apply(fix_id: String, query_tokens: Array = []) -> void:
	if fix_id == "":
		return
	var entry: Dictionary = _ensure_entry(fix_id)
	entry["applied"] = int(entry.get("applied", 0)) + 1
	entry["last_applied"] = int(Time.get_unix_time_from_system())
	var token_set: Dictionary = entry.get("tokens", {})
	var i: int = 0
	while i < query_tokens.size():
		var tok: String = str(query_tokens[i]).to_lower()
		if tok != "" and token_set.size() < MAX_TOKENS_PER_FIX:
			token_set[tok] = true
		i += 1
	entry["tokens"] = token_set
	_fixes[fix_id] = entry
	_enforce_cap()
	save_to_path()


func record_decline(fix_id: String) -> void:
	if fix_id == "":
		return
	var entry: Dictionary = _ensure_entry(fix_id)
	entry["declined"] = int(entry.get("declined", 0)) + 1
	_fixes[fix_id] = entry
	_enforce_cap()
	save_to_path()


func _ensure_entry(fix_id: String) -> Dictionary:
	if _fixes.has(fix_id):
		var existing: Variant = _fixes[fix_id]
		if existing is Dictionary:
			return existing
	var entry: Dictionary = {
		"applied": 0,
		"declined": 0,
		"last_applied": 0,
		"tokens": {},
	}
	_fixes[fix_id] = entry
	return entry


func _enforce_cap() -> void:
	if _fixes.size() <= MAX_FIXES:
		return
	# Drop the oldest entries by last_applied. Simpler than a proper
	# LRU and rarely hit in practice.
	var ids: Array = _fixes.keys()
	var entry_pairs: Array = []
	var i: int = 0
	while i < ids.size():
		var fid: String = str(ids[i])
		var entry: Dictionary = _fixes[fid]
		entry_pairs.append({
			"id": fid,
			"last": int(entry.get("last_applied", 0)),
		})
		i += 1
	entry_pairs.sort_custom(_compare_by_last)
	var to_drop: int = _fixes.size() - MAX_FIXES
	i = 0
	while i < to_drop:
		var item: Dictionary = entry_pairs[i]
		_fixes.erase(str(item["id"]))
		i += 1


static func _compare_by_last(a: Dictionary, b: Dictionary) -> bool:
	return int(a.get("last", 0)) < int(b.get("last", 0))


# --- query --------------------------------------------------------------

func get_boost(fix_id: String, query_tokens: Array = []) -> float:
	if not _fixes.has(fix_id):
		return 0.0
	var entry: Dictionary = _fixes[fix_id]
	var applied: int = int(entry.get("applied", 0))
	var declined: int = int(entry.get("declined", 0))
	var token_set: Dictionary = entry.get("tokens", {})

	var applied_score: float = minf(1.0, float(applied) / 3.0)
	var decline_penalty: float = minf(0.5, float(declined) * 0.1)

	var token_match: float = 0.0
	if not query_tokens.is_empty() and not token_set.is_empty():
		var overlap: int = 0
		var i: int = 0
		while i < query_tokens.size():
			var tok: String = str(query_tokens[i]).to_lower()
			if token_set.has(tok):
				overlap += 1
			i += 1
		token_match = float(overlap) / float(query_tokens.size())

	var raw: float = 0.7 * token_match + 0.3 * applied_score
	return maxf(0.0, raw - decline_penalty)


## Multiply every result's confidence by its boost and re-sort.
func apply_boosts(results: Array, query_tokens: Array = []) -> Array:
	var out: Array = []
	var i: int = 0
	while i < results.size():
		var r: Dictionary = results[i].duplicate()
		var fid: String = str(r.get("fix_id", ""))
		var boost: float = get_boost(fid, query_tokens)
		var conf: float = float(r.get("confidence", 0.0))
		var multiplier: float = 1.0 + boost * BOOST_STRENGTH
		r["confidence"] = clampf(conf * multiplier, 0.0, 1.0)
		r["user_boost"] = boost
		out.append(r)
		i += 1
	out.sort_custom(_compare_confidence_desc)
	return out


static func _compare_confidence_desc(a: Dictionary, b: Dictionary) -> bool:
	return float(a.get("confidence", 0.0)) > float(b.get("confidence", 0.0))


# --- stats --------------------------------------------------------------

func get_fix_stats(fix_id: String) -> Dictionary:
	if not _fixes.has(fix_id):
		return {
			"applied": 0,
			"declined": 0,
			"last_applied": 0,
			"token_count": 0,
		}
	var entry: Dictionary = _fixes[fix_id]
	var token_set: Dictionary = entry.get("tokens", {})
	return {
		"applied": int(entry.get("applied", 0)),
		"declined": int(entry.get("declined", 0)),
		"last_applied": int(entry.get("last_applied", 0)),
		"token_count": token_set.size(),
	}


func fix_count() -> int:
	return _fixes.size()


## List every fix ID with any history.
func known_fixes() -> Array:
	return _fixes.keys()


# --- self-test ----------------------------------------------------------

static func self_test() -> void:
	print("=== LearningStore self-test ===")
	var failures: Array[String] = []

	# --- 1. Fresh store starts empty ---
	var ls: LearningStore = LearningStore.new()
	ls.store_path = "user://gdse_test_history_%d.json" % Time.get_ticks_msec()
	ls._fixes = {}
	ls.loaded = true
	if ls.fix_count() != 0:
		failures.append("1: fresh store should have zero fixes")

	# --- 2. record_apply adds an entry ---
	ls.record_apply("test_fix_a", ["jump", "player"])
	if ls.fix_count() != 1:
		failures.append("2: after one apply, fix_count should be 1")
	var st2: Dictionary = ls.get_fix_stats("test_fix_a")
	if int(st2.get("applied", 0)) != 1:
		failures.append("2: applied count should be 1")
	if int(st2.get("token_count", 0)) != 2:
		failures.append("2: token_count should be 2, got %d" % int(st2.get("token_count", 0)))

	# --- 3. Duplicate tokens don't grow the set ---
	ls.record_apply("test_fix_a", ["jump", "player", "jump"])
	var st3: Dictionary = ls.get_fix_stats("test_fix_a")
	if int(st3.get("applied", 0)) != 2:
		failures.append("3: applied count should be 2")
	if int(st3.get("token_count", 0)) != 2:
		failures.append("3: token_count should still be 2")

	# --- 4. decline increments separately ---
	ls.record_decline("test_fix_b")
	var st4: Dictionary = ls.get_fix_stats("test_fix_b")
	if int(st4.get("declined", 0)) != 1:
		failures.append("4: declined count should be 1")
	if int(st4.get("applied", 0)) != 0:
		failures.append("4: applied count should be 0 for fix_b")

	# --- 5. get_boost is zero for unknown fixes ---
	if ls.get_boost("no_such_fix", ["jump"]) != 0.0:
		failures.append("5: unknown fix should have zero boost")

	# --- 6. get_boost is positive after several applies with matching tokens ---
	ls.record_apply("test_fix_c", ["jump", "player", "cant"])
	ls.record_apply("test_fix_c", ["jump", "player"])
	ls.record_apply("test_fix_c", ["jump"])
	var boost6: float = ls.get_boost("test_fix_c", ["jump", "player"])
	if boost6 <= 0.0:
		failures.append("6: boost should be positive with matching tokens")

	# --- 7. Boost bounded in [0, 1] ---
	if boost6 > 1.0:
		failures.append("7: boost should be at most 1.0")

	# --- 8. Decline reduces boost ---
	var before_decline: float = ls.get_boost("test_fix_a", ["jump", "player"])
	ls.record_decline("test_fix_a")
	ls.record_decline("test_fix_a")
	ls.record_decline("test_fix_a")
	var after_decline: float = ls.get_boost("test_fix_a", ["jump", "player"])
	if after_decline >= before_decline:
		failures.append("8: declines should reduce boost (before %f, after %f)" % [before_decline, after_decline])

	# --- 9. apply_boosts re-ranks toward user-preferred fixes ---
	ls.record_apply("test_fix_d", [])
	var results: Array = []
	results.append({"fix_id": "test_fix_d", "confidence": 0.50, "record": {}})
	results.append({"fix_id": "test_fix_c", "confidence": 0.48, "record": {}})
	var boosted: Array = ls.apply_boosts(results, ["jump", "player"])
	if boosted.is_empty():
		failures.append("9: apply_boosts returned empty")
	else:
		var top: Dictionary = boosted[0]
		var top_id: String = str(top.get("fix_id", ""))
		if top_id != "test_fix_c":
			failures.append("9: test_fix_c should be top after boost, got " + top_id)

	# --- 10. apply_boosts attaches user_boost field ---
	if not boosted.is_empty():
		var top2: Dictionary = boosted[0]
		if not top2.has("user_boost"):
			failures.append("10: boosted result should have user_boost field")

	# --- 11. Save / load round-trip preserves history ---
	var tmp: String = "user://gdse_test_history_%d.json" % Time.get_ticks_msec()
	ls.store_path = tmp
	if not ls.save_to_path(tmp):
		failures.append("11: save_to_path failed: " + ls.load_error)
	else:
		var ls2: LearningStore = LearningStore.new()
		if not ls2.load_from_path(tmp):
			failures.append("11: load_from_path failed: " + ls2.load_error)
		else:
			var st_c: Dictionary = ls2.get_fix_stats("test_fix_c")
			if int(st_c.get("applied", 0)) != 3:
				failures.append("11: round-trip applied count mismatch for test_fix_c")
			var boost_c: float = ls2.get_boost("test_fix_c", ["jump", "player"])
			if abs(boost_c - ls.get_boost("test_fix_c", ["jump", "player"])) > 0.0001:
				failures.append("11: round-trip boost mismatch")
		if FileAccess.file_exists(tmp):
			DirAccess.remove_absolute(tmp)

	# --- 12. Missing file on load is not an error ---
	var ls3: LearningStore = LearningStore.new()
	var missing_path: String = "user://definitely_not_here_%d.json" % Time.get_ticks_msec()
	if not ls3.load_from_path(missing_path):
		failures.append("12: missing file should load as empty, not fail")
	if ls3.fix_count() != 0:
		failures.append("12: missing file should produce empty store")

	# --- 13. Corrupt JSON is rejected with an error, silently ---
	var bad_path: String = "user://gdse_test_bad_%d.json" % Time.get_ticks_msec()
	var bf: FileAccess = FileAccess.open(bad_path, FileAccess.WRITE)
	if bf != null:
		bf.store_string("{ not valid json")
		bf.close()
		var ls4: LearningStore = LearningStore.new()
		if ls4.load_from_path(bad_path):
			failures.append("13: invalid JSON should be rejected")
		if ls4.load_error == "":
			failures.append("13: invalid JSON should set load_error")
		if FileAccess.file_exists(bad_path):
			DirAccess.remove_absolute(bad_path)

	# --- 14. clear() wipes state ---
	ls.clear()
	if ls.fix_count() != 0:
		failures.append("14: clear() should empty the store")

	print("")
	if failures.is_empty():
		print("OK — all assertions passed")
	else:
		print("FAILED — %d issues:" % failures.size())
		var i: int = 0
		while i < failures.size():
			print("  " + failures[i])
			i += 1
