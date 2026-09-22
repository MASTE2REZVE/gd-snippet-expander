@tool
extends RefCounted


func get_data() -> Dictionary:
	return {
		"version": 2,
		"blueprints": {
			"pause_menu_ui": {
				"title": "Pause Menu",
				"phrases": ["pause menu blueprint", "add pause menu", "make pause menu", "pause ui blueprint"],
				"category": "ui",
				"dimension": "ui",
				"difficulty": "beginner",
				"root": {
					"type": "CanvasLayer",
					"name": "PauseMenu"
				},
				"required_children": [
					{"type": "ColorRect", "name": "Overlay", "properties": {"color": [0, 0, 0, 0.6], "anchors_preset": 15}},
					{"type": "VBoxContainer", "name": "Buttons", "properties": {"anchors_preset": 8, "offset_left": -80, "offset_top": -60, "offset_right": 80, "offset_bottom": 60}}
				],
				"recommended_children": [],
				"script": "pause_menu",
				"required_actions": [],
				"setup_notes": [
					"Add Button nodes as children of the Buttons VBoxContainer.",
					"Name them Resume, Restart, Quit — the script only handles opening/closing, not what the buttons do.",
					"Connect each button's pressed signal to a function that unpauses, reloads the scene, or quits.",
					"The script sets process_mode = ALWAYS automatically, so the menu works while the game is paused."
				],
				"next_steps": [
					{"snippet": "main_menu", "why": "For the pause menu's Quit button to return to."},
					{"snippet": "options_menu", "why": "To add a Settings button."},
					{"snippet": "audio_bus_volume", "why": "If you add a volume slider."}
				],
				"mistakes": [
					"Forgetting process_mode = ALWAYS means the menu itself freezes and can't unpause.",
					"The script is on CanvasLayer — attaching it to a Button instead breaks everything.",
					"Not adding a ColorRect overlay means the paused game is visible behind the menu."
				]
			},
			"main_menu_ui": {
				"title": "Main Menu",
				"phrases": ["main menu blueprint", "add main menu", "make main menu", "title screen blueprint", "start menu blueprint"],
				"category": "ui",
				"dimension": "ui",
				"difficulty": "beginner",
				"root": {
					"type": "Control",
					"name": "MainMenu"
				},
				"required_children": [
					{"type": "VBoxContainer", "name": "Buttons", "properties": {"anchors_preset": 8, "offset_left": -100, "offset_top": -80, "offset_right": 100, "offset_bottom": 80}}
				],
				"recommended_children": [
					{"type": "ColorRect", "name": "Background", "properties": {"color": [0.1, 0.1, 0.15, 1.0], "anchors_preset": 15}}
				],
				"script": "main_menu",
				"required_actions": [],
				"setup_notes": [
					"Add Button nodes as children of the Buttons container: Start, Options, Quit.",
					"Connect each button's pressed signal to the matching function.",
					"The script has a game_scene property — set it in the Inspector to your first level.",
					"For a background image, replace the ColorRect with a TextureRect using a background texture."
				],
				"next_steps": [
					{"snippet": "options_menu", "why": "For the Options button to open."},
					{"snippet": "change_scene", "why": "What the Start button actually does."},
					{"snippet": "quit_game", "why": "What the Quit button actually does."}
				],
				"mistakes": [
					"Forgetting to set game_scene means Start does nothing.",
					"Putting the script on a Button instead of the root Control means signals never connect."
				]
			},
			"health_bar_ui_blueprint": {
				"title": "Health Bar UI",
				"phrases": ["health bar blueprint", "hp bar blueprint", "add health ui", "health ui blueprint"],
				"category": "ui",
				"dimension": "ui",
				"difficulty": "beginner",
				"root": {
					"type": "CanvasLayer",
					"name": "HUD"
				},
				"required_children": [
					{"type": "ProgressBar", "name": "HealthBar", "properties": {"anchors_preset": 1, "offset_left": 20, "offset_top": 20, "offset_right": 220, "offset_bottom": 50, "max_value": 100, "value": 100}}
				],
				"recommended_children": [],
				"script": "health_bar_ui",
				"required_actions": [],
				"setup_notes": [
					"The script has a player_path property. In the Inspector, set it to point at the player node.",
					"Make sure the ProgressBar's max_value matches the player's max_health.",
					"For a pixel-art style bar, add a StyleBoxFlat theme override to the ProgressBar."
				],
				"next_steps": [
					{"snippet": "health_system", "why": "The player needs health and a health_changed signal."},
					{"snippet": "score_display", "why": "To add a score display alongside the health bar."},
					{"snippet": "countdown_timer_ui", "why": "For a timer if your game needs one."}
				],
				"mistakes": [
					"Forgetting to set player_path means the bar stays at its scene default and never updates.",
					"Not matching max_value to the player's max_health makes the bar fill inconsistently."
				]
			},
			"settings_menu_ui": {
				"title": "Settings Menu",
				"phrases": ["settings menu blueprint", "options menu blueprint", "add settings menu", "config menu blueprint"],
				"category": "ui",
				"dimension": "ui",
				"difficulty": "intermediate",
				"root": {
					"type": "Control",
					"name": "SettingsMenu"
				},
				"required_children": [
					{"type": "VBoxContainer", "name": "Rows", "properties": {"anchors_preset": 8, "offset_left": -200, "offset_top": -150, "offset_right": 200, "offset_bottom": 150}}
				],
				"recommended_children": [],
				"script": "options_menu",
				"required_actions": [],
				"setup_notes": [
					"The script looks for a child named 'MasterSlider'. Add an HSlider named 'MasterSlider' to the Rows container.",
					"Add a Label next to each slider so the player knows what it controls.",
					"Wire up more sliders for Music and SFX buses — remember to add those buses in Godot's Audio panel first.",
					"To persist settings across runs, combine with settings_save."
				],
				"next_steps": [
					{"snippet": "settings_save", "why": "So the player's settings stick between sessions."},
					{"snippet": "audio_bus_volume", "why": "The actual volume change logic."},
					{"snippet": "config_file", "why": "A simpler read/write pattern for the config."}
				],
				"mistakes": [
					"Changing slider values without an actual AudioServer call means nothing changes.",
					"Not saving settings means they reset to defaults next time the game runs."
				]
			},
			"game_over_ui": {
				"title": "Game Over Screen",
				"phrases": ["game over blueprint", "death screen blueprint", "add game over", "lose screen"],
				"category": "ui",
				"dimension": "ui",
				"difficulty": "beginner",
				"root": {
					"type": "CanvasLayer",
					"name": "GameOver"
				},
				"required_children": [
					{"type": "ColorRect", "name": "Overlay", "properties": {"color": [0, 0, 0, 0.8], "anchors_preset": 15}},
					{"type": "Label", "name": "Message", "properties": {"anchors_preset": 8, "offset_left": -150, "offset_top": -100, "offset_right": 150, "offset_bottom": -60, "text": "GAME OVER", "horizontal_alignment": 1}},
					{"type": "VBoxContainer", "name": "Buttons", "properties": {"anchors_preset": 8, "offset_left": -100, "offset_top": 0, "offset_right": 100, "offset_bottom": 80}}
				],
				"recommended_children": [],
				"script": "game_over_screen",
				"required_actions": [],
				"setup_notes": [
					"Add Button nodes to the Buttons container: Retry and Main Menu.",
					"Connect Retry's pressed signal to the restart() function provided by the script.",
					"Hide the CanvasLayer by default — set visible = false in the Inspector.",
					"Connect your player's died signal to the show_game_over() function."
				],
				"next_steps": [
					{"snippet": "health_system", "why": "The died signal comes from here."},
					{"snippet": "reload_scene", "why": "What Retry does."},
					{"blueprint": "main_menu_ui", "why": "So the Main Menu button has a destination."}
				],
				"mistakes": [
					"Forgetting to hide the CanvasLayer means the game over screen is visible at game start.",
					"Not unpausing before reloading the scene means the new scene starts paused."
				]
			},
			"hud_score_ui": {
				"title": "Score HUD",
				"phrases": ["score hud", "score ui blueprint", "add score display", "hud score"],
				"category": "ui",
				"dimension": "ui",
				"difficulty": "beginner",
				"root": {
					"type": "CanvasLayer",
					"name": "HUD"
				},
				"required_children": [
					{"type": "Label", "name": "ScoreLabel", "properties": {"anchors_preset": 1, "offset_left": 20, "offset_top": 20, "offset_right": 220, "offset_bottom": 50, "text": "Score: 0"}}
				],
				"recommended_children": [],
				"script": "score_display",
				"required_actions": [],
				"setup_notes": [
					"The script has a score variable and add_score(amount) function.",
					"Call add_score(100) from your coin pickup's collected signal.",
					"For a pixel font, set the Label's theme font override to your pixel font.",
					"Position the label anywhere on screen — top-left is standard."
				],
				"next_steps": [
					{"snippet": "coin_pickup", "why": "What triggers the score to increase."},
					{"blueprint": "health_bar_ui_blueprint", "why": "To add a health bar next to the score."},
					{"snippet": "countdown_timer_ui", "why": "For timed challenges."}
				],
				"mistakes": [
					"Updating score text every frame wastes CPU — only update when score actually changes.",
					"Not adding the HUD to a CanvasLayer means it scrolls with the camera instead of staying fixed."
				]
			},
			"dialog_box_ui": {
				"title": "Dialog Box",
				"phrases": ["dialog box blueprint", "dialogue box blueprint", "add dialog", "npc dialog blueprint"],
				"category": "ui",
				"dimension": "ui",
				"difficulty": "intermediate",
				"root": {
					"type": "CanvasLayer",
					"name": "DialogBox"
				},
				"required_children": [
					{"type": "Panel", "name": "Panel", "properties": {"anchors_preset": 12, "offset_left": 20, "offset_top": -180, "offset_right": -20, "offset_bottom": -20}},
					{"type": "Label", "name": "Label", "properties": {"anchors_preset": 15, "offset_left": 20, "offset_top": 20, "offset_right": -20, "offset_bottom": -20, "autowrap_mode": 3}}
				],
				"recommended_children": [],
				"script": "dialog_box",
				"required_actions": [],
				"setup_notes": [
					"The Label must be a child of the Panel, named 'Label'.",
					"Call start_dialog([\"First line\", \"Second line\", \"Third line\"]) to begin.",
					"Press Space or Enter to advance each line. The dialog closes automatically at the end.",
					"The dialog_finished signal fires when all lines are shown."
				],
				"next_steps": [
					{"snippet": "signal_connect", "why": "To react when dialog finishes."},
					{"snippet": "state_machine", "why": "To switch NPC state while dialog is open."},
					{"snippet": "pause_game", "why": "To pause the game during dialog if desired."}
				],
				"mistakes": [
					"Naming the Label something else means the script can't find it.",
					"Forgetting autowrap_mode means long lines run off the panel."
				]
			}
		}
	}
