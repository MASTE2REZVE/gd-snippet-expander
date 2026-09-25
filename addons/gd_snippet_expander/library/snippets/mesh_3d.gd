@tool
extends RefCounted


func get_data() -> Dictionary:
	return {
		"version": 2,
		"snippets": {
			"mesh_material_3d": {
				"phrases": ["standard material 3d", "pbr material", "material 3d", "make material"],
				"code": """func make_metal_material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = 0.9
	mat.roughness = 0.2
	return mat

func make_rough_material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = 0.0
	mat.roughness = 0.9
	return mat

func make_glass_material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(color.r, color.g, color.b, 0.3)
	mat.metallic = 0.1
	mat.roughness = 0.05
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	return mat

func make_emissive_material(color: Color, intensity: float = 2.0) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = intensity
	return mat

func apply_to_mesh(mesh_instance: MeshInstance3D, mat: Material) -> void:
	if mesh_instance == null or mat == null:
		return
	mesh_instance.material_override = mat
""",
				"params": [],
				"category": "mesh",
				"subcategory": "material",
				"platforms": ["desktop", "mobile", "web"],
				"dimension": "3d",
				"difficulty": "beginner",
				"details": {
					"what": "Helper functions that build common StandardMaterial3D presets — metal, rough, glass, emissive. One call each.",
					"where": "Attach to any script that needs to create materials at runtime. Or copy the pattern into your project.",
					"before": "A MeshInstance3D to apply the material to.",
					"after": "In the editor, you can also create materials as separate .tres files and reuse them across meshes.",
					"why_optimized": "StandardMaterial3D is Godot's built-in PBR material. Efficiently compiled by the engine.",
					"mistakes": "Forgetting transparency mode for glass means the alpha channel is ignored. Set transparency before using alpha colors.",
					"related": ["mesh_surface_override_3d", "mesh_swap_3d", "emissive_material_3d"]
				}
			},
			"mesh_swap_3d": {
				"phrases": ["swap mesh 3d", "change mesh", "mesh replacement", "damage state mesh"],
				"code": """extends MeshInstance3D

signal mesh_swapped(mesh_id: String)

@export var mesh_variants: Dictionary = {}

var current_variant: String = ""

func _ready() -> void:
	for key in mesh_variants.keys():
		if mesh_variants[key] is PackedScene:
			push_warning("mesh_variants should contain Mesh resources, not scenes: " + str(key))

func swap_to(variant_id: String) -> bool:
	if not mesh_variants.has(variant_id):
		push_warning("No mesh variant named: " + variant_id)
		return false
	var new_mesh = mesh_variants[variant_id]
	if new_mesh is Mesh:
		mesh = new_mesh
		current_variant = variant_id
		mesh_swapped.emit(variant_id)
		return true
	return false

func swap_mesh_direct(new_mesh: Mesh) -> void:
	if new_mesh != null:
		mesh = new_mesh
		current_variant = ""

func restore_original() -> void:
	# Call this to swap back to whatever mesh was assigned in the editor
	pass
""",
				"params": ["mesh_variants"],
				"category": "mesh",
				"subcategory": "swap",
				"platforms": ["desktop", "mobile", "web"],
				"dimension": "3d",
				"difficulty": "beginner",
				"param_info": {
					"mesh_variants": {
						"default": {},
						"range": [],
						"what": "Dictionary mapping string IDs to Mesh resources.",
						"typical": "{\"full\": mesh_full, \"damaged\": mesh_damaged, \"broken\": mesh_broken}",
						"increase": "More states.",
						"decrease": "Fewer."
					}
				},
				"details": {
					"what": "Swaps a MeshInstance3D's mesh at runtime. Useful for damage states, modular weapons, or visual upgrades.",
					"where": "Attach to a MeshInstance3D. Assign mesh_variants in the Inspector with Mesh resources.",
					"before": "Multiple Mesh resources saved as .tres or .res files, or imported models with individual meshes.",
					"after": "Connect mesh_swapped to play a transition animation or particle effect.",
					"why_optimized": "Setting .mesh is a single property assignment. No re-instantiation.",
					"mistakes": "Assigning PackedScenes to mesh_variants instead of Mesh resources causes silent failure. Use Mesh resources directly.",
					"related": ["mesh_surface_override_3d", "equipment_visual_swap", "mesh_material_3d"]
				}
			},
			"mesh_fade_3d": {
				"phrases": ["fade mesh 3d", "mesh transparency 3d", "dissolve mesh 3d", "mesh alpha 3d"],
				"code": """extends MeshInstance3D

@export var fade_duration: float = 0.5
@export var transparent_material: StandardMaterial3D

var _fading: bool = false

func fade_out() -> void:
	if _fading:
		return
	_fading = true
	_ensure_transparent()
	var tween := create_tween()
	tween.tween_property(self, "transparency", 1.0, fade_duration)
	await tween.finished
	_fading = false

func fade_in() -> void:
	if _fading:
		return
	_fading = true
	var tween := create_tween()
	tween.tween_property(self, "transparency", 0.0, fade_duration)
	await tween.finished
	_fading = false

func set_alpha(alpha: float) -> void:
	_ensure_transparent()
	transparency = clampf(1.0 - alpha, 0.0, 1.0)

func _ensure_transparent() -> void:
	if material_override != null:
		return
	# Duplicate the mesh's material so we can modify transparency without
	# affecting other instances
	var current := get_surface_override_material(0)
	if current == null:
		current = get_active_material(0)
	if current == null:
		return
	var mat := current.duplicate() as BaseMaterial3D
	if mat == null:
		return
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	set_surface_override_material(0, mat)
""",
				"params": ["fade_duration", "transparent_material"],
				"category": "mesh",
				"subcategory": "fade",
				"platforms": ["desktop", "mobile", "web"],
				"dimension": "3d",
				"difficulty": "intermediate",
				"param_info": {
					"fade_duration": {
						"default": 0.5,
						"range": [0.1, 3.0],
						"what": "How long the fade takes.",
						"typical": "0.2 quick / 0.5 standard / 1.5+ cinematic",
						"increase": "Slower fade.",
						"decrease": "Faster."
					}
				},
				"details": {
					"what": "Fades a MeshInstance3D in or out by animating the built-in transparency property.",
					"where": "Attach to a MeshInstance3D. The script duplicates the mesh material and enables transparency automatically.",
					"before": "A mesh with a material assigned. Godot's built-in transparency works with StandardMaterial3D or any BaseMaterial3D.",
					"after": "For a dissolve effect with a burning edge, use shader_dissolve on the material instead.",
					"why_optimized": "MeshInstance3D's built-in transparency property is a single float. No shader parameters needed.",
					"mistakes": "Forgetting to duplicate the material means fading this mesh also fades every other mesh sharing the material.",
					"related": ["shader_dissolve", "mesh_swap_3d", "fade_in_ui"]
				}
			},
			"mesh_outline_3d": {
				"phrases": ["3d outline", "mesh outline 3d", "inverted hull", "object outline 3d"],
				"code": """// Save this as res://shaders/outline_3d.gdshader
// Applied to a second MeshInstance3D that shares the same mesh,
// scaled slightly larger with a solid color. This is the "inverted
// hull" technique — cheap and works with any mesh.

shader_type spatial;
render_mode unshaded, cull_front, depth_draw_opaque;

uniform vec4 outline_color : source_color = vec4(1.0, 0.0, 0.0, 1.0);
uniform float outline_size : hint_range(0.0, 0.5) = 0.05;

void vertex() {
	// Push vertices outward along the normal
	VERTEX += NORMAL * outline_size;
}

void fragment() {
	ALBEDO = outline_color.rgb;
	ALPHA = outline_color.a;
}

// USAGE
// 1. Duplicate the MeshInstance3D you want to outline.
// 2. Give it a new name like 'OutlineOverlay'.
// 3. Apply a ShaderMaterial using this shader to the outline mesh.
// 4. Set the shader's outline_color and outline_size.
// 5. Parent the outline mesh to the original so they move together.
// 6. Enable outline only when the object is selected/highlighted.
//
// function example:
extends MeshInstance3D

@export var outline_material: ShaderMaterial

func set_outline_visible(value: bool) -> void:
	if outline_material != null:
		outline_material.set_shader_parameter("outline_color",
			Color(1, 0, 0, 1) if value else Color(0, 0, 0, 0))
""",
				"params": ["outline_color", "outline_size"],
				"category": "mesh",
				"subcategory": "shader",
				"platforms": ["desktop", "mobile"],
				"dimension": "3d",
				"difficulty": "intermediate",
				"param_info": {
					"outline_color": {
						"default": [1, 0, 0, 1],
						"range": [],
						"what": "Color of the outline.",
						"typical": "red enemy / yellow target / cyan highlight / white selection",
						"increase": "N/A",
						"decrease": "N/A"
					},
					"outline_size": {
						"default": 0.05,
						"range": [0.005, 0.5],
						"what": "How far the outline mesh expands from the original. In world units.",
						"typical": "0.01 thin / 0.05 standard / 0.15 thick",
						"increase": "Thicker outline.",
						"decrease": "Thinner."
					}
				},
				"details": {
					"what": "3D object outlines via the inverted hull technique. Duplicate the mesh, expand it slightly, render only the back faces.",
					"where": "Save the shader as a .gdshader file. Create a duplicate MeshInstance3D child with this material.",
					"before": "A MeshInstance3D to outline.",
					"after": "For selection highlights in an RTS or editor, toggle the outline shader based on which object is selected.",
					"why_optimized": "Inverted hull is one extra draw call per outlined object. Much cheaper than a post-process edge detection.",
					"mistakes": "Not enabling cull_front means the outline renders on top of the original mesh. The shader above includes it.",
					"related": ["shader_outline", "mesh_material_3d", "selection_highlight_3d"]
				}
			},
			"multimesh_instancing_3d": {
				"phrases": ["multimesh", "instancing 3d", "many objects 3d", "performance instancing"],
				"code": """extends MultiMeshInstance3D

@export var source_mesh: Mesh
@export var instance_count: int = 1000
@export var area_size: float = 100.0

func _ready() -> void:
	_setup()

func _setup() -> void:
	if source_mesh == null:
		source_mesh = mesh
	if source_mesh == null:
		push_warning("MultiMeshInstance3D needs a source mesh.")
		return
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = source_mesh
	mm.instance_count = instance_count
	multimesh = mm
	_scatter_instances()

func _scatter_instances() -> void:
	if multimesh == null:
		return
	for i in range(multimesh.instance_count):
		var x := randf_range(-area_size, area_size)
		var z := randf_range(-area_size, area_size)
		var t := Transform3D()
		t.origin = Vector3(x, 0, z)
		t.basis = Basis.from_euler(Vector3(0, randf() * TAU, 0))
		multimesh.set_instance_transform(i, t)

func set_instance_position(index: int, position: Vector3, rotation_y: float = 0.0) -> void:
	if multimesh == null or index < 0 or index >= multimesh.instance_count:
		return
	var t := Transform3D()
	t.origin = position
	t.basis = Basis.from_euler(Vector3(0, rotation_y, 0))
	multimesh.set_instance_transform(index, t)

func update_all_positions(positions: Array) -> void:
	if multimesh == null:
		return
	for i in range(min(positions.size(), multimesh.instance_count)):
		var p: Vector3 = positions[i]
		var t := Transform3D()
		t.origin = p
		multimesh.set_instance_transform(i, t)
""",
				"params": ["source_mesh", "instance_count", "area_size"],
				"category": "mesh",
				"subcategory": "instancing",
				"platforms": ["desktop", "mobile", "web"],
				"dimension": "3d",
				"difficulty": "intermediate",
				"param_info": {
					"instance_count": {
						"default": 1000,
						"range": [1, 100000],
						"what": "How many instances to render.",
						"typical": "100 small scene / 1000 standard / 10000+ particle-like",
						"increase": "More instances.",
						"decrease": "Fewer."
					},
					"area_size": {
						"default": 100.0,
						"range": [1.0, 1000.0],
						"what": "Half-width of the scatter area, in meters.",
						"typical": "10 small / 100 standard / 500+ open world",
						"increase": "Larger area.",
						"decrease": "Smaller."
					}
				},
				"details": {
					"what": "Renders thousands of copies of the same mesh in a single draw call. The correct way to have grass, trees, rocks, or debris.",
					"where": "Attach to a MultiMeshInstance3D. Assign source_mesh in the Inspector.",
					"before": "A Mesh resource (BoxMesh, or an imported model).",
					"after": "For per-instance color, set the MultiMesh's color_format and use set_instance_color.",
					"why_optimized": "One draw call for all instances. This is the single biggest 3D performance win available.",
					"mistakes": "Creating 1000 separate MeshInstance3D nodes instead of a MultiMesh kills performance. Any repeat count above ~50 should use MultiMesh.",
					"related": ["mesh_3d", "particles_3d", "gridmap_setup"]
				}
			},
			"mesh_surface_override_3d": {
				"phrases": ["surface override", "mesh surface material", "override material", "per surface material"],
				"code": """extends MeshInstance3D

func set_surface_material(surface_index: int, material: Material) -> void:
	if mesh == null:
		return
	if surface_index < 0 or surface_index >= mesh.get_surface_count():
		push_warning("Surface index out of range: " + str(surface_index))
		return
	set_surface_override_material(surface_index, material)

func get_surface_material(surface_index: int) -> Material:
	return get_surface_override_material(surface_index)

func clear_all_overrides() -> void:
	if mesh == null:
		return
	for i in range(mesh.get_surface_count()):
		set_surface_override_material(i, null)

func list_surfaces() -> Array:
	if mesh == null:
		return []
	var out: Array = []
	for i in range(mesh.get_surface_count()):
		out.append({
			"index": i,
			"override": get_surface_override_material(i),
			"active": get_active_material(i)
		})
	return out

# USAGE for character colors:
# 1. Import a character model with multiple surfaces (body, hair, outfit).
# 2. Find which surface index corresponds to which part (use list_surfaces).
# 3. Apply custom materials to just the outfit surface:
#    set_surface_material(2, my_custom_outfit_material)
#
# Works for: player customization, enemy variants, faction colors,
# seasonal skins.
""",
				"params": [],
				"category": "mesh",
				"subcategory": "material",
				"platforms": ["desktop", "mobile", "web"],
				"dimension": "3d",
				"difficulty": "intermediate",
				"details": {
					"what": "Override specific surface materials on a mesh without touching the others. Character customization, faction colors, enemy variants.",
					"where": "Attach to a MeshInstance3D. Call set_surface_material with the index of the surface you want to change.",
					"before": "A mesh with multiple surfaces (multiple materials imported with the model).",
					"after": "For a whole-model recolor, use material_override instead. For one part, use this.",
					"why_optimized": "Override materials are a reference swap — no mesh rebuild. Applied per draw call.",
					"mistakes": "Using surface_override for everything wastes memory. Clear overrides when a character is despawned to free memory.",
					"related": ["mesh_material_3d", "mesh_swap_3d", "equipment_visual_swap"]
				}
			}
		}
	}
