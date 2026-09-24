@tool
extends AcceptDialog

var _text: TextEdit = null


func _ready() -> void:
	title = "Library Report"
	ok_button_text = "Close"
	min_size = Vector2i(720, 620)
	_build_ui()


func _build_ui() -> void:
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)

	var header := Label.new()
	header.text = "A snapshot of every file and entry in your library."
	header.add_theme_font_size_override("font_size", 12)
	vbox.add_child(header)

	_text = TextEdit.new()
	_text.editable = false
	_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_text.custom_minimum_size = Vector2(700, 500)
	_text.add_theme_font_size_override("font_size", 11)
	vbox.add_child(_text)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)

	var copy_btn := Button.new()
	copy_btn.text = "Copy to Clipboard"
	copy_btn.pressed.connect(_on_copy_pressed)
	row.add_child(copy_btn)

	var save_btn := Button.new()
	save_btn.text = "Save to File..."
	save_btn.pressed.connect(_on_save_pressed)
	row.add_child(save_btn)

	vbox.add_child(row)
	add_child(vbox)


func set_report(text: String) -> void:
	if _text != null:
		_text.text = text


func _on_copy_pressed() -> void:
	if _text != null:
		DisplayServer.clipboard_set(_text.text)


func _on_save_pressed() -> void:
	var dialog := FileDialog.new()
	dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.add_filter("*.txt", "Text files")
	dialog.title = "Save Library Report"
	dialog.current_file = "gdse_library_report.txt"
	dialog.file_selected.connect(_on_save_path_selected)
	add_child(dialog)
	dialog.popup_centered_ratio(0.7)


func _on_save_path_selected(path: String) -> void:
	if _text == null:
		return
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(_text.text)
	file.close()
