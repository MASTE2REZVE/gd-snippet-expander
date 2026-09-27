# res://addons/gd_snippet_expander/ai_debugger/embedding.gd
@tool
class_name Embedding
extends RefCounted

## 200-dimensional token embeddings for the mini AI debugger.
##
## Part of the GD Snippet Expander mini AI debugger (v1.6).
## Loads a pre-computed lookup table from a binary file that maps
## every English and GDScript token to a 200-dim float vector.
## English words and GDScript identifiers live in the SAME vector
## space, so "jump" lands near velocity, move_and_slide, is_on_floor.
##
## The binary is generated offline by a Python script (not part of
## the plugin). Until that pipeline runs, this loader operates in
## STUB MODE: no file found, every lookup returns a zero vector,
## every embed() returns a zero vector, every cosine is 0. Nothing
## crashes — the chain downstream just sees "no signal."
##
## BINARY FORMAT (little-endian, all values):
##   magic     4 bytes   "GDSE" (0x47 0x44 0x53 0x45)
##   version   uint32    1
##   dim       uint32    200
##   count     uint32    number of entries
##   entry*    repeated:
##     tok_len uint32
##     tok     tok_len bytes, UTF-8
##     vec     dim * float32
##
## Usage:
##   var em := Embedding.new()
##   em.try_load_default()
##   var v := em.embed(["player", "jump", "wall"])   # PackedFloat32Array
##   var sim := Embedding.cosine(v, other_v)         # float in [-1, 1]

const DIM := 200
const MAGIC_STR := "GDSE"
const VERSION := 1

const DEFAULT_USER_PATH := "user://gd_snippet_expander/embeddings.bin"
const DEFAULT_RES_PATH := "res://addons/gd_snippet_expander/ai_debugger/embeddings.bin"

# --- public state -------------------------------------------------------

var dim: int = DIM
var loaded: bool = false
var load_error: String = ""

# --- internal -----------------------------------------------------------

var _vectors: Dictionary = {}   # String -> PackedFloat32Array (length == dim)


# --- loading ------------------------------------------------------------

## Tries user:// first (dev overrides), then res:// (shipped file).
## Returns true on success, false if neither exists or the file is
## malformed. On failure, `load_error` explains why.
func try_load_default() -> bool:
	if FileAccess.file_exists(DEFAULT_USER_PATH):
		if load_from(DEFAULT_USER_PATH):
			return true
	if FileAccess.file_exists(DEFAULT_RES_PATH):
		if load_from(DEFAULT_RES_PATH):
			return true
	load_error = "no embeddings.bin found in user:// or res://"
	loaded = false
	return false


## Loads from an explicit path. Populates `_vectors` on success.
## Leaves the previous state untouched if the file is malformed.
func load_from(path: String) -> bool:
	if not FileAccess.file_exists(path):
		load_error = "file not found: " + path
		return false
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		load_error = "cannot open: " + path
		return false

	var magic_bytes: PackedByteArray = f.get_buffer(4)
	if magic_bytes.size() != 4 or magic_bytes.get_string_from_utf8() != MAGIC_STR:
		load_error = "bad magic in " + path
		f.close()
		return false

	var version := f.get_32()
	if version != VERSION:
		load_error = "unsupported version %d (expected %d)" % [version, VERSION]
		f.close()
		return false

	var d := f.get_32()
	if d != DIM:
		load_error = "dim mismatch: file has %d, expected %d" % [d, DIM]
		f.close()
		return false

	var count := f.get_32()
	if count < 0 or count > 10_000_000:
		load_error = "implausible entry count %d" % count
		f.close()
		return false

	var new_vectors := {}
	for i in count:
		if f.get_position() >= f.get_length():
			load_error = "truncated at entry %d of %d" % [i, count]
			f.close()
			return false
		var slen := f.get_32()
		if slen < 0 or slen > 512:
			load_error = "implausible token length %d at entry %d" % [slen, i]
			f.close()
			return false
		var raw: PackedByteArray = f.get_buffer(slen)
		if raw.size() != slen:
			load_error = "truncated token at entry %d" % i
			f.close()
			return false
		var tok := raw.get_string_from_utf8()
		var v := PackedFloat32Array()
		v.resize(d)
		for j in d:
			v[j] = f.get_float()
		new_vectors[tok] = v

	f.close()
	_vectors = new_vectors
	dim = d
	loaded = true
	load_error = ""
	return true


# --- writer (used by the self-test, and by the training pipeline if
# --- it ever runs from GDScript; Python writes the same format) ---

## Writes the current vector table to `path` in the binary format.
## Returns true on success.
func save_to(path: String) -> bool:
	var dir := path.get_base_dir()
	if dir != "" and not DirAccess.dir_exists_absolute(dir):
		DirAccess.make_dir_recursive_absolute(dir)
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		load_error = "cannot write: " + path
		return false

	f.store_buffer(MAGIC_STR.to_utf8_buffer())
	f.store_32(VERSION)
	f.store_32(dim)
	f.store_32(_vectors.size())

	var keys := _vectors.keys()
	keys.sort()
	for tok in keys:
		var v: PackedFloat32Array = _vectors[tok]
		var raw: PackedByteArray = tok.to_utf8_buffer()
		f.store_32(raw.size())
		f.store_buffer(raw)
		for j in dim:
			f.store_float(v[j] if j < v.size() else 0.0)

	f.close()
	return true


# --- vector access ------------------------------------------------------

func has_token(tok: String) -> bool:
	return _vectors.has(tok)


func token_count() -> int:
	return _vectors.size()


## Returns the raw 200-dim vector for a token, or a zero vector if
## the token isn't in the table (stub mode, unknown word, etc.).
func get_vector(tok: String) -> PackedFloat32Array:
	if _vectors.has(tok):
		return _vectors[tok]
	var z := PackedFloat32Array()
	z.resize(dim)
	return z


# --- embedding ----------------------------------------------------------

## Converts a token list into a single L2-normalized vector by mean
## pooling. Returns a zero vector if the input is empty or no token
## is known. Output length is `dim`.
func embed(tokens: Array) -> PackedFloat32Array:
	var acc := PackedFloat32Array()
	acc.resize(dim)
	var hit := 0
	for t_p in tokens:
		var t: String = t_p
		if not _vectors.has(t):
			continue
		var v: PackedFloat32Array = _vectors[t]
		for j in dim:
			acc[j] += v[j]
		hit += 1
	if hit == 0:
		return acc   # all zeros
	for j in dim:
		acc[j] /= float(hit)
	return _l2_normalize(acc)


## Same as embed() but does not L2-normalize. Used by tests and by
## any code that wants raw pooled magnitude.
func embed_unnormalized(tokens: Array) -> PackedFloat32Array:
	var acc := PackedFloat32Array()
	acc.resize(dim)
	var hit := 0
	for t_p in tokens:
		var t: String = t_p
		if not _vectors.has(t):
			continue
		var v: PackedFloat32Array = _vectors[t]
		for j in dim:
			acc[j] += v[j]
		hit += 1
	if hit == 0:
		return acc
	for j in dim:
		acc[j] /= float(hit)
	return acc


# --- vector math --------------------------------------------------------

## Cosine similarity. Returns 0.0 if either vector is all zeros.
## Both vectors are assumed to be the same length (dim).
static func cosine(a: PackedFloat32Array, b: PackedFloat32Array) -> float:
	if a.size() != b.size() or a.is_empty():
		return 0.0
	var dot := 0.0
	var na := 0.0
	var nb := 0.0
	for i in a.size():
		dot += a[i] * b[i]
		na += a[i] * a[i]
		nb += b[i] * b[i]
	if na <= 0.0 or nb <= 0.0:
		return 0.0
	return dot / (sqrt(na) * sqrt(nb))


## L2 distance. Returns -1.0 if sizes differ.
static func distance(a: PackedFloat32Array, b: PackedFloat32Array) -> float:
	if a.size() != b.size():
		return -1.0
	var s := 0.0
	for i in a.size():
		var d := a[i] - b[i]
		s += d * d
	return sqrt(s)


func _l2_normalize(v: PackedFloat32Array) -> PackedFloat32Array:
	var mag := 0.0
	for x in v:
		mag += x * x
	mag = sqrt(mag)
	if mag <= 0.0:
		return v
	var out := PackedFloat32Array()
	out.resize(v.size())
	for i in v.size():
		out[i] = v[i] / mag
	return out


# --- debug helpers ------------------------------------------------------

## Returns a compact string like "[0.12, -0.03, 0.45, ...]" limited to
## the first `n` values. Useful for print() during debugging.
static func format_vector(v: PackedFloat32Array, n: int = 6) -> String:
	var shown := min(n, v.size())
	var parts: Array[String] = []
	for i in shown:
		parts.append("%.3f" % v[i])
	if v.size() > shown:
		parts.append("...")
	return "[" + ", ".join(parts) + "]"


# --- self-test ----------------------------------------------------------

## Runs a batch of assertions, including a round-trip through the
## binary writer and reader with a small mock table. Writes and
## deletes a temporary file in user://. Pass condition: "OK" printed
## at the end.
static func self_test() -> void:
	print("=== Embedding self-test ===")
	var failures: Array[String] = []

	# --- 1. Stub mode: no file present ---
	var em := Embedding.new()
	# Point try_load_default at paths that don't exist by using an
	# explicit non-existent path.
	var stub_ok := em.load_from("user://definitely_not_here_%d.bin" % Time.get_ticks_msec())
	if stub_ok:
		failures.append("1: load_from(nonexistent) should return false")
	if em.loaded:
		failures.append("1: loaded flag should be false after failed load")

	var zero_v := em.get_vector("anything")
	if zero_v.size() != Embedding.DIM:
		failures.append("1: zero vector wrong size (%d)" % zero_v.size())
	for x in zero_v:
		if x != 0.0:
			failures.append("1: zero vector contains non-zero")
			break

	var zero_embed := em.embed(["player", "jump"])
	if zero_embed.size() != Embedding.DIM:
		failures.append("1: stub embed wrong size")
	var sum_abs := 0.0
	for x in zero_embed:
		sum_abs += abs(x)
	if sum_abs > 0.00001:
		failures.append("1: stub embed should be all zeros")

	# --- 2. Build a mock table and save to a temp path ---
	var em2 := Embedding.new()
	em2.dim = Embedding.DIM
	var kv := {}
	# king = e0, queen = 0.9*e0 + 0.1*e1, banana = e2, jump = e3
	kv["king"]   = _mk_vec([1.0, 0.0, 0.0, 0.0])
	kv["queen"]  = _mk_vec([0.9, 0.1, 0.0, 0.0])
	kv["banana"] = _mk_vec([0.0, 0.0, 1.0, 0.0])
	kv["jump"]   = _mk_vec([0.0, 0.0, 0.0, 1.0])
	kv["run"]    = _mk_vec([0.0, 0.0, 0.0, 1.0])   # same direction as jump
	kv["move_and_slide"] = _mk_vec([0.0, 0.0, 0.0, 0.9])
	em2._vectors = kv

	var tmp := "user://gdse_test_embedding_%d.bin" % Time.get_ticks_msec()
	if not em2.save_to(tmp):
		failures.append("2: save_to failed: " + em2.load_error)
		_report(failures)
		return

	if not FileAccess.file_exists(tmp):
		failures.append("2: file not written")

	# --- 3. Round-trip load ---
	var em3 := Embedding.new()
	if not em3.load_from(tmp):
		failures.append("3: load_from failed: " + em3.load_error)
		_report(failures)
		_cleanup(tmp)
		return

	if not em3.loaded:
		failures.append("3: loaded flag false after success")
	if em3.token_count() != 6:
		failures.append("3: expected 6 tokens, got %d" % em3.token_count())

	for t in ["king", "queen", "banana", "jump", "run", "move_and_slide"]:
		if not em3.has_token(t):
			failures.append("3: missing token '%s'" % t)

	# --- 4. Vector values survive the round trip ---
	var king_v := em3.get_vector("king")
	if abs(king_v[0] - 1.0) > 0.0001 or abs(king_v[1]) > 0.0001:
		failures.append("4: king vector wrong: %s" % Embedding.format_vector(king_v))

	# --- 5. Embedding is L2-normalized ---
	var jump_embed := em3.embed(["jump"])
	var mag := 0.0
	for x in jump_embed:
		mag += x * x
	if abs(sqrt(mag) - 1.0) > 0.0001:
		failures.append("5: embed not L2-normalized, mag=%f" % sqrt(mag))

	# --- 6. Cosine similarity ordering ---
	var king_e := em3.embed(["king"])
	var queen_e := em3.embed(["queen"])
	var banana_e := em3.embed(["banana"])
	var sim_kq := Embedding.cosine(king_e, queen_e)
	var sim_kb := Embedding.cosine(king_e, banana_e)
	if sim_kq < 0.9:
		failures.append("6: sim(king, queen) should be high, got %f" % sim_kq)
	if abs(sim_kb) > 0.0001:
		failures.append("6: sim(king, banana) should be ~0, got %f" % sim_kb)
	if sim_kq <= sim_kb:
		failures.append("6: expected sim(king,queen) > sim(king,banana)")

	# --- 7. Multi-token pooling ---
	var pool_a := em3.embed(["jump", "move_and_slide"])
	var pool_b := em3.embed(["run"])
	var sim_pool := Embedding.cosine(pool_a, pool_b)
	if sim_pool < 0.95:
		failures.append("7: sim(jump+move_and_slide, run) should be very high, got %f" % sim_pool)

	# --- 8. Empty token list -> zero vector ---
	var empty_e := em3.embed([])
	var s := 0.0
	for x in empty_e:
		s += abs(x)
	if s > 0.00001:
		failures.append("8: embed([]) should be zero vector")

	# --- 9. Unknown tokens are silently skipped ---
	var mixed := em3.embed(["wibble", "jump", "flibble"])
	var sim_mixed := Embedding.cosine(mixed, jump_embed)
	if sim_mixed < 0.999:
		failures.append("9: unknown tokens should be skipped, sim=%f" % sim_mixed)

	# --- 10. Cosine with zero vector ---
	if Embedding.cosine(king_e, zero_v) != 0.0:
		failures.append("10: cosine with zero vector should be 0")

	_cleanup(tmp)
	_report(failures)


static func _mk_vec(values: Array) -> PackedFloat32Array:
	var v := PackedFloat32Array()
	v.resize(Embedding.DIM)
	for i in values.size():
		v[i] = float(values[i])
	return v


static func _cleanup(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)


static func _report(failures: Array[String]) -> void:
	print("")
	if failures.is_empty():
		print("OK — all assertions passed")
	else:
		print("FAILED — %d issues:" % failures.size())
		for f in failures:
			print("  " + f)
