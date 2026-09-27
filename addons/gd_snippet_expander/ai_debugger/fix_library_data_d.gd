# res://addons/gd_snippet_expander/ai_debugger/fix_library_data_d.gd
@tool
class_name FixLibraryDataD
extends RefCounted

## Fix records, volume D: UI, health/damage, misc.
##
## Part of the GD Snippet Expander mini AI debugger (v1.6).
## Forty-one curated records covering Control nodes and layout,
## health and damage systems, and a batch of misc pitfalls.
##
## Usage from the plugin loader:
##   var lib := FixLibrary.new()
##   lib.load_all()
##   FixLibraryDataA.register_into(lib)
##   FixLibraryDataB.register_into(lib)
##   FixLibraryDataC.register_into(lib)
##   FixLibraryDataD.register_into(lib)   # this file

# --- public entry points -----------------------------------------------

static func register_into(lib: FixLibrary) -> int:
	return lib.register_records(records())


static func records() -> Array:
	var out: Array = []

	# ===================================================================
	# UI (14)
	# ===================================================================

	out.append({
		"id": "ui_control_anchor_basics",
		"title": "Control node doesn't stay where you put it",
		"category": "ui",
		"phrases": [
			"ui moves when window resizes",
			"button position wrong",
			"anchors not working",
			"ui shifts on screen",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "Control"},
			{"kind": "identifier", "value": "anchors_preset", "negate": true},
		],
		"candidates": [{
			"code": "# In the inspector, set Layout -> Anchors Preset to something\n# like \"Center\", \"Top Left\", \"Full Rect\".\n# Or from code:\nanchors_preset = Control.PRESET_CENTER\n",
			"description": "Control nodes position themselves relative to their anchors. Without a preset the position is relative to the top-left and won't resize. Set the preset in the Layout menu.",
			"confidence": 0.80,
		}],
	})

	out.append({
		"id": "ui_container_vs_manual_position",
		"title": "Children of a Container ignore manual positions",
		"category": "ui",
		"phrases": [
			"container overrides position",
			"can't move ui node",
			"margin container ignores position",
			"layout fights me",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "Container"},
		],
		"candidates": [{
			"code": "# A Container (VBoxContainer, HBoxContainer, MarginContainer, ...)\n# automatically positions its children and ignores manual offsets.\n# If you need free placement, don't use a Container — use a plain\n# Control with anchor presets instead.\n",
			"description": "Containers own their children's layout. Setting position on a child of a container has no effect — the container resets it every frame.",
			"confidence": 0.78,
		}],
	})

	out.append({
		"id": "ui_button_signal",
		"title": "Connect a button's pressed signal",
		"category": "ui",
		"phrases": [
			"button click",
			"connect button",
			"on pressed signal",
			"button doesn't respond",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "Button"},
			{"kind": "identifier", "value": "pressed"},
		],
		"candidates": [{
			"code": "func _ready() -> void:\n\t$StartButton.pressed.connect(_on_start_pressed)\n\nfunc _on_start_pressed() -> void:\n\tget_tree().change_scene_to_file(\"res://game.tscn\")\n",
			"description": "Button emits pressed with no arguments. Connect it in _ready with the Callable form. button_down and button_up are also available.",
			"confidence": 0.80,
		}],
	})

	out.append({
		"id": "ui_health_bar_value",
		"title": "Drive a ProgressBar from a health value",
		"category": "ui",
		"phrases": [
			"health bar",
			"progress bar health",
			"health ui update",
			"healthbar code",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "ProgressBar"},
		],
		"candidates": [{
			"code": "$HealthBar.max_value = max_health\n$HealthBar.value = current_health\n# Or with a TextureProgressBar:\n$HealthBar.max_value = max_health\n$HealthBar.value = current_health\n",
			"description": "ProgressBar and TextureProgressBar both expose max_value and value. Update both whenever health changes. Bind the update to a health_changed signal.",
			"confidence": 0.78,
		}],
	})

	out.append({
		"id": "ui_tween_fade",
		"title": "Fade a UI element in or out with a Tween",
		"category": "ui",
		"phrases": [
			"fade ui",
			"fade in menu",
			"fade effect ui",
			"fade out panel",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "modulate"}
		],
		"candidates": [{
			"code": "var t: Tween = create_tween()\nt.tween_property($Menu, \"modulate:a\", 0.0, 0.3)\n",
			"description": "Tween modulate.a from current to 0 to fade out. create_tween() requires the node to be inside the tree. Tween auto-frees when done.",
			"confidence": 0.75,
		}],
	})

	out.append({
		"id": "ui_pause_menu",
		"title": "Pause the game and show a menu",
		"category": "ui",
		"phrases": [
			"pause menu",
			"pause game",
			"pause button",
			"freeze game",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "paused"},
		],
		"candidates": [{
			"code": "func _on_pause_pressed() -> void:\n\tget_tree().paused = true\n\t$PauseMenu.visible = true\n\n# The menu itself must have process_mode = PROCESS_MODE_WHEN_PAUSED\n# (or PROCESS_MODE_ALWAYS) so its buttons still receive input.\n",
			"description": "get_tree().paused stops _process and _physics_process on nodes with the default process mode. Nodes with PROCESS_MODE_WHEN_PAUSED or ALWAYS keep running.",
			"confidence": 0.78,
		}],
	})

	out.append({
		"id": "ui_scale_with_screen",
		"title": "UI scales with the window or device resolution",
		"category": "ui",
		"phrases": [
			"ui too small on high dpi",
			"ui not scaling",
			"ui fits screen",
			"ui sizing",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "stretch_mode"},
		],
		"candidates": [{
			"code": "# Project Settings -> Display -> Window:\n#   Stretch Mode: canvas_items\n#   Stretch Aspect: expand\n#   Base Size: 1920 x 1080\n# This scales UI uniformly across resolutions.\n",
			"description": "canvas_items stretch scales 2D and UI to match the window. expand aspect handles ultrawide and tall screens gracefully.",
			"confidence": 0.72,
		}],
	})

	out.append({
		"id": "ui_mouse_filter",
		"title": "UI covers the game and swallows clicks",
		"category": "ui",
		"phrases": [
			"ui blocks input",
			"can't click game",
			"ui covers gameplay",
			"mouse filter ignored",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "mouse_filter"}
		],
		"candidates": [{
			"code": "# On any Control that should let clicks pass through:\nmouse_filter = Control.MOUSE_FILTER_IGNORE\n# MOUSE_FILTER_PASS lets clicks through but still shows hover.\n# MOUSE_FILTER_STOP (default) blocks all clicks.\n",
			"description": "Control nodes default to MOUSE_FILTER_STOP, which consumes clicks in their rect. Set IGNORE on decorative overlays, or PASS if you want hover feedback.",
			"confidence": 0.78,
		}],
	})

	out.append({
		"id": "ui_focus_neighbors",
		"title": "Keyboard navigation between UI elements",
		"category": "ui",
		"phrases": [
			"ui keyboard navigation",
			"tab key ui",
			"gamepad ui navigation",
			"focus next control",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "focus_neighbor"},
		],
		"candidates": [{
			"code": "# In the editor, select each Control and set:\n#   focus_neighbor_top / bottom / left / right\n#   focus_next / focus_previous\n# to NodePaths of sibling Controls.\n# Or call from code:\n$Button.grab_focus()\n",
			"description": "Godot uses focus_neighbor_* to decide where arrow keys and D-pad move focus. Set them in the editor for menus. grab_focus() picks the initial focused element.",
			"confidence": 0.68,
		}],
	})

	out.append({
		"id": "ui_line_edit_text_submitted",
		"title": "React to Enter in a LineEdit",
		"category": "ui",
		"phrases": [
			"line edit enter",
			"text submitted",
			"input field enter key",
			"text field submit",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "LineEdit"},
		],
		"candidates": [{
			"code": "$NameInput.text_submitted.connect(_on_name_submitted)\n\nfunc _on_name_submitted(new_text: String) -> void:\n\tprint(\"Player entered: \", new_text)\n",
			"description": "LineEdit emits text_submitted(text) when the user presses Enter. text_changed fires on every keystroke.",
			"confidence": 0.75,
		}],
	})

	out.append({
		"id": "ui_scroll_container",
		"title": "Content doesn't scroll in a ScrollContainer",
		"category": "ui",
		"phrases": [
			"scroll doesn't work",
			"scroll container not scrolling",
			"content clipped no scroll",
			"scroll list",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "ScrollContainer"},
		],
		"candidates": [{
			"code": "# ScrollContainer needs exactly one child that's larger than itself.\n# That child should have size_flags_horizontal = SIZE_EXPAND_FILL\n# and the ScrollContainer's horizontal_scroll_mode controls behavior.\n# Common mistake: putting multiple children directly under the\n# ScrollContainer. Wrap them in a VBoxContainer first.\n",
			"description": "ScrollContainer scrolls its single child. Wrap multiple items in a VBoxContainer (or similar) and add that as the child.",
			"confidence": 0.72,
		}],
	})

	out.append({
		"id": "ui_rich_text_bbcode",
		"title": "Colored or styled text in a Label",
		"category": "ui",
		"phrases": [
			"colored label text",
			"rich text label",
			"bbcode label",
			"format label",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "RichTextLabel"},
		],
		"candidates": [{
			"code": "$Label.text = \"[color=red]DANGER[/color]\"   # on RichTextLabel only\n# To enable BBCode:\n$Label.bbcode_enabled = true\n",
			"description": "Plain Label doesn't parse BBCode. Use RichTextLabel and enable bbcode_enabled for color, bold, italic, and other formatting.",
			"confidence": 0.75,
		}],
	})

	out.append({
		"id": "ui_custom_font_size",
		"title": "Change font size on a Label or Button",
		"category": "ui",
		"phrases": [
			"font size label",
			"bigger text button",
			"change ui font size",
			"text too small",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "theme_override_font_size"},
		],
		"candidates": [{
			"code": "$Label.add_theme_font_size_override(\"font_size\", 32)\n# Or in the inspector: Theme Overrides -> Font Sizes -> font_size\n",
			"description": "Per-node font size lives in theme overrides. add_theme_font_size_override sets it from code.",
			"confidence": 0.72,
		}],
	})

	out.append({
		"id": "ui_show_hide_instantly",
		"title": "Toggle visibility of a UI element",
		"category": "ui",
		"phrases": [
			"show hide ui",
			"toggle visibility",
			"hide panel",
			"show menu",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "visible"},
		],
		"candidates": [{
			"code": "$Panel.visible = not $Panel.visible\n# Or explicitly:\n$Panel.show()\n$Panel.hide()\n",
			"description": "Control.visible also controls input handling — a hidden Control doesn't receive clicks.",
			"confidence": 0.80,
		}],
	})

	# ===================================================================
	# HEALTH (13)
	# ===================================================================

	out.append({
		"id": "health_damage_signature",
		"title": "Standard damage() function signature",
		"category": "health",
		"phrases": [
			"damage function",
			"take damage",
			"apply damage",
			"hurt function",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "health"}
		],
		"candidates": [{
			"code": "signal health_changed(old_value: int, new_value: int)\nsignal died()\n\nvar max_health: int = 100\nvar current_health: int = 100\n\nfunc take_damage(amount: int) -> void:\n\tif amount <= 0:\n\t\treturn\n\tvar old: int = current_health\n\tcurrent_health = max(current_health - amount, 0)\n\thealth_changed.emit(old, current_health)\n\tif current_health == 0:\n\t\tdied.emit()\n",
			"description": "The conventional pattern: take_damage(amount), clamp to zero, emit health_changed with old and new, then emit died when it hits zero.",
			"confidence": 0.80,
		}],
	})

	out.append({
		"id": "health_death_signal",
		"title": "React to death exactly once",
		"category": "health",
		"phrases": [
			"death handling",
			"on death",
			"player dies twice",
			"death signal",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "died"},
		],
		"candidates": [{
			"code": "var _dead: bool = false\n\nfunc take_damage(amount: int) -> void:\n\tif _dead:\n\t\treturn\n\tcurrent_health = max(current_health - amount, 0)\n\tif current_health == 0:\n\t\t_dead = true\n\t\tdied.emit()\n",
			"description": "Guard the damage function so a second hit on a dead entity is a no-op. Otherwise the died signal fires multiple times and any handlers run repeatedly.",
			"confidence": 0.78,
		}],
	})

	out.append({
		"id": "health_invulnerability_frames",
		"title": "Invulnerability window after taking damage",
		"category": "health",
		"phrases": [
			"invulnerability after hit",
			"iframes",
			"damage cooldown",
			"invincible after damage",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "invulnerable", "negate": true},
		],
		"candidates": [{
			"code": "var _invulnerable_time: float = 0.0\nvar invulnerability_duration: float = 0.5\n\nfunc take_damage(amount: int) -> void:\n\tif _invulnerable_time > 0.0:\n\t\treturn\n\tcurrent_health -= amount\n\t_invulnerable_time = invulnerability_duration\n\nfunc _process(delta: float) -> void:\n\t_invulnerable_time = max(_invulnerable_time - delta, 0.0)\n",
			"description": "Track a cooldown timer. Refuse damage while it's above zero. Decrement in _process. Prevents multi-hit attacks from stacking.",
			"confidence": 0.78,
		}],
	})

	out.append({
		"id": "health_heal_clamp",
		"title": "Heal clamps to max health",
		"category": "health",
		"phrases": [
			"health over max",
			"healing too much",
			"hp above max",
			"clamp health",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "heal"},
		],
		"candidates": [{
			"code": "func heal(amount: int) -> void:\n\tif amount <= 0:\n\t\treturn\n\tvar old: int = current_health\n\tcurrent_health = min(current_health + amount, max_health)\n\thealth_changed.emit(old, current_health)\n",
			"description": "Always clamp healing to max_health. Emit health_changed so the UI updates and don't emit if the value didn't change (optional).",
			"confidence": 0.80,
		}],
	})

	out.append({
		"id": "health_negative_values",
		"title": "Health can't go negative",
		"category": "health",
		"phrases": [
			"health below zero",
			"negative health",
			"health goes negative",
			"clamp damage",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "current_health"},
		],
		"candidates": [{
			"code": "current_health = max(current_health - amount, 0)\n",
			"description": "Clamp to zero every time. Otherwise a big hit leaves health at -50, and any code that checks `health <= 0` continues to fire damage effects.",
			"confidence": 0.82,
		}],
	})

	out.append({
		"id": "health_signal_on_change",
		"title": "Health bar not updating?",
		"category": "health",
		"phrases": [
			"health bar not updating",
			"ui doesn't reflect health",
			"health ui stale",
			"health signal missing",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "health_changed"},
		],
		"candidates": [{
			"code": "signal health_changed(old_value: int, new_value: int)\n\nfunc take_damage(amount: int) -> void:\n\tvar old: int = current_health\n\tcurrent_health = max(current_health - amount, 0)\n\thealth_changed.emit(old, current_health)\n\n# UI side:\nfunc _ready() -> void:\n\tplayer.health_changed.connect(_on_health_changed)\n\nfunc _on_health_changed(old_value: int, new_value: int) -> void:\n\t$HealthBar.value = float(new_value)\n",
			"description": "Emit a health_changed signal whenever the value changes. Hook the health bar to that signal instead of polling every frame.",
			"confidence": 0.80,
		}],
	})

	out.append({
		"id": "health_regen_over_time",
		"title": "Health regenerates after a delay",
		"category": "health",
		"phrases": [
			"health regen",
			"regenerate health",
			"hp over time",
			"regen after damage",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "regen"}
		],
		"candidates": [{
			"code": "var regen_per_second: float = 2.0\nvar regen_delay: float = 5.0\nvar _time_since_damage: float = 999.0\n\nfunc take_damage(amount: int) -> void:\n\tcurrent_health = max(current_health - amount, 0)\n\t_time_since_damage = 0.0\n\nfunc _process(delta: float) -> void:\n\t_time_since_damage += delta\n\tif _time_since_damage >= regen_delay and current_health < max_health:\n\t\tcurrent_health = min(current_health + int(regen_per_second * delta), max_health)\n",
			"description": "Regen pauses for a delay after each hit, then ticks up. Track time since the last damage to know when to start healing.",
			"confidence": 0.70,
		}],
	})

	out.append({
		"id": "health_damage_numbers",
		"title": "Floating damage numbers",
		"category": "health",
		"phrases": [
			"damage numbers",
			"floating text",
			"damage popup",
			"hit numbers",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "Label"},
		],
		"candidates": [{
			"code": "# On hit, spawn a Label at the world position:\nvar label: Label = Label.new()\nlabel.text = \"-%d\" % amount\nlabel.position = global_position + Vector2(0, -20)\nadd_sibling(label)\n\nvar t: Tween = create_tween()\nt.set_parallel(true)\nt.tween_property(label, \"position:y\", label.position.y - 40, 0.6)\nt.tween_property(label, \"modulate:a\", 0.0, 0.6)\nt.chain().tween_callback(label.queue_free)\n",
			"description": "Spawn a Label, tween it upward and fade to zero, then free it. set_parallel runs the tweens together; chain runs the callback after.",
			"confidence": 0.68,
		}],
	})

	out.append({
		"id": "health_bar_follow",
		"title": "Health bar floats above a character",
		"category": "health",
		"phrases": [
			"health bar above head",
			"floating health bar",
			"health bar follows enemy",
			"health bar over character",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "health"}
		],
		"candidates": [{
			"code": "# 2D: add a Control (ProgressBar) as a child of the character.\n# Position it above the sprite with a negative y offset.\n#\n# 3D: use a Sprite3D or a Control inside a SubViewport on a\n# Sprite3D, or use the billboard + unshaded material on a MeshInstance3D.\n",
			"description": "In 2D just make the ProgressBar a child and offset it upward. In 3D use Sprite3D with billboard mode so it always faces the camera.",
			"confidence": 0.65,
		}],
	})

	out.append({
		"id": "health_low_warning",
		"title": "Flash the screen red at low health",
		"category": "health",
		"phrases": [
			"low health warning",
			"red flash low hp",
			"low hp effect",
			"health warning",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "modulate"}
		],
		"candidates": [{
			"code": "func _on_health_changed(old_value: int, new_value: int) -> void:\n\tif new_value < 30 and old_value >= 30:\n\t\t$Vignette.visible = true\n\t\tvar t: Tween = create_tween()\n\t\tt.tween_property($Vignette, \"modulate:a\", 0.6, 0.4)\n\t\tt.tween_property($Vignette, \"modulate:a\", 0.3, 0.4)\n\t\tt.set_loops()\n",
			"description": "Show a vignette overlay when health crosses below the threshold. Tween its alpha back and forth with set_loops for a pulse.",
			"confidence": 0.65,
		}],
	})

	out.append({
		"id": "health_hearts_ui",
		"title": "Heart-based health display",
		"category": "health",
		"phrases": [
			"hearts ui",
			"heart display",
			"zelda hearts",
			"heart health bar",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "TextureRect"},
		],
		"candidates": [{
			"code": "# Add N TextureRects to an HBoxContainer, one per heart.\n# On health_changed, update each one's texture:\nvar hearts: Array = $HBox.get_children()\nfor i in hearts.size():\n\tif i < new_value:\n\t\thearts[i].texture = preload(\"res://ui/heart_full.png\")\n\telse:\n\t\thearts[i].texture = preload(\"res://ui/heart_empty.png\")\n",
			"description": "Store one TextureRect per heart in an HBoxContainer. On each health change, swap the texture for the correct state. Full, half, empty variations give finer resolution.",
			"confidence": 0.68,
		}],
	})

	out.append({
		"id": "health_respawn",
		"title": "Respawn after death",
		"category": "health",
		"phrases": [
			"respawn",
			"player respawn",
			"restart after death",
			"respawn mechanic",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "died"}
		],
		"candidates": [{
			"code": "func _on_died() -> void:\n\t# Option A: reload the scene\n\tget_tree().reload_current_scene()\n\t# Option B: reset state and reposition\n\t# current_health = max_health\n\t# global_position = spawn_point\n",
			"description": "The simplest respawn is reload_current_scene(). For a checkpoint system, reset health and teleport to a spawn point instead.",
			"confidence": 0.72,
		}],
	})

	out.append({
		"id": "health_max_min",
		"title": "Upgradable max health",
		"category": "health",
		"phrases": [
			"increase max health",
			"max health upgrade",
			"health upgrade",
			"bigger health pool",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "max_health"}
		],
		"candidates": [{
			"code": "func increase_max_health(amount: int) -> void:\n\tmax_health += amount\n\tcurrent_health += amount   # heal by the increase\n\thealth_changed.emit(current_health - amount, current_health)\n",
			"description": "Bump both max_health and current_health by the same amount. Typical RPG convention — the upgrade also heals.",
			"confidence": 0.68,
		}],
	})

	# ===================================================================
	# MISC (14)
	# ===================================================================

	out.append({
		"id": "misc_print_debug",
		"title": "Debug printing without spamming the console",
		"category": "misc",
		"phrases": [
			"print debug",
			"debug output",
			"print statement",
			"console log",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "print"}
		],
		"candidates": [{
			"code": "print(\"health=\", current_health, \" pos=\", global_position)\nprint_rich(\"[color=yellow]warning[/color]: value=\", value)\npush_warning(\"something odd\")\npush_error(\"this should not happen\")\n",
			"description": "print takes comma-separated args and joins with spaces. print_rich supports BBCode. push_warning/push_error log with severity levels and attach to the caller.",
			"confidence": 0.72,
		}],
	})

	out.append({
		"id": "misc_assert_vs_push_error",
		"title": "assert vs push_error",
		"category": "misc",
		"phrases": [
			"assert vs push_error",
			"assertion or push_error",
			"debug vs runtime check",
			"assert in production",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "assert"},
			{"kind": "identifier", "value": "push_error"},
		],
		"candidates": [{
			"code": "# assert  — development only, halts the game on failure in debug builds.\n#           Stripped out entirely from release builds.\n# push_error — always runs, logs and continues.\n\nassert(index < arr.size())   # dev-time check\nif index >= arr.size():\n\tpush_error(\"index out of bounds\")\n\treturn\n",
			"description": "Use assert for conditions that should never be false and reveal bugs. Use push_error for conditions you want to survive in production.",
			"confidence": 0.72,
		}],
	})

	out.append({
		"id": "misc_string_format",
		"title": "Format strings in GDScript",
		"category": "misc",
		"phrases": [
			"string format",
			"format string",
			"sprintf gdscript",
			"string interpolation",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "%"}
		],
		"candidates": [{
			"code": "var name: String = \"Player\"\nvar hp: int = 87\nvar s1: String = \"%s has %d HP\" % [name, hp]\n# Concatenation also works:\nvar s2: String = name + \" has \" + str(hp) + \" HP\"\n",
			"description": "% uses sprintf-style formatting with an array of args. The array is required even for one value: \"%d\" % [n], not \"%d\" % n.",
			"confidence": 0.78,
		}],
	})

	out.append({
		"id": "misc_signal_disconnect_safety",
		"title": "Disconnect a signal safely",
		"category": "misc",
		"phrases": [
			"disconnect signal safely",
			"is_connected check",
			"safe disconnect",
			"disconnect before connect",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "disconnect"},
			{"kind": "identifier", "value": "is_connected", "negate": true},
		],
		"candidates": [{
			"code": "if target.signal_name.is_connected(_on_signal):\n\ttarget.signal_name.disconnect(_on_signal)\n",
			"description": "Calling disconnect on a signal that isn't connected returns an error. Guard with is_connected first.",
			"confidence": 0.75,
		}],
	})

	out.append({
		"id": "misc_export_annotation",
		"title": "Expose a variable in the inspector",
		"category": "misc",
		"phrases": [
			"export variable",
			"show variable in inspector",
			"inspector variable",
			"export annotation",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "export"},
		],
		"candidates": [{
			"code": "@export var speed: float = 200.0\n@export_range(0.0, 1000.0, 10.0) var max_health: float = 100.0\n@export_color_no_alpha var team_color: Color = Color.RED\n@export_file(\"*.png\") var sprite_path: String = \"\"\n@export var scene: PackedScene\n",
			"description": "@export exposes a variable in the inspector. @export_range clamps it, @export_file opens a file picker, @export_color_no_alpha hides the alpha channel.",
			"confidence": 0.82,
		}],
	})

	out.append({
		"id": "misc_onready_annotation",
		"title": "@onready caches a node reference",
		"category": "misc",
		"phrases": [
			"onready",
			"cache node reference",
			"store node ref",
			"onready var",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "onready"},
		],
		"candidates": [{
			"code": "@onready var sprite: Sprite2D = $Sprite2D\n@onready var health_bar: ProgressBar = $UI/HealthBar\n",
			"description": "@onready defers the assignment until _ready, so the node exists. The type annotation makes autocomplete better and catches typos early.",
			"confidence": 0.82,
		}],
	})

	out.append({
		"id": "misc_static_typing",
		"title": "Add type hints for autocomplete and errors",
		"category": "misc",
		"phrases": [
			"type hints",
			"static typing",
			"typed variables",
			"why type hints",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "->"}
		],
		"candidates": [{
			"code": "var speed: float = 200.0\nfunc move(direction: Vector2, delta: float) -> void:\n\tpass\nfunc get_name_of(id: int) -> String:\n\treturn \"\"\n",
			"description": "Typed variables and functions get autocomplete, catch typos at parse time, and run slightly faster. Inference (:=) works when the right side has a clear type.",
			"confidence": 0.72,
		}],
	})

	out.append({
		"id": "misc_enum_values",
		"title": "Enum values and how to use them",
		"category": "misc",
		"phrases": [
			"enum",
			"enumeration",
			"enum values",
			"state enum",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "enum"}
		],
		"candidates": [{
			"code": "enum State { IDLE, WALK, RUN }\n\nvar current_state: State = State.IDLE\n\nfunc change_state(new_state: State) -> void:\n\tcurrent_state = new_state\n\tmatch current_state:\n\t\tState.IDLE:\n\t\t\tpass\n\t\tState.WALK:\n\t\t\tpass\n",
			"description": "Enums create a named set of integer constants. Values start at 0 by default. Use them for state machines and typed options.",
			"confidence": 0.78,
		}],
	})

	out.append({
		"id": "misc_array_shuffle",
		"title": "Shuffle an array",
		"category": "misc",
		"phrases": [
			"shuffle array",
			"randomize array order",
			"shuffle list",
			"random array",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "shuffle"},
		],
		"candidates": [{
			"code": "var cards: Array = [1, 2, 3, 4, 5]\ncards.shuffle()\n",
			"description": "Array.shuffle() randomizes in place. Uses the global RNG, so seed it with seed() if you need reproducible order.",
			"confidence": 0.80,
		}],
	})

	out.append({
		"id": "misc_time_ticks",
		"title": "Measure elapsed time",
		"category": "misc",
		"phrases": [
			"elapsed time",
			"timer ticks",
			"milliseconds since",
			"stopwatch",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "get_ticks_msec"},
		],
		"candidates": [{
			"code": "var start: int = Time.get_ticks_msec()\n# ... work ...\nvar elapsed_ms: int = Time.get_ticks_msec() - start\nprint(\"took %d ms\" % elapsed_ms)\n",
			"description": "Time.get_ticks_msec() returns monotonic milliseconds. Subtract two reads for a duration. Usec for microsecond resolution.",
			"confidence": 0.75,
		}],
	})

	out.append({
		"id": "misc_file_path",
		"title": "Path returned by get_path() is res:// not user://",
		"category": "misc",
		"phrases": [
			"file path res vs user",
			"res:// user://",
			"where to save files",
			"path differences",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "res://"},
		],
		"candidates": [{
			"code": "# res:// is read-only in exported games. Use it for shipped assets.\n# user:// is writable everywhere. Use it for saves, config, logs.\nvar save_path: String = \"user://savegame.json\"\nvar config_path: String = \"user://settings.cfg\"\n",
			"description": "res:// is packed into the exported binary and not writable at runtime. user:// resolves to a per-platform writable directory (app data, Documents, etc.).",
			"confidence": 0.82,
		}],
	})

	out.append({
		"id": "misc_pause_game",
		"title": "Pause the entire game",
		"category": "misc",
		"phrases": [
			"pause game",
			"freeze everything",
			"stop game",
			"pause all",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "paused"},
		],
		"candidates": [{
			"code": "get_tree().paused = true\n\n# Nodes with default process_mode stop processing.\n# To keep a node running while paused:\nprocess_mode = Node.PROCESS_MODE_ALWAYS\n",
			"description": "paused on the SceneTree stops _process, _physics_process, and input on nodes whose process_mode doesn't include ALWAYS or WHEN_PAUSED.",
			"confidence": 0.80,
		}],
	})

	out.append({
		"id": "misc_random_seed",
		"title": "Make random output reproducible",
		"category": "misc",
		"phrases": [
			"random seed",
			"reproducible random",
			"seed random",
			"same random every time",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "seed"}
		],
		"candidates": [{
			"code": "seed(12345)   # every run produces the same random sequence\n# Or for a RandomNumberGenerator instance:\nvar rng: RandomNumberGenerator = RandomNumberGenerator.new()\nrng.seed = 12345\n",
			"description": "The global RNG (randi, randf, ...) accepts a seed() call. For isolated streams, create a RandomNumberGenerator and set its seed.",
			"confidence": 0.72,
		}],
	})

	out.append({
		"id": "misc_lambda_capture",
		"title": "Lambdas capture variables by value at creation",
		"category": "misc",
		"phrases": [
			"lambda capture",
			"closure in gdscript",
			"anonymous function capture",
			"lambda variable",
		],
		"code_patterns": [
			{"kind": "identifier", "value": "func"}
		],
		"candidates": [{
			"code": "var mult: int = 2\nvar scale: Callable = func(x: int) -> int:\n\treturn x * mult\n# mult is captured at creation. Changing it later doesn't affect\n# the lambda. To share state, capture a mutable object like an Array.\n",
			"description": "GDScript lambdas capture by value. To share mutable state between the outer function and the lambda, capture an Array or Dictionary and mutate its contents.",
			"confidence": 0.62,
		}],
	})

	return out


# --- self-test ----------------------------------------------------------

static func self_test() -> void:
	print("=== FixLibraryDataD self-test ===")
	var failures: Array[String] = []

	var arr: Array = records()

	var lib: FixLibrary = FixLibrary.new()
	lib.load_all()
	var added: int = register_into(lib)
	if added != arr.size():
		failures.append("register_into accepted %d of %d" % [added, arr.size()])
	if not lib.reject_log().is_empty():
		failures.append("%d rejects during registration" % lib.reject_log().size())

	var actual: Dictionary = {}
	var i: int = 0
	while i < arr.size():
		var rec: Dictionary = arr[i]
		var cat: String = str(rec.get("category", ""))
		actual[cat] = int(actual.get(cat, 0)) + 1
		i += 1

	var expected: Dictionary = {
		"ui": 14,
		"health": 13,
		"misc": 14,
	}

	var expected_total: int = 0
	var ekeys: Array = expected.keys()
	i = 0
	while i < ekeys.size():
		expected_total += int(expected[ekeys[i]])
		i += 1

	if arr.size() != expected_total:
		failures.append("total records: expected %d, got %d" % [expected_total, arr.size()])

	i = 0
	while i < ekeys.size():
		var k: String = str(ekeys[i])
		var want: int = int(expected[k])
		var got: int = int(actual.get(k, 0))
		if want != got:
			failures.append("category '%s' expected %d, got %d" % [k, want, got])
		i += 1

	var seen: Dictionary = {}
	i = 0
	while i < arr.size():
		var id: String = str(arr[i].get("id", ""))
		if seen.has(id):
			failures.append("duplicate id '%s'" % id)
		seen[id] = true
		i += 1

	# Cross-check against every prior ID.
	var prior_ids: Array = [
		# Starter
		"is_on_floor_missing", "gravity_not_applied", "delta_not_used",
		"input_map_missing", "input_get_action_strength",
		"get_node_returns_null", "node_path_wrong",
		"signal_wrong_signature", "await_signal_never_fires",
		"wrong_node_type", "queue_free_after_use",
		"rigidbody_moved_directly", "collision_layer_mismatch",
		"missing_type_hint", "godot3_to_godot4_rename",
		# A
		"coyote_time_2d", "jump_buffer_2d", "variable_jump_height",
		"air_control_2d", "wall_slide_2d", "wall_jump_2d",
		"dash_2d", "dash_air_2d", "sprint_toggle", "crouch_2d",
		"slope_slide_2d", "max_fall_speed", "jump_velocity_setup",
		"double_jump_2d", "jump_cut_on_release", "jump_particles_land",
		"jump_particles_takeoff", "jump_sound_pitch_variation",
		"landing_recovery_time", "dash_iframes", "dash_direction_8way",
		"dash_cancel_into_attack", "camera_follow_smooth",
		"camera_deadzone", "camera_lookahead", "camera_shake",
		"camera_limits_2d", "camera_zoom_smooth", "camera_mouse_look_3d",
		"camera_smooth_3d", "dash_camera_zoom", "input_deadzone_analog",
		"input_remap_runtime", "input_controller_detection",
		"input_touch_button_2d", "input_hold_vs_press", "input_double_tap",
		"dash_cooldown_ui", "dash_trail",
		# B
		"null_after_free", "null_signal_arg", "null_typed_var",
		"get_node_or_null_returns_null", "instantiate_returns_null",
		"owner_is_null", "get_first_node_in_group_empty", "dict_key_missing",
		"resource_load_failed", "get_parent_at_root", "autoload_not_registered",
		"await_result_null", "null_typed_array_access", "assert_condition_false",
		"signal_not_emitted", "signal_connect_failed",
		"signal_emitted_before_connect", "signal_arg_type_mismatch",
		"signal_one_shot", "signal_await_timeout", "signal_callable_bind",
		"signal_typed_params", "signal_duplicate_connection",
		"signal_disconnect_during_emit", "signal_emit_in_ready",
		"signal_custom_no_params", "signal_wrong_arg_count",
		"ready_not_called", "process_not_called", "node_added_to_wrong_parent",
		"node_name_collision", "node_order_in_scene", "ready_vs_enter_tree",
		"remove_child_vs_queue_free", "node_visibility", "node_processing_disabled",
		"z_index_wrong", "node_duplicate", "node_reparent",
		"_ready_called_before_parent_ready", "call_deferred_pattern",
		# C
		"physics_process_vs_process", "body_type_selection",
		"move_and_slide_vs_move_and_collide", "raycast_ignore_self",
		"raycast_target_to_global", "area_monitoring_disabled",
		"area_body_entered_signal", "continuous_collision_detection",
		"rigidbody_sleep_issue", "physics_material_bounce",
		"one_way_collision_3d", "get_slide_collision_info",
		"is_on_wall_only_checks", "max_slides_exhausted",
		"collision_layer_vs_mask", "collision_shape_missing",
		"collision_shape_scale_issue", "collision_shape_2d_vs_3d",
		"one_way_collision_2d", "collision_debug_visible",
		"area_signals_setup", "collision_shape_rotation",
		"rigidbody_disable_collision", "character_body_floor_snap",
		"animation_player_vs_tree", "animation_tree_parameters",
		"animation_state_transition", "animation_blend_2d",
		"animation_method_call", "sprite_frames_timing",
		"animation_not_playing", "animation_looping_setup",
		"tween_vs_animation_player", "animation_speed_scale",
		"add_to_group_basics", "get_nodes_in_group",
		"node_added_signal_tree", "group_typo_issue",
		"remove_from_group", "group_cleanup_on_free",
	]
	i = 0
	while i < prior_ids.size():
		var pid: String = str(prior_ids[i])
		if seen.has(pid):
			failures.append("id '%s' collides with prior volume" % pid)
		i += 1

	if not lib.has_record("ui_container_vs_manual_position"):
		failures.append("ui_container_vs_manual_position missing")
	if not lib.has_record("health_damage_signature"):
		failures.append("health_damage_signature missing")
	if not lib.has_record("misc_export_annotation"):
		failures.append("misc_export_annotation missing")

	var m1: Array = lib.records_matching_tokens(["health"])
	if m1.is_empty():
		failures.append("'health' token should match records")
	var m2: Array = lib.records_matching_tokens(["button"])
	if m2.is_empty():
		failures.append("'button' token should match records")

	print("")
	if failures.is_empty():
		print("OK — all assertions passed (%d records, %d categories)" % [arr.size(), actual.size()])
	else:
		print("FAILED — %d issues:" % failures.size())
		i = 0
		while i < failures.size():
			print("  " + failures[i])
			i += 1
