@tool
extends Node

signal item_selected(kind: String, id: String)

const KIND_SNIPPET := "snippet"
const KIND_BLUEPRINT := "blueprint"

var _tree: Tree = null
var _library = null


func build_tree(tree: Tree, library) -> void:
	_tree = tree
	_library = library
	tree.clear()
	var root := tree.create_item()
	root.set_text(0, "Library")
	root.set_selectable(0, false)

	var category_index: Dictionary = library.get_category_index()
	var categories: Array = category_index.keys()
	categories.sort()

	for category in categories:
		var bucket: Dictionary = category_index[category]
		var cat_item := tree.create_item(root)
		cat_item.set_text(0, _pretty_category(str(category)))
		cat_item.set_selectable(0, false)

		var blueprints: Array = bucket.get("blueprints", [])
		if not blueprints.is_empty():
			var bp_branch := tree.create_item(cat_item)
			bp_branch.set_text(0, "Blueprints")
			bp_branch.set_selectable(0, false)
			blueprints.sort()
			for bp_id in blueprints:
				var bp: Dictionary = library.get_blueprint(str(bp_id))
				if bp.is_empty():
					continue
				var title := str(bp.get("title", bp_id))
				var leaf := tree.create_item(bp_branch)
				leaf.set_text(0, title)
				leaf.set_metadata(0, {"kind": KIND_BLUEPRINT, "id": str(bp_id)})
				leaf.set_tooltip_text(0, str(bp_id))

		var snippets: Array = bucket.get("snippets", [])
		if not snippets.is_empty():
			var sn_branch := tree.create_item(cat_item)
			sn_branch.set_text(0, "Snippets")
			sn_branch.set_selectable(0, false)
			snippets.sort()
			for sn_id in snippets:
				var phrases: Array = library.phrases_for(str(sn_id))
				var label := str(phrases[0]) if not phrases.is_empty() else str(sn_id)
				var leaf := tree.create_item(sn_branch)
				leaf.set_text(0, label)
				leaf.set_metadata(0, {"kind": KIND_SNIPPET, "id": str(sn_id)})
				leaf.set_tooltip_text(0, str(sn_id))


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


func _pretty_category(cat: String) -> String:
	if cat.is_empty():
		return "Uncategorized"
	var s := cat.capitalize()
	return s
