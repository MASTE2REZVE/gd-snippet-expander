@tool
extends RefCounted


func get_data() -> Dictionary:
	return {
		"version": 2,
		"blueprints": {
			"flying_enemy_3d_blueprint": {
				"title": "Flying Enemy (3D)",
				"phrases": ["flying enemy blueprint 3d", "add flying enemy 3d", "3d drone enemy", "3d flying ai"],
				"category": "enemy",
				"subcategory": "3d",
				"platforms": ["desktop", "mobile", "web"],
				"dimension": "3d",
				"difficulty": "intermediate",
				"root": {
					"type": "CharacterBody3D",
					"name": "FlyingEnemy"
				},
				"required_children": [
					{"type": "CollisionShape3D", "name": "CollisionShape3D", "shape": "SphereShape3D"},
					{"type": "MeshInstance3D", "name": "Mesh", "mesh": "BoxMesh"}
				],
				"recommended_children": [
					{"type": "Area3D", "name": "HitArea"}
				],
				"script": "flying_enemy_3d",
				"required_actions": [],
				"setup_notes": [
					"Sphere collision shape defaults to radius 0.5 meters. Adjust to match the visual mesh.",
					"Replace the BoxMesh placeholder with your drone, bat, or floating orb model.",
					"Set the enemy's collision layer so it interacts with the player's hurtbox but not the floor — flying enemies pass through ground obstacles.",
					"In the Inspector for the FlyingEnemy script:",
					"  - speed: 6.0 for standard movement",
					"  - hover_amplitude: 0.3 meters of vertical bob",
					"  - attack_range: 8.0 meters",
					"  - attack_damage: 10",
					"  - attack_cooldown: 1.5 seconds",
					"The player must be in group 'player' or assigned via target_path.",
					"Optional HitArea: an Area3D with a larger sphere that detects the player within a wider radius than the physical collision. Use this for detecting the player without needing collision response.",
					"Add an AnimatedSprite3D or AnimationPlayer for hover animation. Or use a simple code-driven bob (see the snippet).",
					"For variety, duplicate this scene and adjust speed, colors, and attack patterns."
				],
				"next_steps": [
					{"snippet": "flying_enemy_3d", "why": "The behavior logic."},
					{"snippet": "health_system", "why": "Make it killable."},
					{"snippet": "loot_table", "why": "Drops on death."},
					{"snippet": "particle_explosion_3d", "why": "Death effect."},
					{"snippet": "damage_number_3d", "why": "Floating damage numbers."}
				],
				"mistakes": [
					"Enabling gravity on a flying enemy defeats the purpose. The script never applies gravity.",
					"Small collision sphere means the player can walk under the enemy without touching. Match the sphere to the visual size.",
					"No attack_range check means the enemy attacks from across the map. Gate attacks with a distance check.",
					"Very high speed (over 15) makes the enemy overshoot and jitter around the player."
				]
			},
			"turret_enemy_3d_blueprint": {
				"title": "Turret Enemy (3D)",
				"phrases": ["turret blueprint 3d", "3d turret", "add turret 3d", "3d gun turret"],
				"category": "enemy",
				"subcategory": "3d",
				"platforms": ["desktop", "mobile", "web"],
				"dimension": "3d",
				"difficulty": "intermediate",
				"root": {
					"type": "StaticBody3D",
					"name": "Turret"
				},
				"required_children": [
					{"type": "CollisionShape3D", "name": "CollisionShape3D", "shape": "CylinderShape3D"},
					{"type": "MeshInstance3D", "name": "Base", "mesh": "CylinderMesh"},
					{"type": "Node3D", "name": "YawPivot"},
					{"type": "MeshInstance3D", "name": "Barrel", "mesh": "BoxMesh"},
					{"type": "Marker3D", "name": "Muzzle"}
				],
				"recommended_children": [
					{"type": "MeshInstance3D", "name": "ShieldMesh", "mesh": "SphereMesh"}
				],
				"script": "turret_enemy_3d",
				"required_actions": [],
				"setup_notes": [
					"Note: re-parent the children after building. The tree should be:",
					"  Turret (StaticBody3D) — script on this",
					"    CollisionShape3D (CylinderShape3D)",
					"    Base (MeshInstance3D, CylinderMesh) — the mounting",
					"    YawPivot (Node3D) — rotates horizontally",
					"      Barrel (MeshInstance3D, BoxMesh) — the gun barrel",
					"      Muzzle (Marker3D) — where projectiles spawn",
					"    ShieldMesh (MeshInstance3D, SphereMesh) — optional, disabled by default",
					"Position Muzzle at the tip of the Barrel. Its coordinates are local to YawPivot.",
					"Set the Barrel mesh size to something like Vector3(0.2, 0.2, 1.5) for a long thin barrel.",
					"The CollisionShape3D CylinderShape3D should be about 0.6 meters tall and 0.5 meters wide.",
					"Add the turret to the interaction collision layer so the player's shots hit it.",
					"In the Inspector for the Turret script:",
					"  - projectile_scene: your bullet .tscn (see projectile_3d snippet)",
					"  - fire_rate: 1.5 seconds between shots",
					"  - range: 30.0 meters detection",
					"  - rotate_horizontal_only: true for ground turrets, false for AA guns",
					"The player must be in group 'player'."
				],
				"next_steps": [
					{"snippet": "turret_enemy_3d", "why": "The turret logic."},
					{"snippet": "projectile_3d", "why": "The bullet scene."},
					{"snippet": "impact_particles_3d", "why": "Bullet impact effect."},
					{"snippet": "health_system", "why": "Make the turret killable."},
					{"snippet": "loot_table", "why": "Drops on destroy."}
				],
				"mistakes": [
					"Putting the Barrel as a direct child of Turret instead of YawPivot means the barrel doesn't rotate.",
					"Forgetting the Muzzle Marker3D means bullets spawn from the turret center, looking wrong with a long barrel.",
					"Not assigning projectile_scene in the Inspector means nothing fires — no warning is printed.",
					"Very high fire_rate (over 3 shots per second) with a burst_count over 1 empties the scene of bullets and tanks performance."
				]
			},
			"boss_3d": {
				"title": "Boss Enemy (3D)",
				"phrases": ["boss 3d", "3d boss", "boss blueprint 3d", "add 3d boss"],
				"category": "enemy",
				"subcategory": "3d",
				"platforms": ["desktop", "mobile", "web"],
				"dimension": "3d",
				"difficulty": "advanced",
				"root": {
					"type": "CharacterBody3D",
					"name": "Boss"
				},
				"required_children": [
					{"type": "CollisionShape3D", "name": "CollisionShape3D", "shape": "CapsuleShape3D"},
					{"type": "MeshInstance3D", "name": "Mesh", "mesh": "BoxMesh"},
					{"type": "NavigationAgent3D", "name": "NavigationAgent3D"},
					{"type": "Node3D", "name": "Attacks"}
				],
				"recommended_children": [
					{"type": "Marker3D", "name": "AttackPoint"},
					{"type": "Area3D", "name": "MeleeRange"}
				],
				"script": "",
				"required_actions": [],
				"setup_notes": [
					"Note: re-parent children after building so the tree is:",
					"  Boss (CharacterBody3D)",
					"    CollisionShape3D (CapsuleShape3D)",
					"    Mesh (MeshInstance3D) — replace with your boss model",
					"    NavigationAgent3D",
					"    Attacks (Node3D) — container for attack scripts",
					"    AttackPoint (Marker3D) — where projectiles or effects spawn",
					"    MeleeRange (Area3D) — detects the player for melee attacks",
					"Attach this script to the Boss root:",
					"",
					"    extends CharacterBody3D",
					"",
					"    signal died",
					"    signal phase_changed(phase: int)",
					"",
					"    @export var max_health: int = 500",
					"    @export var speed: float = 3.0",
					"    @export var attack_cooldown: float = 2.0",
					"    @export var phase_2_threshold: float = 0.5",
					"    @export var phase_3_threshold: float = 0.2",
					"",
					"    var health: int = max_health",
					"    var phase: int = 1",
					"    var _attack_timer: float = 0.0",
					"    var _target: Node3D = null",
					"    @onready var _agent: NavigationAgent3D = $NavigationAgent3D",
					"",
					"    func _ready() -> void:",
					"        health = max_health",
					"        var players := get_tree().get_nodes_in_group(\"player\")",
					"        if not players.is_empty():",
					"            _target = players[0]",
					"",
					"    func _physics_process(delta: float) -> void:",
					"        if not is_on_floor():",
					"            velocity += get_gravity() * delta",
					"        if _target == null or not is_instance_valid(_target):",
					"            move_and_slide()",
					"            return",
					"        _attack_timer = maxf(_attack_timer - delta, 0.0)",
					"        var distance := global_position.distance_to(_target.global_position)",
					"        if distance > 5.0:",
					"            _agent.target_position = _target.global_position",
					"            if not _agent.is_navigation_finished():",
					"                var next := _agent.get_next_path_position()",
					"                var dir := (next - global_position).normalized()",
					"                velocity.x = dir.x * speed * (1.0 + float(phase - 1) * 0.3)",
					"                velocity.z = dir.z * speed * (1.0 + float(phase - 1) * 0.3)",
					"        if _attack_timer <= 0.0 and distance < 8.0:",
					"            _attack()",
					"            _attack_timer = attack_cooldown * (1.0 - float(phase - 1) * 0.2)",
					"        move_and_slide()",
					"",
					"    func _attack() -> void:",
					"        match phase:",
					"            1:",
					"                _melee_attack()",
					"            2:",
					"                _melee_attack()",
					"                _ranged_attack()",
					"            3:",
					"                _ranged_attack()",
					"                _spawn_minions()",
					"",
					"    func _melee_attack() -> void:",
					"        if _target != null and _target.has_method(\"take_damage\"):",
					"            if global_position.distance_to(_target.global_position) < 4.0:",
					"                _target.take_damage(20)",
					"",
					"    func _ranged_attack() -> void:",
					"        # Spawn projectile from AttackPoint",
					"        pass",
					"",
					"    func _spawn_minions() -> void:",
					"        # Spawn smaller enemies",
					"        pass",
					"",
					"    func take_damage(amount: int) -> void:",
					"        health -= amount",
					"        _check_phase()",
					"        if health <= 0:",
					"            died.emit()",
					"            queue_free()",
					"",
					"    func _check_phase() -> void:",
					"        var ratio := float(health) / float(max_health)",
					"        var new_phase := 1",
					"        if ratio <= phase_3_threshold:",
					"            new_phase = 3",
					"        elif ratio <= phase_2_threshold:",
					"            new_phase = 2",
					"        if new_phase != phase:",
					"            phase = new_phase",
					"            phase_changed.emit(phase)",
					"",
					"Set the boss's collision capsule to match the model. Boss should be larger than normal enemies — 2 to 4 meters tall.",
					"Add a NavigationRegion3D in the level and bake it for the boss to path around.",
					"Place the AttackPoint Marker3D where attacks originate — the boss's hand, mouth, or weapon."
				],
				"next_steps": [
					{"blueprint": "boss_health_bar", "why": "UI showing boss health and phases."},
					{"snippet": "navigation_agent_3d", "why": "Navigation setup."},
					{"snippet": "hitstop_3d", "why": "Impact feel on hits."},
					{"snippet": "camera_shake_3d", "why": "Shake on heavy attacks."},
					{"snippet": "particle_explosion_3d", "why": "Phase transition effects."}
				],
				"mistakes": [
					"Not setting up a NavigationRegion3D means the boss can't path and walks into walls.",
					"Boss too small (under 1.5 meters) feels like a regular enemy. Make it visibly larger.",
					"Attack cooldown that doesn't decrease per phase makes later phases feel sluggish.",
					"Forgetting to connect phase_changed to visual feedback (color changes, particle effects) means the player doesn't notice the phase shift.",
					"Spawning minions without a cap floods the arena. Cap minion count to 3-5."
				]
			}
		}
	}
