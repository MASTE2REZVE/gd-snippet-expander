@tool
extends RefCounted


func get_data() -> Dictionary:
	return {
		"version": 2,
		"blueprints": {
			"enemy_spawner": {
				"title": "Enemy Spawner",
				"phrases": ["enemy spawner", "spawn enemies", "wave spawner", "enemy spawn"],
				"category": "enemy",
				"subcategory": "spawner",
				"dimension": "2d",
				"difficulty": "intermediate",
				"root": {
					"type": "Node2D",
					"name": "EnemySpawner"
				},
				"required_children": [
					{"type": "Timer", "name": "SpawnTimer", "properties": {"wait_time": 3.0, "autostart": true}}
				],
				"recommended_children": [],
				"script": "spawn_prefab",
				"required_actions": [],
				"setup_notes": [
					"In the Inspector for the EnemySpawner, set the 'prefab' property to your enemy scene (.tscn file).",
					"Adjust spawn_interval on the script if you want a different rate than the Timer's wait_time.",
					"The spawner adds enemies as children of itself. If you want them in the world, change add_child to get_tree().current_scene.add_child(node) in the script.",
					"For multiple spawn points, duplicate this node and position each at a different location.",
					"For wave-based spawning, disable autostart on the Timer and call the timer manually from a wave manager."
				],
				"next_steps": [
					{"blueprint": "enemy_patrol_2d", "why": "Enemies that walk around."},
					{"blueprint": "enemy_chaser_3d", "why": "Enemies that chase the player."},
					{"snippet": "health_system", "why": "So spawned enemies can be killed."},
					{"snippet": "coin_pickup", "why": "Reward for killing enemies."}
				],
				"mistakes": [
					"Forgetting to assign the prefab slot means nothing spawns.",
					"Spawning very fast without any cap floods the scene and tanks performance.",
					"Spawning as a child of the spawner means enemies move with the spawner if it moves. Usually not what you want — change add_child to current_scene in the script."
				]
			},
			"damage_popup_scene": {
				"title": "Damage Popup Scene",
				"phrases": ["damage popup blueprint", "damage number scene", "floating damage scene", "hit number"],
				"category": "effects",
				"subcategory": "feedback",
				"dimension": "2d",
				"difficulty": "intermediate",
				"root": {
					"type": "Node2D",
					"name": "DamagePopup"
				},
				"required_children": [
					{"type": "Label", "name": "AmountLabel", "properties": {"text": "0", "horizontal_alignment": 1}}
				],
				"recommended_children": [],
				"script": "",
				"required_actions": [],
				"setup_notes": [
					"Save this blueprint as its own scene file (right-click the root → Save Branch as Scene, name it damage_popup.tscn).",
					"Then attach this script to the root (paste into a new script file called damage_popup.gd):",
					"",
					"    extends Node2D",
					"",
					"    func _ready() -> void:",
					"        var t := create_tween()",
					"        t.set_parallel(true)",
					"        t.tween_property(self, \"position\", position + Vector2(0, -40), 0.8)",
					"        t.tween_property(self, \"modulate:a\", 0.0, 0.8).set_delay(0.2)",
					"        await t.finished",
					"        queue_free()",
					"",
					"    func set_text(value: String) -> void:",
					"        $AmountLabel.text = value",
					"",
					"Then reference this scene from the damage_number_popup snippet, or use a manager script to spawn it.",
					"The Label should be centered. Set its horizontal_alignment to Center in the Inspector.",
					"Use a bold or outlined font via Theme override on the Label — thin fonts are hard to read at small sizes."
				],
				"next_steps": [
					{"snippet": "damage_number_popup", "why": "The spawner side of this effect."},
					{"snippet": "health_system", "why": "Where the damage amount comes from."},
					{"snippet": "camera_shake", "why": "Adds weight to each hit."}
				],
				"mistakes": [
					"Forgetting to save as a separate scene means you can't instantiate it from code.",
					"Naming the Label anything other than 'AmountLabel' means the script can't find it. Either rename or update the script.",
					"Long numbers (1000+) overflow the Label. Set autowrap or a larger size."
				]
			},
			"boss_health_bar": {
				"title": "Boss Health Bar",
				"phrases": ["boss health bar", "boss bar", "boss hp", "boss health ui"],
				"category": "ui",
				"subcategory": "hud",
				"dimension": "ui",
				"difficulty": "intermediate",
				"root": {
					"type": "CanvasLayer",
					"name": "BossBar"
				},
				"required_children": [
					{"type": "Panel", "name": "Background", "properties": {"anchors_preset": 5, "offset_left": 40, "offset_top": 20, "offset_right": -40, "offset_bottom": 60}},
					{"type": "Label", "name": "BossName", "properties": {"text": "BOSS", "horizontal_alignment": 1, "anchors_preset": 5, "offset_left": 40, "offset_top": -4, "offset_right": -40, "offset_bottom": 16}},
					{"type": "ProgressBar", "name": "HealthBar", "properties": {"anchors_preset": 5, "offset_left": 44, "offset_top": 24, "offset_right": -44, "offset_bottom": 56, "max_value": 100, "value": 100, "show_percentage": false}},
					{"type": "ColorRect", "name": "DamageLag", "properties": {"color": [0.8, 0.1, 0.1, 0.7], "anchors_preset": 5, "offset_left": 44, "offset_top": 24, "offset_right": -44, "offset_bottom": 56}}
				],
				"recommended_children": [],
				"script": "",
				"required_actions": [],
				"setup_notes": [
					"Hide the CanvasLayer by default — set visible = false in the Inspector.",
					"The DamageLag ColorRect sits behind the HealthBar. When the boss takes a hit, tween the HealthBar down instantly and the DamageLag down over 0.5 seconds. This produces the classic 'white delay' effect.",
					"Attach this script to the root CanvasLayer:",
					"",
					"    extends CanvasLayer",
					"",
					"    @onready var _bar: ProgressBar = $HealthBar",
					"    @onready var _lag: ColorRect = $DamageLag",
					"",
					"    func show_bar(boss_name: String, max_hp: int) -> void:",
					"        visible = true",
					"        $BossName.text = boss_name",
					"        _bar.max_value = max_hp",
					"        _bar.value = max_hp",
					"        _lag.size.x = _bar.size.x",
					"",
					"    func set_health(current: int, max_hp: int) -> void:",
					"        _bar.value = current",
					"        var t := create_tween()",
					"        t.tween_property(_lag, \"size:x\", _bar.size.x * float(current) / float(max_hp), 0.5)",
					"",
					"Call show_bar(\"Dragon\", 500) when the boss spawns. Connect the boss's health_changed signal to set_health.",
					"For a bottom-of-screen bar instead, change the anchors of the Background, BossName, HealthBar, and DamageLag to preset 12 (bottom wide)."
				],
				"next_steps": [
					{"snippet": "health_system", "why": "The boss's health."},
					{"snippet": "health_signal", "why": "Emits health_changed with current and max together."},
					{"snippet": "game_over_screen", "why": "Shown when the player dies to the boss."}
				],
				"mistakes": [
					"Forgetting to hide the CanvasLayer means the empty bar is visible at game start.",
					"Not anchoring the Panel properly causes the bar to overflow on different screen sizes.",
					"Making DamageLag the same color as HealthBar defeats the purpose — it should contrast visibly (dark red under bright red, for example)."
				]
			}
		}
	}
