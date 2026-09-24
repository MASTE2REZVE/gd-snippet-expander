@tool
extends EditorPlugin

const PANEL_SCENE_PATH := "res://addons/gd_snippet_expander/panel.tscn"
const REPORT_SCRIPT_PATH := "res://addons/gd_snippet_expander/library_report.gd"
const REPORT_DIALOG_PATH := "res://addons/gd_snippet_expander/report_dialog.gd"
const PANEL_TITLE := "Snippet Expander"
const PLUGIN_VERSION := "1.1.0"
const TOOL_MENU_SAVE := "Save Selected Node as Blueprint..."
const TOOL_MENU_REPORT := "Library Report..."

var _panel: Control = null
var _report_dialog: AcceptDialog = null


func _enter_tree() -> void:
	_load_panel()
	add_tool_menu_item(TOOL_MENU_SAVE, _on_save_blueprint_tool)
	add_tool_menu_item(TOOL_MENU_REPORT, _on_library_report_tool)


func _exit_tree() -> void:
	remove_tool_menu_item(TOOL_MENU_SAVE)
	remove_tool_menu_item(TOOL_MENU_REPORT)
	_unload_panel()
	if _report_dialog != null:
		_report_dialog.queue_free()
		_report_dialog = null


func _load_panel() -> void:
	var scene := load(PANEL_SCENE_PATH)
	if scene == null:
		push_error("GD Snippet Expander: could not load panel scene at " + PANEL_SCENE_PATH)
		return
	_panel = scene.instantiate()
	if _panel == null:
		push_error("GD Snippet Expander: could not instantiate panel.")
		return
	if _panel.has_method("set_editor_interface"):
		_panel.set_editor_interface(get_editor_interface())
	add_control_to_bottom_panel(_panel, PANEL_TITLE)


func _unload_panel() -> void:
	if _panel != null:
		remove_control_from_bottom_panel(_panel)
		_panel.queue_free()
		_panel = null


func _on_save_blueprint_tool() -> void:
	if _panel == null:
		return
	if _panel.has_method("prompt_save_blueprint"):
		_panel.prompt_save_blueprint()


func _on_library_report_tool() -> void:
	var report_script = load(REPORT_SCRIPT_PATH)
	if report_script == null:
		push_error("GD Snippet Expander: could not load library_report.gd")
		return
	var report = report_script.new()
	if report == null or not report.has_method("generate_report"):
		push_error("GD Snippet Expander: library_report.gd missing generate_report().")
		return
	var text: String = report.generate_report()

	if _report_dialog == null:
		var dialog_script = load(REPORT_DIALOG_PATH)
		if dialog_script == null:
			print(text)
			return
		_report_dialog = dialog_script.new()
		add_child(_report_dialog)

	if _report_dialog.has_method("set_report"):
		_report_dialog.set_report(text)
	_report_dialog.popup_centered_ratio(0.85)


func get_plugin_version() -> String:
	return PLUGIN_VERSION
