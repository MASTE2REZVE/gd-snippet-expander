@tool
extends RefCounted


func get_data() -> Dictionary:
	return {
		"version": 2,
		"snippets": {
			"tilemap_autotile": {
				"phrases": ["autotile", "auto tile", "tilemap autotile", "auto terrain"],
				"code": """# Autotile setup happens in the TileSet editor, not in code.
# This snippet shows the correct workflow.

# 1. Select your TileMapLayer in the scene.
# 2. In the Inspector, click the TileSet resource to expand it.
# 3. Click the TileSet tab at the bottom of the editor.
# 4. Select the source tilesheet in the left panel.
# 5. Click 'TileSet' in the top menu -> 'Add Terrain Set'.
# 6. Name the terrain (e.g. 'grass'), pick a color.
# 7. In the tile palette at the bottom, switch to 'Terrains' mode.
# 8. Paint the terrain icon onto tiles to mark them as grass.
# 9. Switch to 'Paint' mode and draw on the map.

# To make tiles auto-connect, in the Terrains panel:
# - Set the terrain to 'Match Corners and Sides' for 47-tile autotile.
# - Or 'Match Sides' for 16-tile.
# - Match modes change how many tile variations you need to draw.

# Programmatic access (rarely needed, autotile handles most cases):
func set_tile(layer: TileMapLayer, coords: Vector2i, source_id: int, atlas_coords: Vector2i) -> void:
	layer.set_cell(coords, source_id, atlas_coords)

func erase_tile(layer: TileMapLayer, coords: Vector2i) -> void:
	layer.erase_cell(coords)

func get_tile(layer: TileMapLayer, coords: Vector2i) -> Vector2i:
	return layer.get_cell_atlas_coords(coords)
""",
				"params": [],
				"category": "tilemap",
				"subcategory": "autotile",
				"dimension": "2d",
				"difficulty": "intermediate",
				"details": {
					"what": "Workflow for setting up autotiling — tiles that automatically pick the right sprite based on neighbours. This is a comment-only snippet: no runtime code, just the process.",
					"where": "In the TileSet editor, accessed from the TileMapLayer Inspector.",
					"before": "A TileMapLayer node with a TileSet resource containing your tilesheet image.",
					"after": "Paint with the terrain tools. The engine picks the right variation automatically.",
					"why_optimized": "Autotile runs in the editor — zero runtime cost. The set_cell() calls are for procedural generation only.",
					"mistakes": "Not marking enough tiles as terrain means certain edge combinations have no matching tile. Draw the full tileset variations before painting.",
					"related": ["tilemap_collision", "tilemap_layer_setup", "tilemap_paint_programmatic"]
				}
			},
			"tilemap_collision": {
				"phrases": ["tilemap collision", "tile collision", "tileset physics", "solid tiles"],
				"code": """# Tile collision is configured on the TileSet, not the TileMapLayer.

# 1. Select the TileMapLayer -> expand TileSet in the Inspector.
# 2. Click the TileSet tab at the bottom.
# 3. In the left panel, select your tilesheet source.
# 4. Click 'TileSet' in the top menu -> 'Add Physics Layer'.
# 5. Now the paint tools have a 'Physics' mode.
# 6. Switch to 'Physics' in the palette toolbar.
# 7. Paint collision polygons on each tile you want solid.

# Bulk-select many tiles at once:
# - In the palette, drag-select a rectangle of tiles.
# - The Physics tool applies to the whole selection.

# To verify collisions, enable the debug menu:
# Debug -> Visible Collision Shapes (in the running game).

# Programmatic tile queries:
func is_wall(layer: TileMapLayer, world_position: Vector2) -> bool:
	var coords := layer.local_to_map(layer.to_local(world_position))
	var data := layer.get_cell_tile_data(coords)
	if data == null:
		return false
	return data.get_collision_polygons_count(0) > 0

func world_to_tile(layer: TileMapLayer, world_position: Vector2) -> Vector2i:
	return layer.local_to_map(layer.to_local(world_position))

func tile_to_world(layer: TileMapLayer, tile_coords: Vector2i) -> Vector2:
	return layer.to_global(layer.map_to_local(tile_coords))
""",
				"params": [],
				"category": "tilemap",
				"subcategory": "collision",
				"dimension": "2d",
				"difficulty": "intermediate",
				"details": {
					"what": "How to add collision to tiles plus helper functions for querying tile collision at runtime.",
					"where": "Configure in the TileSet editor. Use the helper functions from any script that needs to check the map.",
					"before": "A TileMapLayer with a TileSet and a tilesheet loaded.",
					"after": "For one-way collisions (jump-through platforms), use a different physics layer and set the tile's collision polygon to only cover the top edge.",
					"why_optimized": "get_cell_tile_data is O(1) — direct lookup. No scanning.",
					"mistakes": "Forgetting to add a Physics Layer to the TileSet means the collision tool doesn't appear. Add it before trying to paint.",
					"related": ["tilemap_autotile", "tilemap_layer_setup", "one_way_platform"]
				}
			},
			"tilemap_layer_setup": {
				"phrases": ["tilemap layer", "multiple tilemaps", "tile layers", "layered tilemap"],
				"code": """# In Godot 4.3+, use TileMapLayer (a single layer per node).
# In Godot 4.0-4.2, use TileMap with multiple layers in one node.

# Recommended node structure for a 2D level:
#   Level (Node2D)
#     Background (TileMapLayer)     -- behind everything, no collision
#     Ground (TileMapLayer)         -- solid tiles, collision layer 1
#     Decor (TileMapLayer)          -- bushes, rocks, no collision
#     Foreground (TileMapLayer)     -- tall grass in front of player
#     Player (CharacterBody2D)
#     Enemies (Node2D)              -- container for enemy instances

# Each TileMapLayer shares the same TileSet resource if you assign it.

func setup_layers() -> void:
	# If building layers programmatically:
	var tile_set := load("res://tilesets/level_tileset.tres")
	var ground := TileMapLayer.new()
	ground.name = "Ground"
	ground.tile_set = tile_set
	ground.z_index = 0
	ground.collision_enabled = true
	add_child(ground)

func set_z_order(layer: TileMapLayer, order: int) -> void:
	layer.z_index = order

func toggle_layer_visibility(layer: TileMapLayer, visible_state: bool) -> void:
	layer.visible = visible_state
""",
				"params": [],
				"category": "tilemap",
				"subcategory": "structure",
				"dimension": "2d",
				"difficulty": "beginner",
				"details": {
					"what": "How to structure a level with multiple TileMapLayer nodes for background, ground, decoration, and foreground.",
					"where": "Node tree setup. Two or more TileMapLayer children of your level root.",
					"before": "None.",
					"after": "Assign the same TileSet to every layer (Godot caches it), but only enable collision on layers that need it.",
					"why_optimized": "Separate layers means you can toggle visibility or z-order at runtime without touching tile data.",
					"mistakes": "Enabling collision on decorative layers makes bushes and rocks solid to the player. Only enable on the ground layer.",
					"related": ["tilemap_autotile", "tilemap_collision", "parallax_layer"]
				}
			},
			"tilemap_paint_programmatic": {
				"phrases": ["paint tile code", "tilemap code", "generate tilemap", "tilemap procedural"],
				"code": """@export var ground_source_id: int = 0
@export var ground_atlas_coords: Vector2i = Vector2i(0, 0)
@export var wall_source_id: int = 0
@export var wall_atlas_coords: Vector2i = Vector2i(1, 0)

func fill_rect(layer: TileMapLayer, from: Vector2i, to: Vector2i, source_id: int, atlas: Vector2i) -> void:
	var min_x: int = min(from.x, to.x)
	var max_x: int = max(from.x, to.x)
	var min_y: int = min(from.y, to.y)
	var max_y: int = max(from.y, to.y)
	for x in range(min_x, max_x + 1):
		for y in range(min_y, max_y + 1):
			layer.set_cell(Vector2i(x, y), source_id, atlas)

func fill_platform(layer: TileMapLayer, from_x: int, to_x: int, y: int) -> void:
	for x in range(from_x, to_x + 1):
		layer.set_cell(Vector2i(x, y), ground_source_id, ground_atlas_coords)

func fill_border(layer: TileMapLayer, width: int, height: int, source_id: int, atlas: Vector2i) -> void:
	for x in range(width):
		layer.set_cell(Vector2i(x, 0), source_id, atlas)
		layer.set_cell(Vector2i(x, height - 1), source_id, atlas)
	for y in range(height):
		layer.set_cell(Vector2i(0, y), source_id, atlas)
		layer.set_cell(Vector2i(width - 1, y), source_id, atlas)

func fill_random_patches(layer: TileMapLayer, width: int, height: int, density: float, source_id: int, atlas: Vector2i) -> void:
	for x in range(width):
		for y in range(height):
			if randf() < density:
				layer.set_cell(Vector2i(x, y), source_id, atlas)

func clear_all(layer: TileMapLayer) -> void:
	layer.clear()
""",
				"params": ["ground_source_id", "ground_atlas_coords", "wall_source_id", "wall_atlas_coords"],
				"category": "tilemap",
				"subcategory": "generation",
				"dimension": "2d",
				"difficulty": "intermediate",
				"param_info": {
					"ground_source_id": {
						"default": 0,
						"range": [0, 20],
						"what": "The source ID of your ground tilesheet in the TileSet.",
						"typical": "0 for a single-source TileSet",
						"increase": "N/A",
						"decrease": "N/A"
					},
					"ground_atlas_coords": {
						"default": [0, 0],
						"range": [],
						"what": "The tile coordinates within the tilesheet.",
						"typical": "[0, 0] for top-left tile",
						"increase": "N/A",
						"decrease": "N/A"
					}
				},
				"details": {
					"what": "Helper functions that paint tiles programmatically. Useful for procedural levels, testing, and level editors.",
					"where": "Attach to your level root or a generator script.",
					"before": "A TileMapLayer node with a TileSet. Get source_id and atlas_coords from the TileSet panel.",
					"after": "Chain these to build rooms: fill_border first, then fill_platform for floors, then fill_random_patches for decoration.",
					"why_optimized": "set_cell is a direct API call. For 10,000+ tiles, use layer.set_cells_terrain_connect to batch.",
					"mistakes": "Wrong source_id / atlas_coords means nothing appears. Verify by painting one tile manually and checking the printed coords.",
					"related": ["tilemap_autotile", "tilemap_layer_setup", "room_generator"]
				}
			},
			"tilemap_terrain_connect": {
				"phrases": ["terrain connect", "auto connect tiles", "batch autotile", "procedural autotile"],
				"code": """@export var terrain_set: int = 0
@export var terrain_id: int = 0

func paint_terrain_cells(layer: TileMapLayer, cells: Array) -> void:
	# cells is an Array of Vector2i
	layer.set_cells_terrain_connect(cells, terrain_set, terrain_id, false)

func paint_terrain_rect(layer: TileMapLayer, from: Vector2i, to: Vector2i) -> void:
	var cells: Array = []
	var min_x: int = min(from.x, to.x)
	var max_x: int = max(from.x, to.x)
	var min_y: int = min(from.y, to.y)
	var max_y: int = max(from.y, to.y)
	for x in range(min_x, max_x + 1):
		for y in range(min_y, max_y + 1):
			cells.append(Vector2i(x, y))
	layer.set_cells_terrain_connect(cells, terrain_set, terrain_id, false)

func erase_terrain_cells(layer: TileMapLayer, cells: Array) -> void:
	layer.erase_cells(cells)
""",
				"params": ["terrain_set", "terrain_id"],
				"category": "tilemap",
				"subcategory": "generation",
				"dimension": "2d",
				"difficulty": "advanced",
				"param_info": {
					"terrain_set": {
						"default": 0,
						"range": [0, 5],
						"what": "Which terrain set to use. Most projects have one.",
						"typical": "0 for the first terrain set",
						"increase": "N/A",
						"decrease": "N/A"
					},
					"terrain_id": {
						"default": 0,
						"range": [0, 20],
						"what": "Which terrain within the set (grass, dirt, stone, etc.).",
						"typical": "0 grass / 1 dirt / 2 stone",
						"increase": "N/A",
						"decrease": "N/A"
					}
				},
				"details": {
					"what": "Paints tiles with automatic terrain picking. Godot chooses the right tile variation based on neighbours.",
					"where": "Attach to a generator script. The TileSet must have at least one terrain set defined.",
					"before": "Terrain set defined in the TileSet. Tiles marked with the terrain icon in the palette.",
					"after": "For a 100x100 map, this is a single call that handles all 10,000 tiles at once. Much faster than looping set_cell.",
					"why_optimized": "Batches the terrain connect across all cells in one call. Runs at the C++ layer, not per-tile GDScript.",
					"mistakes": "Calling set_cells_terrain_connect one cell at a time defeats the purpose. Always pass the full cell array.",
					"related": ["tilemap_autotile", "tilemap_paint_programmatic", "room_generator"]
				}
			},
			"tilemap_query": {
				"phrases": ["tile query", "get tile", "check tile", "tile lookup"],
				"code": """func get_tile_at(layer: TileMapLayer, world_position: Vector2) -> Vector2i:
	return layer.local_to_map(layer.to_local(world_position))

func get_cell_type(layer: TileMapLayer, world_position: Vector2) -> String:
	var coords := get_tile_at(layer, world_position)
	var data := layer.get_cell_tile_data(coords)
	if data == null:
		return "empty"
	var terrain := data.terrain
	if terrain >= 0:
		return "terrain_" + str(terrain)
	return "solid"

func is_solid_at(layer: TileMapLayer, world_position: Vector2) -> bool:
	var coords := get_tile_at(layer, world_position)
	var data := layer.get_cell_tile_data(coords)
	if data == null:
		return false
	return data.get_collision_polygons_count(0) > 0

func find_nearest_of_type(layer: TileMapLayer, from: Vector2, source_id: int, max_distance: float = 200.0) -> Vector2:
	var best: Vector2 = from
	var best_dist: float = max_distance
	var used := layer.get_used_cells()
	for cell in used:
		if layer.get_cell_source_id(cell) != source_id:
			continue
		var world := layer.to_global(layer.map_to_local(cell))
		var d := from.distance_to(world)
		if d < best_dist:
			best_dist = d
			best = world
	return best
""",
				"params": [],
				"category": "tilemap",
				"subcategory": "query",
				"dimension": "2d",
				"difficulty": "intermediate",
				"details": {
					"what": "Query functions for reading tile data at runtime — checking if a position is solid, finding tiles by type, pathfinding helpers.",
					"where": "Attach to any script that needs to inspect the level (AI, spawners, debug tools).",
					"before": "TileMapLayer with TileSet and painted tiles.",
					"after": "Combine with AStar2D or a navigation region for pathfinding. This is best for local checks, not full pathfinding.",
					"why_optimized": "local_to_map and get_cell_tile_data are direct lookups. find_nearest scans all used cells — cache the result if called frequently.",
					"mistakes": "Calling find_nearest_of_type every frame is expensive on large maps. Cache the result or use a spatial index.",
					"related": ["tilemap_collision", "navigation_agent_2d", "raycast_2d"]
				}
			}
		}
	}
