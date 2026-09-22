@tool
extends ConfirmationDialog

signal blueprint_confirmed(id: String, title: String, phrases: Array, category: String, subcategory: String)

var _id_input: LineEdit = null
var _title_input: LineEdit = null
var _phrases_input: LineEdit = null
var _category_input: LineEdit = null
var _subcategory_input: LineEdit = null
var _error_label: Label = null


func _ready() -> void:
	title = "Save Node as Blueprint"
	ok_button_text = "Save"
	cancel_button_text = "Cancel"
	min_size = Vector2i(460, 320)
	_build_ui()
	confirmed.connect(_on_confirmed)
	canceled.connect(_on_canceled)


func _build_ui() -> void:
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)

	vbox.add_child(_make_label("ID (lowercase, digits, underscores):"))
	_id_input = LineEdit.new()
	_id_input.placeholder_text = "custom_my_node"
	vbox.add_child(_id_input)

	vbox.add_child(_make_label("Title:"))
	_title_input = LineEdit.new()
	_title_input.placeholder_text = "My Node"
	vbox.add_child(_title_input)

	vbox.add_child(_make_label("Phrases (comma-separated):"))
	_phrases_input = LineEdit.new()
	_phrases_input.placeholder_text = "my node, custom node"
	vbox.add_child(_phrases_input)

	vbox.add_child(_make_label("Category:"))
	_category_input = LineEdit.new()
	_category_input.text = "custom"
	vbox.add_child(_category_input)

	vbox.add_child(_make_label("Subcategory (optional):"))
	_subcategory_input = LineEdit.new()
	vbox.add_child(_subcategory_input)

	_error_label = Label.new()
	_error_label.modulate = Color(1, 0.5, 0.5)
	_error_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_error_label.visible = false
	vbox.add_child(_error_label)

	add_child(vbox)


func _make_label(text: String) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 12)
	return lbl


func prefill(id: String, title_text: String, phrases: String) -> void:
	if _id_input != null:
		_id_input.text = id
	if _title_input != null:
		_title_input.text = title_text
	if _phrases_input != null:
		_phrases_input.text = phrases
	if _category_input != null:
		_category_input.text = "custom"
	if _subcategory_input != null:
		_subcategory_input.text = ""
	if _error_label != null:
		_error_label.visible = false


func _on_canceled() -> void:
	if _error_label != null:
		_error_label.visible = false


func _on_confirmed() -> void:
	if _id_input == null or _title_input == null or _phrases_input == null:
		return
	var id := _id_input.text.strip_edges()
	var title_text := _title_input.text.strip_edges()
	var phrases_text := _phrases_input.text.strip_edges()
	var category := _category_input.text.strip_edges() if _category_input != null else "custom"
	var subcategory := _subcategory_input.text.strip_edges() if _subcategory_input != null else ""

	if id.is_empty():
		_show_error("ID is required.")
		return
	if not _is_valid_id(id):
		_show_error("ID must be lowercase letters, digits, and underscores only.")
		return
	if title_text.is_empty():
		_show_error("Title is required.")
		return
	if phrases_text.is_empty():
		_show_error("At least one phrase is required.")
		return

	var phrases: Array = []
	for part in phrases_text.split(",", false):
		var p := str(part).strip_edges()
		if not p.is_empty():
			phrases.append(p)
	if phrases.is_empty():
		_show_error("At least one phrase is required.")
		return

	if category.is_empty():
		category = "custom"

	_error_label.visible = false
	blueprint_confirmed.emit(id, title_text, phrases, category, subcategory)


func _is_valid_id(id: String) -> bool:
	if id.is_empty():
		return false
	for i in range(id.length()):
		var c := id[i]
		if (c >= "a" and c <= "z") or (c >= "0" and c <= "9") or c == "_":
			continue
		return false
	return true


func _show_error(msg: String) -> void:
	_error_label.text = msg
	_error_label.visible = true
