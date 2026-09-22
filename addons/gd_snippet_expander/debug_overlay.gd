@tool
extends Node

const GDASELibraryScript := preload("res://addons/gd_snippet_expander/library.gd")

const OVERLAY_ID := "gdse_debug_overlay"


func install(editor_interface: EditorInterface) -> Dictionary:
	var scene_root: Node = editor_interface.get_edited_scene_root()
	if scene_root == null:
		return {"ok": false, "message": "No scene open."}

	if scene_root.has_node(OVERLAY_ID):
		return {"ok": false, "message": "Debug overlay is already in this scene."}

	var layer := CanvasLayer.new()
	layer.name = OVERLAY_ID
	layer.layer = 100

	var panel := PanelContainer.new()
	panel.name = "Panel"
	panel.anchor_left = 0.0
	panel.anchor_top = 0.0
	panel.anchor_right = 0.0
	panel.anchor_bottom = 0.0
	panel.offset_left = 8
	panel.offset_top = 8
	panel.offset_right = 240
	panel.offset_bottom = 120

	var label := Label.new()
	label.name = "Label"
	label.text = "FPS: --"
	label.add_theme_font_size_override("font_size", 12)
	panel.add_child(label)

	var script := _build_runtime_script()
	var s := GDScript.new()
	s.source_code = script
	s.reload()
	layer.set_script(s)
	layer.name = OVERLAY_ID

	var ur: EditorUndoRedoManager = editor_interface.get_editor_undo_redo()
	ur.create_action("Install Debug Overlay")
	ur.add_do_method(scene_root, "add_child", layer)
	ur.add_do_method(layer, "set_owner", scene_root)
	ur.add_do_method(label, "set_owner", scene_root)
	ur.add_do_method(panel, "set_owner", scene_root)
	ur.add_do_reference(layer)
	ur.add_undo_method(scene_root, "remove_child", layer)
	ur.commit_action()

	return {"ok": true, "message": "Debug overlay installed. Press F3 in-game to toggle."}


func remove(editor_interface: EditorInterface) -> Dictionary:
	var scene_root: Node = editor_interface.get_edited_scene_root()
	if scene_root == null:
		return {"ok": false, "message": "No scene open."}
	if not scene_root.has_node(OVERLAY_ID):
		return {"ok": false, "message": "No debug overlay in this scene."}
	var layer := scene_root.get_node(OVERLAY_ID)
	var ur: EditorUndoRedoManager = editor_interface.get_editor_undo_redo()
	ur.create_action("Remove Debug Overlay")
	ur.add_do_method(scene_root, "remove_child", layer)
	ur.add_undo_method(scene_root, "add_child", layer)
	ur.add_undo_method(layer, "set_owner", scene_root)
	ur.commit_action()
	return {"ok": true, "message": "Debug overlay removed."}


func _build_runtime_script() -> String:
	return """extends CanvasLayer

var _label: Label = null
var _visible_state: bool = true

func _ready() -> void:
	_label = $Panel/Label
	if _label == null:
		return
	_label.text = "FPS: --"

func _process(_delta: float) -> void:
	if _label == null:
		return
	if not _visible_state:
		_label.text = ""
		return
	var fps := Engine.get_frames_per_second()
	var draw_calls := Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
	var mem_mb := Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0
	var nodes := Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
	_label.text = "FPS: %d\\nDraw calls: %d\\nMemory: %.1f MB\\nNodes: %d" % [fps, draw_calls, mem_mb, nodes]

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F3:
			_visible_state = not _visible_state
			$Panel.visible = _visible_state
"""
