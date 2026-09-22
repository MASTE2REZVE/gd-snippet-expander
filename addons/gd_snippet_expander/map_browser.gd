@tool
extends Node

signal item_selected(kind: String, id: String)

const KIND_SNIPPET := "snippet"
const KIND_BLUEPRINT := "blueprint"
const UNGROUPED := "_ungrouped"

const COLOR_CATEGORY := Color(1.0, 0.85, 0.4)
const COLOR_SUBCATEGORY := Color(0.55, 0.85, 1.0)
const COLOR_BRANCH := Color(0.75, 0.75, 0.75)
const COLOR_BLUEPRINT_LEAF := Color(0.7, 0.95, 0.7)
const COLOR_SNIPPET_LEAF := Color(0.95, 0.9, 0.8)

var _tree: Tree = null
var _library = null


func build_tree(tree: Tree, library) -> void:
	_tree = tree
	_library = library
	tree.clear()
	var root := tree.create_item()
	root.set_text(0, "Library")
	root.set_selectable(0, false)
	root.set_custom_color(0, Color(1, 1, 1))

	var browse: Dictionary = library.get_browse_tree()
	var categories: Array = browse.keys()
	categories.sort()

	for category in categories:
		var cat_bucket: Dictionary = browse[category]
		var total := _count_entries(cat_bucket)
		if total == 0:
			continue
		var cat_item := tree.create_item(root)
		cat_item.set_text(0, _pretty_category(str(category)))
		cat_item.set_selectable(0, false)
		cat_item.set_custom_color(0, COLOR_CATEGORY)

		var subcategories: Array = cat_bucket.keys()
		subcategories.sort()

		for subcat in subcategories:
			var sub_bucket: Dictionary = cat_bucket[subcat]
			var sub_count := _count_entries_for(sub_bucket)
			if sub_count == 0:
				continue

			var parent_item: TreeItem = cat_item
			if str(subcat) != UNGROUPED:
				parent_item = tree.create_item(cat_item)
				parent_item.set_text(0, _pretty_subcategory(str(subcat)))
				parent_item.set_selectable(0, false)
				parent_item.set_custom_color(0, COLOR_SUBCATEGORY)

			var blueprints: Array = sub_bucket.get("blueprints", [])
			if not blueprints.is_empty():
				var bp_branch := tree.create_item(parent_item)
				bp_branch.set_text(0, "Blueprints")
				bp_branch.set_selectable(0, false)
				bp_branch.set_custom_color(0, COLOR_BRANCH)
				for bp_id in blueprints:
					_add_blueprint_leaf(bp_branch, str(bp_id))

			var snippets: Array = sub_bucket.get("snippets", [])
			if not snippets.is_empty():
				var sn_branch := tree.create_item(parent_item)
				sn_branch.set_text(0, "Snippets")
				sn_branch.set_selectable(0, false)
				sn_branch.set_custom_color(0, COLOR_BRANCH)
				for sn_id in snippets:
					_add_snippet_leaf(sn_branch, str(sn_id))


func connect_tree_signal() -> void:
	if _tree == null:
		return
	if not _tree.item_selected.is_connected(_on_item_selected):
		_tree.item_selected.connect(_on_item_selected)


func _on_item_selected() -> void:
	if _tree == null:
		return
	var item: TreeItem = _tree.get_selected()
	if item == null:
		return
	var meta = item.get_metadata(0)
	if meta == null or not (meta is Dictionary):
		return
	var data: Dictionary = meta
	item_selected.emit(str(data.get("kind", "")), str(data.get("id", "")))


# =========================================================================
# Leaf builders
# =========================================================================

func _add_blueprint_leaf(parent: TreeItem, bp_id: String) -> void:
	var bp: Dictionary = _library.get_blueprint(bp_id)
	if bp.is_empty():
		return
	var title := str(bp.get("title", bp_id))
	var leaf := _tree.create_item(parent)
	leaf.set_text(0, title)
	leaf.set_custom_color(0, COLOR_BLUEPRINT_LEAF)
	leaf.set_metadata(0, {"kind": KIND_BLUEPRINT, "id": bp_id})
	leaf.set_tooltip_text(0, bp_id)


func _add_snippet_leaf(parent: TreeItem, sn_id: String) -> void:
	var phrases: Array = _library.phrases_for(sn_id)
	var label := str(phrases[0]) if not phrases.is_empty() else sn_id
	var leaf := _tree.create_item(parent)
	leaf.set_text(0, label)
	leaf.set_custom_color(0, COLOR_SNIPPET_LEAF)
	leaf.set_metadata(0, {"kind": KIND_SNIPPET, "id": sn_id})
	leaf.set_tooltip_text(0, sn_id)


# =========================================================================
# Counts
# =========================================================================

func _count_entries(cat_bucket: Dictionary) -> int:
	var total := 0
	for sub in cat_bucket.keys():
		total += _count_entries_for(cat_bucket[sub])
	return total


func _count_entries_for(bucket: Dictionary) -> int:
	var n := 0
	n += bucket.get("snippets", []).size()
	n += bucket.get("blueprints", []).size()
	return n


# =========================================================================
# Pretty labels
# =========================================================================

func _pretty_category(cat: String) -> String:
	if cat.is_empty():
		return "Uncategorized"
	var acronym := _acronym(cat)
	if not acronym.is_empty():
		return acronym
	return _title_case(cat)


func _pretty_subcategory(sub: String) -> String:
	if sub.is_empty() or sub == UNGROUPED:
		return "General"
	var acronym := _acronym(sub)
	if not acronym.is_empty():
		return acronym
	return _title_case(sub)


func _acronym(text: String) -> String:
	match text.to_lower():
		"ai": return "AI"
		"ui": return "UI"
		"ux": return "UX"
		"hud": return "HUD"
		"rpg": return "RPG"
		"fps": return "FPS"
		"tps": return "TPS"
		"npc": return "NPC"
		"pvp": return "PvP"
		"pve": return "PvE"
		"mmo": return "MMO"
		"sfx": return "SFX"
		"bgm": return "BGM"
		"2d": return "2D"
		"3d": return "3D"
		"2.5d": return "2.5D"
		"io": return "IO"
		"rpc": return "RPC"
		"api": return "API"
		"json": return "JSON"
		"csv": return "CSV"
		_: return ""


func _title_case(text: String) -> String:
	var parts := text.split("_", false)
	var out: Array = []
	for p in parts:
		var s := str(p)
		if s.length() > 0:
			out.append(s.substr(0, 1).to_upper() + s.substr(1))
	return " ".join(out)
