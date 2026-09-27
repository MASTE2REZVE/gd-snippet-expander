# res://addons/gd_snippet_expander/ai_debugger/rule_matcher.gd
@tool
class_name RuleMatcher
extends RefCounted

## Scores fix records against a script source.
##
## Part of the GD Snippet Expander mini AI debugger (v1.6).
##
## Each fix record declares a list of code_patterns — small signals
## that hint the record's problem is present in a given script.
## This matcher walks the fix library, evaluates every record's
## patterns against the source, and returns the top-scoring records
## as candidates.
##
## Pattern kinds:
##   identifier  — word-boundary match (via identifier scan)
##   substring   — literal substring match
##   regex       — full regex, compiled once per match call
##
## Every pattern can carry "negate": true, which inverts the result.
## Negated patterns express "the fix applies when this token is
## absent" — e.g. a jump fix applies when move_and_slide is present
## but is_on_floor is not.
##
## WEIGHTING:
##   Positive patterns contribute full weight (1.0) when they match.
##   Negated patterns contribute half weight (0.5) when the target
##   is absent. This makes them filters, not triggers.
##
##   Records whose patterns are ALL negated cannot be triggered by
##   source content alone — they cap at 0.15 pattern score. Such
##   records only become useful when a query strongly overlaps.
##
##   When a query string is provided, records whose English phrases
##   share tokens with the query get a soft boost. Without a query,
##   pure pattern matching dominates.
##
## Usage:
##   var matcher := RuleMatcher.new()
##   matcher.set_library(lib)
##   var results := matcher.match(source_text, ast, "player can't jump")
##   for r in results:
##       print("%s — %.0f%%" % [r["title"], r["confidence"] * 100.0])

# --- blend weights ------------------------------------------------------

const W_PATTERN := 0.7        # pattern_score weight when no query
const W_BASE_NO_Q := 0.3      # base_confidence weight when no query
const W_PATTERN_Q := 0.5      # pattern_score weight with query
const W_QUERY_Q := 0.3        # query_score weight with query
const W_BASE_Q := 0.2         # base_confidence weight with query

const NEGATED_WEIGHT := 0.5
const ALL_NEGATED_CAP := 0.15

const DEFAULT_MIN_SCORE := 0.20
const DEFAULT_TOP_N := 5

# --- internal state -----------------------------------------------------

var _library: FixLibrary = null
var _tokenizer: EnglishTokenizer = null


# --- setup --------------------------------------------------------------

func set_library(lib: FixLibrary) -> void:
	_library = lib


func set_tokenizer(tok: EnglishTokenizer) -> void:
	_tokenizer = tok


func has_library() -> bool:
	return _library != null


# --- main entry ---------------------------------------------------------

## Match a source string against the fix library. Returns an array of
## result dictionaries sorted by descending confidence, capped at
## `top_n`, and filtered to those scoring above `min_score`.
##
## Result shape:
##   {
##     "fix_id":         String
##     "title":          String
##     "category":       String
##     "confidence":     float   final blended score, [0, 1]
##     "pattern_score":  float   raw pattern match ratio, [0, 1]
##     "query_score":    float   token overlap with query, [0, 1]
##     "base_confidence":float   top candidate's declared confidence
##     "why":            String  short human-readable explanation
##     "primary":        Dictionary  top candidate {code, description, confidence}
##     "alternatives":   Array       remaining candidates
##     "record":         Dictionary  the full fix record
##   }
func match(source: String, _ast: Dictionary, query: String = "",
		top_n: int = DEFAULT_TOP_N, min_score: float = DEFAULT_MIN_SCORE) -> Array:
	if _library == null:
		return []

	var ids := _library.all_ids()
	var query_tokens: Array = []
	if query.strip_edges() != "" and _tokenizer != null:
		query_tokens = _tokenizer.tokenize(query)

	var identifiers := _collect_identifiers(source)

	var results: Array = []
	var i: int = 0
	while i < ids.size():
		var rid: String = str(ids[i])
		var rec: Dictionary = _library.get_record(rid)
		if not rec.is_empty():
			var scored: Dictionary = _score_record(rec, source, identifiers, query_tokens)
			if float(scored["confidence"]) >= min_score:
				results.append(scored)
		i += 1

	results.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a["confidence"]) > float(b["confidence"]))

	if results.size() > top_n:
		results.resize(top_n)
	return results


## Detailed breakdown for a single fix record. Useful for debugging
## and for an "explain this suggestion" panel.
func match_record(fix_id: String, source: String) -> Dictionary:
	if _library == null or not _library.has_record(fix_id):
		return {}
	var rec: Dictionary = _library.get_record(fix_id)
	var ids := _collect_identifiers(source)
	return _score_record(rec, source, ids, [])


# --- scoring ------------------------------------------------------------

func _score_record(rec: Dictionary, source: String, identifiers: Dictionary,
		query_tokens: Array) -> Dictionary:
	var pattern_score: float = _pattern_score(rec, source, identifiers)
	var query_score: float = 0.0
	if not query_tokens.is_empty():
		query_score = _query_score(rec, query_tokens)

	var base_confidence: float = _top_candidate_confidence(rec)

	var final: float
	if query_tokens.is_empty():
		final = W_PATTERN * pattern_score + W_BASE_NO_Q * base_confidence
	else:
		final = W_PATTERN_Q * pattern_score \
			+ W_QUERY_Q * query_score \
			+ W_BASE_Q * base_confidence

	var cands: Array = rec.get("candidates", [])
	var primary: Dictionary = {}
	var alternatives: Array = []
	if not cands.is_empty():
		var sorted_cands: Array = cands.duplicate()
		sorted_cands.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			return float(a.get("confidence", 0.0)) > float(b.get("confidence", 0.0)))
		primary = sorted_cands[0]
		var k: int = 1
		while k < sorted_cands.size():
			alternatives.append(sorted_cands[k])
			k += 1

	return {
		"fix_id": str(rec.get("id", "")),
		"title": str(rec.get("title", "")),
		"category": str(rec.get("category", "")),
		"confidence": clampf(final, 0.0, 1.0),
		"pattern_score": pattern_score,
		"query_score": query_score,
		"base_confidence": base_confidence,
		"why": _explain(rec, pattern_score, query_score, query_tokens),
		"primary": primary,
		"alternatives": alternatives,
		"record": rec,
	}


## Compute the pattern score for a record. Positive patterns carry
## full weight; negated patterns carry half weight. Records with no
## positive patterns are capped low — they can't be triggered by
## source content alone.
func _pattern_score(rec: Dictionary, source: String, identifiers: Dictionary) -> float:
	var patterns: Array = rec.get("code_patterns", [])
	if patterns.is_empty():
		# No patterns at all — the record can only be validated by the
		# query. Return neutral-low so a query must carry it.
		return 0.3

	var hit_weight: float = 0.0
	var total_weight: float = 0.0
	var positive_count: int = 0

	var i: int = 0
	while i < patterns.size():
		var p: Variant = patterns[i]
		if p is Dictionary:
			var pd: Dictionary = p
			var kind: String = str(pd.get("kind", "substring"))
			var value: String = str(pd.get("value", ""))
			var negate: bool = bool(pd.get("negate", false))
			var w: float = NEGATED_WEIGHT if negate else 1.0
			var raw: bool = _pattern_matches(kind, value, source, identifiers)
			var hit: bool = (not raw) if negate else raw
			if not negate:
				positive_count += 1
			total_weight += w
			if hit:
				hit_weight += w
		i += 1

	if total_weight <= 0.0:
		return 0.0

	var score: float = hit_weight / total_weight
	# Records with no positive patterns can't be triggered by source
	# content alone — they're filters. Cap them low so only a strong
	# query can surface them.
	if positive_count == 0:
		return minf(ALL_NEGATED_CAP, score)
	return score


func _pattern_matches(kind: String, value: String, source: String,
		identifiers: Dictionary) -> bool:
	if value == "":
		return false
	match kind:
		"identifier":
			return identifiers.has(value)
		"substring":
			return source.find(value) != -1
		"regex":
			var re := RegEx.new()
			var err := re.compile(value)
			if err != OK:
				return false
			return re.search(source) != null
	return false


func _query_score(rec: Dictionary, query_tokens: Array) -> float:
	var phrases: Array = rec.get("phrases", [])
	if phrases.is_empty() or _tokenizer == null:
		return 0.0
	# Build the union of tokens across every phrase in the record.
	var phrase_tokens: Dictionary = {}
	var i: int = 0
	while i < phrases.size():
		var toks: Array = _tokenizer.tokenize(str(phrases[i]))
		var j: int = 0
		while j < toks.size():
			phrase_tokens[str(toks[j])] = true
			j += 1
		i += 1
	# Count how many of the query's tokens appear in the record.
	var overlap: int = 0
	var q: int = 0
	while q < query_tokens.size():
		var t: String = str(query_tokens[q])
		if phrase_tokens.has(t):
			overlap += 1
		q += 1
	if query_tokens.is_empty():
		return 0.0
	return minf(1.0, float(overlap) / float(query_tokens.size()))


func _top_candidate_confidence(rec: Dictionary) -> float:
	var cands: Array = rec.get("candidates", [])
	var best: float = 0.0
	var i: int = 0
	while i < cands.size():
		var c: Variant = cands[i]
		if c is Dictionary:
			var cd: Dictionary = c
			var v: float = float(cd.get("confidence", 0.0))
			if v > best:
				best = v
		i += 1
	return best


func _explain(rec: Dictionary, pattern_score: float, query_score: float,
		query_tokens: Array) -> String:
	var parts: Array[String] = []
	var patterns: Array = rec.get("code_patterns", [])
	if not patterns.is_empty():
		var hits: int = int(round(pattern_score * float(patterns.size())))
		parts.append("%d/%d patterns matched" % [hits, patterns.size()])
	if not query_tokens.is_empty() and query_score > 0.0:
		parts.append("query overlap %.0f%%" % (query_score * 100.0))
	if parts.is_empty():
		return "no signals"
	return ", ".join(parts)


# --- identifier scanning -----------------------------------------------

## Collects every word-like identifier in the source. Cached nowhere —
## each call rebuilds. For files up to a few thousand lines this is
## sub-millisecond.
func _collect_identifiers(source: String) -> Dictionary:
	var out: Dictionary = {}
	if source == "":
		return out
	var re := RegEx.new()
	var err := re.compile("[A-Za-z_][A-Za-z0-9_]*")
	if err != OK:
		return out
	var matches: Array = re.search_all(source)
	var i: int = 0
	while i < matches.size():
		out[matches[i].get_string()] = true
		i += 1
	return out


# --- diagnostics --------------------------------------------------------

## Convenience wrapper — returns just the top result, or empty.
func top_match(source: String, query: String = "") -> Dictionary:
	var r: Array = match(source, {}, query, 1, 0.0)
	if r.is_empty():
		return {}
	return r[0]


# --- self-test ----------------------------------------------------------

## Builds a full library (all volumes), runs the matcher against a few
## crafted scripts, and verifies the expected records rank highly.
## Pass condition: "OK" printed at the end.
static func self_test() -> void:
	print("=== RuleMatcher self-test ===")
	var failures: Array[String] = []

	# --- Setup: full library, tokenizer, matcher ---
	var lib: FixLibrary = FixLibrary.new()
	lib.load_all()
	FixLibraryDataA.register_into(lib)
	FixLibraryDataB.register_into(lib)
	FixLibraryDataC.register_into(lib)
	FixLibraryDataD.register_into(lib)
	FixLibraryDataE.register_into(lib)

	var tk: EnglishTokenizer = EnglishTokenizer.new()
	var rm: RuleMatcher = RuleMatcher.new()
	rm.set_library(lib)
	rm.set_tokenizer(tk)

	# --- 1. Empty source, no query: no result should score high ---
	var r1: Array = rm.match("", {}, "", 5, 0.5)
	if not r1.is_empty():
		failures.append("1: empty source shouldn't return high-confidence results")

	# --- 2. is_on_floor_missing pattern ---
	# Source has move_and_slide but no is_on_floor — that's the signature.
	var src_jump: String = "extends CharacterBody2D\n\nfunc _physics_process(delta):\n\tvelocity.x = 100\n\tmove_and_slide()\n"
	var r2: Array = rm.match(src_jump, {}, "", 10, 0.0)
	var found_jump: bool = false
	var i: int = 0
	while i < r2.size():
		if str(r2[i]["fix_id"]) == "is_on_floor_missing":
			found_jump = true
			break
		i += 1
	if not found_jump:
		failures.append("2: is_on_floor_missing should appear for source with move_and_slide and no is_on_floor")

	# --- 3. Query-only match: phrase token overlap ---
	var r3: Array = rm.match("", {}, "player cant jump", 5, 0.0)
	if r3.is_empty():
		failures.append("3: query 'player cant jump' should match something")
	else:
		var top_id: String = str(r3[0]["fix_id"])
		if top_id != "is_on_floor_missing" and top_id != "jump_velocity_setup" \
				and top_id != "coyote_time_2d" and top_id != "double_jump_2d" \
				and top_id != "jump_buffer_2d":
			failures.append("3: query 'player cant jump' top result unexpected: " + top_id)

	# --- 4. Negate pattern: source that DOES have is_on_floor shouldn't match ---
	var src_ok: String = "extends CharacterBody2D\n\nfunc _physics_process(delta):\n\tif is_on_floor() and Input.is_action_just_pressed(\"jump\"):\n\t\tvelocity.y = -400\n\tmove_and_slide()\n"
	var r4: Array = rm.match(src_ok, {}, "", 20, 0.0)
	i = 0
	while i < r4.size():
		if str(r4[i]["fix_id"]) == "is_on_floor_missing":
			# It may still appear low in the list, but its pattern_score should be reduced
			if float(r4[i]["pattern_score"]) >= 0.9:
				failures.append("4: is_on_floor_missing pattern_score should be reduced when is_on_floor present")
			break
		i += 1

	# --- 5. Results are sorted by descending confidence ---
	if r2.size() >= 2:
		var prev: float = float(r2[0]["confidence"])
		i = 1
		while i < r2.size():
			var cur: float = float(r2[i]["confidence"])
			if cur > prev + 0.0001:
				failures.append("5: results not sorted descending at index %d" % i)
				break
			prev = cur
			i += 1

	# --- 6. Result shape ---
	if not r2.is_empty():
		var first: Dictionary = r2[0]
		for key in ["fix_id", "title", "category", "confidence",
				"pattern_score", "query_score", "base_confidence",
				"why", "primary", "alternatives", "record"]:
			if not first.has(key):
				failures.append("6: result missing key '%s'" % key)
		if not (first["primary"] is Dictionary) or first["primary"].is_empty():
			failures.append("6: primary candidate missing")
		if not (first["record"] is Dictionary):
			failures.append("6: record should be a Dictionary")

	# --- 7. min_score filter ---
	var r7: Array = rm.match(src_jump, {}, "", 100, 0.99)
	if not r7.is_empty():
		failures.append("7: min_score 0.99 should return nothing")

	# --- 8. top_n cap ---
	var r8: Array = rm.match(src_jump, {}, "", 3, 0.0)
	if r8.size() > 3:
		failures.append("8: top_n=3 returned %d results" % r8.size())

	# --- 9. Identifier word-boundary: 'jump' should not match 'jumped' ---
	var ids: Dictionary = rm._collect_identifiers("var jumped = 5")
	if ids.has("jump"):
		failures.append("9: identifier scan shouldn't strip word boundaries")

	# --- 10. match_record returns detailed breakdown ---
	var mr: Dictionary = rm.match_record("is_on_floor_missing", src_jump)
	if mr.is_empty():
		failures.append("10: match_record returned empty")
	elif not mr.has("pattern_score"):
		failures.append("10: match_record missing pattern_score")

	# --- 11. top_match wrapper returns a single dictionary ---
	var tm: Dictionary = rm.top_match(src_jump)
	if tm.is_empty():
		failures.append("11: top_match should return a result for src_jump")
	elif not tm.has("fix_id"):
		failures.append("11: top_match missing fix_id")

	# --- 12. Signal-not-emitted pattern (negate) ---
	var src_signals: String = "signal health_changed\nfunc _ready():\n\tpass\n"
	var r12: Array = rm.match(src_signals, {}, "signal not firing", 10, 0.0)
	var found_sig: bool = false
	i = 0
	while i < r12.size():
		if str(r12[i]["fix_id"]) == "signal_not_emitted":
			found_sig = true
			break
		i += 1
	if not found_sig:
		failures.append("12: signal_not_emitted should appear when source has 'signal' but no emit")

	# --- 13. All-negated-pattern records must not dominate empty source ---
	# camera_lookahead has a single negated pattern. With the cap, it
	# should stay low when the source is empty.
	var mr13: Dictionary = rm.match_record("camera_lookahead", "")
	if not mr13.is_empty():
		var ps: float = float(mr13["pattern_score"])
		if ps > 0.2:
			failures.append("13: all-negated record pattern_score should cap low, got %.3f" % ps)

	# --- 14. All-negated records can still be surfaced by a strong query ---
	var r14: Array = rm.match("", {}, "camera look ahead", 20, 0.0)
	var found_cam: bool = false
	i = 0
	while i < r14.size():
		if str(r14[i]["fix_id"]) == "camera_lookahead":
			found_cam = true
			break
		i += 1
	if not found_cam:
		failures.append("14: camera_lookahead should still be reachable via matching query")

	print("")
	if failures.is_empty():
		print("OK — all assertions passed (%d records in library)" % lib.record_count())
	else:
		print("FAILED — %d issues:" % failures.size())
		i = 0
		while i < failures.size():
			print("  " + failures[i])
			i += 1
