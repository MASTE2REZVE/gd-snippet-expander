@tool
extends RefCounted


func get_data() -> Dictionary:
	return {
		"version": 2,
		"snippets": {
			"gridmap_setup": {
				"phrases": ["gridmap setup", "gridmap 3d", "3d tilemap", "grid 3d level"],
				"code": """# GridMap places 3D meshes on a grid — the 3D equivalent of TileMap.
# Perfect for blocky voxel-style levels, modular architecture, or
# dungeon layouts.

# 1. Add a GridMap node to your 3D scene.
# 2. Create a MeshLibrary resource:
#    - In the Inspector, click MeshLibrary -> New MeshLibrary
#    - Click the MeshLibrary to open it in the bottom panel
#    - Drag .glb or .obj files into the panel to add them as items
#    - Assign collision shapes per item
# 3. Set the GridMap's Cell Size (e.g. Vector3(1, 1, 1)).
# 4. Use the GridMap panel at the bottom to paint cells.

extends GridMap

@export var cell_size: Vector3 = Vector3(1, 1, 1)

func _ready() -> void:
	cell_size = cell_size

func set_cell_from_world(world_position: Vector3, item_id: int) -> void:
	var local := to_local(world_position)
	var cell := local_to_map(local)
	set_cell_item(cell, item_id)

func erase_at_world(world_position: Vector3) -> void:
	var local := to_local(world_position)
	var cell := local_to_map(local)
	set_cell_item(cell, -1)

func get_item_at_world(world_position: Vector3) -> int:
	var local := to_local(world_position)
	var cell := local_to_map(local)
	return get_cell_item(cell)
""",
				"params": ["cell_size"],
				"category": "world",
				"subcategory": "gridmap",
				"platforms": ["desktop", "mobile", "web"],
				"dimension": "3d",
				"difficulty": "intermediate",
				"param_info": {
					"cell_size": {
						"default": [1, 1, 1],
						"range": [],
						"what": "Size of each grid cell in meters. Must match your mesh scale.",
						"typical": "[1, 1, 1] standard block / [2, 2, 2] large chunks / [0.5, 0.5, 0.5] fine detail",
						"increase": "Bigger cells.",
						"decrease": "Smaller."
					}
				},
				"details": {
					"what": "3D grid-based level building. Place modular mesh pieces on a grid — walls, floors, props.",
					"where": "Add as a child of your 3D scene. Configure the MeshLibrary resource first.",
					"before": "A MeshLibrary resource with the pieces you want to place. Each piece needs a mesh and optional collision shape.",
					"after": "For large levels, consider splitting into multiple GridMap nodes by area for better culling.",
					"why_optimized": "GridMap batches all meshes into a single draw call per MeshLibrary item. Very efficient for many repeated pieces.",
					"mistakes": "Mismatched cell_size and mesh scale means gaps or overlapping pieces. Verify by placing one cell first.",
					"related": ["mesh_library_setup", "gridmap_room_builder", "gridmap_query"]
				}
			},
			"mesh_library_setup": {
				"phrases": ["mesh library", "mesh library setup", "gridmap items", "3d modular pieces"],
				"code": """# MeshLibrary is the resource that GridMap uses. Each item is a
# mesh + collision shape + optional navigation mesh.
#
# Setting up a MeshLibrary:
# 1. In your project, create a new MeshLibrary (right-click in
#    FileSystem -> New Resource -> MeshLibrary).
# 2. Save it as res://resources/level_meshlibrary.tres.
# 3. Open the MeshLibrary editor (double-click the resource).
# 4. Drag .glb, .obj, or .tscn files from FileSystem into the panel.
# 5. Each import creates an item with:
#    - Name
#    - Mesh (auto-detected from the dragged scene)
#    - Collision shape (add manually by clicking the Collision slot)
#    - Navigation mesh (optional, for AI pathfinding)
# 6. Assign the MeshLibrary to your GridMap node in the Inspector.
#
# Naming convention: prefix items by category
#   floor_01, floor_02
#   wall_straight, wall_corner, wall_door
#   prop_barrel, prop_crate

@tool
extends Node

@export var mesh_library_path: String = "res://resources/level_meshlibrary.tres"

func load_library() -> MeshLibrary:
	return load(mesh_library_path) as MeshLibrary

func list_items(library: MeshLibrary) -> Array:
	var items: Array = []
	for i in range(library.get_item_list().size()):
		items.append({
			"id": i,
			"name": library.get_item_name(i)
		})
	return items

func find_item_by_name(library: MeshLibrary, name: String) -> int:
	for i in range(library.get_item_list().size()):
		if library.get_item_name(i) == name:
			return i
	return -1
""",
				"params": ["mesh_library_path"],
				"category": "world",
				"subcategory": "gridmap",
				"platforms": ["desktop", "mobile", "web"],
				"dimension": "3d",
				"difficulty": "intermediate",
				"param_info": {
					"mesh_library_path": {
						"default": "res://resources/level_meshlibrary.tres",
						"range": [],
						"what": "Path to your MeshLibrary resource.",
						"typical": "one per style of level (dungeon, castle, tech)",
						"increase": "N/A",
						"decrease": "N/A"
					}
				},
				"details": {
					"what": "Create and manage a MeshLibrary — the palette of 3D pieces GridMap places.",
					"where": "One MeshLibrary per visual style. Assign to a GridMap in the Inspector.",
					"before": "Imported 3D models (.glb recommended for combined mesh + collision).",
					"after": "For pieces that need custom logic (doors, chests), use regular scenes instead of GridMap items.",
					"why_optimized": "MeshLibrary batches all items into a single resource. Fast to load and reference.",
					"mistakes": "Forgetting to add collision shapes means the player falls through GridMap floors.",
					"related": ["gridmap_setup", "gridmap_query", "mesh_3d"]
				}
			},
			"gridmap_room_builder": {
				"phrases": ["gridmap room", "room builder 3d", "procedural room", "gridmap level builder"],
				"code": """@export var floor_item: int = 0
@export var wall_item: int = 1
@export var ceiling_item: int = 2

func build_room(grid: GridMap, origin: Vector3i, width: int, depth: int, height: int = 3) -> void:
	# Floor
	for x in range(width):
		for z in range(depth):
			grid.set_cell_item(origin + Vector3i(x, 0, z), floor_item)
	# Ceiling
	for x in range(width):
		for z in range(depth):
			grid.set_cell_item(origin + Vector3i(x, height - 1, z), ceiling_item)
	# Walls — four sides
	for x in range(width):
		for y in range(1, height - 1):
			grid.set_cell_item(origin + Vector3i(x, y, 0), wall_item)
			grid.set_cell_item(origin + Vector3i(x, y, depth - 1), wall_item)
	for z in range(depth):
		for y in range(1, height - 1):
			grid.set_cell_item(origin + Vector3i(0, y, z), wall_item)
			grid.set_cell_item(origin + Vector3i(width - 1, y, z), wall_item)

func carve_doorway(grid: GridMap, origin: Vector3i, width: int, depth: int, height: int, side: String) -> void:
	var mid_x := width / 2
	var mid_z := depth / 2
	for y in range(1, min(3, height - 1)):
		match side:
			"north":
				grid.set_cell_item(origin + Vector3i(mid_x, y, 0), -1)
				grid.set_cell_item(origin + Vector3i(mid_x + 1, y, 0), -1)
			"south":
				grid.set_cell_item(origin + Vector3i(mid_x, y, depth - 1), -1)
				grid.set_cell_item(origin + Vector3i(mid_x + 1, y, depth - 1), -1)
			"west":
				grid.set_cell_item(origin + Vector3i(0, y, mid_z), -1)
				grid.set_cell_item(origin + Vector3i(0, y, mid_z + 1), -1)
			"east":
				grid.set_cell_item(origin + Vector3i(width - 1, y, mid_z), -1)
				grid.set_cell_item(origin + Vector3i(width - 1, y, mid_z + 1), -1)

func clear_region(grid: GridMap, origin: Vector3i, width: int, height: int, depth: int) -> void:
	for x in range(width):
		for y in range(height):
			for z in range(depth):
				grid.set_cell_item(origin + Vector3i(x, y, z), -1)
""",
				"params": ["floor_item", "wall_item", "ceiling_item"],
				"category": "world",
				"subcategory": "gridmap",
				"platforms": ["desktop", "mobile", "web"],
				"dimension": "3d",
				"difficulty": "intermediate",
				"param_info": {
					"floor_item": {
						"default": 0,
						"range": [0, 100],
						"what": "Item ID of the floor mesh in the MeshLibrary.",
						"typical": "depends on your MeshLibrary order",
						"increase": "N/A",
						"decrease": "N/A"
					},
					"wall_item": {
						"default": 1,
						"range": [0, 100],
						"what": "Item ID of the wall mesh.",
						"typical": "depends on your MeshLibrary order",
						"increase": "N/A",
						"decrease": "N/A"
					}
				},
				"details": {
					"what": "Programmatic room building on a GridMap. Creates floor, walls, ceiling, and doorways.",
					"where": "Attach to a GridMap or a level generator. Call build_room with an origin cell and dimensions.",
					"before": "GridMap with a MeshLibrary where IDs match the floor_item / wall_item / ceiling_item exports.",
					"after": "Chain multiple build_room calls to create a multi-room dungeon. Use carve_doorway to connect them.",
					"why_optimized": "Direct set_cell_item calls. For very large levels, batch with a single call per room.",
					"mistakes": "Wrong item IDs mean nothing appears or the wrong mesh is placed. Verify IDs in the MeshLibrary editor.",
					"related": ["gridmap_setup", "mesh_library_setup", "room_generator"]
				}
			},
			"gridmap_query": {
				"phrases": ["gridmap query", "gridmap get cell", "check gridmap", "gridmap lookup"],
				"code": """func get_cell_at_world(grid: GridMap, world_position: Vector3) -> Vector3i:
	var local := grid.to_local(world_position)
	return grid.local_to_map(local)

func get_item_at_world(grid: GridMap, world_position: Vector3) -> int:
	var local := grid.to_local(world_position)
	var cell := grid.local_to_map(local)
	return grid.get_cell_item(cell)

func get_world_position(grid: GridMap, cell: Vector3i) -> Vector3:
	return grid.to_global(grid.map_to_local(cell))

func is_empty_at(grid: GridMap, world_position: Vector3) -> bool:
	return get_item_at_world(grid, world_position) == -1

func get_all_cells_with_item(grid: GridMap, item_id: int) -> Array:
	var cells: Array = []
	for cell in grid.get_used_cells():
		if grid.get_cell_item(cell) == item_id:
			cells.append(cell)
	return cells

func get_cells_in_radius(grid: GridMap, center: Vector3, radius: float) -> Array:
	var cells: Array = []
	var center_cell := get_cell_at_world(grid, center)
	var radius_cells := int(ceil(radius / grid.cell_size.x))
	for x in range(-radius_cells, radius_cells + 1):
		for y in range(-radius_cells, radius_cells + 1):
			for z in range(-radius_cells, radius_cells + 1):
				var cell := center_cell + Vector3i(x, y, z)
				if grid.get_cell_item(cell) != -1:
					cells.append(cell)
	return cells

func get_neighbors_with_item(grid: GridMap, cell: Vector3i, item_id: int) -> Array:
	var neighbors: Array = []
	var offsets := [
		Vector3i(1, 0, 0), Vector3i(-1, 0, 0),
		Vector3i(0, 0, 1), Vector3i(0, 0, -1)
	]
	for offset in offsets:
		if grid.get_cell_item(cell + offset) == item_id:
			neighbors.append(cell + offset)
	return neighbors
""",
				"params": [],
				"category": "world",
				"subcategory": "gridmap",
				"platforms": ["desktop", "mobile", "web"],
				"dimension": "3d",
				"difficulty": "intermediate",
				"details": {
					"what": "Query functions for reading and searching GridMap contents. Pathfinding helpers, area checks, neighbor detection.",
					"where": "Attach to your level manager or a script that inspects the GridMap.",
					"before": "GridMap with cells placed.",
					"after": "Combine with AStar3D for pathfinding on the grid. Convert cell positions to AStar points.",
					"why_optimized": "get_used_cells returns only placed cells. Radius search is bounded by cube volume.",
					"mistakes": "Searching a large radius (over 20 cells) is slow. Use AStar3D for real pathfinding instead.",
					"related": ["gridmap_setup", "gridmap_room_builder", "navigation_agent_3d"]
				}
			},
			"gridmap_navigation": {
				"phrases": ["gridmap navigation", "gridmap pathfinding", "grid ai 3d", "gridmap nav mesh"],
				"code": """# GridMap and NavigationRegion3D work together. The mesh library
# can include navigation data per item.
#
# 1. In the MeshLibrary editor, select each walkable item (floors).
# 2. In the item properties, add a Navigation Mesh.
# 3. Or, use a NavigationRegion3D that covers the GridMap:
#    - Add NavigationRegion3D as a sibling of GridMap
#    - In its Inspector, click Bake Navigation Mesh
#    - The region uses the GridMap's collision to compute walkable area
# 4. Place a NavigationAgent3D in each AI character.

@export var nav_agent_path: NodePath

@onready var _agent: NavigationAgent3D = get_node_or_null(nav_agent_path)

func move_toward_target(target_position: Vector3, speed: float, delta: float) -> void:
	if _agent == null:
		return
	_agent.target_position = target_position
	if _agent.is_navigation_finished():
		return
	var next := _agent.get_next_path_position()
	var direction := (next - global_position).normalized()
	var body := get_parent()
	if body is CharacterBody3D:
		(body as CharacterBody3D).velocity = direction * speed
		(body as CharacterBody3D).move_and_slide()

func rebuild_navigation(grid: GridMap, region: NavigationRegion3D) -> void:
	if Engine.is_editor_hint():
		region.bake_navigation_mesh()

func find_nearest_walkable(grid: GridMap, world_position: Vector3) -> Vector3:
	# Fallback if the target position is inside a wall
	var cell := grid.local_to_map(grid.to_local(world_position))
	for radius in range(1, 10):
		for x in range(-radius, radius + 1):
			for z in range(-radius, radius + 1):
				var test := cell + Vector3i(x, 0, z)
				if grid.get_cell_item(test) != -1:
					return grid.to_global(grid.map_to_local(test))
	return world_position
""",
				"params": ["nav_agent_path"],
				"category": "world",
				"subcategory": "gridmap",
				"platforms": ["desktop", "mobile", "web"],
				"dimension": "3d",
				"difficulty": "advanced",
				"param_info": {
					"nav_agent_path": {
						"default": "",
						"range": [],
						"what": "NodePath to the NavigationAgent3D child of this character.",
						"typical": "NavigationAgent3D node",
						"increase": "N/A",
						"decrease": "N/A"
					}
				},
				"details": {
					"what": "Connects GridMap-based levels to Godot's navigation system. AI characters path through the grid.",
					"where": "NavigationRegion3D sibling of GridMap. NavigationAgent3D on each AI character.",
					"before": "GridMap with a MeshLibrary that includes navigation data on walkable items.",
					"after": "Rebake the navigation mesh whenever you add or remove GridMap cells.",
					"why_optimized": "Navigation is computed once and cached. Pathfinding per agent uses the shared nav mesh.",
					"mistakes": "Forgetting to bake means AI walks straight into walls. Rebake after every level edit.",
					"related": ["gridmap_setup", "navigation_agent_3d", "navigation_3d_extras"]
				}
			}
		}
	}
