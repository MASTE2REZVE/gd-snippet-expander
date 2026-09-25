@tool
extends RefCounted


func get_data() -> Dictionary:
	return {
		"version": 2,
		"blueprints": {
			"virtual_joystick_ui": {
				"title": "Virtual Joystick UI",
				"phrases": ["virtual joystick ui", "touch joystick ui", "add joystick", "mobile joystick rig"],
				"category": "touch",
				"subcategory": "joystick",
				"platforms": ["mobile"],
				"dimension": "ui",
				"difficulty": "intermediate",
				"root": {
					"type": "CanvasLayer",
					"name": "TouchControls"
				},
				"required_children": [
					{"type": "Control", "name": "JoystickZone", "properties": {"anchors_preset": 9, "anchor_right": 0.5, "anchor_bottom": 1.0, "mouse_filter": 2}},
					{"type": "Control", "name": "Joystick", "properties": {"visible": false, "mouse_filter": 2}},
					{"type": "Panel", "name": "Base", "properties": {"custom_minimum_size": [128, 128], "size": [128, 128]}},
					{"type": "Panel", "name": "Knob", "properties": {"custom_minimum_size": [56, 56], "size": [56, 56]}}
				],
				"recommended_children": [],
				"script": "virtual_joystick",
				"required_actions": [],
				"setup_notes": [
					"Note: re-parent after building so the structure is:",
					"  TouchControls (CanvasLayer)",
					"    JoystickZone (Control, anchors_preset 9 = left half)",
					"      Joystick (Control, hidden)",
					"        Base (Panel)",
					"          Knob (Panel)",
					"The script virtual_joystick attaches to TouchControls. The Joystick script is the same but expects the actual joystick node as its target.",
					"Make Base and Knob circular by adding a StyleBoxFlat theme override:",
					"  - corner_radius: 64 for Base, 28 for Knob",
					"  - bg_color: Color(1, 1, 1, 0.15) for Base, Color(1, 1, 1, 0.3) for Knob",
					"Add TouchControls to group 'touch_controls' if other systems need to find it.",
					"Hide the CanvasLayer by default on desktop. In Project Settings → Autoload, add a script that checks DisplayServer.is_touchscreen_available() and shows/hides the whole rig.",
					"For iOS: safe area matters. Put everything inside a Control that uses the ios_safe_area_helper snippet as its parent.",
					"Place the joystick zone on the LEFT half so the right half is free for action buttons."
				],
				"next_steps": [
					{"blueprint": "touch_buttons_ui", "why": "The action buttons for the right half."},
					{"snippet": "virtual_joystick", "why": "The script logic."},
					{"snippet": "input_abstraction", "why": "Reads keyboard, gamepad, and this joystick through one API."},
					{"snippet": "ios_safe_area_helper", "why": "iOS-specific safe area handling."}
				],
				"mistakes": [
					"Not hiding the joystick by default means it flashes on desktop before the platform check runs.",
					"Forgetting mouse_filter = 2 (Ignore) on the zone means UI taps don't pass through to the game.",
					"Making the JoystickZone cover the full screen instead of half means the joystick appears in the button area.",
					"Using a solid circle style with full opacity hides the game — keep Base alpha below 0.3.",
					"Adding the joystick to a Control with anchors_preset = 15 (full rect) makes the position calculation use the wrong reference."
				]
			},
			"touch_buttons_ui": {
				"title": "Touch Buttons UI",
				"phrases": ["touch buttons ui", "mobile buttons", "add touch buttons", "action buttons rig"],
				"category": "touch",
				"subcategory": "buttons",
				"platforms": ["mobile"],
				"dimension": "ui",
				"difficulty": "intermediate",
				"root": {
					"type": "CanvasLayer",
					"name": "ActionButtons"
				},
				"required_children": [
					{"type": "Control", "name": "ButtonZone", "properties": {"anchors_preset": 11, "anchor_left": 0.5, "anchor_right": 1.0, "anchor_bottom": 1.0, "mouse_filter": 2}},
					{"type": "Control", "name": "JumpButton", "properties": {"custom_minimum_size": [100, 100], "size": [100, 100]}},
					{"type": "Panel", "name": "Background", "properties": {"anchors_preset": 15}},
					{"type": "Label", "name": "Label", "properties": {"text": "A", "horizontal_alignment": 1, "vertical_alignment": 1, "anchors_preset": 15}}
				],
				"recommended_children": [],
				"script": "touch_button",
				"required_actions": [],
				"setup_notes": [
					"Note: re-parent and duplicate after building so the structure is:",
					"  ActionButtons (CanvasLayer)",
					"    ButtonZone (Control, right half of screen)",
					"      JumpButton (Control)",
					"        Background (Panel)",
					"        Label (Label)",
					"      AttackButton (Control, duplicate of JumpButton)",
					"      InteractButton (Control, duplicate of JumpButton)",
					"The script touch_button attaches to each button. Set action_name per button:",
					"  - JumpButton → action_name = 'jump', button_label = 'A'",
					"  - AttackButton → action_name = 'attack', button_label = 'B'",
					"  - InteractButton → action_name = 'interact', button_label = 'E'",
					"Position the buttons by dragging in the 2D editor. Typical layout:",
					"  - Jump at bottom-right corner",
					"  - Attack above and slightly left of Jump",
					"  - Interact above Jump",
					"Each button needs a Panel (circle style) and a Label showing the action letter.",
					"Style the Background Panel with a StyleBoxFlat: corner_radius 50, bg_color Color(1, 1, 1, 0.15).",
					"Set every button's mouse_filter to STOP (0) so touches register on the button itself."
				],
				"next_steps": [
					{"blueprint": "virtual_joystick_ui", "why": "The joystick that pairs with these buttons."},
					{"snippet": "touch_button", "why": "The script logic."},
					{"snippet": "input_abstraction", "why": "One API across keyboard, gamepad, and touch."},
					{"snippet": "safe_area_ui", "why": "Keep buttons inside the safe area on notched devices."}
				],
				"mistakes": [
					"Placing a button outside the ButtonZone means it interferes with the joystick on the left half.",
					"Not setting action_name means the button does nothing when pressed.",
					"Missing input actions in Input Map means Input.action_press silently fails.",
					"Buttons too close together cause accidental double-taps — keep at least 20 px apart.",
					"Not hiding the rig on desktop wastes screen space and confuses keyboard players."
				]
			}
		}
	}
