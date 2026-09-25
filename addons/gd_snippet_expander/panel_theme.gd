@tool
extends RefCounted

# Programmatic theme for the Snippet Expander panel.
# Built in code rather than shipped as a .tres so every value is
# visible and tweakable without a resource editor round-trip.

# --- Palette ---------------------------------------------------------
# Values chosen to sit naturally inside Godot's own dark editor theme.

const BG_PANEL      := Color(0.13, 0.13, 0.15)
const BG_INPUT      := Color(0.075, 0.075, 0.09)
const BG_HOVER      := Color(0.18, 0.18, 0.21)
const BG_PRESSED    := Color(0.22, 0.34, 0.55)
const BG_DISABLED   := Color(0.11, 0.11, 0.12)
const BG_SELECTED   := Color(0.19, 0.24, 0.35)

const ACCENT        := Color(0.28, 0.51, 0.91)
const ACCENT_SOFT   := Color(0.28, 0.51, 0.91, 0.35)
const ACCENT_STRONG := Color(0.42, 0.65, 1.00)
const ACCENT_DIM    := Color(0.24, 0.38, 0.62)

const TEXT          := Color(0.88, 0.88, 0.90)
const TEXT_DIM      := Color(0.60, 0.60, 0.64)
const TEXT_MUTED    := Color(0.40, 0.40, 0.44)
const BORDER        := Color(0.20, 0.20, 0.23)
const BORDER_FOCUS  := Color(0.35, 0.55, 0.90)

# --- Sizing ----------------------------------------------------------
# Base font size for labels, buttons, tabs, trees.
const FONT_SIZE := 28
# Font size for code and details text areas — monospace, slightly smaller.
const MONO_FONT_SIZE := 28
# Padding across the whole panel. Increase both to zoom everything in.
const PAD_H := 13
const PAD_V := 13
const PAD_PANEL := 13
const TAB_PAD_H := 25
const TAB_PAD_V := 17
const LINE_EDIT_PAD_V := 18


func build() -> Theme:
	print("GDSE theme built with FONT_SIZE=", FONT_SIZE)
	var t := Theme.new()
	t.default_font_size = FONT_SIZE
	_setup_label(t)
	_setup_button(t)
	_setup_line_edit(t)
	_setup_text_edit(t)
	_setup_code_edit(t)
	_setup_tab_container(t)
	_setup_tree(t)
	_setup_item_list(t)
	_setup_separator(t)
	_setup_scroll(t)
	return t


# =========================================================================
# Widgets
# =========================================================================

func _setup_label(t: Theme) -> void:
	t.set_color("font_color", "Label", TEXT)
	t.set_font_size("font_size", "Label", FONT_SIZE)


func _setup_button(t: Theme) -> void:
	var normal := _flat(Color.TRANSPARENT, 6, BORDER, 1)
	_pad(normal, PAD_H, PAD_V)
	t.set_stylebox("normal", "Button", normal)

	var hover := _flat(BG_HOVER, 6, BORDER, 1)
	_pad(hover, PAD_H, PAD_V)
	t.set_stylebox("hover", "Button", hover)

	var pressed := _flat(BG_PRESSED, 6, ACCENT, 1)
	_pad(pressed, PAD_H, PAD_V)
	t.set_stylebox("pressed", "Button", pressed)

	var hover_pressed := _flat(ACCENT_DIM, 6, ACCENT_STRONG, 1)
	_pad(hover_pressed, PAD_H, PAD_V)
	t.set_stylebox("hover_pressed", "Button", hover_pressed)

	var disabled := _flat(BG_DISABLED, 6, BORDER, 1)
	_pad(disabled, PAD_H, PAD_V)
	t.set_stylebox("disabled", "Button", disabled)

	var focus := _flat(Color.TRANSPARENT, 6, ACCENT_SOFT, 2)
	_pad(focus, PAD_H, PAD_V)
	t.set_stylebox("focus", "Button", focus)

	t.set_color("font_color", "Button", TEXT)
	t.set_color("font_hover_color", "Button", Color(1, 1, 1))
	t.set_color("font_pressed_color", "Button", Color(1, 1, 1))
	t.set_color("font_hover_pressed_color", "Button", Color(1, 1, 1))
	t.set_color("font_focus_color", "Button", TEXT)
	t.set_color("font_disabled_color", "Button", TEXT_MUTED)
	t.set_font_size("font_size", "Button", FONT_SIZE)


func _setup_line_edit(t: Theme) -> void:
	var normal := _flat(BG_INPUT, 6, BORDER, 1)
	_pad(normal, PAD_H, PAD_V + 2)
	t.set_stylebox("normal", "LineEdit", normal)

	var focus := _flat(BG_INPUT, 6, BORDER_FOCUS, 2)
	_pad(focus, PAD_H, PAD_V + 2)
	t.set_stylebox("focus", "LineEdit", focus)

	var read_only := _flat(BG_DISABLED, 6, BORDER, 1)
	_pad(read_only, PAD_H, PAD_V + 2)
	t.set_stylebox("read_only", "LineEdit", read_only)

	t.set_color("font_color", "LineEdit", TEXT)
	t.set_color("font_placeholder_color", "LineEdit", TEXT_MUTED)
	t.set_color("font_selected_color", "LineEdit", TEXT)
	t.set_color("caret_color", "LineEdit", ACCENT_STRONG)
	t.set_color("selection_color", "LineEdit", ACCENT_SOFT)
	t.set_font_size("font_size", "LineEdit", FONT_SIZE + 2)


func _setup_text_edit(t: Theme) -> void:
	var normal := _flat(BG_INPUT, 6, BORDER, 1)
	_pad(normal, PAD_H, PAD_V + 2)
	t.set_stylebox("normal", "TextEdit", normal)
	t.set_stylebox("focus", "TextEdit", normal)
	t.set_stylebox("read_only", "TextEdit", normal)

	t.set_color("font_color", "TextEdit", TEXT)
	t.set_color("font_readonly_color", "TextEdit", TEXT)
	t.set_color("font_placeholder_color", "TextEdit", TEXT_MUTED)
	t.set_color("caret_color", "TextEdit", ACCENT_STRONG)
	t.set_color("selection_color", "TextEdit", ACCENT_SOFT)
	t.set_font_size("font_size", "TextEdit", MONO_FONT_SIZE)


func _setup_code_edit(t: Theme) -> void:
	var normal := _flat(BG_INPUT, 6, BORDER, 1)
	_pad(normal, PAD_H, PAD_V + 2)
	t.set_stylebox("normal", "CodeEdit", normal)
	t.set_stylebox("focus", "CodeEdit", normal)
	t.set_stylebox("read_only", "CodeEdit", normal)

	t.set_color("font_color", "CodeEdit", Color(0.86, 0.90, 0.92))
	t.set_color("font_readonly_color", "CodeEdit", Color(0.86, 0.90, 0.92))
	t.set_color("caret_color", "CodeEdit", ACCENT_STRONG)
	t.set_color("selection_color", "CodeEdit", ACCENT_SOFT)
	t.set_font_size("font_size", "CodeEdit", MONO_FONT_SIZE)


func _setup_tab_container(t: Theme) -> void:
	t.set_stylebox("tabbar_background", "TabContainer", StyleBoxEmpty.new())

	var tab_selected := StyleBoxFlat.new()
	tab_selected.bg_color = Color.TRANSPARENT
	tab_selected.border_width_bottom = 3
	tab_selected.border_color = ACCENT_STRONG
	tab_selected.content_margin_left = TAB_PAD_H
	tab_selected.content_margin_right = TAB_PAD_H
	tab_selected.content_margin_top = TAB_PAD_V
	tab_selected.content_margin_bottom = TAB_PAD_V
	t.set_stylebox("tab_selected", "TabContainer", tab_selected)

	var tab_unselected := StyleBoxFlat.new()
	tab_unselected.bg_color = Color.TRANSPARENT
	tab_unselected.content_margin_left = TAB_PAD_H
	tab_unselected.content_margin_right = TAB_PAD_H
	tab_unselected.content_margin_top = TAB_PAD_V
	tab_unselected.content_margin_bottom = TAB_PAD_V
	t.set_stylebox("tab_unselected", "TabContainer", tab_unselected)

	var tab_hovered := _flat(BG_HOVER, 4)
	tab_hovered.content_margin_left = TAB_PAD_H
	tab_hovered.content_margin_right = TAB_PAD_H
	tab_hovered.content_margin_top = TAB_PAD_V
	tab_hovered.content_margin_bottom = TAB_PAD_V
	t.set_stylebox("tab_hovered", "TabContainer", tab_hovered)

	var panel := _flat(BG_PANEL, 6, BORDER, 1)
	_pad(panel, PAD_PANEL, PAD_PANEL)
	t.set_stylebox("panel", "TabContainer", panel)

	t.set_color("font_selected_color", "TabContainer", TEXT)
	t.set_color("font_unselected_color", "TabContainer", TEXT_DIM)
	t.set_color("font_hovered_color", "TabContainer", TEXT)
	t.set_font_size("font_size", "TabContainer", FONT_SIZE)


func _setup_tree(t: Theme) -> void:
	var panel := _flat(BG_INPUT, 6, BORDER, 1)
	_pad(panel, 8, 8)
	t.set_stylebox("panel", "Tree", panel)

	var selected := _flat(BG_SELECTED, 4)
	selected.content_margin_left = 6
	selected.content_margin_right = 6
	selected.content_margin_top = 4
	selected.content_margin_bottom = 4
	t.set_stylebox("selected", "Tree", selected)
	t.set_stylebox("selected_focus", "Tree", selected)

	var cursor := _flat(Color.TRANSPARENT, 4, ACCENT_STRONG, 1)
	t.set_stylebox("cursor", "Tree", cursor)
	t.set_stylebox("cursor_unfocused", "Tree", cursor)

	t.set_color("font_color", "Tree", TEXT)
	t.set_color("font_selected_color", "Tree", TEXT)
	t.set_color("font_hovered_color", "Tree", Color(1, 1, 1))
	t.set_color("guide_color", "Tree", BORDER)
	t.set_font_size("font_size", "Tree", FONT_SIZE)


func _setup_item_list(t: Theme) -> void:
	var panel := _flat(BG_INPUT, 6, BORDER, 1)
	_pad(panel, 6, 6)
	t.set_stylebox("panel", "ItemList", panel)

	var selected := _flat(BG_SELECTED, 4)
	selected.content_margin_left = 6
	selected.content_margin_right = 6
	selected.content_margin_top = 4
	selected.content_margin_bottom = 4
	t.set_stylebox("selected", "ItemList", selected)
	t.set_stylebox("selected_focus", "ItemList", selected)

	var cursor := _flat(Color.TRANSPARENT, 0)
	t.set_stylebox("cursor", "ItemList", cursor)
	t.set_stylebox("cursor_unfocused", "ItemList", cursor)

	t.set_color("font_color", "ItemList", TEXT)
	t.set_color("font_selected_color", "ItemList", TEXT)
	t.set_font_size("font_size", "ItemList", FONT_SIZE)


func _setup_separator(t: Theme) -> void:
	var sb := StyleBoxLine.new()
	sb.color = BORDER
	sb.thickness = 1
	t.set_stylebox("separator", "HSeparator", sb)
	t.set_constant("separation", "HSeparator", 4)


func _setup_scroll(t: Theme) -> void:
	t.set_stylebox("panel", "ScrollContainer", StyleBoxEmpty.new())


# =========================================================================
# Helpers
# =========================================================================

func _flat(bg: Color, radius: int = 0, border_color: Color = Color.TRANSPARENT, border_width: int = 0) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	if radius > 0:
		sb.corner_radius_top_left = radius
		sb.corner_radius_top_right = radius
		sb.corner_radius_bottom_left = radius
		sb.corner_radius_bottom_right = radius
	if border_width > 0:
		sb.border_width_left = border_width
		sb.border_width_right = border_width
		sb.border_width_top = border_width
		sb.border_width_bottom = border_width
		sb.border_color = border_color
	return sb


func _pad(sb: StyleBoxFlat, horizontal: int, vertical: int) -> void:
	sb.content_margin_left = horizontal
	sb.content_margin_right = horizontal
	sb.content_margin_top = vertical
	sb.content_margin_bottom = vertical
