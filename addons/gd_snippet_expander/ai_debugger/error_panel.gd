# res://addons/gd_snippet_expander/ai_debugger/error_panel.gd
@tool
class_name ErrorPanel
extends VBoxContainer

const FONT_STATUS := 32
const FONT_SOURCE := 26
const FONT_CARD_TITLE := 36
const FONT_CARD_META := 26
const FONT_CODE := 30
const FONT_DESC := 30
const FONT_BUTTON := 32
const ROW_HEIGHT := 72
const MAX_CARDS := 25
const DECAY_SECONDS := 3.0

var _library: ErrorLibrary = null
var _watcher: OutputWatcher = null
var _scroll: ScrollContainer = null
var _inner: VBoxContainer = null
var _brain: BrainUI = null
var _status_label: Label = null
var _watcher_status_label: Label = null
var _clear_button: Button = null
var _refresh_button: Button = null
var _paste_row: HBoxContainer = null
var _paste_field: LineEdit = null
var _paste_button: Button = null
var _cards_container: VBoxContainer = null
var _decay_timer: Timer = null

var _seen: Dictionary = {}
var _card_order: Array = []


func set_library(lib: ErrorLibrary) -> void:
	_library = lib


func set_watcher(w: OutputWatcher) -> void:
	if _watcher != null:
		if _watcher.error_detected.is_connected(_on_error_detected):
			_watcher.error_detected.disconnect(_on_error_detected)
		if _watcher.error_removed.is_connected(_on_error_removed):
			_watcher.error_removed.disconnect(_on_error_removed)
	_watcher = w
	if _watcher != null:
		_watcher.error_detected.connect(_on_error_detected)
		_watcher.error_removed.connect(_on_error_removed)


func has_dependencies() -> bool:
	return _library != null


func _ready() -> void:
	add_theme_constant_override("separation", 20)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	_build_ui()
	_ensure_decay_timer()
	_refresh_watcher_status()


func _build_ui() -> void:
	_scroll = ScrollContainer.new()
	_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	add_child(_scroll)

	_inner = VBoxContainer.new()
	_inner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_inner.add_theme_constant_override("separation", 20)
	_scroll.add_child(_inner)

	var status_row: HBoxContainer = HBoxContainer.new()
	status_row.add_theme_constant_override("separation", 20)

	_brain = BrainUI.new()
	_brain.custom_minimum_size = Vector2(96, 96)
	status_row.add_child(_brain)

	var status_col: VBoxContainer = VBoxContainer.new()
	status_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status_col.add_theme_constant_override("separation", 8)

	_status_label = Label.new()
	_status_label.text = "Watching for errors..."
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.add_theme_font_size_override("font_size", FONT_STATUS)
	status_col.add_child(_status_label)

	_watcher_status_label = Label.new()
	_watcher_status_label.text = ""
	_watcher_status_label.add_theme_font_size_override("font_size", FONT_SOURCE)
	_watcher_status_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))
	_watcher_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_col.add_child(_watcher_status_label)

	status_row.add_child(status_col)

	_refresh_button = Button.new()
	_refresh_button.text = "Rescan"
	_refresh_button.add_theme_font_size_override("font_size", FONT_BUTTON)
	_refresh_button.custom_minimum_size = Vector2(140, ROW_HEIGHT)
	_refresh_button.pressed.connect(_on_refresh_pressed)
	status_row.add_child(_refresh_button)

	_clear_button = Button.new()
	_clear_button.text = "Clear"
	_clear_button.add_theme_font_size_override("font_size", FONT_BUTTON)
	_clear_button.custom_minimum_size = Vector2(140, ROW_HEIGHT)
	_clear_button.pressed.connect(_on_clear_pressed)
	status_row.add_child(_clear_button)

	_inner.add_child(status_row)

	_paste_row = HBoxContainer.new()
	_paste_row.add_theme_constant_override("separation", 12)
	_paste_row.visible = false

	_paste_field = LineEdit.new()
	_paste_field.placeholder_text = "Paste a Godot error line here"
	_paste_field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_paste_field.add_theme_font_size_override("font_size", FONT_STATUS)
	_paste_field.custom_minimum_size = Vector2(0, ROW_HEIGHT)
	_paste_field.text_submitted.connect(_on_paste_submitted)
	_paste_row.add_child(_paste_field)

	_paste_button = Button.new()
	_paste_button.text = "Check"
	_paste_button.add_theme_font_size_override("font_size", FONT_BUTTON)
	_paste_button.custom_minimum_size = Vector2(140, ROW_HEIGHT)
	_paste_button.pressed.connect(_on_paste_pressed)
	_paste_row.add_child(_paste_button)

	_inner.add_child(_paste_row)

	_cards_container = VBoxContainer.new()
	_cards_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_cards_container.add_theme_constant_override("separation", 20)
	_inner.add_child(_cards_container)


func _ensure_decay_timer() -> void:
	if _decay_timer != null:
		return
	_decay_timer = Timer.new()
	_decay_timer.wait_time = DECAY_SECONDS
	_decay_timer.one_shot = true
	_decay_timer.timeout.connect(_on_decay_timeout)
	add_child(_decay_timer)


func start_watching() -> bool:
	if _watcher == null:
		_refresh_watcher_status()
		return false
	var ok: bool = _watcher.start()
	_refresh_watcher_status()
	if ok:
		_set_status("Watching for errors...", Color(0.75, 0.85, 0.95))
	else:
		_set_status("Watcher couldn't find the Output panel.", Color(0.9, 0.7, 0.4))
	return ok


func stop_watching() -> void:
	if _watcher != null:
		_watcher.stop()
	_refresh_watcher_status()


func is_watching() -> bool:
	return _watcher != null and _watcher.is_running()


func on_show() -> void:
	if _watcher == null:
		_refresh_watcher_status()
		return
	if not _watcher.is_running():
		_watcher.start()
	_watcher.trigger_now()
	_refresh_watcher_status()
	if _scroll != null:
		_scroll.scroll_vertical = 0
	var cards: int = _card_order.size()
	if cards == 0:
		_set_status("Watching for errors...", Color(0.75, 0.85, 0.95))
	else:
		_set_status("%d error(s) tracked." % cards, Color(0.75, 0.8, 0.85))


func rescan_all() -> void:
	clear_all()
	if _watcher == null:
		_refresh_watcher_status()
		return
	if not _watcher.is_running():
		_watcher.start()
	_watcher.rescan()
	_refresh_watcher_status()
	if _scroll != null:
		_scroll.scroll_vertical = 0
	if _card_order.size() == 0:
		_set_status("Rescanned. No errors found.", Color(0.75, 0.8, 0.85))
	else:
		_set_status("Rescanned. %d error(s) found." % _card_order.size(), Color(0.4, 0.85, 0.45))


func feed_line(line: String) -> Dictionary:
	if _library == null:
		return {}
	var hit: Dictionary = _library.match_line(line)
	if hit.is_empty():
		_set_status("No match for that line.", Color(0.85, 0.6, 0.3))
		return {}
	_add_error_card(hit, line.strip_edges())
	return hit


func clear_all() -> void:
	_seen.clear()
	_card_order.clear()
	_clear_container(_cards_container)
	if _brain != null:
		_brain.set_confidence(0.0)
	_set_status("Cleared.", Color(0.7, 0.7, 0.75))


func card_count() -> int:
	return _card_order.size()


func _on_error_detected(record: Dictionary, raw_line: String) -> void:
	_add_error_card(record, raw_line)


func _on_error_removed(fix_id: String) -> void:
	if not _seen.has(fix_id):
		return
	var entry: Dictionary = _seen[fix_id]
	var card = entry.get("card", null)
	if card != null and is_instance_valid(card):
		card.queue_free()
	_seen.erase(fix_id)
	var idx: int = _card_order.find(fix_id)
	if idx >= 0:
		_card_order.remove_at(idx)
	if _card_order.is_empty():
		_set_status("No errors in Output.", Color(0.75, 0.8, 0.85))
	else:
		_set_status("%d error(s) tracked." % _card_order.size(), Color(0.75, 0.8, 0.85))


func _on_clear_pressed() -> void:
	clear_all()


func _on_refresh_pressed() -> void:
	rescan_all()


func _on_paste_submitted(_text: String) -> void:
	_on_paste_pressed()


func _on_paste_pressed() -> void:
	if _paste_field == null:
		return
	var text: String = _paste_field.text
	if text.strip_edges() == "":
		_set_status("Paste an error line first.", Color(0.85, 0.6, 0.3))
		return
	var hit: Dictionary = feed_line(text)
	if not hit.is_empty():
		_paste_field.text = ""


func _on_decay_timeout() -> void:
	if _brain != null:
		_brain.set_confidence(0.05)


func _on_locate_pressed(file_path: String, line_number: int) -> void:
	if file_path == "" or line_number <= 0:
		_set_status("No file location in this error.", Color(0.85, 0.6, 0.3))
		return
	var res: Resource = load(file_path)
	if res == null or not (res is Script):
		_set_status("Could not load " + file_path, Color(0.85, 0.6, 0.3))
		return
	EditorInterface.edit_script(res, line_number - 1, 0, true)
	_set_status("Jumped to %s:%d" % [file_path, line_number], Color(0.4, 0.85, 0.45))


func _on_undo_pressed() -> void:
	var se: ScriptEditor = EditorInterface.get_script_editor()
	if se == null:
		_set_status("No script editor.", Color(0.85, 0.6, 0.3))
		return
	var base: ScriptEditorBase = se.get_current_editor()
	if base == null:
		_set_status("No open script.", Color(0.85, 0.6, 0.3))
		return
	var inner: Control = base.get_base_editor()
	if inner == null or not (inner is CodeEdit):
		_set_status("No editable script.", Color(0.85, 0.6, 0.3))
		return
	var ce: CodeEdit = inner
	ce.undo()
	_set_status("Undone.", Color(0.75, 0.8, 0.85))


func _on_copy_pressed(code: String) -> void:
	if code == "":
		return
	DisplayServer.clipboard_set(code)
	_set_status("Copied to clipboard.", Color(0.4, 0.85, 0.45))


func _on_insert_pressed(code: String) -> void:
	if code == "":
		return
	var ok: bool = _insert_at_cursor(code)
	if ok:
		_set_status("Inserted fix at cursor.", Color(0.4, 0.85, 0.45))
	else:
		_set_status("No active script editor. Copy instead.", Color(0.9, 0.6, 0.2))


func _insert_at_cursor(text: String) -> bool:
	var se: ScriptEditor = EditorInterface.get_script_editor()
	if se == null:
		return false
	var base: ScriptEditorBase = se.get_current_editor()
	if base == null:
		return false
	var inner: Control = base.get_base_editor()
	if inner == null or not (inner is CodeEdit):
		return false
	var ce: CodeEdit = inner
	ce.insert_text_at_caret(text)
	return true


static func extract_location(raw_line: String) -> Dictionary:
	if raw_line == "":
		return {}
	var re: RegEx = RegEx.new()
	var pattern: String = "(res://[^\\s\"']+?):(\\d+)"
	var err: int = re.compile(pattern)
	if err != OK:
		return {}
	var m: RegExMatch = re.search(raw_line)
	if m == null:
		return {}
	var path: String = m.get_string(1)
	var line_str: String = m.get_string(2)
	if path == "" or line_str == "":
		return {}
	return {"file": path, "line": int(line_str)}


static func is_advice_only(code: String) -> bool:
	if code.strip_edges() == "":
		return true
	var lines: Array = code.split("\n")
	var k: int = 0
	while k < lines.size():
		var s: String = str(lines[k]).strip_edges()
		if s != "" and not s.begins_with("#"):
			return false
		k += 1
	return true


func _add_error_card(record: Dictionary, raw_line: String) -> void:
	var id: String = str(record.get("id", ""))
	if id == "":
		return

	if _seen.has(id):
		var entry: Dictionary = _seen[id]
		entry["count"] = int(entry.get("count", 1)) + 1
		var lbl: Label = entry.get("count_label", null)
		if lbl != null and is_instance_valid(lbl):
			lbl.text = "x%d" % int(entry["count"])
			lbl.visible = true
		_bump_severity(record)
		return

	var card: Control = null
	var count_label: Label = null
	if _cards_container != null:
		card = _build_card(record, raw_line)
		_cards_container.add_child(card)
		count_label = card.get_node_or_null("CountLabel")

	_seen[id] = {"card": card, "count": 1, "count_label": count_label}
	_card_order.append(id)

	while _card_order.size() > MAX_CARDS:
		var old_id: String = str(_card_order.pop_front())
		if _seen.has(old_id):
			var old_entry: Dictionary = _seen[old_id]
			var old_card = old_entry.get("card", null)
			if old_card != null and is_instance_valid(old_card):
				old_card.queue_free()
			_seen.erase(old_id)

	_bump_severity(record)
	_set_status("Caught: %s" % str(record.get("title", id)), Color(0.9, 0.5, 0.5))


func _bump_severity(record: Dictionary) -> void:
	if _brain == null:
		return
	var cat: String = str(record.get("category", "misc"))
	_brain.set_confidence(_severity_for_category(cat))
	if _decay_timer != null:
		_decay_timer.start()


func _severity_for_category(cat: String) -> float:
	match cat:
		"null_safety", "type_error", "syntax":
			return 0.9
		"node", "signal", "input":
			return 0.65
		"physics", "animation":
			return 0.45
		"migration":
			return 0.35
	return 0.3


func _build_card(record: Dictionary, raw_line: String) -> Control:
	var id: String = str(record.get("id", ""))
	var title: String = str(record.get("title", id))
	var category: String = str(record.get("category", ""))
	var explains: String = str(record.get("explains", ""))
	var causes: Array = record.get("causes", [])
	var fix: Dictionary = record.get("fix", {})
	var code: String = str(fix.get("code", ""))
	var fix_desc: String = str(fix.get("description", ""))

	var panel: PanelContainer = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	panel.add_child(vbox)

	var header: HBoxContainer = HBoxContainer.new()
	header.add_theme_constant_override("separation", 16)

	var title_label: Label = Label.new()
	title_label.text = title
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_label.add_theme_font_size_override("font_size", FONT_CARD_TITLE)
	header.add_child(title_label)

	var count_label: Label = Label.new()
	count_label.name = "CountLabel"
	count_label.text = ""
	count_label.visible = false
	count_label.add_theme_font_size_override("font_size", FONT_CARD_TITLE)
	count_label.add_theme_color_override("font_color", Color(0.9, 0.6, 0.5))
	header.add_child(count_label)

	vbox.add_child(header)

	if category != "":
		var meta: Label = Label.new()
		meta.text = category.replace("_", " ")
		meta.add_theme_font_size_override("font_size", FONT_CARD_META)
		meta.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))
		vbox.add_child(meta)

	if explains != "":
		var expl: Label = Label.new()
		expl.text = explains
		expl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		expl.add_theme_font_size_override("font_size", FONT_DESC)
		expl.add_theme_color_override("font_color", Color(0.85, 0.87, 0.92))
		vbox.add_child(expl)

	if not causes.is_empty():
		var causes_header: Label = Label.new()
		causes_header.text = "Common causes:"
		causes_header.add_theme_font_size_override("font_size", FONT_CARD_META)
		causes_header.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))
		vbox.add_child(causes_header)

		var ci: int = 0
		while ci < causes.size():
			var cause: Label = Label.new()
			cause.text = "  - " + str(causes[ci])
			cause.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			cause.add_theme_font_size_override("font_size", FONT_DESC)
			cause.add_theme_color_override("font_color", Color(0.75, 0.78, 0.82))
			vbox.add_child(cause)
			ci += 1

	var advice_only: bool = is_advice_only(code)

	if code != "":
		var code_panel: PanelContainer = PanelContainer.new()
		var code_style: StyleBoxFlat = StyleBoxFlat.new()
		code_style.bg_color = Color(0.10, 0.11, 0.13, 1.0)
		code_style.content_margin_left = 16.0
		code_style.content_margin_right = 16.0
		code_style.content_margin_top = 12.0
		code_style.content_margin_bottom = 12.0
		code_style.corner_radius_top_left = 6
		code_style.corner_radius_top_right = 6
		code_style.corner_radius_bottom_left = 6
		code_style.corner_radius_bottom_right = 6
		code_panel.add_theme_stylebox_override("panel", code_style)

		var code_scroll: ScrollContainer = ScrollContainer.new()
		code_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		code_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
		code_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		code_panel.add_child(code_scroll)

		var code_label: Label = Label.new()
		code_label.text = code
		code_label.autowrap_mode = TextServer.AUTOWRAP_OFF
		code_label.add_theme_font_size_override("font_size", FONT_CODE)
		if advice_only:
			code_label.add_theme_color_override("font_color", Color(0.7, 0.75, 0.8))
		else:
			code_label.add_theme_color_override("font_color", Color(0.85, 0.88, 0.92))
		code_scroll.add_child(code_label)

		vbox.add_child(code_panel)

	if advice_only:
		var advice_note: Label = Label.new()
		advice_note.text = "This fix is guidance, not code. Read the checklist and apply the change to your script manually."
		advice_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		advice_note.add_theme_font_size_override("font_size", FONT_CARD_META)
		advice_note.add_theme_color_override("font_color", Color(0.85, 0.75, 0.5))
		vbox.add_child(advice_note)

	if fix_desc != "":
		var fd: Label = Label.new()
		fd.text = fix_desc
		fd.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		fd.add_theme_font_size_override("font_size", FONT_DESC)
		fd.add_theme_color_override("font_color", Color(0.72, 0.75, 0.8))
		vbox.add_child(fd)

	var actions: HBoxContainer = HBoxContainer.new()
	actions.add_theme_constant_override("separation", 12)

	var loc: Dictionary = extract_location(raw_line)
	if not loc.is_empty():
		var locate_btn: Button = Button.new()
		locate_btn.text = "Locate"
		locate_btn.add_theme_font_size_override("font_size", FONT_BUTTON)
		locate_btn.custom_minimum_size = Vector2(130, ROW_HEIGHT)
		var loc_file: String = str(loc["file"])
		var loc_line: int = int(loc["line"])
		locate_btn.pressed.connect(_on_locate_pressed.bind(loc_file, loc_line))
		actions.add_child(locate_btn)

	if code != "":
		var copy_btn: Button = Button.new()
		copy_btn.text = "Copy"
		copy_btn.add_theme_font_size_override("font_size", FONT_BUTTON)
		copy_btn.custom_minimum_size = Vector2(130, ROW_HEIGHT)
		copy_btn.pressed.connect(_on_copy_pressed.bind(code))
		actions.add_child(copy_btn)

	if code != "" and not advice_only:
		var insert_btn: Button = Button.new()
		insert_btn.text = "Insert"
		insert_btn.add_theme_font_size_override("font_size", FONT_BUTTON)
		insert_btn.custom_minimum_size = Vector2(130, ROW_HEIGHT)
		insert_btn.pressed.connect(_on_insert_pressed.bind(code))
		actions.add_child(insert_btn)

	if not advice_only:
		var undo_btn: Button = Button.new()
		undo_btn.text = "Undo"
		undo_btn.add_theme_font_size_override("font_size", FONT_BUTTON)
		undo_btn.custom_minimum_size = Vector2(130, ROW_HEIGHT)
		undo_btn.pressed.connect(_on_undo_pressed)
		actions.add_child(undo_btn)

	vbox.add_child(actions)

	if raw_line != "":
		var raw: Label = Label.new()
		raw.text = raw_line
		raw.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		raw.add_theme_font_size_override("font_size", FONT_SOURCE)
		raw.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55))
		vbox.add_child(raw)

	return panel


func _refresh_watcher_status() -> void:
	if _watcher_status_label == null:
		return
	if _watcher == null:
		_watcher_status_label.text = "No watcher attached."
		if _paste_row != null:
			_paste_row.visible = true
		return
	if _watcher.is_running() and _watcher.is_available():
		_watcher_status_label.text = "Auto-detecting errors from the Output panel. Click Rescan to re-check."
		if _paste_row != null:
			_paste_row.visible = false
	else:
		_watcher_status_label.text = "Manual mode - paste errors below."
		if _paste_row != null:
			_paste_row.visible = true


func _set_status(text: String, color: Color) -> void:
	if _status_label == null:
		return
	_status_label.text = text
	_status_label.add_theme_color_override("font_color", color)


func _clear_container(container: Node) -> void:
	if container == null:
		return
	var children: Array = container.get_children()
	var k: int = 0
	while k < children.size():
		var child: Node = children[k]
		child.queue_free()
		k += 1


# =========================================================================
# Self-test
# =========================================================================

static func self_test() -> void:
	print("=== ErrorPanel self-test ===")
	var failures: Array[String] = []

	var lib: ErrorLibrary = ErrorLibrary.new()
	lib.load_all()

	var watcher: OutputWatcher = OutputWatcher.new()
	watcher.set_library(lib)

	var panel: ErrorPanel = ErrorPanel.new()
	if panel.has_dependencies():
		failures.append("1: fresh panel should have no library")

	panel.set_library(lib)
	panel.set_watcher(watcher)
	if not panel.has_dependencies():
		failures.append("2: has_dependencies should be true after injection")

	var hit: Dictionary = panel.feed_line("ERROR: Division by zero in operator '/'.")
	if hit.is_empty():
		failures.append("3: matching line should return a record")
	elif str(hit.get("id", "")) != "division_by_zero":
		failures.append("3: expected division_by_zero, got " + str(hit.get("id", "?")))
	if panel.card_count() != 1:
		failures.append("3: card_count should be 1, got %d" % panel.card_count())

	var miss: Dictionary = panel.feed_line("Just a normal log line")
	if not miss.is_empty():
		failures.append("4: non-matching line should return {}")
	if panel.card_count() != 1:
		failures.append("4: card_count should still be 1, got %d" % panel.card_count())

	panel.feed_line("ERROR: Division by zero in operator '/'.")
	panel.feed_line("ERROR: Division by zero in operator '/'.")
	if panel.card_count() != 1:
		failures.append("5: repeat error should not create new card, got %d" % panel.card_count())

	panel.feed_line("ERROR: Node not found: \"Player\".")
	if panel.card_count() != 2:
		failures.append("6: second distinct error should create a card, got %d" % panel.card_count())

	watcher.error_removed.emit("division_by_zero")
	if panel.card_count() != 1:
		failures.append("7: error_removed should drop the card, got %d" % panel.card_count())

	watcher.error_removed.emit("no_such_fix_id")
	if panel.card_count() != 1:
		failures.append("8: unknown id removal should be a no-op, got %d" % panel.card_count())

	watcher.error_removed.emit("node_not_found")
	if panel.card_count() != 0:
		failures.append("9: removing all cards should leave 0, got %d" % panel.card_count())

	panel.feed_line("ERROR: Division by zero in operator '/'.")
	panel.clear_all()
	if panel.card_count() != 0:
		failures.append("10: clear_all should empty card_count")

	panel.feed_line("ERROR: Division by zero in operator '/'.")
	if panel.card_count() != 1:
		failures.append("11: feed after clear should create a card")

	var loc16: Dictionary = ErrorPanel.extract_location("ERROR: res://player.gd:42 - Invalid call.")
	if loc16.is_empty():
		failures.append("16: extract_location should parse standard line")
	else:
		if str(loc16.get("file", "")) != "res://player.gd":
			failures.append("16: file should be res://player.gd, got " + str(loc16.get("file", "")))
		if int(loc16.get("line", 0)) != 42:
			failures.append("16: line should be 42, got %d" % int(loc16.get("line", 0)))

	var loc17: Dictionary = ErrorPanel.extract_location("ERROR: res://test.gd:5:10 - Parse Error")
	if loc17.is_empty():
		failures.append("17: extract_location should parse column format")
	elif int(loc17.get("line", 0)) != 5:
		failures.append("17: line should be 5, got %d" % int(loc17.get("line", 0)))

	var loc18: Dictionary = ErrorPanel.extract_location("ERROR: res://test.gd:5 - Parse Error: Expected expression as the function argument.")
	if loc18.is_empty():
		failures.append("18: extract_location should parse parse-error format")
	elif str(loc18.get("file", "")) != "res://test.gd" or int(loc18.get("line", 0)) != 5:
		failures.append("18: parse-error location wrong: " + str(loc18))

	var loc19: Dictionary = ErrorPanel.extract_location("ERROR: Division by zero in operator '/'.")
	if not loc19.is_empty():
		failures.append("19: extract_location should return empty for locationless error")

	var loc20: Dictionary = ErrorPanel.extract_location("  ERROR: res://foo.gd:99 - X")
	if loc20.is_empty():
		failures.append("20: extract_location should handle leading whitespace")
	elif int(loc20.get("line", 0)) != 99:
		failures.append("20: line should be 99, got %d" % int(loc20.get("line", 0)))

	if not ErrorPanel.is_advice_only("# fix this\n# check that\n"):
		failures.append("21: pure comments should be advice-only")

	if ErrorPanel.is_advice_only("var x: int = 5\n"):
		failures.append("22: real code should not be advice-only")

	if ErrorPanel.is_advice_only("# do thing\npass\n"):
		failures.append("23: mixed comment+code should not be advice-only")

	if not ErrorPanel.is_advice_only(""):
		failures.append("24: empty string should be advice-only")

	if not ErrorPanel.is_advice_only("\n\n   \n"):
		failures.append("25: blank lines should be advice-only")

	if not ErrorPanel.is_advice_only("\t# indented comment\n"):
		failures.append("26: indented comment should be advice-only")

	var parse_rec: Dictionary = lib.get_record("parse_error_expected_expression")
	if not parse_rec.is_empty():
		var pf: Dictionary = parse_rec.get("fix", {})
		var pcode: String = str(pf.get("code", ""))
		if not ErrorPanel.is_advice_only(pcode):
			failures.append("27: parse error fix should be advice-only")

	var null_rec: Dictionary = lib.get_record("null_instance_call")
	if not null_rec.is_empty():
		var nf: Dictionary = null_rec.get("fix", {})
		var ncode: String = str(nf.get("code", ""))
		if ErrorPanel.is_advice_only(ncode):
			failures.append("28: null_instance_call fix should NOT be advice-only")

	var panel2: ErrorPanel = ErrorPanel.new()
	panel2.on_show()
	panel2.rescan_all()

	watcher.free()
	panel.free()
	panel2.free()

	print("")
	if failures.is_empty():
		print("OK - all assertions passed")
	else:
		print("FAILED - %d issues:" % failures.size())
		var fi: int = 0
		while fi < failures.size():
			print("  " + failures[fi])
			fi += 1
