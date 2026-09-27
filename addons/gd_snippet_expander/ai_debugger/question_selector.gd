# res://addons/gd_snippet_expander/ai_debugger/question_selector.gd
@tool
class_name QuestionSelector
extends RefCounted

## Picks the disambiguating question that best separates tied candidates.
##
## Part of the GD Snippet Expander mini AI debugger (v1.6).
##
## When a rule matcher or classifier produces a top-N list where the
## leading candidates are close together, asking the user a targeted
## question can collapse the uncertainty in one shot. Each fix record
## may carry a questions array. Each question has answers that
## boost specific fix IDs. The selector picks the question whose
## answers best separate the current top candidates.
##
## Information gain formula (Shannon entropy, base 2):
##   H_before = entropy of the current normalized confidence distribution
##   For each answer A in question Q:
##     simulate boosting the confidences of the fix IDs A.boosts
##     H_after_A = entropy of the boosted distribution
##   H_after = sum over A of P(A) * H_after_A
##   gain = H_before - H_after
##
## P(A) is the current confidence mass of the candidates A boosts.
## A question that boosts nothing relevant has gain 0.
##
## should_ask decides whether to ask at all: if the top candidate is
## clearly ahead of the runner-up, no question is worth asking.
##
## Usage:
##   var qs := QuestionSelector.new()
##   qs.set_library(lib)
##   if qs.should_ask(results):
##       var q := qs.pick_question(results)
##       # render q text and q answers to the user
##       # when they click answer i:
##       var reranked := qs.apply_answer(q, i, results)

# --- constants ----------------------------------------------------------

const DEFAULT_TOP_K := 5
const BOOST_FACTOR := 4.0
const MIN_GAIN_BITS := 0.05

# --- internal state -----------------------------------------------------

var _library: FixLibrary = null


# --- setup --------------------------------------------------------------

func set_library(lib: FixLibrary) -> void:
	_library = lib


func has_library() -> bool:
	return _library != null


# --- decision -----------------------------------------------------------

## Should we ask a question at all? True when the top candidate is
## close to the runner-up — i.e. the classifier is uncertain.
## Returns false on empty or single-candidate lists.
func should_ask(results: Array, gap: float = 0.15) -> bool:
	if results.size() < 2:
		return false
	var top: Dictionary = results[0]
	var second: Dictionary = results[1]
	var p1: float = float(top.get("confidence", 0.0))
	var p2: float = float(second.get("confidence", 0.0))
	if p1 <= 0.0:
		return false
	return (p1 - p2) < gap


# --- main entry ---------------------------------------------------------

## Pick the question with the highest information gain. Returns an
## empty dictionary if no useful question exists.
func pick_question(results: Array, top_k: int = DEFAULT_TOP_K) -> Dictionary:
	if _library == null or results.size() < 2:
		return {}

	var take: int = top_k
	if take > results.size():
		take = results.size()
	var top: Array = results.slice(0, take)
	var h_before: float = _entropy_of_results(top)
	if h_before <= 0.0:
		return {}

	var best: Dictionary = {}
	var best_gain: float = MIN_GAIN_BITS

	var i: int = 0
	while i < top.size():
		var entry: Dictionary = top[i]
		var rec: Dictionary = entry.get("record", {})
		var questions: Array = rec.get("questions", [])
		var rid: String = str(entry.get("fix_id", "?"))

		var qi: int = 0
		while qi < questions.size():
			var q: Variant = questions[qi]
			if q is Dictionary:
				var qd: Dictionary = q
				var gain: float = _information_gain(qd, top, h_before)
				if gain > best_gain:
					best_gain = gain
					var candidate_id: String = "q_%s_%d" % [rid, qi]
					var answer_list: Array = qd.get("answers", [])
					var cand_list: Array = _candidate_ids(top)
					best = {
						"question_id": candidate_id,
						"text": str(qd.get("text", "")),
						"answers": answer_list,
						"expected_gain": gain,
						"source_fix_id": rid,
						"candidates": cand_list,
					}
			qi += 1
		i += 1

	return best


## Re-rank results after the user picked answer index answer_index
## on the given question. Candidates that the chosen answer boosts
## get their confidence multiplied; the array is re-sorted.
func apply_answer(question: Dictionary, answer_index: int, results: Array) -> Array:
	if question.is_empty() or results.is_empty():
		return results.duplicate()

	var answers: Array = question.get("answers", [])
	if answer_index < 0 or answer_index >= answers.size():
		return results.duplicate()

	var picked: Variant = answers[answer_index]
	if not (picked is Dictionary):
		return results.duplicate()
	var picked_dict: Dictionary = picked
	var boosts: Array = picked_dict.get("boosts", [])

	var boosted_set: Dictionary = {}
	var b: int = 0
	while b < boosts.size():
		var boosted_id: String = str(boosts[b])
		boosted_set[boosted_id] = true
		b += 1

	var out: Array = []
	var i: int = 0
	while i < results.size():
		var r: Dictionary = results[i].duplicate()
		var fid: String = str(r.get("fix_id", ""))
		var c: float = float(r.get("confidence", 0.0))
		if boosted_set.has(fid):
			c = c * BOOST_FACTOR
		r["confidence"] = clampf(c, 0.0, 1.0)
		out.append(r)
		i += 1

	out.sort_custom(_compare_confidence_desc)
	return out


static func _compare_confidence_desc(a: Dictionary, b: Dictionary) -> bool:
	return float(a.get("confidence", 0.0)) > float(b.get("confidence", 0.0))


# --- gain math ----------------------------------------------------------

func _information_gain(q: Dictionary, top: Array, h_before: float) -> float:
	var answers: Array = q.get("answers", [])
	if answers.size() < 2:
		return 0.0

	var total_conf: float = 0.0
	var i: int = 0
	while i < top.size():
		var entry: Dictionary = top[i]
		total_conf += float(entry.get("confidence", 0.0))
		i += 1
	if total_conf <= 0.0:
		return 0.0

	var h_after: float = 0.0
	i = 0
	while i < answers.size():
		var a: Variant = answers[i]
		if a is Dictionary:
			var ad: Dictionary = a
			var boosts: Array = ad.get("boosts", [])
			var mass: float = _confidence_mass(top, boosts)
			if mass > 0.0:
				var boosted: Array = _simulate_boost(top, boosts)
				var h_a: float = _entropy_of_results(boosted)
				var p_a: float = mass / total_conf
				h_after += p_a * h_a
		i += 1

	return maxf(0.0, h_before - h_after)


func _confidence_mass(top: Array, fix_ids: Array) -> float:
	var idset: Dictionary = {}
	var i: int = 0
	while i < fix_ids.size():
		var fid: String = str(fix_ids[i])
		idset[fid] = true
		i += 1
	var mass: float = 0.0
	i = 0
	while i < top.size():
		var entry: Dictionary = top[i]
		var entry_id: String = str(entry.get("fix_id", ""))
		if idset.has(entry_id):
			mass += float(entry.get("confidence", 0.0))
		i += 1
	return mass


func _simulate_boost(top: Array, fix_ids: Array) -> Array:
	var idset: Dictionary = {}
	var i: int = 0
	while i < fix_ids.size():
		var f: String = str(fix_ids[i])
		idset[f] = true
		i += 1
	var out: Array = []
	i = 0
	while i < top.size():
		var r: Dictionary = top[i].duplicate()
		var fid: String = str(r.get("fix_id", ""))
		var c: float = float(r.get("confidence", 0.0))
		if idset.has(fid):
			c = c * BOOST_FACTOR
		r["confidence"] = c
		out.append(r)
		i += 1
	return out


func _entropy_of_results(results: Array) -> float:
	var total: float = 0.0
	var i: int = 0
	while i < results.size():
		var entry: Dictionary = results[i]
		total += float(entry.get("confidence", 0.0))
		i += 1
	if total <= 0.0:
		return 0.0
	var h: float = 0.0
	i = 0
	while i < results.size():
		var entry2: Dictionary = results[i]
		var p: float = float(entry2.get("confidence", 0.0)) / total
		if p > 0.0:
			h -= p * (log(p) / log(2.0))
		i += 1
	return h


func _candidate_ids(results: Array) -> Array:
	var out: Array = []
	var i: int = 0
	while i < results.size():
		var entry: Dictionary = results[i]
		out.append(str(entry.get("fix_id", "")))
		i += 1
	return out


# --- diagnostics --------------------------------------------------------

## Debug helper: compute info gain for every question reachable from
## the top-K results. Returns an array of {question_id, gain, text}
## sorted descending. Useful for tuning thresholds.
func debug_all_questions(results: Array, top_k: int = DEFAULT_TOP_K) -> Array:
	if _library == null or results.size() < 2:
		return []
	var take: int = top_k
	if take > results.size():
		take = results.size()
	var top: Array = results.slice(0, take)
	var h_before: float = _entropy_of_results(top)
	var out: Array = []
	var i: int = 0
	while i < top.size():
		var entry: Dictionary = top[i]
		var rec: Dictionary = entry.get("record", {})
		var questions: Array = rec.get("questions", [])
		var rid: String = str(entry.get("fix_id", "?"))
		var qi: int = 0
		while qi < questions.size():
			var q: Variant = questions[qi]
			if q is Dictionary:
				var qd: Dictionary = q
				var gain: float = _information_gain(qd, top, h_before)
				var entry_out: Dictionary = {
					"question_id": "q_%s_%d" % [rid, qi],
					"text": str(qd.get("text", "")),
					"gain": gain,
				}
				out.append(entry_out)
			qi += 1
		i += 1
	out.sort_custom(_compare_gain_desc)
	return out


static func _compare_gain_desc(a: Dictionary, b: Dictionary) -> bool:
	return float(a.get("gain", 0.0)) > float(b.get("gain", 0.0))


# --- self-test ----------------------------------------------------------

static func self_test() -> void:
	print("=== QuestionSelector self-test ===")
	var failures: Array[String] = []

	# --- Build a minimal library with custom records that carry
	# --- questions. We don't depend on the shipped data volumes.

	var lib: FixLibrary = FixLibrary.new()

	var rec_a: Dictionary = {
		"id": "test_null_a",
		"title": "Null from get_node",
		"category": "null_safety",
		"phrases": ["null reference"],
		"candidates": [{"code": "pass\n", "description": "x", "confidence": 0.6}],
		"questions": [{
			"text": "Where does the null come from?",
			"answers": [
				{"text": "get_node failed", "boosts": ["test_null_a"]},
				{"text": "await returned nothing", "boosts": ["test_null_b"]},
				{"text": "I set it to null", "boosts": ["test_null_c"]},
			],
		}],
	}

	var rec_b: Dictionary = {
		"id": "test_null_b",
		"title": "Null from await",
		"category": "null_safety",
		"phrases": ["await null"],
		"candidates": [{"code": "pass\n", "description": "x", "confidence": 0.6}],
	}

	var rec_c: Dictionary = {
		"id": "test_null_c",
		"title": "Null by assignment",
		"category": "null_safety",
		"phrases": ["var x null"],
		"candidates": [{"code": "pass\n", "description": "x", "confidence": 0.6}],
	}

	if not lib.register_record(rec_a):
		failures.append("setup: rec_a rejected: " + str(lib.reject_log()))
	if not lib.register_record(rec_b):
		failures.append("setup: rec_b rejected")
	if not lib.register_record(rec_c):
		failures.append("setup: rec_c rejected")

	var qs: QuestionSelector = QuestionSelector.new()
	qs.set_library(lib)

	# --- 1. should_ask: three tied candidates, yes ---
	var tied: Array = []
	tied.append({"fix_id": "test_null_a", "confidence": 0.32, "record": rec_a})
	tied.append({"fix_id": "test_null_b", "confidence": 0.30, "record": rec_b})
	tied.append({"fix_id": "test_null_c", "confidence": 0.28, "record": rec_c})

	if not qs.should_ask(tied):
		failures.append("1: tied list should trigger should_ask")

	# --- 2. should_ask: clear winner, no ---
	var clear: Array = []
	clear.append({"fix_id": "test_null_a", "confidence": 0.90, "record": rec_a})
	clear.append({"fix_id": "test_null_b", "confidence": 0.05, "record": rec_b})
	clear.append({"fix_id": "test_null_c", "confidence": 0.03, "record": rec_c})

	if qs.should_ask(clear):
		failures.append("2: clear winner should NOT trigger should_ask")

	# --- 3. should_ask: single result, no ---
	var single: Array = []
	single.append({"fix_id": "x", "confidence": 0.9, "record": {}})
	if qs.should_ask(single):
		failures.append("3: single result should not trigger should_ask")

	# --- 4. should_ask: empty, no ---
	var empty: Array = []
	if qs.should_ask(empty):
		failures.append("4: empty list should not trigger should_ask")

	# --- 5. pick_question returns the useful question ---
	var q: Dictionary = qs.pick_question(tied)
	if q.is_empty():
		failures.append("5: pick_question should return a question for tied candidates")
	else:
		var text: String = str(q.get("text", ""))
		if text == "":
			failures.append("5: question missing text")
		var q_answers: Array = q.get("answers", [])
		if q_answers.is_empty():
			failures.append("5: question missing answers")
		var gain5: float = float(q.get("expected_gain", 0.0))
		if gain5 <= 0.0:
			failures.append("5: expected_gain should be positive")
		var src: String = str(q.get("source_fix_id", ""))
		if src != "test_null_a":
			failures.append("5: question should come from test_null_a, got " + src)

	# --- 6. pick_question returns empty when no questions available ---
	var no_q: Array = []
	no_q.append({"fix_id": "test_null_b", "confidence": 0.5, "record": rec_b})
	no_q.append({"fix_id": "test_null_c", "confidence": 0.4, "record": rec_c})
	var q6: Dictionary = qs.pick_question(no_q)
	if not q6.is_empty():
		failures.append("6: no questions available should return empty")

	# --- 7. apply_answer boosts the right candidates ---
	var reranked: Array = qs.apply_answer(q, 1, tied)
	if reranked.is_empty():
		failures.append("7: apply_answer returned empty")
	else:
		var first7: Dictionary = reranked[0]
		var id7: String = str(first7.get("fix_id", ""))
		if id7 != "test_null_b":
			failures.append("7: after picking answer 1, test_null_b should rank first, got " + id7)

	# --- 8. apply_answer with answer 0 keeps test_null_a on top ---
	var reranked0: Array = qs.apply_answer(q, 0, tied)
	if reranked0.is_empty():
		failures.append("8: apply_answer(0) returned empty")
	else:
		var first8: Dictionary = reranked0[0]
		var id8: String = str(first8.get("fix_id", ""))
		if id8 != "test_null_a":
			failures.append("8: after picking answer 0, test_null_a should rank first, got " + id8)

	# --- 9. apply_answer with answer 2 promotes test_null_c ---
	var reranked2: Array = qs.apply_answer(q, 2, tied)
	if reranked2.is_empty():
		failures.append("9: apply_answer(2) returned empty")
	else:
		var first9: Dictionary = reranked2[0]
		var id9: String = str(first9.get("fix_id", ""))
		if id9 != "test_null_c":
			failures.append("9: after picking answer 2, test_null_c should rank first, got " + id9)

	# --- 10. apply_answer with invalid index returns a copy unchanged ---
	var orig_first: Dictionary = tied[0]
	var orig_conf: float = float(orig_first.get("confidence", 0.0))
	var reranked_bad: Array = qs.apply_answer(q, 99, tied)
	if reranked_bad.size() != tied.size():
		failures.append("10: invalid answer index should return same-size list")
	else:
		var rb_first: Dictionary = reranked_bad[0]
		var rb_conf: float = float(rb_first.get("confidence", 0.0))
		if abs(rb_conf - orig_conf) > 0.0001:
			failures.append("10: invalid answer index should not change confidences")

	# --- 11. Entropy is zero for a single result ---
	var one: Array = []
	one.append({"confidence": 1.0})
	var h1: float = qs._entropy_of_results(one)
	if abs(h1) > 0.0001:
		failures.append("11: single result should have zero entropy")

	# --- 12. Entropy of two equal results is 1 bit ---
	var two_equal: Array = []
	two_equal.append({"confidence": 0.5})
	two_equal.append({"confidence": 0.5})
	var h2: float = qs._entropy_of_results(two_equal)
	if abs(h2 - 1.0) > 0.001:
		failures.append("12: two equal results should have 1 bit entropy, got %f" % h2)

	# --- 13. debug_all_questions lists the reachable question ---
	var dbg: Array = qs.debug_all_questions(tied)
	if dbg.is_empty():
		failures.append("13: debug_all_questions should find the question")
	else:
		var first_dbg: Dictionary = dbg[0]
		if not first_dbg.has("gain"):
			failures.append("13: debug entry missing gain")

	print("")
	if failures.is_empty():
		print("OK — all assertions passed")
	else:
		print("FAILED — %d issues:" % failures.size())
		var i: int = 0
		while i < failures.size():
			print("  " + failures[i])
			i += 1
