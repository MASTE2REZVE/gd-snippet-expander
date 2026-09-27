# res://addons/gd_snippet_expander/ai_debugger/feature_extractor.gd
@tool
class_name FeatureExtractor
extends RefCounted

## Turns (AST + English query + user history) into a feature vector
## for the mini AI debugger's classifier.
##
## Part of the GD Snippet Expander mini AI debugger (v1.6).
##
## The classifier is a feed-forward network with a 200-dim input.
## This file produces that input by embedding three separate signals
## and blending them with fixed weights:
##
##   query   0.60   the user's English text, embedded
##   ast     0.30   the structure of the current script, embedded
##   history 0.10   recent fixes the user has applied, embedded
##
## All three sources use the same Embedding table. English words and
## GDScript tokens share one vector space, so blending them is
## meaningful rather than arbitrary.
##
## AST-to-tokens: we walk the parse tree and emit every node's kind
## ("funcdecl", "ifstmt", "assignstmt"), the important scalar fields
## (name, op, base, type), and string-literal contents. That gives
## the embedder a compact fingerprint of "what this script looks
## like" that pools to a 200-dim vector alongside the query vector.
##
## Usage:
##   var fe := FeatureExtractor.new()
##   fe.set_embedding(embedding_instance)
##   var v := fe.extract(ast_dict, ["jump", "player"], ["jump_fix_1"])
##   # v is PackedFloat32Array of length 200, L2-normalized.
##
## If no embedding is set, extract() returns a zero vector of the
## correct length so downstream code doesn't crash in stub mode.

const FEATURE_DIM := 200
const QUERY_WEIGHT := 0.60
const AST_WEIGHT := 0.30
const HISTORY_WEIGHT := 0.10

# Scalar fields on AST nodes that carry meaningful strings. We emit
# each of these into the token stream so the embedder sees them.
const _AST_SCALAR_KEYS := ["name", "op", "base", "type", "var_name"]

# --- internal state -----------------------------------------------------

var _embedding: Embedding = null


# --- setup --------------------------------------------------------------

## Attach an Embedding instance. Safe to call before or after build.
## Passing null puts the extractor into stub mode (zero vectors out).
func set_embedding(em: Embedding) -> void:
	_embedding = em


func has_embedding() -> bool:
	return _embedding != null


# --- main entry ---------------------------------------------------------

## Produce the 200-dim feature vector.
##   ast            — a Program node from GDScriptParser.parse()
##   query_tokens   — English tokens from EnglishTokenizer.tokenize()
##   history_tokens — recent fix IDs the user has applied, already
##                    tokenized. Pass [] on cold start.
func extract(ast: Dictionary, query_tokens: Array, history_tokens: Array) -> PackedFloat32Array:
	if _embedding == null:
		return _zero_vector()

	var q_vec: PackedFloat32Array = _embedding.embed(query_tokens)

	var ast_toks: Array[String] = ast_to_tokens(ast)
	var a_vec: PackedFloat32Array = _embedding.embed(ast_toks)

	var h_vec: PackedFloat32Array = _embedding.embed(history_tokens)

	var out: PackedFloat32Array = PackedFloat32Array()
	out.resize(FEATURE_DIM)
	var i: int = 0
	while i < FEATURE_DIM:
		out[i] = QUERY_WEIGHT * q_vec[i] \
			+ AST_WEIGHT * a_vec[i] \
			+ HISTORY_WEIGHT * h_vec[i]
		i += 1
	return _l2_normalize(out)


# --- AST walker ---------------------------------------------------------

## Walk the AST and return a flat list of tokens that describe it.
## Emits node kinds lowercased ("funcdecl", "ifstmt"), scalar field
## values ("hurt", ">", "int"), and string-literal contents with the
## quotes stripped. Order is pre-order traversal.
func ast_to_tokens(ast: Dictionary) -> Array[String]:
	var out: Array[String] = []
	_walk_ast(ast, out)
	return out


func _walk_ast(node: Dictionary, out: Array[String]) -> void:
	if node.is_empty():
		return

	var kind: String = str(node.get("kind", ""))
	if kind != "":
		out.append(kind.to_lower())

	# Emit scalar fields that carry meaning.
	var k: int = 0
	while k < _AST_SCALAR_KEYS.size():
		var key: String = _AST_SCALAR_KEYS[k]
		if node.has(key):
			var val: String = str(node[key])
			if _is_meaningful_string(val):
				out.append(val.to_lower())
		k += 1

	# Literal string values: strip quotes and lowercase.
	if kind == "Literal":
		var lit_type: String = str(node.get("literal_type", ""))
		if lit_type == "string":
			var raw: String = str(node.get("value", ""))
			raw = _strip_quotes(raw)
			if _is_meaningful_string(raw):
				out.append(raw.to_lower())
		elif lit_type == "bool":
			out.append("bool")
		elif lit_type == "null":
			out.append("null")
		elif lit_type == "number":
			out.append("number")

	# Annotations get a prefix so "export" doesn't collide with an
	# identifier named "export".
	if kind == "Annotation":
		var aname: String = str(node.get("name", ""))
		if aname != "":
			out.append("annotation_" + aname.to_lower())

	# Recurse. Iterate keys in sorted order so the token stream is
	# deterministic — useful for tests and for caching.
	var keys: Array = node.keys()
	keys.sort()
	var i: int = 0
	while i < keys.size():
		var kname: String = str(keys[i])
		var v: Variant = node[kname]
		if v is Dictionary:
			_walk_ast(v, out)
		elif v is Array:
			var arr: Array = v
			var j: int = 0
			while j < arr.size():
				var item: Variant = arr[j]
				if item is Dictionary:
					_walk_ast(item, out)
				j += 1
		i += 1


func _is_meaningful_string(s: String) -> bool:
	if s == "":
		return false
	if s == "null" or s == "true" or s == "false":
		return false
	return true


func _strip_quotes(s: String) -> String:
	var out: String = s
	if out.begins_with("\"\"\"") and out.ends_with("\"\"\""):
		out = out.substr(3, out.length() - 6)
	elif out.begins_with("'''") and out.ends_with("'''"):
		out = out.substr(3, out.length() - 6)
	elif out.length() >= 2:
		var first: String = out[0]
		var last: String = out[out.length() - 1]
		if (first == "\"" and last == "\"") or (first == "'" and last == "'"):
			out = out.substr(1, out.length() - 2)
	return out


# --- diagnostics --------------------------------------------------------

## Returns a Dictionary of {node_kind_lowercase: count} for the whole
## AST. Useful for print() during development.
func describe_ast(ast: Dictionary) -> Dictionary:
	var counts: Dictionary = {}
	_count_kinds(ast, counts)
	return counts


func _count_kinds(node: Dictionary, counts: Dictionary) -> void:
	if node.is_empty():
		return
	var kind: String = str(node.get("kind", ""))
	if kind != "":
		var lk: String = kind.to_lower()
		counts[lk] = int(counts.get(lk, 0)) + 1
	var keys: Array = node.keys()
	var i: int = 0
	while i < keys.size():
		var v: Variant = node[keys[i]]
		if v is Dictionary:
			_count_kinds(v, counts)
		elif v is Array:
			var arr: Array = v
			var j: int = 0
			while j < arr.size():
				var item: Variant = arr[j]
				if item is Dictionary:
					_count_kinds(item, counts)
				j += 1
		i += 1


# --- helpers ------------------------------------------------------------

func _zero_vector() -> PackedFloat32Array:
	var z: PackedFloat32Array = PackedFloat32Array()
	z.resize(FEATURE_DIM)
	return z


func _l2_normalize(v: PackedFloat32Array) -> PackedFloat32Array:
	var mag: float = 0.0
	for x in v:
		mag += x * x
	mag = sqrt(mag)
	if mag <= 0.0:
		return v
	var out: PackedFloat32Array = PackedFloat32Array()
	out.resize(v.size())
	var i: int = 0
	while i < v.size():
		out[i] = v[i] / mag
		i += 1
	return out


# --- self-test ----------------------------------------------------------

## Builds a small mock embedding, parses a couple of sample scripts,
## extracts features, and verifies the output is a 200-dim
## L2-normalized vector with the expected qualitative properties.
## Pass condition: "OK" printed at the end.
static func self_test() -> void:
	print("=== FeatureExtractor self-test ===")
	var failures: Array[String] = []

	# --- 1. Stub mode (no embedding attached) ---
	var fe_stub: FeatureExtractor = FeatureExtractor.new()
	var v_stub: PackedFloat32Array = fe_stub.extract({"kind": "Program"}, ["jump"], [])
	if v_stub.size() != FeatureExtractor.FEATURE_DIM:
		failures.append("1: stub vector wrong size (%d)" % v_stub.size())
	var ssum: float = 0.0
	for x in v_stub:
		ssum += abs(x)
	if ssum > 0.00001:
		failures.append("1: stub extract should be zero vector")

	# --- 2. Build a mock embedding with just enough vocabulary ---
	var em: Embedding = Embedding.new()
	em.dim = Embedding.DIM
	# Small orthogonal basis: query direction, ast direction, history
	# direction. Each vocab token gets a vector so we can verify that
	# blending works.
	var e_query: Array = [1.0, 0.0, 0.0, 0.0]
	var e_ast:   Array = [0.0, 1.0, 0.0, 0.0]
	var e_hist:  Array = [0.0, 0.0, 1.0, 0.0]
	em._vectors["jump"]        = _mk_vec(e_query)
	em._vectors["player"]      = _mk_vec(e_query)
	em._vectors["funcdecl"]    = _mk_vec(e_ast)
	em._vectors["passstmt"]    = _mk_vec(e_ast)
	em._vectors["ready"]       = _mk_vec(e_ast)
	em._vectors["ifstmt"]      = _mk_vec(e_ast)
	em._vectors["apply_jump"]  = _mk_vec(e_hist)

	# --- 3. Attach and extract from a real parse ---
	var lx: GDScriptLexer = GDScriptLexer.new()
	var pr: GDScriptParser = GDScriptParser.new()
	var fe: FeatureExtractor = FeatureExtractor.new()
	fe.set_embedding(em)

	var src: String = "func _ready():\n\tpass\n"
	var toks: Array = lx.tokenize(src)
	var ast: Dictionary = pr.parse(toks, "<test>")
	if not pr.errors.is_empty():
		failures.append("3: parser errors on sample")

	var v: PackedFloat32Array = fe.extract(ast, ["jump", "player"], [])
	if v.size() != FeatureExtractor.FEATURE_DIM:
		failures.append("3: vector wrong size")

	# Magnitude should be 1 after L2 normalize.
	var mag: float = 0.0
	for x in v:
		mag += x * x
	mag = sqrt(mag)
	if abs(mag - 1.0) > 0.001:
		failures.append("3: not L2-normalized, mag=%f" % mag)

	# Query side should carry the most weight: v[0] should be
	# dominated by the query direction (0.60) plus ast (0.30) plus
	# history (0.10).
	if v[0] <= 0.0:
		failures.append("3: query component missing (v[0]=%f)" % v[0])
	if v[1] <= 0.0:
		failures.append("3: ast component missing (v[1]=%f)" % v[1])

	# Query weight (0.60) should exceed AST weight (0.30) before
	# normalization. After normalization the ratio is preserved.
	if v[0] <= v[1]:
		failures.append("3: query weight should dominate ast weight, got q=%f a=%f" % [v[0], v[1]])

	# --- 4. Adding history should nudge the third axis ---
	var v_hist: PackedFloat32Array = fe.extract(ast, ["jump", "player"], ["apply_jump"])
	if v_hist[2] <= v[2]:
		failures.append("4: history should increase v[2], got %f -> %f" % [v[2], v_hist[2]])

	# --- 5. ast_to_tokens produces a stable, non-empty list ---
	var ast_toks: Array[String] = fe.ast_to_tokens(ast)
	if ast_toks.is_empty():
		failures.append("5: ast_to_tokens returned empty")
	if not ("funcdecl" in ast_toks):
		failures.append("5: ast_to_tokens missing funcdecl")
	if not ("passstmt" in ast_toks):
		failures.append("5: ast_to_tokens missing passstmt")

	# --- 6. Deterministic ordering ---
	var ast_toks_b: Array[String] = fe.ast_to_tokens(ast)
	if ast_toks != ast_toks_b:
		failures.append("6: ast_to_tokens not deterministic")

	# --- 7. describe_ast counts ---
	var counts: Dictionary = fe.describe_ast(ast)
	if int(counts.get("funcdecl", 0)) != 1:
		failures.append("7: describe_ast funcdecl count wrong")
	if int(counts.get("passstmt", 0)) != 1:
		failures.append("7: describe_ast passstmt count wrong")
	if int(counts.get("program", 0)) != 1:
		failures.append("7: describe_ast program count wrong")

	# --- 8. Empty AST is safe ---
	var v_empty: PackedFloat32Array = fe.extract({}, [], [])
	if v_empty.size() != FeatureExtractor.FEATURE_DIM:
		failures.append("8: empty AST vector wrong size")

	# --- 9. Query-only extraction ---
	var v_q: PackedFloat32Array = fe.extract({"kind": "Program"}, ["jump"], [])
	if v_q[0] <= 0.0:
		failures.append("9: query-only extraction lost the query signal")

	print("")
	if failures.is_empty():
		print("OK — all assertions passed")
	else:
		print("FAILED — %d issues:" % failures.size())
		var i: int = 0
		while i < failures.size():
			print("  " + failures[i])
			i += 1


static func _mk_vec(values: Array) -> PackedFloat32Array:
	var v: PackedFloat32Array = PackedFloat32Array()
	v.resize(Embedding.DIM)
	var i: int = 0
	while i < values.size():
		v[i] = float(values[i])
		i += 1
	return v
