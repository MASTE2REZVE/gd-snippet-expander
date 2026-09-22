@tool
extends Node

const BLUEPRINT_BUILDER_PATH := "res://addons/gd_snippet_expander/blueprint_builder.gd"


func apply(template_id: String, library, editor_interface: EditorInterface) -> Dictionary:
	var template: Dictionary = library.get_template(template_id)
	if template.is_empty():
		return {"ok": false, "message": "Template not found: " + template_id}

	if editor_interface.get_edited_scene_root() == null:
		return {"ok": false, "message": "No scene open. Open or create a scene first."}

	var builder_script = load(BLUEPRINT_BUILDER_PATH)
	if builder_script == null:
		return {"ok": false, "message": "Blueprint builder not found."}
	var builder = builder_script.new()

	var steps: Array = template.get("steps", [])
	var built: Array = []
	var snippets: Array = []
	var failures: Array = []

	for step in steps:
		var kind := str(step.get("kind", ""))
		var id := str(step.get("id", ""))
		if kind == "blueprint":
			var result: Dictionary = builder.build(id, library, editor_interface)
			if result.get("ok", false):
				built.append(id)
			else:
				failures.append(id + ": " + str(result.get("message", "unknown")))
		elif kind == "snippet":
			snippets.append(id)
		else:
			failures.append("unknown step kind: " + kind)

	var title := str(template.get("title", template_id))
	var msg := "Applied template: " + title + "\n"
	msg += "Built %d blueprints. %d snippets need manual placement." % [built.size(), snippets.size()]
	if not failures.is_empty():
		msg += "\n\nFailures:\n" + "\n".join(failures)

	return {
		"ok": true,
		"message": msg,
		"title": title,
		"built": built,
		"snippets": snippets,
		"failures": failures
	}
