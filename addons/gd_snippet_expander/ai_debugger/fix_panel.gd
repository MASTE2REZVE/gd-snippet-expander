# res://addons/gd_snippet_expander/ai_debugger/fix_panel.gd
@tool
class_name FixPanel
extends VBoxContainer

## The "Fix" tab for the mini AI debugger.

const MAX_RESULTS_SHOWN := 5
const MIN_RESULT_CONFIDENCE := 0.15

const FONT_QUERY := 40
const FONT_BUTTON := 32
const FONT_STATUS := 32
const FONT_SOURCE := 26
const FONT_CARD_TITLE := 36
const FONT_CARD_META := 26
const FONT_CODE := 30
const FONT_DESC := 30
const FONT_ALT := 28
const FONT_HINT := 28

const ROW_HEIGHT := 72

var _library: FixLibrary = null
var _matcher: RuleMatcher = null
var _questions: QuestionSelector = null
var _store: LearningStore = null
var _tokenizer: EnglishTokenizer = null

var _scroll: ScrollContainer = null
var _inner: VBoxContainer = null
var _query_input: LineEdit = null
var _refresh_button: Button = null
var _status_label: Label = null
var _source_label: Label = null
var _brain: BrainUI = null
var _results_container: VBoxContainer = null
var _question_container: VBoxContainer = null

var _current_results: Array = []
var _current_question: Dictionary = {}
var _last_source: String = ""


func set_library(lib: FixLibrary) -> void:
	_library = lib

func set_matcher(rm: RuleMatcher) -> void:
	_matcher = rm

func set_question_selector(qs: QuestionSelector) -> void:
	_questions = qs

func set_learning_store(ls: LearningStore) -> void:
	_store = ls

func set_tokenizer(tk: EnglishTokenizer) -> void:
	_tokenizer = tk

func has_dependencies() -> bool:
	return _library != null and _matcher != null


func _ready() -> void:
	add_theme_constant_override("separation", 20)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	_build_ui()


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

	var query_row: HBoxContainer = HBoxContainer.new()
	query_row.add_theme_constant_override("separation", 12)

	_query_input = LineEdit.new()
	_query_input.placeholder_text = "Describe the problem, e.g. \"player cant jump\""
	_query_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_query_input.add_theme_font_size_override("font_size", FONT_QUERY)
	_query_input.custom_minimum_size = Vector2(0, ROW_HEIGHT)
	_query_input.text_submitted.connect(_on_query_submitted)
	query_row.add_child(_query_input)

	_refresh_button = Button.new()
	_refresh_button.text = "Search"
	_refresh_button.add_theme_font_size_override("font_size", FONT_BUTTON)
	_refresh_button.custom_minimum_size = Vector2(180, ROW_HEIGHT)
	_refresh_button.pressed.connect(_on_refresh_pressed)
	query_row.add_child(_refresh_button)

	_inner.add_child(query_row)

	var status_row: HBoxContainer = HBoxContainer.new()
	status_row.add_theme_constant_override("separation", 20)

	_brain = BrainUI.new()
	_brain.custom_minimum_size = Vector2(96, 96)
	status_row.add_child(_brain)

	var status_col: VBoxContainer = VBoxContainer.new()
	status_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status_col.add_theme_constant_override("separation", 8)

	_status_label = Label.new()
	_status_label.text = "Ready."
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.add_theme_font_size_override("font_size", FONT_STATUS)
	status_col.add_child(_status_label)

	_source_label = Label.new()
	_source_label.text = ""
	_source_label.add_theme_font_size_override("font_size", FONT_SOURCE)
	_source_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))
	_source_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_col.add_child(_source_label)

	status_row.add_child(status_col)
	_inner.add_child(status_row)

	_question_container = VBoxContainer.new()
	_question_container.add_theme_constant_override("separation", 12)
	_question_container.visible = false
	_inner.add_child(_question_container)

	_results_container = VBoxContainer.new()
	_results_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_results_container.add_theme_constant_override("separation", 20)
	_inner.add_child(_results_container)


func refresh() -> void:
	if not has_dependencies():
		_set_status("Plugin not fully loaded yet.", Color(0.9, 0.6, 0.2))
		return
	var src: String = _get_current_source()
	if src == "":
		_show_no_source()
		return

	var query: String = ""
	if _query_input != null:
		query = _query_input.text

	if query.strip_edges() == "":
		_show_query_hint(src)
		return

	refresh_from_source(src, query)


func refresh_from_source(source: String, query: String) -> void:
	if not has_dependencies():
		return
	if source == "":
		_show_no_source()
		return
	if query.strip_edges() == "":
		_show_query_hint(source)
		return

	_last_source = source
	var results: Array = _matcher.match(source, {}, query, MAX_RESULTS_SHOWN, MIN_RESULT_CONFIDENCE)

	if _store != null and not results.is_empty():
		var query_tokens: Array = []
		if _tokenizer != null:
			query_tokens = _tokenizer.tokenize(query)
		results = _store.apply_boosts(results, query_tokens)

	_current_results = results

	_current_question = {}
	if _questions != null and not results.is_empty() and _questions.should_ask(results):
		_current_question = _questions.pick_question(results)

	_set_source_line_count(source)

	var top_conf: float = 0.0
	if not results.is_empty():
		var first: Dictionary = results[0]
		top_conf = float(first.get("confidence", 0.0))
	if _brain != null:
		_brain.push_confidence(top_conf)

	_render_question()
	_render_results()


func clear_results() -> void:
	_current_results = []
	_current_question = {}
	_clear_container(_results_container)
	_clear_container(_question_container)
	_set_question_visible(false)
	_reset_brain()
	_set_status("Cleared.", Color(0.7, 0.7, 0.75))


func _show_no_source() -> void:
	_last_source = ""
	_current_results = []
	_current_question = {}
	_set_status("Open a .gd script to get suggestions.", Color(0.7, 0.7, 0.75))
	_set_source_label("")
	_clear_container(_results_container)
	_clear_container(_question_container)
	_set_question_visible(false)
	_reset_brain()
	if _results_container == null:
		return
	var hint: Label = Label.new()
	hint.text = "Open a GDScript file in the Script Editor.\nThen describe the problem in the box at the top."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size", FONT_HINT)
	hint.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75))
	_results_container.add_child(hint)


func _show_query_hint(source: String) -> void:
	_last_source = source
	_current_results = []
	_current_question = {}
	_clear_container(_results_container)
	_clear_container(_question_container)
	_set_question_visible(false)
	_reset_brain()
	_set_source_line_count(source)
	_set_status("Type what's wrong above, then press Enter.", Color(0.75, 0.85, 0.95))
	if _results_container == null:
		return
	var hint: Label = Label.new()
	hint.text = "Describe the problem in the box above.\n\nFor example:\n  - player cant jump\n  - signal not firing\n  - collision not working\n  - health bar not updating"
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size", FONT_HINT)
	hint.add_theme_color_override("font_color", Color(0.7, 0.75, 0.8))
	_results_container.add_child(hint)


func _set_source_line_count(source: String) -> void:
	var src_lines: int = source.split("\n").size()
	_set_source_label("Source: %d lines" % src_lines)


func _get_current_source() -> String:
	var se: ScriptEditor = EditorInterface.get_script_editor()
	if se == null:
		return ""
	var script: Script = se.get_current_script()
	if script == null:
		return ""
	return script.source_code


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


func _copy_to_clipboard(text: String) -> void:
	DisplayServer.clipboard_set(text)


func _on_refresh_pressed() -> void:
	refresh()


func _on_query_submitted(_text: String) -> void:
	refresh()


func _on_insert_pressed(fix_id: String, code: String) -> void:
	if code == "":
		return
	var ok: bool = _insert_at_cursor(code)
	if ok:
		_record_apply(fix_id)
		_set_status("Inserted. Thanks - this helps future suggestions.", Color(0.4, 0.85, 0.45))
	else:
		_set_status("Couldn't insert - is a .gd script open in the editor?", Color(0.9, 0.6, 0.2))


func _on_copy_pressed(fix_id: String, code: String) -> void:
	if code == "":
		return
	_copy_to_clipboard(code)
	_record_apply(fix_id)
	_set_status("Copied to clipboard.", Color(0.4, 0.85, 0.45))


func _on_decline_pressed(fix_id: String) -> void:
	if _store != null:
		_store.record_decline(fix_id)
	_set_status("Noted - that suggestion will rank lower next time.", Color(0.7, 0.7, 0.75))


func _on_answer_pressed(answer_index: int) -> void:
	if _current_question.is_empty() or _current_results.is_empty():
		return
	if _questions == null:
		return
	var reranked: Array = _questions.apply_answer(_current_question, answer_index, _current_results)
	_current_results = reranked
	_current_question = {}
	_render_question()
	_render_results()


func _on_alternative_pressed(fix_index: int, alt_index: int) -> void:
	if fix_index < 0 or fix_index >= _current_results.size():
		return
	var result: Dictionary = _current_results[fix_index]
	var alts: Array = result.get("alternatives", [])
	if alt_index < 0 or alt_index >= alts.size():
		return
	var old_primary: Dictionary = result.get("primary", {})
	var chosen: Dictionary = alts[alt_index]
	var new_alts: Array = []
	var i: int = 0
	while i < alts.size():
		if i != alt_index:
			new_alts.append(alts[i])
		i += 1
	if not old_primary.is_empty():
		new_alts.append(old_primary)
	result["primary"] = chosen
	result["alternatives"] = new_alts
	_current_results[fix_index] = result
	_render_results()


func _record_apply(fix_id: String) -> void:
	if _store == null or fix_id == "":
		return
	var query_tokens: Array = []
	if _tokenizer != null and _query_input != null:
		var q: String = _query_input.text
		if q.strip_edges() != "":
			query_tokens = _tokenizer.tokenize(q)
	_store.record_apply(fix_id, query_tokens)


func _render_question() -> void:
	_clear_container(_question_container)
	if _question_container == null:
		return
	if _current_question.is_empty():
		_question_container.visible = false
		return
	_question_container.visible = true

	var header: Label = Label.new()
	header.text = str(_current_question.get("text", "Which one?"))
	header.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	header.add_theme_font_size_override("font_size", FONT_STATUS)
	header.add_theme_color_override("font_color", Color(0.95, 0.85, 0.5))
	_question_container.add_child(header)

	var answers: Array = _current_question.get("answers", [])
	var i: int = 0
	while i < answers.size():
		var a: Variant = answers[i]
		if a is Dictionary:
			var ad: Dictionary = a
			var btn: Button = Button.new()
			btn.text = str(ad.get("text", "Answer %d" % i))
			btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
			btn.add_theme_font_size_override("font_size", FONT_BUTTON)
			btn.custom_minimum_size = Vector2(0, ROW_HEIGHT)
			btn.pressed.connect(_on_answer_pressed.bind(i))
			_question_container.add_child(btn)
		i += 1


func _render_results() -> void:
	_clear_container(_results_container)
	if _results_container == null:
		return

	if _current_results.is_empty():
		var empty: Label = Label.new()
		empty.text = "No suggestions matched.\nTry rephrasing, or check for typos in the query."
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty.add_theme_font_size_override("font_size", FONT_HINT)
		empty.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75))
		_results_container.add_child(empty)
		_set_status("No matching fixes for that query.", Color(0.85, 0.6, 0.3))
		return

	_set_status("%d suggestion(s)." % _current_results.size(), Color(0.75, 0.75, 0.8))

	var i: int = 0
	while i < _current_results.size():
		var card: Control = _build_result_card(i)
		_results_container.add_child(card)
		i += 1


func _build_result_card(fix_index: int) -> Control:
	var result: Dictionary = _current_results[fix_index]
	var fix_id: String = str(result.get("fix_id", ""))
	var title: String = str(result.get("title", ""))
	var category: String = str(result.get("category", ""))
	var confidence: float = float(result.get("confidence", 0.0))
	var why: String = str(result.get("why", ""))
	var primary: Dictionary = result.get("primary", {})
	var code: String = str(primary.get("code", ""))
	var description: String = str(primary.get("description", ""))

	var panel: PanelContainer = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	panel.add_child(vbox)

	var header: HBoxContainer = HBoxContainer.new()
	header.add_theme_constant_override("separation", 16)

	var title_label: Label = Label.new()
	title_label.text = title if title != "" else fix_id
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_label.add_theme_font_size_override("font_size", FONT_CARD_TITLE)
	header.add_child(title_label)

	var conf_color: Color = BrainUI.color_for(confidence)
	var conf_label: Label = Label.new()
	conf_label.text = "%d%%" % int(round(confidence * 100.0))
	conf_label.add_theme_color_override("font_color", conf_color)
	conf_label.add_theme_font_size_override("font_size", FONT_CARD_TITLE)
	header.add_child(conf_label)

	vbox.add_child(header)

	var meta_parts: Array[String] = []
	if category != "":
		meta_parts.append(category)
	if why != "":
		meta_parts.append(why)
	if not meta_parts.is_empty():
		var meta: Label = Label.new()
		meta.text = " - ".join(meta_parts)
		meta.add_theme_font_size_override("font_size", FONT_CARD_META)
		meta.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))
		vbox.add_child(meta)

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
		code_label.add_theme_color_override("font_color", Color(0.85, 0.88, 0.92))
		code_scroll.add_child(code_label)

		vbox.add_child(code_panel)

	if description != "":
		var desc: Label = Label.new()
		desc.text = description
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc.add_theme_font_size_override("font_size", FONT_DESC)
		desc.add_theme_color_override("font_color", Color(0.75, 0.78, 0.82))
		vbox.add_child(desc)

	var actions: HBoxContainer = HBoxContainer.new()
	actions.add_theme_constant_override("separation", 12)

	var insert_btn: Button = Button.new()
	insert_btn.text = "Insert"
	insert_btn.add_theme_font_size_override("font_size", FONT_BUTTON)
	insert_btn.custom_minimum_size = Vector2(140, ROW_HEIGHT)
	insert_btn.pressed.connect(_on_insert_pressed.bind(fix_id, code))
	actions.add_child(insert_btn)

	var copy_btn: Button = Button.new()
	copy_btn.text = "Copy"
	copy_btn.add_theme_font_size_override("font_size", FONT_BUTTON)
	copy_btn.custom_minimum_size = Vector2(140, ROW_HEIGHT)
	copy_btn.pressed.connect(_on_copy_pressed.bind(fix_id, code))
	actions.add_child(copy_btn)

	if fix_index == 0:
		var decline_btn: Button = Button.new()
		decline_btn.text = "Not this"
		decline_btn.add_theme_font_size_override("font_size", FONT_BUTTON)
		decline_btn.custom_minimum_size = Vector2(160, ROW_HEIGHT)
		decline_btn.pressed.connect(_on_decline_pressed.bind(fix_id))
		actions.add_child(decline_btn)

	vbox.add_child(actions)

	var alts: Array = result.get("alternatives", [])
	if not alts.is_empty():
		var alt_label: Label = Label.new()
		alt_label.text = "Alternative fixes:"
		alt_label.add_theme_font_size_override("font_size", FONT_CARD_META)
		alt_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))
		vbox.add_child(alt_label)

		var ai: int = 0
		while ai < alts.size():
			var alt: Variant = alts[ai]
			if alt is Dictionary:
				var alt_dict: Dictionary = alt
				var alt_btn: Button = Button.new()
				var alt_desc: String = str(alt_dict.get("description", "Alternative"))
				if alt_desc.length() > 60:
					alt_desc = alt_desc.substr(0, 57) + "..."
				alt_btn.text = "- " + alt_desc
				alt_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
				alt_btn.add_theme_font_size_override("font_size", FONT_ALT)
				alt_btn.custom_minimum_size = Vector2(0, ROW_HEIGHT - 8)
				alt_btn.pressed.connect(_on_alternative_pressed.bind(fix_index, ai))
				vbox.add_child(alt_btn)
			ai += 1

	return panel


func _clear_container(container: Node) -> void:
	if container == null:
		return
	var children: Array = container.get_children()
	var i: int = 0
	while i < children.size():
		var child: Node = children[i]
		child.queue_free()
		i += 1


func _set_status(text: String, color: Color) -> void:
	if _status_label == null:
		return
	_status_label.text = text
	_status_label.add_theme_color_override("font_color", color)


func _set_source_label(text: String) -> void:
	if _source_label == null:
		return
	_source_label.text = text


func _set_question_visible(v: bool) -> void:
	if _question_container == null:
		return
	_question_container.visible = v


func _reset_brain() -> void:
	if _brain == null:
		return
	_brain.reset()
	# --- self-test ----------------------------------------------------------

static func self_test() -> void:
	print("=== FixPanel self-test ===")
	var failures: Array[String] = []

	var lib: FixLibrary = FixLibrary.new()
	lib.load_all()
	FixLibraryDataA.register_into(lib)
	FixLibraryDataB.register_into(lib)
	FixLibraryDataC.register_into(lib)
	FixLibraryDataD.register_into(lib)
	FixLibraryDataE.register_into(lib)

	var tk: EnglishTokenizer = EnglishTokenizer.new()
	var rm: RuleMatcher = RuleMatcher.new()
	rm.set_library(lib)
	rm.set_tokenizer(tk)

	var qs: QuestionSelector = QuestionSelector.new()
	qs.set_library(lib)

	var ls: LearningStore = LearningStore.new()
	ls.loaded = true
	ls.store_path = "user://gdse_fixpanel_selftest_%d.json" % Time.get_ticks_msec()

	var fp: FixPanel = FixPanel.new()
	if fp.has_dependencies():
		failures.append("1: dependencies should be unset on a fresh panel")

	fp.set_library(lib)
	fp.set_matcher(rm)
	fp.set_question_selector(qs)
	fp.set_learning_store(ls)
	fp.set_tokenizer(tk)

	if not fp.has_dependencies():
		failures.append("2: has_dependencies should be true after injection")

	var src: String = "extends CharacterBody2D\n\nfunc _physics_process(delta):\n\tvelocity.x = 100\n\tmove_and_slide()\n"
	fp._last_source = ""
	fp.refresh_from_source(src, "")
	if not fp._current_results.is_empty():
		failures.append("3: no query should produce zero results")
	if fp._last_source != src:
		failures.append("3: hint mode should still store the source")

	fp.refresh_from_source(src, "player cant jump")
	if fp._current_results.is_empty():
		failures.append("4: query should produce results")
	else:
		var first: Dictionary = fp._current_results[0]
		var fid: String = str(first.get("fix_id", ""))
		if fid == "":
			failures.append("4: top result missing fix_id")

	fp.refresh_from_source("", "anything")
	if not fp._current_results.is_empty():
		failures.append("5: empty source should produce zero results")

	fp.refresh_from_source(src, "signal not firing")
	var results: Array = []
	var rec_a: Dictionary = {
		"id": "test_q_a",
		"title": "A",
		"category": "null_safety",
		"phrases": ["x"],
		"candidates": [{"code": "pass\n", "description": "a", "confidence": 0.5}],
		"questions": [{
			"text": "Which is it?",
			"answers": [
				{"text": "Option A", "boosts": ["test_q_a"]},
				{"text": "Option B", "boosts": ["test_q_b"]},
			],
		}],
	}
	var r_a: Dictionary = {
		"fix_id": "test_q_a", "confidence": 0.32, "record": rec_a,
		"title": "A", "category": "null_safety", "why": "",
		"primary": {}, "alternatives": [],
	}
	var r_b: Dictionary = {
		"fix_id": "test_q_b", "confidence": 0.30, "record": {},
		"title": "B", "category": "null_safety", "why": "",
		"primary": {}, "alternatives": [],
	}
	results.append(r_a)
	results.append(r_b)
	fp._current_results = results
	fp._current_question = qs.pick_question(results)
	if fp._current_question.is_empty():
		failures.append("6: question should be picked for tied candidates")
	fp._on_answer_pressed(1)
	if not fp._current_question.is_empty():
		failures.append("7: after answering, question should be cleared")
	if fp._current_results.is_empty():
		failures.append("7: after answering, results should remain")
	else:
		var top_after: Dictionary = fp._current_results[0]
		var top_id: String = str(top_after.get("fix_id", ""))
		if top_id != "test_q_b":
			failures.append("7: after answer 1, test_q_b should be top, got " + top_id)

	var ls2: LearningStore = LearningStore.new()
	ls2.loaded = true
	ls2.store_path = "user://gdse_fixpanel_test_%d.json" % Time.get_ticks_msec()
	fp.set_learning_store(ls2)
	fp._query_input = LineEdit.new()
	fp._query_input.text = "player cant jump"
	fp._on_copy_pressed("test_fix_x", "pass\n")
	var stats: Dictionary = ls2.get_fix_stats("test_fix_x")
	if int(stats.get("applied", 0)) != 1:
		failures.append("8: copy should record an apply")
	if FileAccess.file_exists(ls2.store_path):
		DirAccess.remove_absolute(ls2.store_path)

	var ls3: LearningStore = LearningStore.new()
	ls3.loaded = true
	ls3.store_path = "user://gdse_fixpanel_test_%d.json" % Time.get_ticks_msec()
	fp.set_learning_store(ls3)
	fp._on_decline_pressed("test_fix_y")
	var stats_y: Dictionary = ls3.get_fix_stats("test_fix_y")
	if int(stats_y.get("declined", 0)) != 1:
		failures.append("9: decline should record on the store")
	if FileAccess.file_exists(ls3.store_path):
		DirAccess.remove_absolute(ls3.store_path)

	fp.clear_results()
	if not fp._current_results.is_empty():
		failures.append("10: clear_results should empty results")
	if not fp._current_question.is_empty():
		failures.append("10: clear_results should clear question")

	if FileAccess.file_exists(ls.store_path):
		DirAccess.remove_absolute(ls.store_path)

	print("")
	if failures.is_empty():
		print("OK - all assertions passed")
	else:
		print("FAILED - %d issues:" % failures.size())
		var i: int = 0
		while i < failures.size():
			print("  " + failures[i])
			i += 1
