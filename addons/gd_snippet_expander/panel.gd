@tool
extends VBoxContainer

const GDASELibraryScript := preload("res://addons/gd_snippet_expander/library.gd")
const BlueprintBuilderScript := preload("res://addons/gd_snippet_expander/blueprint_builder.gd")
const MapBrowserScript := preload("res://addons/gd_snippet_expander/map_browser.gd")
const InspectorScript := preload("res://addons/gd_snippet_expander/inspector.gd")
const SceneCheckerScript := preload("res://addons/gd_snippet_expander/scene_checker.gd")
const StarterTemplatesScript := preload("res://addons/gd_snippet_expander/starter_templates.gd")
const WizardScript := preload("res://addons/gd_snippet_expander/wizard.gd")
const DebugOverlayScript := preload("res://addons/gd_snippet_expander/debug_overlay.gd")

const STATUS_COLOR_OK := Color(0.72, 0.85, 0.72)
const STATUS_COLOR_WARN := Color(1.0, 0.85, 0.4)
const STATUS_COLOR_ERR := Color(1.0, 0.6, 0.55)

var _editor_interface: EditorInterface = null
var _library: GDASELibrary = null
var _blueprint_builder: Node = null
var _map_browser: Node = null
var _inspector: Node = null
var _scene_checker: Node = null
var _starter_templates: Node = null
var _wizard: Node = null
var _debug_overlay: Node = null

var _current_match: Dictionary = {}
var _current_results: Array = []
var _suppress_text_changed: bool = false

@onready var _phrase_input: LineEdit = %PhraseInput
@onready var _insert_button: Button = %InsertButton
@onready var _copy_button: Button = %CopyButton
@onready var _mode_code_only: Button = %ModeCodeOnly
@onready var _mode_code_details: Button = %ModeCodeDetails
@onready var _mode_full_details: Button = %ModeFullDetails
@onready var _main_tabs: TabContainer = %MainTabs
@onready var _results_list: ItemList = %ResultsList
@onready var _warning_label: Label = %WarningLabel
@onready var _preview_tabs: TabContainer = %PreviewTabs
@onready var _preview_code: CodeEdit = %Code
@onready var _preview_details: TextEdit = %Details
@onready var _preview_params: TextEdit = %Params
@onready var _chips_row: HBoxContainer = %ChipsRow
@onready var _related_chips: HBoxContainer = %RelatedChips
@onready var _status: Label = %StatusLabel
@onready var _browse_tree: Tree = %BrowseTree
@onready var _learn_node_label: Label = %LearnNodeLabel
@onready var _learn_refresh_button: Button = %LearnRefreshButton
@onready var _learn_text: TextEdit = %LearnText
@onready var _templates_list: VBoxContainer = %TemplatesList
@onready var _checker_button: Button = %CheckerButton
@onready var _checker_output: TextEdit = %CheckerOutput
@onready var _overlay_install_button: Button = %OverlayInstallButton
@onready var _overlay_remove_button: Button = %OverlayRemoveButton


# =========================================================================
# Lifecycle
# =========================================================================

func _ready() -> void:
	_ensure_library()
	_ensure_helpers()

	_insert_button.pressed.connect(_on_insert_pressed)
	_copy_button.pressed.connect(_on_copy_pressed)
	_phrase_input.text_changed.connect(_on_text_changed)
	_phrase_input.text_submitted.connect(_on_text_submitted)
	_mode_code_only.pressed.connect(_on_mode_code_only_pressed)
	_mode_code_details.pressed.connect(_on_mode_code_details_pressed)
	_mode_full_details.pressed.connect(_on_mode_full_details_pressed)
	_results_list.item_selected.connect(_on_result_selected)
	_learn_refresh_button.pressed.connect(_on_learn_refresh_pressed)
	_checker_button.pressed.connect(_on_checker_pressed)
	_overlay_install_button.pressed.connect(_on_overlay_install_pressed)
	_overlay_remove_button.pressed.connect(_on_overlay_remove_pressed)

	if _map_browser != null and _map_browser.has_signal("item_selected"):
		_map_browser.item_selected.connect(_on_browse_item_selected)

	_apply_saved_mode()
	_clear_match()
	_rebuild_browse_tree()
	_rebuild_templates_list()
	_set_status("Ready. Type a phrase and press Enter.")


func set_editor_interface(ei: EditorInterface) -> void:
	_editor_interface = ei
	if _wizard != null and ei != null:
		_maybe_show_wizard()


# =========================================================================
# Helper instances
# =========================================================================

func _ensure_library() -> GDASELibrary:
	if _library == null:
		_library = GDASELibraryScript.new()
		_library.load_all()
	return _library


func _ensure_helpers() -> void:
	if _blueprint_builder == null:
		_blueprint_builder = BlueprintBuilderScript.new()
	if _map_browser == null:
		_map_browser = MapBrowserScript.new()
	if _inspector == null:
		_inspector = InspectorScript.new()
	if _scene_checker == null:
		_scene_checker = SceneCheckerScript.new()
	if _starter_templates == null:
		_starter_templates = StarterTemplatesScript.new()
	if _wizard == null:
		_wizard = WizardScript.new()


# =========================================================================
# Wizard
# =========================================================================

func _maybe_show_wizard() -> void:
	if _wizard == null or _library == null:
		return
	if not _wizard.should_run(_library):
		return
	var dialog : AcceptDialog = _wizard.build_dialog(_library)
	if not _wizard.wizard_finished.is_connected(_on_wizard_finished):
		_wizard.wizard_finished.connect(_on_wizard_finished)
	dialog.confirmed.connect(func(): dialog.queue_free())
	dialog.canceled.connect(func(): dialog.queue_free())
	dialog.close_requested.connect(func(): dialog.queue_free())
	add_child(dialog)
	dialog.popup_centered()
	_wizard.mark_done(_library)


func _on_wizard_finished(template_id: String) -> void:
	if _editor_interface == null:
		_set_status("No editor interface — cannot apply template.", STATUS_COLOR_WARN)
		return
	var result: Dictionary = _starter_templates.apply(template_id, _library, _editor_interface)
	_set_status(str(result.get("message", "Template applied.")), STATUS_COLOR_OK)
	_main_tabs.current_tab = 2


# =========================================================================
# Search / Preview
# =========================================================================

func _on_text_changed(new_text: String) -> void:
	if _suppress_text_changed:
		return
	_run_search(new_text)


func _on_text_submitted(_text: String) -> void:
	if _current_match.is_empty():
		_set_status("Nothing matched. Try a different phrase.", STATUS_COLOR_WARN)
		return
	_on_insert_pressed()


func _run_search(query: String) -> void:
	var trimmed := query.strip_edges()
	if trimmed.is_empty():
		_clear_match()
		_set_status("")
		return

	var results := _library.search(trimmed)
	_current_results = results

	if results.is_empty():
		_clear_match()
		_hide_results()
		_set_status("No match for \"%s\"." % trimmed, STATUS_COLOR_WARN)
		return

	var top: Dictionary = results[0]
	_apply_match(str(top.kind), str(top.id), str(top.phrase_matched))

	if results.size() >= 2 and results[0].score == results[1].score:
		_show_results(results)
	else:
		_hide_results()

	_main_tabs.current_tab = 0


func _apply_match(kind: String, id: String, phrase: String, overwrite_input: bool = false) -> void:
	if kind == GDASELibrary.KIND_SNIPPET:
		var data: Dictionary = _library.get_snippet(id).duplicate()
		if data.is_empty():
			_clear_match()
			return
		data["kind"] = GDASELibrary.KIND_SNIPPET
		data["id"] = id
		data["phrase_matched"] = phrase
		_current_match = data
	elif kind == GDASELibrary.KIND_BLUEPRINT:
		var data: Dictionary = _library.get_blueprint(id).duplicate()
		if data.is_empty():
			_clear_match()
			return
		data["kind"] = GDASELibrary.KIND_BLUEPRINT
		data["id"] = id
		data["phrase_matched"] = phrase
		_current_match = data
	else:
		_clear_match()
		return

	if overwrite_input:
		_suppress_text_changed = true
		var phrases: Array = _library.phrases_for(id) if kind == GDASELibrary.KIND_SNIPPET else _library.blueprint_phrases_for(id)
		if not phrases.is_empty():
			_phrase_input.text = str(phrases[0])
		_suppress_text_changed = false

	_render_preview()
	_check_warnings()
	_render_related()
	_update_insert_button_label()

	var display_name := id
	if kind == GDASELibrary.KIND_BLUEPRINT:
		display_name = str(_current_match.get("title", id))
	_set_status("Matched \"%s\" \u2192 %s" % [phrase, display_name], STATUS_COLOR_OK)


func _clear_match() -> void:
	_current_match = {}
	_current_results = []
	_preview_code.text = ""
	_preview_details.text = ""
	_preview_params.text = ""
	_warning_label.visible = false
	_chips_row.visible = false
	_clear_related_chips()
	_preview_tabs.set_tab_title(0, "Code")
	_preview_tabs.set_tab_title(2, "Params")
	_update_insert_button_label()


# =========================================================================
# Result list
# =========================================================================

func _show_results(results: Array) -> void:
	_results_list.clear()
	var limit: int = min(results.size(), 8)
	for i in range(limit):
		var entry: Dictionary = results[i]
		var label := str(entry.id)
		if str(entry.kind) == GDASELibrary.KIND_BLUEPRINT:
			var bp: Dictionary = _library.get_blueprint(str(entry.id))
			label = str(bp.get("title", entry.id))
		label += "   \u2022  " + str(entry.phrase_matched)
		_results_list.add_item(label)
	_results_list.visible = true


func _hide_results() -> void:
	_results_list.visible = false
	_results_list.clear()


func _on_result_selected(index: int) -> void:
	if index < 0 or index >= _current_results.size():
		return
	var entry: Dictionary = _current_results[index]
	_apply_match(str(entry.kind), str(entry.id), str(entry.phrase_matched), true)


# =========================================================================
# Preview rendering
# =========================================================================

func _render_preview() -> void:
	if _current_match.is_empty():
		return
	var kind := str(_current_match.get("kind", ""))
	var mode := _library.get_mode()
	if kind == GDASELibrary.KIND_SNIPPET:
		_render_snippet(mode)
	elif kind == GDASELibrary.KIND_BLUEPRINT:
		_render_blueprint()
	_focus_default_tab(mode, kind)


func _render_snippet(mode: String) -> void:
	var id := str(_current_match.get("id", ""))
	_preview_tabs.set_tab_title(0, "Code")
	_preview_tabs.set_tab_title(2, "Params")
	_preview_code.text = _library.get_code_for_mode(id, mode)
	_preview_details.text = _format_snippet_details(id)
	_preview_params.text = _format_snippet_params(id)


func _render_blueprint() -> void:
	_preview_tabs.set_tab_title(0, "Tree")
	_preview_tabs.set_tab_title(2, "Setup")
	_preview_code.text = _format_blueprint_tree(_current_match)
	_preview_details.text = _format_blueprint_details(_current_match)
	_preview_params.text = _format_blueprint_setup(_current_match)


func _focus_default_tab(mode: String, kind: String) -> void:
	if kind == GDASELibrary.KIND_BLUEPRINT:
		_preview_tabs.current_tab = 0
		return
	if mode == GDASELibrary.MODE_FULL_DETAILS:
		_preview_tabs.current_tab = 1
	else:
		_preview_tabs.current_tab = 0


func _format_snippet_details(id: String) -> String:
	var details := _library.get_details(id)
	if details.is_empty():
		return "No details for this snippet yet."
	var lines: Array = []
	_append_section(lines, "WHAT", str(details.get("what", "")))
	_append_section(lines, "WHERE", str(details.get("where", "")))
	_append_section(lines, "BEFORE", str(details.get("before", "")))
	_append_section(lines, "AFTER", str(details.get("after", "")))
	_append_section(lines, "WHY THIS IS OPTIMIZED", str(details.get("why_optimized", "")))
	_append_section(lines, "COMMON MISTAKES", str(details.get("mistakes", "")))
	if lines.is_empty():
		return "No details for this snippet yet."
	return "\n".join(lines)


func _append_section(out: Array, title: String, body: String) -> void:
	if body.strip_edges().is_empty():
		return
	if not out.is_empty():
		out.append("")
	out.append(title)
	out.append("  " + body)


func _format_snippet_params(id: String) -> String:
	var params := _library.get_params(id)
	if params.is_empty():
		return "No tunable parameters for this snippet."
	var info_all := _library.get_param_info(id)
	var lines: Array = []
	for p in params:
		var pname := str(p)
		var info: Dictionary = info_all.get(pname, {})
		if not lines.is_empty():
			lines.append("")
		lines.append(pname)
		if info.is_empty():
			lines.append("  (no detailed info for this parameter yet)")
			continue
		var default_value: Variant = info.get("default", null)
		if default_value != null:
			lines.append("  Default: " + str(default_value))
		var range_val: Variant = info.get("range", null)
		if range_val is Array and range_val.size() == 2:
			lines.append("  Range: %s to %s" % [str(range_val[0]), str(range_val[1])])
		var what := str(info.get("what", ""))
		if not what.is_empty():
			lines.append("  What: " + what)
		var typical := str(info.get("typical", ""))
		if not typical.is_empty():
			lines.append("  Typical: " + typical)
		var increase := str(info.get("increase", ""))
		if not increase.is_empty():
			lines.append("  Increase: " + increase)
		var decrease := str(info.get("decrease", ""))
		if not decrease.is_empty():
			lines.append("  Decrease: " + decrease)
	return "\n".join(lines)


func _format_blueprint_tree(bp: Dictionary) -> String:
	var root: Dictionary = bp.get("root", {})
	var root_type := str(root.get("type", "Node"))
	var root_name := str(root.get("name", "Root"))
	var lines: Array = []
	lines.append("%s  (%s)" % [root_name, root_type])
	var required: Array = bp.get("required_children", [])
	if not required.is_empty():
		lines.append("")
		lines.append("Required children:")
		for i in range(required.size()):
			var marker := "\u2514\u2500\u2500" if i == required.size() - 1 else "\u251c\u2500\u2500"
			lines.append("  %s %s" % [marker, _format_child(required[i])])
	var recommended: Array = bp.get("recommended_children", [])
	if not recommended.is_empty():
		lines.append("")
		lines.append("Recommended children:")
		for i in range(recommended.size()):
			var marker := "\u2514\u2500\u2500" if i == recommended.size() - 1 else "\u251c\u2500\u2500"
			lines.append("  %s %s" % [marker, _format_child(recommended[i])])
	var script := str(bp.get("script", ""))
	if not script.is_empty():
		lines.append("")
		lines.append("Script: " + script)
	return "\n".join(lines)


func _format_child(child: Dictionary) -> String:
	var parts: Array = []
	parts.append(str(child.get("name", "?")))
	var detail := "(" + str(child.get("type", "Node"))
	var shape := str(child.get("shape", ""))
	if not shape.is_empty():
		detail += ", " + shape
	var mesh := str(child.get("mesh", ""))
	if not mesh.is_empty():
		detail += ", " + mesh
	detail += ")"
	parts.append(detail)
	return " ".join(parts)


func _format_blueprint_details(bp: Dictionary) -> String:
	var lines: Array = []
	var what := str(bp.get("description", ""))
	if not what.is_empty():
		_append_section(lines, "WHAT", what)
	var dim := str(bp.get("dimension", ""))
	if not dim.is_empty():
		_append_section(lines, "DIMENSION", dim)
	var diff := str(bp.get("difficulty", ""))
	if not diff.is_empty():
		_append_section(lines, "DIFFICULTY", diff)
	if lines.is_empty():
		return "No description for this blueprint."
	return "\n".join(lines)


func _format_blueprint_setup(bp: Dictionary) -> String:
	var lines: Array = []
	var setup_notes: Array = bp.get("setup_notes", [])
	if not setup_notes.is_empty():
		lines.append("SETUP NOTES")
		for note in setup_notes:
			lines.append("  \u2022 " + str(note))
	var next_steps: Array = bp.get("next_steps", [])
	if not next_steps.is_empty():
		if not lines.is_empty():
			lines.append("")
		lines.append("NEXT STEPS")
		for step in next_steps:
			var target := ""
			if step.has("snippet"):
				target = str(step.snippet)
			elif step.has("blueprint"):
				target = str(step.blueprint)
			var why := str(step.get("why", ""))
			var line := "  \u2022 " + target
			if not why.is_empty():
				line += "  \u2014  " + why
			lines.append(line)
	var mistakes: Array = bp.get("mistakes", [])
	if not mistakes.is_empty():
		if not lines.is_empty():
			lines.append("")
		lines.append("COMMON MISTAKES")
		for m in mistakes:
			lines.append("  \u2022 " + str(m))
	if lines.is_empty():
		return "No setup notes for this blueprint."
	return "\n".join(lines)


# =========================================================================
# Warnings
# =========================================================================

func _check_warnings() -> void:
	if _current_match.is_empty():
		_warning_label.visible = false
		return
	var kind := str(_current_match.get("kind", ""))
	var id := str(_current_match.get("id", ""))
	var missing: Array = []
	if kind == GDASELibrary.KIND_SNIPPET:
		missing = _library.check_required_actions(id)
	elif kind == GDASELibrary.KIND_BLUEPRINT:
		missing = _library.check_blueprint_required_actions(id)
	if missing.is_empty():
		_warning_label.visible = false
		return
	var names: Array = []
	for m in missing:
		names.append(str(m))
	_warning_label.text = "\u26a0  Missing input actions: %s  \u2014  add them in Project Settings \u2192 Input Map." % ", ".join(names)
	_warning_label.modulate = STATUS_COLOR_WARN
	_warning_label.visible = true


# =========================================================================
# Related chips
# =========================================================================

func _render_related() -> void:
	_clear_related_chips()
	if _current_match.is_empty():
		_chips_row.visible = false
		return
	var related: Array = []
	var kind := str(_current_match.get("kind", ""))
	if kind == GDASELibrary.KIND_SNIPPET:
		var details: Dictionary = _current_match.get("details", {})
		var r: Variant = details.get("related", [])
		if r is Array:
			related = r
	elif kind == GDASELibrary.KIND_BLUEPRINT:
		var steps: Array = _current_match.get("next_steps", [])
		for step in steps:
			if step.has("snippet"):
				related.append(str(step.snippet))
			elif step.has("blueprint"):
				related.append(str(step.blueprint))
	if related.is_empty():
		_chips_row.visible = false
		return
	for r in related:
		var btn := Button.new()
		btn.text = str(r).replace("_", " ")
		btn.add_theme_font_size_override("font_size", 12)
		btn.pressed.connect(_on_related_pressed.bind(str(r)))
		_related_chips.add_child(btn)
	_chips_row.visible = true


func _clear_related_chips() -> void:
	for child in _related_chips.get_children():
		_related_chips.remove_child(child)
		child.queue_free()


func _on_related_pressed(related_id: String) -> void:
	var phrases: Array = []
	if _library.has_snippet(related_id):
		phrases = _library.phrases_for(related_id)
	elif _library.has_blueprint(related_id):
		phrases = _library.blueprint_phrases_for(related_id)
	if phrases.is_empty():
		_set_status("Related item has no phrases: " + related_id, STATUS_COLOR_WARN)
		return
	_suppress_text_changed = true
	_phrase_input.text = str(phrases[0])
	_suppress_text_changed = false
	_run_search(_phrase_input.text)
	_phrase_input.grab_focus()


# =========================================================================
# Mode buttons
# =========================================================================

func _on_mode_code_only_pressed() -> void:
	_set_mode(GDASELibrary.MODE_CODE_ONLY)


func _on_mode_code_details_pressed() -> void:
	_set_mode(GDASELibrary.MODE_CODE_DETAILS)


func _on_mode_full_details_pressed() -> void:
	_set_mode(GDASELibrary.MODE_FULL_DETAILS)


func _set_mode(mode: String) -> void:
	_library.set_mode(mode)
	_render_preview()
	_set_status("Mode: " + _mode_label(mode), STATUS_COLOR_OK)


func _apply_saved_mode() -> void:
	var mode := _library.get_mode()
	_mode_code_only.button_pressed = (mode == GDASELibrary.MODE_CODE_ONLY)
	_mode_code_details.button_pressed = (mode == GDASELibrary.MODE_CODE_DETAILS)
	_mode_full_details.button_pressed = (mode == GDASELibrary.MODE_FULL_DETAILS)


func _mode_label(mode: String) -> String:
	if mode == GDASELibrary.MODE_CODE_ONLY:
		return "Code only"
	if mode == GDASELibrary.MODE_CODE_DETAILS:
		return "Code + details"
	if mode == GDASELibrary.MODE_FULL_DETAILS:
		return "Full details"
	return mode


# =========================================================================
# Insert / Copy
# =========================================================================

func _update_insert_button_label() -> void:
	if _current_match.is_empty():
		_insert_button.text = "Insert"
		return
	if str(_current_match.get("kind", "")) == GDASELibrary.KIND_BLUEPRINT:
		_insert_button.text = "Build"
	else:
		_insert_button.text = "Insert"


func _on_insert_pressed() -> void:
	if _current_match.is_empty():
		_set_status("Nothing to insert.", STATUS_COLOR_WARN)
		return
	if str(_current_match.get("kind", "")) == GDASELibrary.KIND_BLUEPRINT:
		_do_blueprint_build()
		return
	_do_snippet_insert()


func _do_snippet_insert() -> void:
	var id := str(_current_match.get("id", ""))
	var mode := _library.get_mode()
	var code := _library.get_code_for_mode(id, mode)
	if code.is_empty():
		_set_status("Nothing to insert.", STATUS_COLOR_WARN)
		return
	var code_edit := _get_active_code_edit()
	if code_edit == null:
		_set_status("No active script editor. Open a .gd file first.", STATUS_COLOR_WARN)
		return
	code_edit.begin_complex_operation()
	code_edit.insert_text_at_caret(code)
	code_edit.end_complex_operation()
	code_edit.grab_focus()
	_library.add_recent(id)
	_set_status("Inserted %d characters." % code.length(), STATUS_COLOR_OK)


func _do_blueprint_build() -> void:
	if _blueprint_builder == null:
		_set_status("Blueprint builder not loaded.", STATUS_COLOR_WARN)
		return
	if _editor_interface == null:
		_set_status("No editor interface. Cannot build.", STATUS_COLOR_WARN)
		return
	var id := str(_current_match.get("id", ""))
	var result: Dictionary = _blueprint_builder.build(id, _library, _editor_interface)
	if result.get("ok", false):
		_library.add_recent(id)
		_set_status(str(result.get("message", "Blueprint built.")), STATUS_COLOR_OK)
	else:
		_set_status("Build failed: " + str(result.get("message", "unknown error")), STATUS_COLOR_ERR)


func _on_copy_pressed() -> void:
	if _current_match.is_empty():
		_set_status("Nothing to copy.", STATUS_COLOR_WARN)
		return
	if str(_current_match.get("kind", "")) == GDASELibrary.KIND_BLUEPRINT:
		DisplayServer.clipboard_set(_preview_code.text)
		_set_status("Copied blueprint tree to clipboard.", STATUS_COLOR_OK)
		return
	var id := str(_current_match.get("id", ""))
	var mode := _library.get_mode()
	var code := _library.get_code_for_mode(id, mode)
	if code.is_empty():
		_set_status("Nothing to copy.", STATUS_COLOR_WARN)
		return
	DisplayServer.clipboard_set(code)
	_set_status("Copied to clipboard.", STATUS_COLOR_OK)


# =========================================================================
# Browse tab
# =========================================================================

func _rebuild_browse_tree() -> void:
	if _map_browser == null or _browse_tree == null:
		return
	_map_browser.build_tree(_browse_tree, _library)
	_map_browser.connect_tree_signal()


func _on_browse_item_selected(kind: String, id: String) -> void:
	_apply_match(kind, id, "", true)
	_main_tabs.current_tab = 0


# =========================================================================
# Learn tab
# =========================================================================

func _on_learn_refresh_pressed() -> void:
	if _editor_interface == null or _inspector == null:
		return
	var selection := _editor_interface.get_selection()
	if selection == null:
		_learn_node_label.text = "No selection."
		_learn_text.text = ""
		return
	var selected := selection.get_selected_nodes()
	if selected.is_empty():
		_learn_node_label.text = "No node selected. Click a node in the Scene tree."
		_learn_text.text = ""
		return
	var node: Node = selected[0]
	_learn_node_label.text = "Selected: " + str(node.name) + " (" + node.get_class() + ")"
	_learn_text.text = _inspector.format(node)


# =========================================================================
# Tools tab — templates
# =========================================================================

func _rebuild_templates_list() -> void:
	if _templates_list == null or _library == null:
		return
	for child in _templates_list.get_children():
		_templates_list.remove_child(child)
		child.queue_free()
	var ids: Array = _library.list_template_ids()
	ids.sort()
	for tid in ids:
		var t: Dictionary = _library.get_template(str(tid))
		if t.is_empty():
			continue
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		var label := Label.new()
		label.text = str(t.get("title", tid))
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(label)
		var btn := Button.new()
		btn.text = "Apply"
		btn.pressed.connect(_on_template_apply_pressed.bind(str(tid)))
		row.add_child(btn)
		_templates_list.add_child(row)


func _on_template_apply_pressed(template_id: String) -> void:
	if _editor_interface == null:
		_set_status("No editor interface.", STATUS_COLOR_WARN)
		return
	var result: Dictionary = _starter_templates.apply(template_id, _library, _editor_interface)
	_set_status(str(result.get("message", "Template applied.")), STATUS_COLOR_OK)


# =========================================================================
# Tools tab — scene checker
# =========================================================================

func _on_checker_pressed() -> void:
	if _editor_interface == null or _scene_checker == null:
		return
	var issues: Array = _scene_checker.scan(_editor_interface)
	_checker_output.text = _scene_checker.format(issues)
	_set_status("Scanned scene. %d issue(s) found." % issues.size(), STATUS_COLOR_OK)


# =========================================================================
# Tools tab — debug overlay
# =========================================================================

func _on_overlay_install_pressed() -> void:
	if _editor_interface == null:
		_set_status("No editor interface.", STATUS_COLOR_WARN)
		return
	if _debug_overlay == null:
		_debug_overlay = DebugOverlayScript.new()
	var result: Dictionary = _debug_overlay.install(_editor_interface)
	_set_status(str(result.get("message", "")), STATUS_COLOR_OK if result.get("ok", false) else STATUS_COLOR_WARN)


func _on_overlay_remove_pressed() -> void:
	if _editor_interface == null:
		_set_status("No editor interface.", STATUS_COLOR_WARN)
		return
	if _debug_overlay == null:
		_debug_overlay = DebugOverlayScript.new()
	var result: Dictionary = _debug_overlay.remove(_editor_interface)
	_set_status(str(result.get("message", "")), STATUS_COLOR_OK if result.get("ok", false) else STATUS_COLOR_WARN)


# =========================================================================
# Editor access
# =========================================================================

func _get_active_code_edit() -> CodeEdit:
	if _editor_interface == null:
		return null
	var script_editor := _editor_interface.get_script_editor()
	if script_editor == null:
		return null
	var current := script_editor.get_current_editor()
	if current == null:
		return null
	var base := current.get_base_editor()
	return base as CodeEdit


# =========================================================================
# Status
# =========================================================================

func _set_status(msg: String, color: Color = Color.WHITE) -> void:
	if _status == null:
		return
	_status.text = msg
	_status.modulate = color
