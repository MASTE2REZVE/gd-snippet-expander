# res://addons/gd_snippet_expander/ai_debugger/output_watcher.gd
@tool
class_name OutputWatcher
extends Node

## Watches Godot's Output panel and emits signals on new errors and
## on errors that disappear from Output.

signal error_detected(record: Dictionary, raw_line: String)
signal error_removed(record_id: String)

const POLL_INTERVAL := 0.5
const SIGNATURE_LENGTH := 120
const BOOTSTRAP_LINES := 30

var _library: ErrorLibrary = null
var _log_label: RichTextLabel = null
var _timer: Timer = null
var _available: bool = false
var _enabled: bool = true
var _last_text_hash: int = 0
var _visible_ids: Dictionary = {}
var _seen_lines: Dictionary = {}
var _poll_count: int = 0
var _match_count: int = 0
var _emit_count: int = 0


func _ready() -> void:
	set_process(false)
	_ensure_timer()


func _exit_tree() -> void:
	if _timer != null and not _timer.is_stopped():
		_timer.stop()


func _ensure_timer() -> void:
	if _timer != null:
		return
	_timer = Timer.new()
	_timer.wait_time = POLL_INTERVAL
	_timer.one_shot = false
	_timer.autostart = false
	_timer.timeout.connect(_on_poll)
	add_child(_timer)


func set_library(lib: ErrorLibrary) -> void:
	_library = lib


func has_library() -> bool:
	return _library != null


func start() -> bool:
	_ensure_timer()
	if not is_inside_tree():
		return false
	if not _available:
		_log_label = _find_output_label()
		if _log_label == null:
			_available = false
			return false
		_available = true
		_last_text_hash = 0
	if _timer.is_stopped():
		_timer.start()
	return true


func stop() -> void:
	if _timer != null and not _timer.is_stopped():
		_timer.stop()


func is_running() -> bool:
	return _timer != null and not _timer.is_stopped()


func is_available() -> bool:
	return _available


func set_enabled(v: bool) -> void:
	_enabled = v


func is_enabled() -> bool:
	return _enabled


func reset_dedupe() -> void:
	_seen_lines.clear()
	_visible_ids.clear()
	_last_text_hash = 0


func trigger_now() -> void:
	if _library == null or _log_label == null:
		return
	_on_poll()


func rescan() -> void:
	if _library == null or _log_label == null:
		return
	reset_dedupe()
	_on_poll()


func get_stats() -> Dictionary:
	return {
		"polls": _poll_count,
		"matches": _match_count,
		"emits": _emit_count,
		"available": _available,
		"running": is_running(),
		"visible_ids": _visible_ids.size(),
	}


func feed_line(line: String) -> Dictionary:
	if _library == null:
		return {}
	var stripped: String = line.strip_edges()
	if stripped == "":
		return {}
	var sig: String = _signature(stripped)
	if _seen_lines.has(sig):
		return {}
	var hit: Dictionary = _library.match_line(stripped)
	if hit.is_empty():
		return {}
	_seen_lines[sig] = true
	_match_count += 1
	_emit_count += 1
	error_detected.emit(hit, stripped)
	return hit


func _on_poll() -> void:
	_poll_count += 1
	if not _enabled or _library == null or _log_label == null:
		return

	var text: String = _read_log_text()
	var h: int = hash(text)
	if h == _last_text_hash:
		return
	_last_text_hash = h

	var lines: Array = text.split("\n")
	var current: int = lines.size()

	var new_visible: Dictionary = {}
	var start: int = max(0, current - BOOTSTRAP_LINES)
	var i: int = start
	while i < current:
		var stripped: String = str(lines[i]).strip_edges()
		if stripped != "":
			var hit: Dictionary = _library.match_line(stripped)
			if not hit.is_empty():
				var id: String = str(hit.get("id", ""))
				if id != "" and not new_visible.has(id):
					new_visible[id] = {"record": hit, "raw_line": stripped}
		i += 1

	for id in new_visible.keys():
		if not _visible_ids.has(id):
			var entry: Dictionary = new_visible[id]
			_match_count += 1
			_emit_count += 1
			error_detected.emit(entry["record"], entry["raw_line"])

	for old_id in _visible_ids.keys():
		if not new_visible.has(old_id):
			error_removed.emit(str(old_id))

	_visible_ids = {}
	for id in new_visible.keys():
		_visible_ids[id] = true


func _read_log_text() -> String:
	if _log_label == null:
		return ""
	if _log_label.has_method("get_parsed_text"):
		return _log_label.get_parsed_text()
	return _log_label.text


func _signature(line: String) -> String:
	if line.length() <= SIGNATURE_LENGTH:
		return line
	return line.substr(0, SIGNATURE_LENGTH)


func _find_output_label() -> RichTextLabel:
	var base: Control = EditorInterface.get_base_control()
	if base == null:
		return null
	var tab: TabContainer = _find_tab_with(base, "Output")
	if tab != null:
		var idx: int = _tab_index_of(tab, "Output")
		if idx >= 0:
			var content: Control = tab.get_tab_control(idx)
			if content != null:
				var rt: RichTextLabel = _find_rich_text(content)
				if rt != null:
					return rt
	var by_name: RichTextLabel = _find_rich_text_named(base, "output")
	if by_name != null:
		return by_name
	return _find_rich_text_named(base, "log")


func _find_tab_with(node: Node, title: String) -> TabContainer:
	if node is TabContainer:
		var tc: TabContainer = node
		var n: int = tc.get_tab_count()
		var i: int = 0
		while i < n:
			if tc.get_tab_title(i) == title:
				return tc
			i += 1
	for child in node.get_children():
		var found: TabContainer = _find_tab_with(child, title)
		if found != null:
			return found
	return null


func _tab_index_of(tab: TabContainer, title: String) -> int:
	var n: int = tab.get_tab_count()
	var i: int = 0
	while i < n:
		if tab.get_tab_title(i) == title:
			return i
		i += 1
	return -1


func _find_rich_text(node: Node) -> RichTextLabel:
	if node is RichTextLabel:
		return node
	for child in node.get_children():
		var found: RichTextLabel = _find_rich_text(child)
		if found != null:
			return found
	return null


func _find_rich_text_named(node: Node, fragment: String) -> RichTextLabel:
	if node is RichTextLabel:
		var n: String = node.name.to_lower()
		if n.find(fragment) != -1:
			return node
	for child in node.get_children():
		var found: RichTextLabel = _find_rich_text_named(child, fragment)
		if found != null:
			return found
	return null


static func self_test() -> void:
	print("=== OutputWatcher self-test ===")
	var failures: Array[String] = []

	var lib: ErrorLibrary = ErrorLibrary.new()
	lib.load_all()
	var w: OutputWatcher = OutputWatcher.new()
	w.set_library(lib)

	var h2: Dictionary = w.feed_line("ERROR: res://player.gd:42 - Invalid call. Nonexistent function 'jump' in base 'Nil'.")
	if h2.is_empty():
		failures.append("1: matching error should return a record")

	var h3: Dictionary = w.feed_line("Just some normal log output")
	if not h3.is_empty():
		failures.append("2: non-error line should not match")

	w.reset_dedupe()
	var h5a: Dictionary = w.feed_line("ERROR: Division by zero in operator '/'.")
	var h5b: Dictionary = w.feed_line("ERROR: Division by zero in operator '/'.")
	if h5a.is_empty():
		failures.append("3: first division-by-zero should match")
	if not h5b.is_empty():
		failures.append("3: duplicate should be suppressed without reset")

	w.reset_dedupe()
	var h7: Dictionary = w.feed_line("ERROR: Division by zero in operator '/'.")
	if h7.is_empty():
		failures.append("4: after reset_dedupe, same line should match again")

	var fire_count: Array = [0]
	w.error_detected.connect(_test_count_signal.bind(fire_count))
	w.reset_dedupe()
	w.feed_line("ERROR: Division by zero in operator '/'.")
	if int(fire_count[0]) != 1:
		failures.append("5: signal should fire once, got %d" % int(fire_count[0]))

	w.free()

	print("")
	if failures.is_empty():
		print("OK - all assertions passed")
	else:
		print("FAILED - %d issues:" % failures.size())
		var i: int = 0
		while i < failures.size():
			print("  " + failures[i])
			i += 1


static func _test_count_signal(_rec: Dictionary, _line: String, counter: Array) -> void:
	counter[0] = int(counter[0]) + 1
