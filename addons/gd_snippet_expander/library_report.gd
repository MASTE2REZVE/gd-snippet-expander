@tool
extends RefCounted

const LIBRARY_SCRIPT_PATH := "res://addons/gd_snippet_expander/library.gd"

const TARGET_SNIPPETS := 450
const TARGET_BLUEPRINTS := 80
const TARGET_TEMPLATES := 15


func generate_report() -> String:
	var lib_script = load(LIBRARY_SCRIPT_PATH)
	if lib_script == null:
		return "Could not load library.gd"
	var lib = lib_script.new()
	if lib == null:
		return "Could not instantiate library."
	lib.load_all()

	var lines: Array = []
	var v := Engine.get_version_info()
	var engine_ver := "%d.%d.%d" % [
		int(v.get("major", 0)),
		int(v.get("minor", 0)),
		int(v.get("patch", 0))
	]
	lines.append("GD Snippet Expander — Library Report")
	lines.append("Engine: Godot " + engine_ver)
	lines.append("")

	var sn_total: int = lib.snippet_count()
	var bp_total: int = lib.blueprint_count()
	var tp_total: int = lib.list_template_ids().size()

	lines.append("TOTALS")
	lines.append("  Snippets:    %d" % sn_total)
	lines.append("  Blueprints:  %d" % bp_total)
	lines.append("  Templates:   %d" % tp_total)
	lines.append("")

	lines.append("PROGRESS TOWARD TARGET")
	lines.append("  Snippets:    %d / %d  (%s)" % [sn_total, TARGET_SNIPPETS, _percent(sn_total, TARGET_SNIPPETS)])
	lines.append("  Blueprints:  %d / %d  (%s)" % [bp_total, TARGET_BLUEPRINTS, _percent(bp_total, TARGET_BLUEPRINTS)])
	lines.append("  Templates:   %d / %d  (%s)" % [tp_total, TARGET_TEMPLATES, _percent(tp_total, TARGET_TEMPLATES)])
	lines.append("")

	lines.append("SNIPPETS BY CATEGORY")
	var sn_tree := _build_tree(lib, false)
	_append_tree(lines, sn_tree, "  ")
	lines.append("")

	lines.append("BLUEPRINTS BY CATEGORY")
	var bp_tree := _build_tree(lib, true)
	_append_tree(lines, bp_tree, "  ")
	lines.append("")

	lines.append("TEMPLATE IDS")
	var tp_ids: Array = lib.list_template_ids()
	tp_ids.sort()
	for id in tp_ids:
		lines.append("  " + str(id))

	return "\n".join(lines)


func _build_tree(lib, blueprints: bool) -> Dictionary:
	var tree: Dictionary = {}
	var ids: Array = lib.list_blueprint_ids() if blueprints else lib.list_ids()
	ids.sort()
	for id in ids:
		var sid := str(id)
		var cat: String = lib.get_blueprint_category(sid) if blueprints else lib.get_category(sid)
		var sub: String = lib.get_blueprint_subcategory(sid) if blueprints else lib.get_subcategory(sid)
		if cat.is_empty():
			cat = "uncategorized"
		if sub.is_empty():
			sub = "general"
		if not tree.has(cat):
			tree[cat] = {}
		if not tree[cat].has(sub):
			tree[cat][sub] = []
		tree[cat][sub].append(sid)
	return tree


func _append_tree(lines: Array, tree: Dictionary, indent: String) -> void:
	var cats: Array = tree.keys()
	cats.sort()
	for cat in cats:
		var total := 0
		for sub in tree[cat].keys():
			total += tree[cat][sub].size()
		lines.append("%s%s (%d)" % [indent, str(cat), total])
		var subs: Array = tree[cat].keys()
		subs.sort()
		for sub in subs:
			var items: Array = tree[cat][sub]
			lines.append("%s  %s (%d)" % [indent, str(sub), items.size()])
			for item in items:
				lines.append("%s    - %s" % [indent, str(item)])


func _percent(current: int, target: int) -> String:
	if target <= 0:
		return "n/a"
	return "%d%%" % int(float(current) / float(target) * 100.0)
