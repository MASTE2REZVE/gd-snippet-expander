# res://addons/gd_snippet_expander/ai_debugger/confidence_calibrator.gd
@tool
class_name ConfidenceCalibrator
extends RefCounted

## Maps raw classifier probabilities to calibrated confidence values.
##
## Part of the GD Snippet Expander mini AI debugger (v1.6).
##
## A neural network's softmax output is a probability, not a
## confidence. A classifier that says 0.72 is often only right 55% of
## the time at that score — the numbers need a mapping to become
## honest. That mapping is learned during training: bin every
## prediction by its softmax score, measure the actual accuracy in
## each bin, and store the observed accuracy as the calibrated value.
##
## BINARY FORMAT (little-endian):
##   magic      4 bytes   "GDCC"
##   version    uint32    1
##   bins       uint32    number of calibration bins (typically 100)
##   table      bins * float32   calibrated value for each bin
##
## The bins are evenly spaced over [0, 1]. To calibrate a raw value
## x, find the bin index i = floor(x * bins), clamped to [0, bins-1],
## and return table[i].
##
## In stub mode (no file), calibration is the identity function —
## the raw value passes through unchanged. Nothing crashes, callers
## get a monotone map that's just not yet adjusted.
##
## Usage:
##   var cc := ConfidenceCalibrator.new()
##   cc.try_load_default()
##   var honest := cc.calibrate(0.72)   # e.g. 0.58 with real table
##   var probs := cc.calibrate_array(classifier_output)

const MAGIC_STR := "GDCC"
const VERSION := 1
const DEFAULT_BINS := 100
const MAX_BINS := 4096

const DEFAULT_USER_PATH := "user://gd_snippet_expander/calibration.bin"
const DEFAULT_RES_PATH := "res://addons/gd_snippet_expander/ai_debugger/calibration.bin"

# --- public state -------------------------------------------------------

var bin_count: int = DEFAULT_BINS
var loaded: bool = false
var load_error: String = ""

# --- internal -----------------------------------------------------------

var _table: PackedFloat32Array = PackedFloat32Array()


# --- loading ------------------------------------------------------------

func try_load_default() -> bool:
	if FileAccess.file_exists(DEFAULT_USER_PATH):
		if load_from(DEFAULT_USER_PATH):
			return true
	if FileAccess.file_exists(DEFAULT_RES_PATH):
		if load_from(DEFAULT_RES_PATH):
			return true
	load_error = "no calibration.bin found in user:// or res://"
	loaded = false
	return false


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

	var bins: int = f.get_32()
	if bins <= 0 or bins > MAX_BINS:
		load_error = "bins out of range: %d" % bins
		f.close()
		return false

	var new_table: PackedFloat32Array = PackedFloat32Array()
	new_table.resize(bins)
	var i: int = 0
	while i < bins:
		new_table[i] = f.get_float()
		i += 1

	f.close()

	_table = new_table
	bin_count = bins
	loaded = true
	load_error = ""
	return true


# --- saving -------------------------------------------------------------

func save_to(path: String) -> bool:
	if _table.is_empty():
		load_error = "no table to save"
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
	f.store_32(_table.size())
	var i: int = 0
	while i < _table.size():
		f.store_float(_table[i])
		i += 1
	f.close()
	return true


# --- manual setup -------------------------------------------------------

## Set the table directly. The table values are interpreted as
## calibrated confidence for each bin, so all values should be in
## [0, 1]. Returns true on success.
func set_table(tbl: PackedFloat32Array) -> bool:
	if tbl.is_empty() or tbl.size() > MAX_BINS:
		return false
	var i: int = 0
	while i < tbl.size():
		if tbl[i] < 0.0 or tbl[i] > 1.0:
			return false
		i += 1
	_table = tbl
	bin_count = tbl.size()
	loaded = true
	load_error = ""
	return true


# --- calibration --------------------------------------------------------

## Map a raw probability to a calibrated confidence. In stub mode
## (no table loaded) the input is returned unchanged, clamped to
## [0, 1].
func calibrate(raw: float) -> float:
	var x: float = clampf(raw, 0.0, 1.0)
	if _table.is_empty():
		return x
	var idx: int = int(x * float(_table.size()))
	if idx >= _table.size():
		idx = _table.size() - 1
	if idx < 0:
		idx = 0
	return clampf(_table[idx], 0.0, 1.0)


## Calibrate every value in an array. Returns a new array of the
## same length.
func calibrate_array(arr: PackedFloat32Array) -> PackedFloat32Array:
	var out: PackedFloat32Array = PackedFloat32Array()
	out.resize(arr.size())
	var i: int = 0
	while i < arr.size():
		out[i] = calibrate(arr[i])
		i += 1
	return out


## Convenience for the common case: calibrate and renormalize so the
## output still sums to 1.0. Useful when feeding calibrated
## probabilities to a UI that expects a distribution.
func calibrate_and_renormalize(arr: PackedFloat32Array) -> PackedFloat32Array:
	var cal: PackedFloat32Array = calibrate_array(arr)
	var sum: float = 0.0
	var i: int = 0
	while i < cal.size():
		sum += cal[i]
		i += 1
	if sum <= 0.0:
		return cal
	i = 0
	while i < cal.size():
		cal[i] = cal[i] / sum
		i += 1
	return cal


# --- diagnostics --------------------------------------------------------

func dump_summary() -> void:
	print("ConfidenceCalibrator:")
	print("  loaded:    %s" % ("yes" if loaded else "no (identity map)"))
	print("  bins:      %d" % bin_count)
	if load_error != "":
		print("  load_error: %s" % load_error)


# --- self-test ----------------------------------------------------------

static func self_test() -> void:
	print("=== ConfidenceCalibrator self-test ===")
	var failures: Array[String] = []

	# --- 1. Stub mode is the identity function ---
	var cc: ConfidenceCalibrator = ConfidenceCalibrator.new()
	if abs(cc.calibrate(0.5) - 0.5) > 0.0001:
		failures.append("1: stub calibrate(0.5) should return 0.5")
	if abs(cc.calibrate(0.0) - 0.0) > 0.0001:
		failures.append("1: stub calibrate(0) should return 0")
	if abs(cc.calibrate(1.0) - 1.0) > 0.0001:
		failures.append("1: stub calibrate(1) should return 1")
	if abs(cc.calibrate(2.0) - 1.0) > 0.0001:
		failures.append("1: stub should clamp above 1")
	if abs(cc.calibrate(-1.0) - 0.0) > 0.0001:
		failures.append("1: stub should clamp below 0")

	# --- 2. Array calibration in stub mode is identity ---
	var in_arr: PackedFloat32Array = PackedFloat32Array()
	in_arr.resize(4)
	in_arr[0] = 0.1
	in_arr[1] = 0.4
	in_arr[2] = 0.7
	in_arr[3] = 0.9
	var out_arr: PackedFloat32Array = cc.calibrate_array(in_arr)
	var i: int = 0
	while i < 4:
		if abs(out_arr[i] - in_arr[i]) > 0.0001:
			failures.append("2: stub array calibration should be identity")
			break
		i += 1

	# --- 3. Manual table round-trip ---
	# A monotone-shrink table: high raw values get pulled down to
	# reflect observed accuracy. Classic shape from a calibrator
	# that finds the net overconfident.
	var tbl: PackedFloat32Array = PackedFloat32Array()
	tbl.resize(10)
	tbl[0] = 0.05
	tbl[1] = 0.10
	tbl[2] = 0.15
	tbl[3] = 0.20
	tbl[4] = 0.30
	tbl[5] = 0.40
	tbl[6] = 0.50
	tbl[7] = 0.60
	tbl[8] = 0.70
	tbl[9] = 0.85

	var cc2: ConfidenceCalibrator = ConfidenceCalibrator.new()
	if not cc2.set_table(tbl):
		failures.append("3: set_table failed")
	if not cc2.loaded:
		failures.append("3: loaded flag should be true after set_table")
	if cc2.bin_count != 10:
		failures.append("3: bin_count should be 10, got %d" % cc2.bin_count)

	# --- 4. Bin mapping ---
	# Raw 0.00 -> bin 0 -> 0.05
	# Raw 0.05 -> bin 0 -> 0.05
	# Raw 0.10 -> bin 1 -> 0.10
	# Raw 0.50 -> bin 5 -> 0.40
	# Raw 0.99 -> bin 9 -> 0.85
	# Raw 1.00 -> bin 9 (clamped) -> 0.85
	if abs(cc2.calibrate(0.00) - 0.05) > 0.0001:
		failures.append("4: 0.00 -> 0.05 expected, got %f" % cc2.calibrate(0.00))
	if abs(cc2.calibrate(0.50) - 0.40) > 0.0001:
		failures.append("4: 0.50 -> 0.40 expected, got %f" % cc2.calibrate(0.50))
	if abs(cc2.calibrate(1.00) - 0.85) > 0.0001:
		failures.append("4: 1.00 -> 0.85 expected, got %f" % cc2.calibrate(1.00))

	# --- 5. Calibration is monotone ---
	var prev: float = -1.0
	var step: float = 0.0
	while step <= 1.0 + 0.0001:
		var v: float = cc2.calibrate(step)
		if v + 0.0001 < prev:
			failures.append("5: calibration not monotone at %.2f" % step)
			break
		prev = v
		step += 0.05

	# --- 6. Save/load round-trip ---
	var tmp: String = "user://gdse_test_calib_%d.bin" % Time.get_ticks_msec()
	if not cc2.save_to(tmp):
		failures.append("6: save_to failed: " + cc2.load_error)
	else:
		var cc3: ConfidenceCalibrator = ConfidenceCalibrator.new()
		if not cc3.load_from(tmp):
			failures.append("6: load_from failed: " + cc3.load_error)
		else:
			if cc3.bin_count != 10:
				failures.append("6: round-trip bin_count mismatch: %d" % cc3.bin_count)
			if not cc3.loaded:
				failures.append("6: round-trip loaded flag false")
			# Same predictions.
			var x: float = 0.0
			while x <= 1.0 + 0.0001:
				if abs(cc3.calibrate(x) - cc2.calibrate(x)) > 0.0001:
					failures.append("6: round-trip drift at %.2f" % x)
					break
				x += 0.1
		if FileAccess.file_exists(tmp):
			DirAccess.remove_absolute(tmp)

	# --- 7. Bad magic rejected ---
	var bad: String = "user://gdse_test_badcalib_%d.bin" % Time.get_ticks_msec()
	var fb: FileAccess = FileAccess.open(bad, FileAccess.WRITE)
	if fb != null:
		fb.store_buffer("XXXX".to_utf8_buffer())
		fb.store_32(1)
		fb.store_32(10)
		fb.close()
		var cc_bad: ConfidenceCalibrator = ConfidenceCalibrator.new()
		if cc_bad.load_from(bad):
			failures.append("7: bad magic should be rejected")
		if FileAccess.file_exists(bad):
			DirAccess.remove_absolute(bad)

	# --- 8. set_table rejects out-of-range values ---
	var bad_tbl: PackedFloat32Array = PackedFloat32Array()
	bad_tbl.resize(3)
	bad_tbl[0] = 0.5
	bad_tbl[1] = 1.5   # out of range
	bad_tbl[2] = 0.7
	var cc_bad2: ConfidenceCalibrator = ConfidenceCalibrator.new()
	if cc_bad2.set_table(bad_tbl):
		failures.append("8: set_table should reject values above 1.0")

	# --- 9. calibrate_and_renormalize sums to 1 ---
	var arr9: PackedFloat32Array = PackedFloat32Array()
	arr9.resize(3)
	arr9[0] = 0.3
	arr9[1] = 0.5
	arr9[2] = 0.2
	var r9: PackedFloat32Array = cc2.calibrate_and_renormalize(arr9)
	var s9: float = 0.0
	i = 0
	while i < r9.size():
		s9 += r9[i]
		i += 1
	if abs(s9 - 1.0) > 0.0001:
		failures.append("9: renormalized output should sum to 1, got %f" % s9)

	# --- 10. Stub calibrate_and_renormalize still sums to 1 ---
	var cc_stub: ConfidenceCalibrator = ConfidenceCalibrator.new()
	var r10: PackedFloat32Array = cc_stub.calibrate_and_renormalize(arr9)
	var s10: float = 0.0
	i = 0
	while i < r10.size():
		s10 += r10[i]
		i += 1
	if abs(s10 - 1.0) > 0.0001:
		failures.append("10: stub renormalize should sum to 1, got %f" % s10)

	print("")
	if failures.is_empty():
		print("OK — all assertions passed")
	else:
		print("FAILED — %d issues:" % failures.size())
		i = 0
		while i < failures.size():
			print("  " + failures[i])
			i += 1
