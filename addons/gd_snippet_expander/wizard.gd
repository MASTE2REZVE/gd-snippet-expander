@tool
extends Node

signal wizard_finished(template_id: String)


func should_run(library) -> bool:
	if library.get_setting("wizard_done", false):
		return false
	if library.total_count() == 0:
		return false
	return true


func mark_done(library) -> void:
	library.set_setting("wizard_done", true)


func build_dialog(library) -> AcceptDialog:
	var dialog := AcceptDialog.new()
	dialog.title = "Welcome to Snippet Expander"
	dialog.dialog_text = "Pick a starter to set up your scene. You can also skip this and use the panel directly."
	dialog.ok_button_text = "Close"
	dialog.min_size = Vector2i(500, 400)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	vbox.custom_minimum_size = Vector2(460, 320)

	var intro := Label.new()
	intro.text = "What kind of game are you making?"
	intro.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(intro)

	var template_ids: Array = library.list_template_ids()
	if template_ids.is_empty():
		var empty := Label.new()
		empty.text = "No starter templates available."
		vbox.add_child(empty)
	else:
		for tid in template_ids:
			var t: Dictionary = library.get_template(tid)
			if t.is_empty():
				continue
			vbox.add_child(_build_template_button(str(tid), t))

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 8)
	vbox.add_child(spacer)

	var skip := Button.new()
	skip.text = "Skip — I'll figure it out"
	skip.pressed.connect(func(): dialog.hide())
	vbox.add_child(skip)

	dialog.add_child(vbox)
	return dialog


func _build_template_button(tid: String, template: Dictionary) -> Control:
	var panel := PanelContainer.new()

	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 2)

	var title := Label.new()
	title.text = str(template.get("title", tid))
	title.add_theme_font_size_override("font_size", 16)
	inner.add_child(title)

	var description := Label.new()
	description.text = str(template.get("description", ""))
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inner.add_child(description)

	var dim := str(template.get("dimension", ""))
	var diff := str(template.get("difficulty", ""))
	var meta := ""
	if not dim.is_empty():
		meta += dim.to_upper()
	if not diff.is_empty():
		if not meta.is_empty():
			meta += "  •  "
		meta += diff
	if not meta.is_empty():
		var meta_label := Label.new()
		meta_label.text = meta
		meta_label.add_theme_font_size_override("font_size", 11)
		meta_label.modulate = Color(0.7, 0.7, 0.7)
		inner.add_child(meta_label)

	var apply := Button.new()
	apply.text = "Use this starter"
	apply.pressed.connect(func(): wizard_finished.emit(tid))
	inner.add_child(apply)

	panel.add_child(inner)
	return panel
