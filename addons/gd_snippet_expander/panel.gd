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
const BlueprintSerializerScript := preload("res://addons/gd_snippet_expander/blueprint_serializer.gd")
const SaveBlueprintDialogScript := preload("res://addons/gd_snippet_expander/save_blueprint_dialog.gd")
const BlueprintIoScript := preload("res://addons/gd_snippet_expander/blueprint_io.gd")
const VersionCheckScript := preload("res://addons/gd_snippet_expander/version_check.gd")
const PanelThemeScript := preload("res://addons/gd_snippet_expander/panel_theme.gd")

const STATUS_COLOR_OK := Color(0.72, 0.85, 0.72)
const STATUS_COLOR_WARN := Color(1.0, 0.85, 0.4)
const STATUS_COLOR_ERR := Color(1.0, 0.6, 0.55)

const STAR_EMPTY := "\u2606"
const STAR_FILLED := "\u2605"

const FADE_DURATION := 0.18
const STATUS_FADE_DURATION := 0.22
const STAR_POP_DURATION := 0.35
const BUTTON_CONFIRM_DURATION := 0.7
const WARN_FADE_DURATION := 0.28

var _editor_interface: EditorInterface = null
var _editor_selection: EditorSelection = null
var _library: GDASELibrary = null
var _blueprint_builder: Node = null
var _map_browser: Node = null
var _inspector: Node = null
var _scene_checker: Node = null
var _starter_templates: Node = null
var _wizard: Node = null
var _debug_overlay: Node = null
var _blueprint_serializer: Node = null
var _blueprint_io: Node = null
var _version_check = null
var _theme_ref = null
var _syntax_highlighter: CodeHighlighter = null
var _save_dialog: ConfirmationDialog = null
var _export_dialog: FileDialog = null
var _import_dialog: FileDialog = null

var _current_match: Dictionary = {}
var _current_results: Array = []
var _suppress_text_changed: bool = false
var _insert_default_text: String = "Insert"
var _copy_default_text: String = "Copy"
var _button_reset_token: int = 0

@onready var _phrase_input: LineEdit = %PhraseInput
@onready var _fav_button: Button = %FavButton
@onready var _insert_button: Button = %InsertButton
@onready var _copy_button: Button = %CopyButton
@onready var _mode_code_only: Button = %ModeCodeOnly
@onready var _mode_code_details: Button = %ModeCodeDetails
@onready var _mode_full_details: Button = %ModeFullDetails
@onready var _favorites_row: HBoxContainer = %FavoritesRow
@onready var _favorites_chips: HBoxContainer = %FavoritesChips
@onready var _suggestion_row: HBoxContainer = %SuggestionRow
@onready var _suggestion_chips: HBoxContainer = %SuggestionChips
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
@onready var _export_blueprints_button: Button = %ExportBlueprintsButton
@onready var _import_blueprints_button: Button = %ImportBlueprintsButton
@onready var _blueprint_io_status: Label = %BlueprintIoStatus
@onready var _checker_button: Button = %CheckerButton
@onready var _checker_output: TextEdit = %CheckerOutput
@onready var _overlay_install_button: Button = %OverlayInstallButton
@onready var _overlay_remove_button: Button = %OverlayRemoveButton


# =========================================================================
# Lifecycle
# =========================================================================

func _ready() -> void:
	_apply_theme()
	_ensure_library()
	_ensure_helpers()

	_fav_button.pressed.connect(_on_fav_pressed)
	_insert_button.pressed.connect(_on_insert_pressed)
	_copy_button.pressed.connect(_on_copy_pressed)
	_phrase_input.text_changed.connect(_on_text_changed)
	_phrase_input.text_submitted.connect(_on_text_submitted)
	_mode_code_only.pressed.connect(_on_mode_code_only_pressed)
	_mode_code_details.pressed.connect(_on_mode_code_details_pressed)
	_mode_full_details.pressed.connect(_on_mode_full_details_pressed)
	_results_list.item_selected.connect(_on_result_selected)
	_learn_refresh_button.pressed.connect(_on_learn_refresh_pressed)
	_export_blueprints_button.pressed.connect(_on_export_blueprints_pressed)
	_import_blueprints_button.pressed.connect(_on_import_blueprints_pressed)
	_checker_button.pressed.connect(_on_checker_pressed)
	_overlay_install_button.pressed.connect(_on_overlay_install_pressed)
	_overlay_remove_button.pressed.connect(_on_overlay_remove_pressed)

	if _map_browser != null and _map_browser.has_signal("item_selected"):
		_map_browser.item_selected.connect(_on_browse_item_selected)

	_apply_saved_mode()
	_clear_match()
	_rebuild_browse_tree()
	_rebuild_templates_list()
	_rebuild_favorites_row()
	_rebuild_suggestions()
	_apply_theme_tweaks()
	if _editor_interface != null and _inspector != null and _inspector.has_method("set_editor_interface"):
		_inspector.set_editor_interface(_editor_interface)
	_set_initial_status()


func set_editor_interface(ei: EditorInterface) -> void:
	_editor_interface = ei
	if _inspector != null and _inspector.has_method("set_editor_interface"):
		_inspector.set_editor_interface(ei)
	_connect_selection_signal()
	if _wizard != null and ei != null:
		_maybe_show_wizard()


func _connect_selection_signal() -> void:
	if _editor_interface == null:
		return
	var sel := _editor_interface.get_selection()
	if sel == null:
		return
	# Already connected to this same selection object — nothing to do.
	if _editor_selection == sel and sel.selection_changed.is_connected(_on_editor_selection_changed):
		return
	# Disconnect from an older selection object if we had one.
	if _editor_selection != null and _editor_selection.selection_changed.is_connected(_on_editor_selection_changed):
		_editor_selection.selection_changed.disconnect(_on_editor_selection_changed)
	_editor_selection = sel
	_editor_selection.selection_changed.connect(_on_editor_selection_changed)


func _on_editor_selection_changed() -> void:
	# The signal fires before _ready() on first setup, so guard against
	# @onready references not being ready yet.
	if not is_node_ready():
		return
	_on_learn_refresh_pressed()


# =========================================================================
# Theme
# =========================================================================

func _apply_theme() -> void:
	if _theme_ref == null:
		_theme_ref = PanelThemeScript.new()
	var built_theme: Theme = _theme_ref.build()
	theme = built_theme


func _apply_theme_tweaks() -> void:
	_phrase_input.add_theme_font_size_override("font_size", 17)
	_preview_code.syntax_highlighter = _ensure_syntax_highlighter()
	_status.add_theme_font_size_override("font_size", 12)
	_status.modulate = Color(1, 1, 1, 0)
	_warning_label.add_theme_font_size_override("font_size", 12)
	_learn_node_label.add_theme_font_size_override("font_size", 12)
	_blueprint_io_status.add_theme_font_size_override("font_size", 11)
	_blueprint_io_status.modulate = Color(1, 1, 1, 0.85)


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
	if _blueprint_serializer == null:
		_blueprint_serializer = BlueprintSerializerScript.new()
	if _blueprint_io == null:
		_blueprint_io = BlueprintIoScript.new()
	if _version_check == null:
		_version_check = VersionCheckScript.new()


# =========================================================================
# Initial status (version-aware)
# =========================================================================

func _set_initial_status() -> void:
	if _version_check != null and _version_check.should_show_warning():
		var level := str(_version_check.get_warning_level())
		var msg := str(_version_check.get_warning_message())
		var color := STATUS_COLOR_WARN if level == "warn" else STATUS_COLOR_ERR
		_set_status(msg, color)
		return
	_set_status("Ready. Type a phrase and press Enter.", STATUS_COLOR_OK)


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
	_update_fav_button()
	_fade_in_preview()

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
	_update_fav_button()


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
# Favorites
# =========================================================================

func _on_fav_pressed() -> void:
	if _current_match.is_empty():
		return
	var id := str(_current_match.get("id", ""))
	if id.is_empty():
		return
	_library.toggle_favorite(id)
	_update_fav_button()
	_pop_star()
	_rebuild_favorites_row()
	if _library.is_favorite(id):
		_set_status("Added to favorites: " + id, STATUS_COLOR_OK)
	else:
		_set_status("Removed from favorites: " + id, STATUS_COLOR_OK)


func _update_fav_button() -> void:
	if _fav_button == null:
		return
	if _current_match.is_empty():
		_fav_button.text = STAR_EMPTY
		_fav_button.disabled = true
		_fav_button.tooltip_text = "No match selected"
		return
	_fav_button.disabled = false
	var id := str(_current_match.get("id", ""))
	if _library.is_favorite(id):
		_fav_button.text = STAR_FILLED
		_fav_button.tooltip_text = "Remove from favorites"
		_fav_button.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
		_fav_button.add_theme_color_override("font_hover_color", Color(1.0, 0.9, 0.55))
	else:
		_fav_button.text = STAR_EMPTY
		_fav_button.tooltip_text = "Add to favorites"
		_fav_button.add_theme_color_override("font_color", Color(0.7, 0.7, 0.72))
		_fav_button.add_theme_color_override("font_hover_color", Color(1.0, 0.85, 0.4))


func _pop_star() -> void:
	if _fav_button == null:
		return
	_fav_button.pivot_offset = _fav_button.size * 0.5
	var tween := create_tween()
	tween.tween_property(_fav_button, "scale", Vector2(1.35, 1.35), STAR_POP_DURATION * 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(_fav_button, "scale", Vector2.ONE, STAR_POP_DURATION * 0.7).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func _rebuild_favorites_row() -> void:
	if _favorites_chips == null or _favorites_row == null:
		return
	for child in _favorites_chips.get_children():
		_favorites_chips.remove_child(child)
		child.queue_free()
	var favs: Array = _library.get_favorites()
	if favs.is_empty():
		_favorites_row.visible = false
		return
	for fav_id in favs:
		var chip := Button.new()
		chip.text = _entry_label(str(fav_id))
		chip.add_theme_font_size_override("font_size", 12)
		chip.tooltip_text = str(fav_id)
		chip.pressed.connect(_on_favorite_chip_pressed.bind(str(fav_id)))
		_favorites_chips.add_child(chip)
	_favorites_row.visible = true
	_favorites_row.modulate = Color(1, 1, 1, 0)
	var fade := create_tween()
	fade.tween_property(_favorites_row, "modulate:a", 1.0, FADE_DURATION)


func _entry_label(id: String) -> String:
	if _library.has_blueprint(id):
		var bp: Dictionary = _library.get_blueprint(id)
		return str(bp.get("title", id))
	var phrases: Array = _library.phrases_for(id)
	if not phrases.is_empty():
		return str(phrases[0])
	return id


func _on_favorite_chip_pressed(id: String) -> void:
	if _library.has_snippet(id):
		_apply_match(GDASELibrary.KIND_SNIPPET, id, "", true)
	elif _library.has_blueprint(id):
		_apply_match(GDASELibrary.KIND_BLUEPRINT, id, "", true)
	else:
		_set_status("Favorite entry no longer exists: " + id, STATUS_COLOR_WARN)
		return
	_main_tabs.current_tab = 0


# =========================================================================
# Suggestions
# =========================================================================

func _rebuild_suggestions() -> void:
	if _suggestion_chips == null or _suggestion_row == null:
		return
	for child in _suggestion_chips.get_children():
		_suggestion_chips.remove_child(child)
		child.queue_free()
	var suggestions: Array = _library.get_suggestions(3)
	if suggestions.is_empty():
		_suggestion_row.visible = false
		return
	for sid in suggestions:
		var chip := Button.new()
		chip.text = _entry_label(str(sid))
		chip.add_theme_font_size_override("font_size", 12)
		chip.tooltip_text = "Try: " + str(sid)
		chip.pressed.connect(_on_suggestion_chip_pressed.bind(str(sid)))
		_suggestion_chips.add_child(chip)
	_suggestion_row.visible = true
	_suggestion_row.modulate = Color(1, 1, 1, 0)
	var fade := create_tween()
	fade.tween_property(_suggestion_row, "modulate:a", 1.0, FADE_DURATION)


func _on_suggestion_chip_pressed(id: String) -> void:
	if _library.has_snippet(id):
		_apply_match(GDASELibrary.KIND_SNIPPET, id, "", true)
	elif _library.has_blueprint(id):
		_apply_match(GDASELibrary.KIND_BLUEPRINT, id, "", true)
	else:
		_set_status("Suggestion no longer exists: " + id, STATUS_COLOR_WARN)
		return
	_main_tabs.current_tab = 0


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
	_fade_in_warning()


func _fade_in_warning() -> void:
	if _warning_label == null:
		return
	_warning_label.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(_warning_label, "modulate:a", 1.0, WARN_FADE_DURATION)


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
	_chips_row.modulate = Color(1, 1, 1, 0)
	var fade := create_tween()
	fade.tween_property(_chips_row, "modulate:a", 1.0, FADE_DURATION)


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
	_fade_in_preview()
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
		_insert_default_text = "Insert"
		_insert_button.text = _insert_default_text
		return
	if str(_current_match.get("kind", "")) == GDASELibrary.KIND_BLUEPRINT:
		_insert_default_text = "Build"
	else:
		_insert_default_text = "Insert"
	_insert_button.text = _insert_default_text


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
	_rebuild_suggestions()
	_flash_button_success(_insert_button, "Inserted")
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
		_rebuild_suggestions()
		_flash_button_success(_insert_button, "Built")
		_set_status(str(result.get("message", "Blueprint built.")), STATUS_COLOR_OK)
	else:
		_set_status("Build failed: " + str(result.get("message", "unknown error")), STATUS_COLOR_ERR)
		_emphasize_error()


func _on_copy_pressed() -> void:
	if _current_match.is_empty():
		_set_status("Nothing to copy.", STATUS_COLOR_WARN)
		return
	if str(_current_match.get("kind", "")) == GDASELibrary.KIND_BLUEPRINT:
		DisplayServer.clipboard_set(_preview_code.text)
		_flash_button_success(_copy_button, "Copied")
		_set_status("Copied blueprint tree to clipboard.", STATUS_COLOR_OK)
		return
	var id := str(_current_match.get("id", ""))
	var mode := _library.get_mode()
	var code := _library.get_code_for_mode(id, mode)
	if code.is_empty():
		_set_status("Nothing to copy.", STATUS_COLOR_WARN)
		return
	DisplayServer.clipboard_set(code)
	_flash_button_success(_copy_button, "Copied")
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
	_fade_in_node(_learn_text)


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
# Tools tab — blueprint import/export
# =========================================================================

func _on_export_blueprints_pressed() -> void:
	if _blueprint_io == null:
		return
	if _export_dialog == null:
		_export_dialog = FileDialog.new()
		_export_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
		_export_dialog.access = FileDialog.ACCESS_FILESYSTEM
		_export_dialog.add_filter("*.json", "JSON files")
		_export_dialog.title = "Export Blueprints"
		_export_dialog.current_file = "gdse_blueprints.json"
		_export_dialog.file_selected.connect(_on_export_path_selected)
		add_child(_export_dialog)
	_export_dialog.popup_centered_ratio(0.7)


func _on_export_path_selected(path: String) -> void:
	if _blueprint_io == null:
		return
	var result: Dictionary = _blueprint_io.export_to_file(path)
	var msg := str(result.get("message", ""))
	if result.get("ok", false):
		_blueprint_io_status.text = msg
		_blueprint_io_status.modulate = STATUS_COLOR_OK
		_set_status(msg, STATUS_COLOR_OK)
	else:
		_blueprint_io_status.text = msg
		_blueprint_io_status.modulate = STATUS_COLOR_ERR
		_set_status(msg, STATUS_COLOR_ERR)


func _on_import_blueprints_pressed() -> void:
	if _blueprint_io == null:
		return
	if _import_dialog == null:
		_import_dialog = FileDialog.new()
		_import_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
		_import_dialog.access = FileDialog.ACCESS_FILESYSTEM
		_import_dialog.add_filter("*.json", "JSON files")
		_import_dialog.title = "Import Blueprints"
		_import_dialog.file_selected.connect(_on_import_path_selected)
		add_child(_import_dialog)
	_import_dialog.popup_centered_ratio(0.7)


func _on_import_path_selected(path: String) -> void:
	if _blueprint_io == null:
		return
	var result: Dictionary = _blueprint_io.import_from_file(path)
	var msg := str(result.get("message", ""))
	if result.get("ok", false):
		_library.reload()
		_rebuild_browse_tree()
		_blueprint_io_status.text = msg
		_blueprint_io_status.modulate = STATUS_COLOR_OK
		_set_status(msg, STATUS_COLOR_OK)
	else:
		_blueprint_io_status.text = msg
		_blueprint_io_status.modulate = STATUS_COLOR_ERR
		_set_status(msg, STATUS_COLOR_ERR)


# =========================================================================
# Tools tab — scene checker
# =========================================================================

func _on_checker_pressed() -> void:
	if _editor_interface == null or _scene_checker == null:
		return
	var issues: Array = _scene_checker.scan(_editor_interface)
	_checker_output.text = _scene_checker.format(issues)
	_fade_in_node(_checker_output)
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
# Save-as-Blueprint
# =========================================================================

func prompt_save_blueprint() -> void:
	if _editor_interface == null:
		_set_status("No editor interface.", STATUS_COLOR_WARN)
		return
	var selection := _editor_interface.get_selection()
	if selection == null:
		_set_status("No selection.", STATUS_COLOR_WARN)
		return
	var selected := selection.get_selected_nodes()
	if selected.is_empty():
		_set_status("Select a node in the Scene tree first.", STATUS_COLOR_WARN)
		return
	var node: Node = selected[0]
	if node == null or not is_instance_valid(node):
		_set_status("Selected node is not valid.", STATUS_COLOR_WARN)
		return
	if _blueprint_serializer == null:
		_blueprint_serializer = BlueprintSerializerScript.new()
	_open_save_dialog(node)


func _open_save_dialog(node: Node) -> void:
	if _save_dialog == null:
		_save_dialog = SaveBlueprintDialogScript.new()
		add_child(_save_dialog)
		_save_dialog.blueprint_confirmed.connect(_on_blueprint_save_confirmed)
	_save_dialog.set_meta("source_node", node)
	var suggested_id := _suggest_id(str(node.name))
	_save_dialog.call("prefill", suggested_id, str(node.name), _suggest_phrases(str(node.name)))
	_save_dialog.popup_centered()


func _suggest_id(node_name: String) -> String:
	var s := node_name.to_lower()
	var out := ""
	for i in range(s.length()):
		var c := s[i]
		if (c >= "a" and c <= "z") or (c >= "0" and c <= "9"):
			out += c
		elif c == " " or c == "_" or c == "-":
			out += "_"
	if out.is_empty():
		out = "blueprint"
	return "custom_" + out


func _suggest_phrases(node_name: String) -> String:
	var s := node_name.to_lower().replace("_", " ")
	var words := s.split(" ", false)
	var out: Array = []
	for w in words:
		out.append(str(w))
	return ", ".join(out)


func _on_blueprint_save_confirmed(id: String, title_text: String, phrases: Array, category: String, subcategory: String) -> void:
	if _blueprint_serializer == null or _save_dialog == null:
		return
	var source = _save_dialog.get_meta("source_node")
	if source == null or not is_instance_valid(source):
		_set_status("Source node is gone.", STATUS_COLOR_WARN)
		return
	var spec: Dictionary = _blueprint_serializer.serialize(source)
	if spec.is_empty():
		_set_status("Could not serialize node.", STATUS_COLOR_ERR)
		return

	var data := {
		"title": title_text,
		"phrases": phrases,
		"category": category,
		"subcategory": subcategory,
		"dimension": "any",
		"difficulty": "custom",
		"root": spec,
		"required_children": [],
		"recommended_children": [],
		"script": "",
		"required_actions": [],
		"setup_notes": ["Custom blueprint saved from the scene tree."],
		"next_steps": [],
		"mistakes": []
	}

	var result: Dictionary = _library.add_user_blueprint(id, data)
	if not result.get("ok", false):
		_set_status("Save failed: " + str(result.get("message", "unknown")), STATUS_COLOR_ERR)
		return

	_rebuild_browse_tree()
	_set_status("Saved custom blueprint: " + title_text + " (id: " + id + ")", STATUS_COLOR_OK)


# =========================================================================
# Status
# =========================================================================

func _set_status(msg: String, color: Color = Color.WHITE) -> void:
	if _status == null:
		return
	_status.text = msg
	_status.modulate = Color(color.r, color.g, color.b, 1.0)
	_pulse_status()


func _pulse_status() -> void:
	if _status == null:
		return
	var target := _status.modulate
	target.a = 1.0
	_status.modulate = Color(target.r, target.g, target.b, 0.35)
	var tween := create_tween()
	tween.tween_property(_status, "modulate:a", 1.0, STATUS_FADE_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


# =========================================================================
# Animations
# =========================================================================

func _fade_in_preview() -> void:
	if _preview_tabs == null:
		return
	var target: float = 1.0
	_preview_tabs.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(_preview_tabs, "modulate:a", target, FADE_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _fade_in_node(node: Control) -> void:
	if node == null:
		return
	node.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(node, "modulate:a", 1.0, FADE_DURATION)


func _flash_button_success(button: Button, label: String) -> void:
	if button == null:
		return
	_button_reset_token += 1
	var my_token := _button_reset_token
	var default_text := _insert_default_text if button == _insert_button else _copy_default_text
	button.text = "\u2713 " + label
	button.pivot_offset = button.size * 0.5
	button.scale = Vector2(1.05, 1.05)
	var tween := create_tween()
	tween.tween_property(button, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await get_tree().create_timer(BUTTON_CONFIRM_DURATION).timeout
	if my_token == _button_reset_token and is_instance_valid(button):
		button.text = default_text


func _emphasize_error() -> void:
	if _status == null:
		return
	var base := _status.modulate
	var flash := Color(1.0, 0.35, 0.35, 1.0)
	var tween := create_tween()
	tween.tween_property(_status, "modulate", flash, 0.08)
	tween.tween_property(_status, "modulate", base, 0.32).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


# =========================================================================
# Syntax highlighting
# =========================================================================

func _ensure_syntax_highlighter() -> CodeHighlighter:
	if _syntax_highlighter != null:
		return _syntax_highlighter
	var hl := CodeHighlighter.new()
	var settings: EditorSettings = null
	if _editor_interface != null:
		settings = _editor_interface.get_editor_settings()

	var keyword_color := _read_editor_color(settings, "text_editor/theme/highlighting/keyword_color", Color(1.0, 0.44, 0.52))
	var function_color := _read_editor_color(settings, "text_editor/theme/highlighting/function_color", Color(0.34, 0.67, 1.0))
	var number_color := _read_editor_color(settings, "text_editor/theme/highlighting/number_color", Color(0.6, 1.0, 0.6))
	var string_color := _read_editor_color(settings, "text_editor/theme/highlighting/string_color", Color(1.0, 0.85, 0.4))
	var comment_color := _read_editor_color(settings, "text_editor/theme/highlighting/comment_color", Color(0.5, 0.6, 0.5))
	var symbol_color := _read_editor_color(settings, "text_editor/theme/highlighting/symbol_color", Color(0.7, 0.7, 0.7))
	var base_type_color := _read_editor_color(settings, "text_editor/theme/highlighting/base_type_color", Color(0.4, 0.8, 0.8))
	var member_var_color := _read_editor_color(settings, "text_editor/theme/highlighting/member_variable_color", Color(0.8, 0.8, 0.6))

	hl.number_color = number_color
	hl.symbol_color = symbol_color
	hl.function_color = function_color
	hl.member_variable_color = member_var_color

	var keywords := [
		"if", "elif", "else", "for", "while", "match", "when", "break", "continue",
		"pass", "return", "await", "yield", "func", "class", "class_name", "extends",
		"var", "const", "enum", "signal", "static", "super", "self", "as", "is",
		"in", "and", "or", "not", "true", "false", "null", "void", "breakpoint",
		"preload", "load", "tool", "onready", "export", "get", "set"
	]
	for kw in keywords:
		hl.add_keyword_color(kw, keyword_color)

	var types := [
		"int", "float", "bool", "String", "StringName", "NodePath",
		"Vector2", "Vector2i", "Vector3", "Vector3i", "Vector4",
		"Rect2", "Rect2i", "Transform2D", "Transform3D", "Basis",
		"Color", "Array", "Dictionary", "PackedByteArray",
		"PackedInt32Array", "PackedFloat32Array", "PackedStringArray",
		"PackedVector2Array", "PackedVector3Array", "PackedColorArray",
		"Callable", "RID", "Object", "Node", "Node2D", "Node3D",
		"Control", "CanvasItem", "Resource", "SceneTree", "Variant",
		"Quaternion", "Plane", "AABB"
	]
	for tp in types:
		hl.add_keyword_color(tp, base_type_color)

	hl.add_color_region("\"\"\"", "\"\"\"", string_color, false)
	hl.add_color_region("\"", "\"", string_color, false)
	hl.add_color_region("'", "'", string_color, false)
	hl.add_color_region("#", "", comment_color, true)

	_syntax_highlighter = hl
	return _syntax_highlighter


func _read_editor_color(settings: EditorSettings, key: String, fallback: Color) -> Color:
	if settings == null:
		return fallback
	if not settings.has_setting(key):
		return fallback
	var value = settings.get_setting(key)
	if value is Color:
		return value
	return fallback
