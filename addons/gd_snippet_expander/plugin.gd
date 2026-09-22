@tool
extends EditorPlugin

const PANEL_SCENE_PATH := "res://addons/gd_snippet_expander/panel.tscn"
const PANEL_TITLE := "Snippet Expander"
const PLUGIN_VERSION := "1.1.0"
const TOOL_MENU_ITEM := "Save Selected Node as Blueprint..."

var _panel: Control = null


func _enter_tree() -> void:
	_load_panel()
	add_tool_menu_item(TOOL_MENU_ITEM, _on_save_blueprint_tool)


func _exit_tree() -> void:
	remove_tool_menu_item(TOOL_MENU_ITEM)
	_unload_panel()


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


func get_plugin_version() -> String:
	return PLUGIN_VERSION
