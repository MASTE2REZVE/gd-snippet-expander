# res://addons/gd_snippet_expander/ai_debugger/classifier.gd
@tool
class_name MiniClassifier
extends RefCounted

## Feed-forward neural network for the mini AI debugger.
##
## Part of the GD Snippet Expander mini AI debugger (v1.6).
##
## Architecture: 200 -> 64 -> 16 -> N
##   Layer 1: 200 inputs, 64 ReLU units
##   Layer 2: 64 inputs, 16 ReLU units
##   Layer 3: 16 inputs, N outputs (N = number of fix records)
##   Softmax over the output logits.
##
## Weights come from a binary file trained offline by a Python script.
## Until that pipeline runs, this class operates in STUB MODE: with no
## weights loaded, predict() returns a uniform distribution over the
## requested class count. Nothing crashes; callers see a flat signal.
##
## BINARY FORMAT (little-endian, all values):
##   magic      4 bytes   "GDCW"
##   version    uint32    1
##   input_dim  uint32    must be 200
##   hidden1    uint32    must be 64
##   hidden2    uint32    must be 16
##   output_dim uint32    N (number of classes)
##   w1         hidden1 * input_dim * float32   (row-major)
##   b1         hidden1 * float32
##   w2         hidden2 * hidden1 * float32
##   b2         hidden2 * float32
##   w3         output_dim * hidden2 * float32
##   b3         output_dim * float32
##
## Usage:
##   var cl := MiniClassifier.new()
##   cl.try_load_default()
##   var probs := cl.predict(features, 200)   # 200 = library size, fallback
##   # probs is PackedFloat32Array of length N summing to ~1.0

const DIM_IN := 200
const HIDDEN1 := 64
const HIDDEN2 := 16
const MAX_CLASSES := 512
const MAGIC_STR := "GDCW"
const VERSION := 1

const DEFAULT_USER_PATH := "user://gd_snippet_expander/classifier_weights.bin"
const DEFAULT_RES_PATH := "res://addons/gd_snippet_expander/ai_debugger/classifier_weights.bin"

# --- public state -------------------------------------------------------

var input_dim: int = DIM_IN
var hidden1_dim: int = HIDDEN1
var hidden2_dim: int = HIDDEN2
var output_dim: int = 0
var loaded: bool = false
var load_error: String = ""

# --- internal weights ---------------------------------------------------

var _w1: PackedFloat32Array = PackedFloat32Array()
var _b1: PackedFloat32Array = PackedFloat32Array()
var _w2: PackedFloat32Array = PackedFloat32Array()
var _b2: PackedFloat32Array = PackedFloat32Array()
var _w3: PackedFloat32Array = PackedFloat32Array()
var _b3: PackedFloat32Array = PackedFloat32Array()


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
	load_error = "no classifier_weights.bin found in user:// or res://"
	loaded = false
	return false


## Loads weights from an explicit path. Leaves prior state untouched
## on failure.
func load_from(path: String) -> bool:
	if not FileAccess.file_exists(path):
		load_error = "file not found: " + path
		return false
	var f: FileAccess = FileAccess.open(path, FileAccess.READ)
	if f == null:
		load_error = "cannot open: " + path
		return false

	var magic_bytes: PackedByteArray = f.get_buffer(4)
	if magic_bytes.size() != 4 or magic_bytes.get_string_from_utf8() != MAGIC_STR:
		load_error = "bad magic in " + path
		f.close()
		return false

	var version: int = f.get_32()
	if version != VERSION:
		load_error = "unsupported version %d (expected %d)" % [version, VERSION]
		f.close()
		return false

	var din: int = f.get_32()
	var h1: int = f.get_32()
	var h2: int = f.get_32()
	var odim: int = f.get_32()
	if din != DIM_IN:
		load_error = "input_dim mismatch: file has %d, expected %d" % [din, DIM_IN]
		f.close()
		return false
	if h1 != HIDDEN1:
		load_error = "hidden1 mismatch: file has %d, expected %d" % [h1, HIDDEN1]
		f.close()
		return false
	if h2 != HIDDEN2:
		load_error = "hidden2 mismatch: file has %d, expected %d" % [h2, HIDDEN2]
		f.close()
		return false
	if odim <= 0 or odim > MAX_CLASSES:
		load_error = "output_dim out of range: %d" % odim
		f.close()
		return false

	var w1: PackedFloat32Array = _read_floats(f, h1 * din)
	if w1.size() != h1 * din:
		load_error = "truncated w1"
		f.close()
		return false
	var b1: PackedFloat32Array = _read_floats(f, h1)
	if b1.size() != h1:
		load_error = "truncated b1"
		f.close()
		return false
	var w2: PackedFloat32Array = _read_floats(f, h2 * h1)
	if w2.size() != h2 * h1:
		load_error = "truncated w2"
		f.close()
		return false
	var b2: PackedFloat32Array = _read_floats(f, h2)
	if b2.size() != h2:
		load_error = "truncated b2"
		f.close()
		return false
	var w3: PackedFloat32Array = _read_floats(f, odim * h2)
	if w3.size() != odim * h2:
		load_error = "truncated w3"
		f.close()
		return false
	var b3: PackedFloat32Array = _read_floats(f, odim)
	if b3.size() != odim:
		load_error = "truncated b3"
		f.close()
		return false

	f.close()

	_w1 = w1
	_b1 = b1
	_w2 = w2
	_b2 = b2
	_w3 = w3
	_b3 = b3
	input_dim = din
	hidden1_dim = h1
	hidden2_dim = h2
	output_dim = odim
	loaded = true
	load_error = ""
	return true


func _read_floats(f: FileAccess, count: int) -> PackedFloat32Array:
	var out: PackedFloat32Array = PackedFloat32Array()
	if count <= 0:
		return out
	out.resize(count)
	var i: int = 0
	while i < count:
		out[i] = f.get_float()
		i += 1
	return out


# --- saving -------------------------------------------------------------

## Writes the current weights to `path`. Returns true on success.
## Used by the self-test, and available if the training pipeline
## chooses to run from GDScript instead of Python.
func save_to(path: String) -> bool:
	if output_dim <= 0:
		load_error = "no weights to save (output_dim = 0)"
		return false
	var dir: String = path.get_base_dir()
	if dir != "" and not DirAccess.dir_exists_absolute(dir):
		DirAccess.make_dir_recursive_absolute(dir)
	var f: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		load_error = "cannot write: " + path
		return false

	f.store_buffer(MAGIC_STR.to_utf8_buffer())
	f.store_32(VERSION)
	f.store_32(input_dim)
	f.store_32(hidden1_dim)
	f.store_32(hidden2_dim)
	f.store_32(output_dim)

	_write_floats(f, _w1)
	_write_floats(f, _b1)
	_write_floats(f, _w2)
	_write_floats(f, _b2)
	_write_floats(f, _w3)
	_write_floats(f, _b3)

	f.close()
	return true


func _write_floats(f: FileAccess, arr: PackedFloat32Array) -> void:
	var i: int = 0
	while i < arr.size():
		f.store_float(arr[i])
		i += 1


# --- manual weight setup (used by tests) --------------------------------

## Assign weights directly. All sizes must match the declared
## dimensions. Returns true on success.
func set_weights(w1: PackedFloat32Array, b1: PackedFloat32Array,
		w2: PackedFloat32Array, b2: PackedFloat32Array,
		w3: PackedFloat32Array, b3: PackedFloat32Array,
		odim: int) -> bool:
	if odim <= 0 or odim > MAX_CLASSES:
		return false
	if w1.size() != hidden1_dim * input_dim:
		return false
	if b1.size() != hidden1_dim:
		return false
	if w2.size() != hidden2_dim * hidden1_dim:
		return false
	if b2.size() != hidden2_dim:
		return false
	if w3.size() != odim * hidden2_dim:
		return false
	if b3.size() != odim:
		return false
	_w1 = w1
	_b1 = b1
	_w2 = w2
	_b2 = b2
	_w3 = w3
	_b3 = b3
	output_dim = odim
	loaded = true
	load_error = ""
	return true


# --- inference ----------------------------------------------------------

## Run a forward pass. If weights are loaded, returns softmax over
## `output_dim` classes. If not loaded (stub mode), returns a uniform
## distribution over `fallback_classes` (or over `output_dim` if that
## was set, or 16 as a final default).
##
## The output always sums to 1.0 (within float32 precision).
func predict(features: PackedFloat32Array, fallback_classes: int = 0) -> PackedFloat32Array:
	if loaded:
		return _forward(features)
	var n: int = fallback_classes
	if n <= 0:
		n = output_dim if output_dim > 0 else 16
	return _uniform(n)


## Same as predict(), but if the classifier is loaded, returns the
## top-k class indices with their probabilities, sorted descending.
## In stub mode, returns the top-k as 0..k-1 with uniform probabilities.
func predict_top_k(features: PackedFloat32Array, k: int, fallback_classes: int = 0) -> Array:
	var probs: PackedFloat32Array = predict(features, fallback_classes)
	var n: int = probs.size()
	if n == 0 or k <= 0:
		return []
	var idx: Array = []
	var i: int = 0
	while i < n:
		idx.append(i)
		i += 1
	idx.sort_custom(func(a: int, b: int) -> bool:
		return probs[a] > probs[b])
	if k > idx.size():
		k = idx.size()
	var out: Array = []
	i = 0
	while i < k:
		var class_i: int = int(idx[i])
		out.append({"class_index": class_i, "probability": probs[class_i]})
		i += 1
	return out


# --- internals ----------------------------------------------------------

func _forward(x: PackedFloat32Array) -> PackedFloat32Array:
	var xin: PackedFloat32Array = PackedFloat32Array()
	xin.resize(input_dim)
	var i: int = 0
	while i < input_dim:
		xin[i] = x[i] if i < x.size() else 0.0
		i += 1

	var h1: PackedFloat32Array = _matmul_vec(_w1, _b1, xin, hidden1_dim, input_dim)
	var r1: PackedFloat32Array = _relu(h1)

	var h2: PackedFloat32Array = _matmul_vec(_w2, _b2, r1, hidden2_dim, hidden1_dim)
	var r2: PackedFloat32Array = _relu(h2)

	var logits: PackedFloat32Array = _matmul_vec(_w3, _b3, r2, output_dim, hidden2_dim)
	return _softmax(logits)


func _matmul_vec(w: PackedFloat32Array, b: PackedFloat32Array,
		x: PackedFloat32Array, rows: int, cols: int) -> PackedFloat32Array:
	var out: PackedFloat32Array = PackedFloat32Array()
	out.resize(rows)
	var i: int = 0
	while i < rows:
		var acc: float = b[i] if i < b.size() else 0.0
		var base: int = i * cols
		var j: int = 0
		while j < cols:
			var wv: float = w[base + j] if base + j < w.size() else 0.0
			var xv: float = x[j] if j < x.size() else 0.0
			acc += wv * xv
			j += 1
		out[i] = acc
		i += 1
	return out


func _relu(v: PackedFloat32Array) -> PackedFloat32Array:
	var out: PackedFloat32Array = PackedFloat32Array()
	out.resize(v.size())
	var i: int = 0
	while i < v.size():
		out[i] = v[i] if v[i] > 0.0 else 0.0
		i += 1
	return out


func _softmax(logits: PackedFloat32Array) -> PackedFloat32Array:
	var n: int = logits.size()
	var out: PackedFloat32Array = PackedFloat32Array()
	out.resize(n)
	if n == 0:
		return out
	# Subtract max for numerical stability.
	var mx: float = logits[0]
	var i: int = 1
	while i < n:
		if logits[i] > mx:
			mx = logits[i]
		i += 1
	var sum: float = 0.0
	i = 0
	while i < n:
		var e: float = exp(logits[i] - mx)
		out[i] = e
		sum += e
		i += 1
	if sum <= 0.0:
		return _uniform(n)
	i = 0
	while i < n:
		out[i] = out[i] / sum
		i += 1
	return out


func _uniform(n: int) -> PackedFloat32Array:
	var out: PackedFloat32Array = PackedFloat32Array()
	out.resize(n)
	if n <= 0:
		return out
	var u: float = 1.0 / float(n)
	var i: int = 0
	while i < n:
		out[i] = u
		i += 1
	return out


# --- diagnostics --------------------------------------------------------

## Prints a one-line summary of the loaded state.
func dump_summary() -> void:
	print("MiniClassifier:")
	print("  loaded:      %s" % ("yes" if loaded else "no (stub mode)"))
	print("  input_dim:   %d" % input_dim)
	print("  hidden1_dim: %d" % hidden1_dim)
	print("  hidden2_dim: %d" % hidden2_dim)
	print("  output_dim:  %d" % output_dim)
	if load_error != "":
		print("  load_error:  %s" % load_error)


# --- self-test ----------------------------------------------------------

## Verifies stub mode, weight setup, save/load round-trip, and forward
## pass with a small deterministic network. Pass condition: "OK".
static func self_test() -> void:
	print("=== MiniClassifier self-test ===")
	var failures: Array[String] = []

	# --- 1. Stub mode: no weights loaded ---
	var cl: MiniClassifier = MiniClassifier.new()
	var probs_stub: PackedFloat32Array = cl.predict(PackedFloat32Array(), 8)
	if probs_stub.size() != 8:
		failures.append("1: stub predict should return 8 classes, got %d" % probs_stub.size())
	else:
		var sum: float = 0.0
		var i: int = 0
		while i < 8:
			sum += probs_stub[i]
			i += 1
		if abs(sum - 1.0) > 0.0001:
			failures.append("1: stub probs should sum to 1, got %f" % sum)
		var first: float = probs_stub[0]
		i = 1
		while i < 8:
			if abs(probs_stub[i] - first) > 0.0001:
				failures.append("1: stub probs should be uniform")
				break
			i += 1

	# --- 2. predict_top_k in stub mode returns the first k indices ---
	var topk: Array = cl.predict_top_k(PackedFloat32Array(), 3, 10)
	if topk.size() != 3:
		failures.append("2: stub top_k should return 3 entries, got %d" % topk.size())

	# --- 3. Build a small deterministic network ---
	# input: 200, hidden1: 64, hidden2: 16, output: 4
	var cl2: MiniClassifier = MiniClassifier.new()
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 12345

	var w1: PackedFloat32Array = PackedFloat32Array()
	w1.resize(MiniClassifier.HIDDEN1 * MiniClassifier.DIM_IN)
	var i: int = 0
	while i < w1.size():
		w1[i] = rng.randf_range(-0.05, 0.05)
		i += 1
	var b1: PackedFloat32Array = PackedFloat32Array()
	b1.resize(MiniClassifier.HIDDEN1)
	i = 0
	while i < b1.size():
		b1[i] = 0.0
		i += 1
	var w2: PackedFloat32Array = PackedFloat32Array()
	w2.resize(MiniClassifier.HIDDEN2 * MiniClassifier.HIDDEN1)
	i = 0
	while i < w2.size():
		w2[i] = rng.randf_range(-0.1, 0.1)
		i += 1
	var b2: PackedFloat32Array = PackedFloat32Array()
	b2.resize(MiniClassifier.HIDDEN2)
	i = 0
	while i < b2.size():
		b2[i] = 0.0
		i += 1
	var odim: int = 4
	var w3: PackedFloat32Array = PackedFloat32Array()
	w3.resize(odim * MiniClassifier.HIDDEN2)
	i = 0
	while i < w3.size():
		w3[i] = rng.randf_range(-0.2, 0.2)
		i += 1
	var b3: PackedFloat32Array = PackedFloat32Array()
	b3.resize(odim)
	i = 0
	while i < b3.size():
		b3[i] = 0.0
		i += 1

	if not cl2.set_weights(w1, b1, w2, b2, w3, b3, odim):
		failures.append("3: set_weights failed")
	if not cl2.loaded:
		failures.append("3: loaded flag should be true after set_weights")
	if cl2.output_dim != odim:
		failures.append("3: output_dim should be %d, got %d" % [odim, cl2.output_dim])

	# --- 4. Forward pass returns valid probability distribution ---
	var input_a: PackedFloat32Array = PackedFloat32Array()
	input_a.resize(MiniClassifier.DIM_IN)
	i = 0
	while i < MiniClassifier.DIM_IN:
		input_a[i] = rng.randf_range(-1.0, 1.0)
		i += 1

	var p4: PackedFloat32Array = cl2.predict(input_a)
	if p4.size() != odim:
		failures.append("4: forward output size should be %d, got %d" % [odim, p4.size()])
	else:
		var s4: float = 0.0
		i = 0
		while i < p4.size():
			if p4[i] < 0.0 or p4[i] > 1.0:
				failures.append("4: prob out of range at %d: %f" % [i, p4[i]])
				break
			s4 += p4[i]
			i += 1
		if abs(s4 - 1.0) > 0.001:
			failures.append("4: probs should sum to 1, got %f" % s4)

	# --- 5. Different inputs produce different outputs ---
	var input_b: PackedFloat32Array = PackedFloat32Array()
	input_b.resize(MiniClassifier.DIM_IN)
	i = 0
	while i < MiniClassifier.DIM_IN:
		input_b[i] = rng.randf_range(-1.0, 1.0)
		i += 1
	var p5: PackedFloat32Array = cl2.predict(input_b)
	var diff: float = 0.0
	i = 0
	while i < p5.size():
		diff += abs(p5[i] - p4[i])
		i += 1
	if diff < 0.001:
		failures.append("5: different inputs should produce different outputs, diff=%f" % diff)

	# --- 6. predict_top_k returns sorted results ---
	var tk6: Array = cl2.predict_top_k(input_a, 3)
	if tk6.size() != 3:
		failures.append("6: top_k should return 3 entries, got %d" % tk6.size())
	else:
		var prev: float = 2.0
		i = 0
		while i < tk6.size():
			var pr: float = float(tk6[i]["probability"])
			if pr > prev + 0.0001:
				failures.append("6: top_k not sorted descending")
				break
			prev = pr
			i += 1

	# --- 7. Softmax stability with extreme logits ---
	var extreme: PackedFloat32Array = PackedFloat32Array()
	extreme.resize(4)
	extreme[0] = 1000.0
	extreme[1] = 999.0
	extreme[2] = 0.0
	extreme[3] = -1000.0
	var sm: PackedFloat32Array = cl2._softmax(extreme)
	var s7: float = 0.0
	i = 0
	while i < sm.size():
		s7 += sm[i]
		i += 1
	if abs(s7 - 1.0) > 0.0001:
		failures.append("7: extreme softmax should sum to 1, got %f" % s7)
	if sm[0] <= sm[1]:
		failures.append("7: logit 1000 should beat logit 999")

	# --- 8. Save / load round-trip ---
	var tmp: String = "user://gdse_test_classifier_%d.bin" % Time.get_ticks_msec()
	if not cl2.save_to(tmp):
		failures.append("8: save_to failed: " + cl2.load_error)
	else:
		var cl3: MiniClassifier = MiniClassifier.new()
		if not cl3.load_from(tmp):
			failures.append("8: load_from failed: " + cl3.load_error)
		else:
			if cl3.output_dim != odim:
				failures.append("8: round-trip output_dim mismatch")
			if not cl3.loaded:
				failures.append("8: round-trip loaded flag false")
			# Predictions should match to float32 precision.
			var p8: PackedFloat32Array = cl3.predict(input_a)
			var max_delta: float = 0.0
			i = 0
			while i < p8.size():
				var d: float = abs(p8[i] - p4[i])
				if d > max_delta:
					max_delta = d
				i += 1
			if max_delta > 0.0001:
				failures.append("8: round-trip prediction drift %f" % max_delta)
		if FileAccess.file_exists(tmp):
			DirAccess.remove_absolute(tmp)

	# --- 9. Bad magic rejected ---
	var bad_path: String = "user://gdse_test_bad_%d.bin" % Time.get_ticks_msec()
	var fb: FileAccess = FileAccess.open(bad_path, FileAccess.WRITE)
	if fb != null:
		fb.store_buffer("XXXX".to_utf8_buffer())
		fb.store_32(1)
		fb.store_32(200)
		fb.store_32(64)
		fb.store_32(16)
		fb.store_32(4)
		fb.close()
		var cl_bad: MiniClassifier = MiniClassifier.new()
		if cl_bad.load_from(bad_path):
			failures.append("9: bad magic should be rejected")
		if FileAccess.file_exists(bad_path):
			DirAccess.remove_absolute(bad_path)

	# --- 10. Wrong dims rejected ---
	var bad2_path: String = "user://gdse_test_bad2_%d.bin" % Time.get_ticks_msec()
	var fb2: FileAccess = FileAccess.open(bad2_path, FileAccess.WRITE)
	if fb2 != null:
		fb2.store_buffer("GDCW".to_utf8_buffer())
		fb2.store_32(1)
		fb2.store_32(100)   # wrong input dim
		fb2.store_32(64)
		fb2.store_32(16)
		fb2.store_32(4)
		fb2.close()
		var cl_bad2: MiniClassifier = MiniClassifier.new()
		if cl_bad2.load_from(bad2_path):
			failures.append("10: wrong input_dim should be rejected")
		if FileAccess.file_exists(bad2_path):
			DirAccess.remove_absolute(bad2_path)

	# --- 11. predict() with mismatched input length pads with zeros ---
	var short_in: PackedFloat32Array = PackedFloat32Array()
	short_in.resize(10)
	i = 0
	while i < 10:
		short_in[i] = 1.0
		i += 1
	var p11: PackedFloat32Array = cl2.predict(short_in)
	if p11.size() != odim:
		failures.append("11: short input should still produce output_dim predictions")

	# --- 12. set_weights rejects wrong sizes ---
	var cl_bad3: MiniClassifier = MiniClassifier.new()
	var wrong_w1: PackedFloat32Array = PackedFloat32Array()
	wrong_w1.resize(10)   # way too small
	if cl_bad3.set_weights(wrong_w1, b1, w2, b2, w3, b3, odim):
		failures.append("12: set_weights should reject wrong w1 size")

	print("")
	if failures.is_empty():
		print("OK — all assertions passed")
	else:
		print("FAILED — %d issues:" % failures.size())
		i = 0
		while i < failures.size():
			print("  " + failures[i])
			i += 1
