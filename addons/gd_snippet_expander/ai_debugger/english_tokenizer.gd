# res://addons/gd_snippet_expander/ai_debugger/english_tokenizer.gd
@tool
class_name EnglishTokenizer
extends RefCounted

## Splits English text into normalized tokens for the mini AI debugger.
##
## Part of the GD Snippet Expander mini AI debugger (v1.6).
## Pipeline:  lowercase -> strip punctuation -> split -> remove
## stopwords -> apply a light suffix stemmer. The result is a list
## of canonical tokens like ["player", "jump", "wall"] that the
## embedding stage can look up without worrying about tense,
## plurality, or case.
##
## The stemmer is NOT full Porter. It handles the suffixes that
## actually matter for game-development English: -ing, -ed, -s,
## -ies, -ly, -ment, -ness. Rare suffixes are left alone on purpose
## to avoid mangling technical words.
##
## Usage:
##   var tk := EnglishTokenizer.new()
##   var toks := tk.tokenize("The player can't jump over the wall")
##   # -> ["player", "jump", "wall"]

const STOPWORDS := {
	# articles
	"a": true, "an": true, "the": true,
	# conjunctions
	"and": true, "or": true, "but": true, "if": true, "then": true,
	"else": true, "so": true, "nor": true, "yet": true,
	# prepositions
	"at": true, "by": true, "in": true, "on": true, "of": true,
	"to": true, "from": true, "with": true, "without": true,
	"into": true, "onto": true, "upon": true, "over": true,
	"under": true, "above": true, "below": true,
	"up": true, "down": true, "out": true, "off": true,
	"as": true, "than": true, "about": true, "against": true,
	"between": true, "among": true, "through": true, "during": true,
	"before": true, "after": true, "since": true, "until": true,
	"while": true, "because": true, "though": true, "although": true,
	"unless": true, "whether": true,
	# pronouns
	"i": true, "you": true, "he": true, "she": true, "it": true,
	"we": true, "they": true, "me": true, "him": true, "her": true,
	"us": true, "them": true, "my": true, "your": true, "his": true,
	"its": true, "our": true, "their": true,
	"mine": true, "yours": true, "hers": true, "ours": true,
	"theirs": true,
	"this": true, "that": true, "these": true, "those": true,
	# question words
	"what": true, "which": true, "who": true, "whom": true,
	"whose": true, "where": true, "when": true, "why": true,
	"how": true,
	# auxiliaries / modals
	"is": true, "are": true, "was": true, "were": true, "be": true,
	"been": true, "being": true,
	"have": true, "has": true, "had": true, "having": true,
	"do": true, "does": true, "did": true, "doing": true,
	"will": true, "would": true, "shall": true, "should": true,
	"may": true, "might": true, "must": true,
	"can": true, "could": true,
	# quantifiers
	"all": true, "some": true, "any": true, "many": true, "few": true,
	"more": true, "most": true, "less": true, "least": true,
	"each": true, "every": true, "both": true, "either": true,
	"neither": true, "other": true, "another": true,
	"such": true, "same": true, "own": true, "very": true,
	"just": true, "too": true, "also": true, "only": true, "even": true,
	# misc filler
	"yes": true, "no": true, "not": true, "now": true,
	"here": true, "there": true,
	"ok": true, "okay": true, "please": true,
	"thanks": true, "thank": true,
	# contractions, apostrophes already stripped
	"cant": true, "dont": true, "wont": true,
	"isnt": true, "arent": true, "wasnt": true, "werent": true,
	"hasnt": true, "havent": true, "hadnt": true,
	"doesnt": true, "didnt": true,
	"wouldnt": true, "shouldnt": true, "couldnt": true, "mustnt": true,
	"im": true, "ive": true, "ill": true, "id": true,
	"hes": true, "shes": true,
	"youre": true, "youve": true, "youll": true, "youd": true,
	"weve": true, "wed": true,
	"theyre": true, "theyve": true, "theyll": true, "theyd": true,
	"lets": true, "thats": true, "whats": true, "whos": true,
	"theres": true, "heres": true,
	# filler verbs that add nothing to a query
	"help": true, "need": true, "want": true, "like": true,
}

# --- public API --------------------------------------------------------

## Full pipeline: normalize, split, drop stopwords, stem.
## Returns a list of canonical lowercase tokens in original order.
func tokenize(text: String) -> Array[String]:
	var out: Array[String] = []
	for w in split_words(text):
		if STOPWORDS.has(w):
			continue
		var s := stem(w)
		if s != "":
			out.append(s)
	return out


## Same as tokenize() but keeps stopwords. Useful for debugging the
## stemmer and for the classifier's "what did the user actually type"
## feature.
func tokenize_keep_stopwords(text: String) -> Array[String]:
	var out: Array[String] = []
	for w in split_words(text):
		var s := stem(w)
		if s != "":
			out.append(s)
	return out


## Lowercase, strip punctuation, split on whitespace. Apostrophes are
## removed so contractions become one token ("can't" -> "cant").
## Hyphens and underscores become spaces so "move_and_slide" splits
## into ["move", "and", "slide"]. No stopword filtering, no stemming.
func split_words(text: String) -> Array[String]:
	var norm := _normalize(text)
	var out: Array[String] = []
	for w in norm.split(" ", false):
		if w != "":
			out.append(w)
	return out


func is_stopword(word: String) -> bool:
	return STOPWORDS.has(word.to_lower())


# --- stemmer -----------------------------------------------------------

## Light suffix stemmer. Not full Porter — handles the suffixes that
## matter for game-dev English. Returns the input with applicable
## suffixes removed. Input shorter than 2 characters is returned as-is.
func stem(word: String) -> String:
	var w := word.to_lower()
	if w.length() < 2:
		return w

	# --- Step 1a: plurals and 3rd-person singular ---
	if w.ends_with("sses"):
		w = w.substr(0, w.length() - 2)          # "classes" -> "class"
	elif w.ends_with("ies"):
		w = w.substr(0, w.length() - 3) + "y"    # "flies"   -> "fly"
	elif w.ends_with("ss"):
		pass                                     # "class"   stays
	elif w.ends_with("s"):
		w = w.substr(0, w.length() - 1)          # "jumps"   -> "jump"

	# --- Step 1b: past tense / gerund ---
	if w.ends_with("eed"):
		var base_e := w.substr(0, w.length() - 3)
		if _has_vowel(base_e):
			w = w.substr(0, w.length() - 1)      # "agreed" -> "agree"
	elif w.ends_with("ed"):
		var base_ed := w.substr(0, w.length() - 2)
		if _has_vowel(base_ed):
			w = _post_ed_ing(base_ed)            # "jumped" -> "jump"
	elif w.ends_with("ing"):
		var base_ing := w.substr(0, w.length() - 3)
		if _has_vowel(base_ing):
			w = _post_ed_ing(base_ing)           # "running" -> "run"

	# --- Step 2: common noun/adverb suffixes ---
	if w.ends_with("ness") and w.length() >= 6:
		w = w.substr(0, w.length() - 4)          # "darkness" -> "dark"
	elif w.ends_with("ment") and w.length() >= 6:
		w = w.substr(0, w.length() - 4)          # "movement" -> "move"
	elif w.ends_with("ly") and w.length() >= 5:
		w = w.substr(0, w.length() - 2)          # "quickly"  -> "quick"

	return w


func _post_ed_ing(stem_in: String) -> String:
	if stem_in.ends_with("at") or stem_in.ends_with("bl") or stem_in.ends_with("iz"):
		return stem_in + "e"
	if _ends_double_consonant(stem_in) \
			and stem_in[stem_in.length() - 1] != "l" \
			and stem_in[stem_in.length() - 1] != "s" \
			and stem_in[stem_in.length() - 1] != "z":
		return stem_in.substr(0, stem_in.length() - 1)
	if _ends_cvc(stem_in):
		return stem_in + "e"
	return stem_in


func _has_vowel(s: String) -> bool:
	for c in s:
		if c == "a" or c == "e" or c == "i" or c == "o" or c == "u":
			return true
	return false


func _ends_double_consonant(s: String) -> bool:
	if s.length() < 2:
		return false
	var last := s[s.length() - 1]
	var prev := s[s.length() - 2]
	if last != prev:
		return false
	if last == "a" or last == "e" or last == "i" or last == "o" or last == "u":
		return false
	return true


func _ends_cvc(s: String) -> bool:
	if s.length() < 3:
		return false
	var c1 := s[s.length() - 3]
	var v := s[s.length() - 2]
	var c2 := s[s.length() - 1]
	if c1 == "a" or c1 == "e" or c1 == "i" or c1 == "o" or c1 == "u":
		return false
	if not (v == "a" or v == "e" or v == "i" or v == "o" or v == "u"):
		return false
	if c2 == "a" or c2 == "e" or c2 == "i" or c2 == "o" or c2 == "u":
		return false
	if c2 == "w" or c2 == "x" or c2 == "y":
		return false
	return true


# --- normalization -----------------------------------------------------

## Lowercase, replace hyphens/underscores with spaces, strip
## apostrophes so contractions become one token, replace all other
## non-alphanumeric characters with spaces, collapse whitespace.
func _normalize(text: String) -> String:
	var s := text.to_lower()
	var out := ""
	for i in s.length():
		var c := s[i]
		if c == "'" or c == "`":
			continue                             # "can't" -> "cant"
		elif c == "-" or c == "_":
			out += " "                           # "move_and_slide" -> "move and slide"
		elif (c >= "a" and c <= "z") or (c >= "0" and c <= "9"):
			out += c
		else:
			out += " "
	return out.strip_edges()


# --- self-test ---------------------------------------------------------

## Runs a batch of assertions. Pass condition is "OK" printed at the
## end. Output is short — one line per failure, if any.
static func self_test() -> void:
	print("=== EnglishTokenizer self-test ===")
	var tk := EnglishTokenizer.new()
	var failures: Array[String] = []

	# 1. Stopwords removed
	var r1 := tk.tokenize("the player can jump")
	_assert_contains(r1, "player", failures, "1")
	_assert_contains(r1, "jump", failures, "1")
	_assert_not_contains(r1, "the", failures, "1")
	_assert_not_contains(r1, "can", failures, "1")
	_assert_size(r1, 2, failures, "1")

	# 2. Contractions and prepositions
	var r2 := tk.tokenize("my player can't jump over the wall")
	_assert_contains(r2, "player", failures, "2")
	_assert_contains(r2, "jump", failures, "2")
	_assert_contains(r2, "wall", failures, "2")
	_assert_not_contains(r2, "cant", failures, "2")
	_assert_not_contains(r2, "over", failures, "2")
	_assert_size(r2, 3, failures, "2")

	# 3. -ing stemmer
	var r3 := tk.tokenize("running and jumping")
	_assert_contains(r3, "run", failures, "3")
	_assert_contains(r3, "jump", failures, "3")
	_assert_not_contains(r3, "running", failures, "3")
	_assert_not_contains(r3, "jumping", failures, "3")

	# 4. All tenses collapse to same stem
	var r4 := tk.tokenize("jumped jumped jumps")
	_assert_size(r4, 3, failures, "4")
	for t in r4:
		if t != "jump":
			failures.append("4: expected all 'jump', got '%s'" % t)

	# 5. Underscores split
	var r5 := tk.tokenize("move_and_slide")
	_assert_contains(r5, "move", failures, "5")
	_assert_contains(r5, "slide", failures, "5")
	_assert_not_contains(r5, "and", failures, "5")

	# 6. Empty input
	var r6 := tk.tokenize("")
	_assert_size(r6, 0, failures, "6")

	# 7. All-stopword input
	var r7 := tk.tokenize("the and or but")
	_assert_size(r7, 0, failures, "7")

	# 8. Punctuation stripped
	var r8 := tk.tokenize("Hello, world!")
	_assert_contains(r8, "hello", failures, "8")
	_assert_contains(r8, "world", failures, "8")
	_assert_size(r8, 2, failures, "8")

	# 9. Possessives + stemming together
	var r9 := tk.tokenize("He's running fast")
	_assert_contains(r9, "run", failures, "9")
	_assert_contains(r9, "fast", failures, "9")
	_assert_not_contains(r9, "hes", failures, "9")
	_assert_size(r9, 2, failures, "9")

	# 10. Plurals and common game-dev vocabulary
	var r10 := tk.tokenize("Classes and nodes and enemies")
	_assert_contains(r10, "class", failures, "10")
	_assert_contains(r10, "node", failures, "10")
	_assert_contains(r10, "enemy", failures, "10")
	_assert_size(r10, 3, failures, "10")

	# 11. -ss is preserved
	var s11 := tk.stem("class")
	if s11 != "class":
		failures.append("11: 'class' should not be stemmed, got '%s'" % s11)

	# 12. -ness, -ment, -ly
	var s12a := tk.stem("darkness")
	if s12a != "dark":
		failures.append("12: 'darkness' -> expected 'dark', got '%s'" % s12a)
	var s12b := tk.stem("movement")
	if s12b != "move":
		failures.append("12: 'movement' -> expected 'move', got '%s'" % s12b)
	var s12c := tk.stem("quickly")
	if s12c != "quick":
		failures.append("12: 'quickly' -> expected 'quick', got '%s'" % s12c)

	print("")
	if failures.is_empty():
		print("OK — all assertions passed")
	else:
		print("FAILED — %d issues:" % failures.size())
		for f in failures:
			print("  " + f)


static func _assert_contains(arr: Array, item: String, fails: Array[String], tag: String) -> void:
	if not (item in arr):
		fails.append("%s: expected '%s' in %s" % [tag, item, str(arr)])


static func _assert_not_contains(arr: Array, item: String, fails: Array[String], tag: String) -> void:
	if item in arr:
		fails.append("%s: did NOT expect '%s' in %s" % [tag, item, str(arr)])


static func _assert_size(arr: Array, n: int, fails: Array[String], tag: String) -> void:
	if arr.size() != n:
		fails.append("%s: expected size %d, got %d — %s" % [tag, n, arr.size(), str(arr)])
