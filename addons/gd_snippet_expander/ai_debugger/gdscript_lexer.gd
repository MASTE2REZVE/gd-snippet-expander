# res://addons/gd_snippet_expander/ai_debugger/gdscript_lexer.gd
@tool
class_name GDScriptLexer
extends RefCounted

## Tokenizes GDScript source code.
##
## Part of the GD Snippet Expander mini AI debugger (v1.6).
## This is a hand-written single-pass lexer. It produces a flat
## token stream with INDENT / DEDENT markers so the parser can
## build block structure without re-counting whitespace.
##
## Token types:
##   KEYWORD     reserved words (func, var, if, return, ...)
##   IDENTIFIER  any user-defined name
##   NUMBER      int, float, hex, binary, underscores, exponent
##   STRING      "..."  '...'  """..."""  '''...'''
##   SYMBOL      operators and punctuation (longest match first)
##   NEWLINE     logical end of statement
##   INDENT      indentation increased (one token per level)
##   DEDENT      indentation decreased (one token per level dropped)
##   EOF         always the final token
##
## Comments are skipped. Whitespace inside a line is skipped.
## Blank lines and comment-only lines are skipped entirely.
## Logical lines continue inside ( [ { and after a trailing \.
##
## Usage:
##   var lx := GDScriptLexer.new()
##   var toks: Array = lx.tokenize(source_text)
##   for e in lx.errors:
##       print("line %d: %s" % [e.line, e.message])

enum TokenType {
	KEYWORD,
	IDENTIFIER,
	NUMBER,
	STRING,
	SYMBOL,
	NEWLINE,
	INDENT,
	DEDENT,
	EOF,
}

const _KEYWORDS := {
	"and": true, "as": true, "assert": true, "await": true,
	"break": true, "breakpoint": true, "class": true, "class_name": true,
	"const": true, "continue": true, "elif": true, "else": true,
	"enum": true, "extends": true, "false": true, "for": true,
	"func": true, "if": true, "in": true, "is": true,
	"match": true, "not": true, "null": true, "or": true,
	"pass": true, "preload": true, "return": true, "self": true,
	"signal": true, "static": true, "super": true, "true": true,
	"var": true, "void": true, "when": true, "while": true,
	"yield": true,
}

# Longest first — the matcher takes the first prefix that fits.
const _MULTI_SYMBOLS := [
	"**=", "<<=", ">>=",
	"->", ":=", "==", "!=", "<=", ">=",
	"+=", "-=", "*=", "/=", "%=",
	"&=", "|=", "^=", "<<", ">>", "**",
	"&&", "||", "::", "..",
]

const _SINGLE_SYMBOLS := "+-*/%=<>!&|^~?:;,.()[]{}$@"

# --- public output ------------------------------------------------------

var tokens: Array = []          # each: {type:int, value:String, line:int, col:int}
var errors: Array = []          # each: {line:int, col:int, message:String}

# --- internal state -----------------------------------------------------

var _src := ""
var _i := 0
var _line := 1
var _line_start := 0
var _at_line_start := true
var _indent_stack: Array[int] = [0]
var _bracket_stack: Array[String] = []


## Tokenizes a source string. Resets all internal state first, so the
## same lexer instance can be reused across files.
func tokenize(source: String) -> Array:
	tokens = []
	errors = []
	_src = source
	_i = 0
	_line = 1
	_line_start = 0
	_at_line_start = true
	_indent_stack = [0]
	_bracket_stack = []

	var n := _src.length()
	while _i < n:
		if _at_line_start:
			if _handle_line_start():
				continue
		_lex_one()

	# Close the final statement if it did not end with a newline.
	if not tokens.is_empty() and tokens[tokens.size() - 1]["type"] != TokenType.NEWLINE:
		_emit(TokenType.NEWLINE, "\n", _line, 1)
	# Emit a DEDENT for every still-open indent level.
	while _indent_stack.size() > 1:
		_indent_stack.pop_back()
		_emit(TokenType.DEDENT, "", _line, 1)
	_emit(TokenType.EOF, "", _line, 1)

	return tokens


## Reads a file and tokenizes it. Sets `errors` on failure to open.
func tokenize_file(path: String) -> Array:
	if not FileAccess.file_exists(path):
		tokens = []
		errors = [{"line": 0, "col": 0, "message": "File not found: %s" % path}]
		return []
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		tokens = []
		errors = [{"line": 0, "col": 0, "message": "Cannot open: %s" % path}]
		return []
	var text := f.get_as_text()
	f.close()
	return tokenize(text)


# --- line-start handling ------------------------------------------------

## Called when `_at_line_start` is true. Handles indentation and skips
## blank or comment-only lines. Returns true if the entire line was
## consumed (caller should not lex a token this iteration).
func _handle_line_start() -> bool:
	var n := _src.length()
	var indent := 0
	var j := _i
	while j < n and (_src[j] == " " or _src[j] == "\t"):
		indent += 1
		j += 1

	# Blank line.
	if j >= n or _src[j] == "\n":
		_i = j
		if _i < n:
			_i += 1
			_line += 1
			_line_start = _i
		return true

	# Comment-only line.
	if _src[j] == "#":
		_i = j
		while _i < n and _src[_i] != "\n":
			_i += 1
		if _i < n:
			_i += 1
			_line += 1
			_line_start = _i
		return true

	# Real content — reconcile indentation.
	var cur: int = _indent_stack[_indent_stack.size() - 1]
	if indent > cur:
		_indent_stack.append(indent)
		_emit(TokenType.INDENT, "", _line, 1)
	elif indent < cur:
		while _indent_stack.size() > 1 and _indent_stack[_indent_stack.size() - 1] > indent:
			_indent_stack.pop_back()
			_emit(TokenType.DEDENT, "", _line, 1)
		if _indent_stack[_indent_stack.size() - 1] != indent:
			_err_at("Inconsistent indentation.", _line, 1)

	_i = j
	_at_line_start = false
	return false


# --- main per-character dispatch ---------------------------------------

func _lex_one() -> void:
	var n := _src.length()
	if _i >= n:
		return
	var ch := _src[_i]

	# Logical line break.
	if ch == "\n":
		_i += 1
		var prev_line := _line
		_line += 1
		_line_start = _i
		if _bracket_stack.is_empty():
			_emit(TokenType.NEWLINE, "\n", prev_line, 1)
			_at_line_start = true
		return

	# Bare carriage return (Windows CRLF — the LF is handled above).
	if ch == "\r":
		_i += 1
		return

	# Whitespace within a line.
	if ch == " " or ch == "\t":
		_i += 1
		return

	# Comment — skip to end of line.
	if ch == "#":
		while _i < n and _src[_i] != "\n":
			_i += 1
		return

	# Line continuation — backslash immediately before a newline.
	if ch == "\\":
		var k := _i + 1
		if k < n and _src[k] == "\r":
			k += 1
		if k < n and _src[k] == "\n":
			_i = k + 1
			_line += 1
			_line_start = _i
			return
		_err("Unexpected '\\' outside a string or line continuation.")
		_i += 1
		return

	# String literal.
	if ch == "\"" or ch == "'":
		_read_string()
		return

	# Numeric literal. A leading '.' followed by a digit is a float.
	if _is_digit(ch) or (ch == "." and _i + 1 < n and _is_digit(_src[_i + 1])):
		_read_number()
		return

	# Identifier or keyword.
	if _is_ident_start(ch):
		var start := _i
		while _i < n and _is_ident_part(_src[_i]):
			_i += 1
		var word := _src.substr(start, _i - start)
		var kind := TokenType.KEYWORD if _KEYWORDS.has(word) else TokenType.IDENTIFIER
		_emit(kind, word, _line, start - _line_start + 1)
		return

	# Multi-character symbols, longest first.
	for sym in _MULTI_SYMBOLS:
		var slen: int = sym.length()
		if _i + slen <= n and _src.substr(_i, slen) == sym:
			_emit(TokenType.SYMBOL, sym, _line, _i - _line_start + 1)
			_i += slen
			return

	# Single-character symbol.
	if _SINGLE_SYMBOLS.contains(ch):
		_emit(TokenType.SYMBOL, ch, _line, _i - _line_start + 1)
		_track_bracket(ch)
		_i += 1
		return

	# Anything else — report and move on.
	_err("Unexpected character '%s'." % ch)
	_i += 1


# --- sub-scanners -------------------------------------------------------

func _read_string() -> void:
	var n := _src.length()
	var start := _i
	var line := _line
	var col := start - _line_start + 1
	var quote := _src[_i]
	var triple := start + 2 < n and _src[start + 1] == quote and _src[start + 2] == quote
	var closed := false

	if triple:
		_i += 3
		while _i < n:
			if _src[_i] == "\\":
				_i += 1
				if _i < n:
					if _src[_i] == "\n":
						_line += 1
						_i += 1
						_line_start = _i
					else:
						_i += 1
				continue
			if _src[_i] == "\n":
				_line += 1
				_i += 1
				_line_start = _i
				continue
			if _i + 2 < n and _src[_i] == quote and _src[_i + 1] == quote and _src[_i + 2] == quote:
				_i += 3
				closed = true
				break
			_i += 1
		if not closed:
			_err_at("Unterminated triple-quoted string.", line, col)
	else:
		_i += 1
		while _i < n:
			if _src[_i] == "\\":
				_i += 2
				continue
			if _src[_i] == quote:
				_i += 1
				closed = true
				break
			if _src[_i] == "\n":
				break
			_i += 1
		if not closed:
			_err_at("Unterminated string.", line, col)

	_emit(TokenType.STRING, _src.substr(start, _i - start), line, col)


func _read_number() -> void:
	var n := _src.length()
	var start := _i
	var line := _line
	var col := start - _line_start + 1

	if _src[_i] == "0" and _i + 1 < n and (_src[_i + 1] == "x" or _src[_i + 1] == "X"):
		_i += 2
		while _i < n and (_is_hex_digit(_src[_i]) or _src[_i] == "_"):
			_i += 1
	elif _src[_i] == "0" and _i + 1 < n and (_src[_i + 1] == "b" or _src[_i + 1] == "B"):
		_i += 2
		while _i < n and (_src[_i] == "0" or _src[_i] == "1" or _src[_i] == "_"):
			_i += 1
	else:
		while _i < n and (_is_digit(_src[_i]) or _src[_i] == "_"):
			_i += 1
		# Fractional part — do not consume the first dot of a ".." range.
		if _i < n and _src[_i] == "." and not (_i + 1 < n and _src[_i + 1] == "."):
			_i += 1
			while _i < n and (_is_digit(_src[_i]) or _src[_i] == "_"):
				_i += 1
		# Exponent.
		if _i < n and (_src[_i] == "e" or _src[_i] == "E"):
			var k := _i + 1
			if k < n and (_src[k] == "+" or _src[k] == "-"):
				k += 1
			if k < n and _is_digit(_src[k]):
				_i = k
				while _i < n and (_is_digit(_src[_i]) or _src[_i] == "_"):
					_i += 1

	_emit(TokenType.NUMBER, _src.substr(start, _i - start), line, col)


func _track_bracket(ch: String) -> void:
	match ch:
		"(", "[", "{":
			_bracket_stack.append(ch)
		")", "]", "}":
			if _bracket_stack.is_empty():
				_err("Unmatched closing '%s'." % ch)
				return
			var opener: String = _bracket_stack[_bracket_stack.size() - 1]
			var expected := {"(" : ")", "[" : "]", "{" : "}"}
			if expected[opener] != ch:
				_err("Mismatched bracket: '%s' closes '%s'." % [ch, opener])
			_bracket_stack.pop_back()


# --- character predicates ----------------------------------------------

func _is_digit(c: String) -> bool:
	return c >= "0" and c <= "9"


func _is_hex_digit(c: String) -> bool:
	return (c >= "0" and c <= "9") or (c >= "a" and c <= "f") or (c >= "A" and c <= "F")


func _is_ident_start(c: String) -> bool:
	return (c >= "a" and c <= "z") or (c >= "A" and c <= "Z") or c == "_"


func _is_ident_part(c: String) -> bool:
	return _is_ident_start(c) or _is_digit(c)


# --- emit / error -------------------------------------------------------

func _emit(type: int, value: String, line: int = -1, col: int = -1) -> void:
	if line < 0:
		line = _line
	if col < 0:
		col = _i - _line_start + 1
	tokens.append({"type": type, "value": value, "line": line, "col": col})


func _err(message: String) -> void:
	_err_at(message, _line, _i - _line_start + 1)


func _err_at(message: String, line: int, col: int) -> void:
	errors.append({"line": line, "col": col, "message": message})


# --- debugging helpers --------------------------------------------------

static func token_type_name(type: int) -> String:
	match type:
		TokenType.KEYWORD: return "KEYWORD"
		TokenType.IDENTIFIER: return "IDENTIFIER"
		TokenType.NUMBER: return "NUMBER"
		TokenType.STRING: return "STRING"
		TokenType.SYMBOL: return "SYMBOL"
		TokenType.NEWLINE: return "NEWLINE"
		TokenType.INDENT: return "INDENT"
		TokenType.DEDENT: return "DEDENT"
		TokenType.EOF: return "EOF"
	return "UNKNOWN"


static func format_tokens(toks: Array) -> String:
	var lines: Array[String] = []
	for t in toks:
		var v: String = t["value"]
		v = v.replace("\n", "\\n").replace("\t", "\\t").replace("\r", "\\r")
		if v.length() > 40:
			v = v.substr(0, 37) + "..."
		lines.append("%4d:%-3d %-10s %s" % [t["line"], t["col"], token_type_name(t["type"]), v])
	return "\n".join(lines)


## Prints the token stream for a handful of representative sources.
## Run this once after adding the file to confirm the lexer behaves.
static func self_test() -> void:
	var samples := [
		["basic function", "func foo():\n\tpass\n"],
		["if / else", "if x > 1:\n\tprint(\"hi\")\nelse:\n\tprint(\"no\")\n"],
		["string escapes", "var s = \"a\\\"b\"\nvar t = 'x'\n"],
		["triple string", "var s = \"\"\"line1\nline2\"\"\"\n"],
		["brackets", "var a = [\n\t1,\n\t2,\n]\n"],
		["continuation", "var x = 1 + \\\n\t2\n"],
		["numbers", "var a = 0xFF\nvar b = 1_000_000\nvar c = 1.5e-3\n"],
		["empty source", ""],
	]
	var total_tokens := 0
	var total_errors := 0
	print("=== GDScriptLexer self-test ===")
	for s in samples:
		var lx := GDScriptLexer.new()
		var toks: Array = lx.tokenize(s[1])
		total_tokens += toks.size()
		total_errors += lx.errors.size()
		print("")
		print("-- %s -- (%d tokens, %d errors)" % [s[0], toks.size(), lx.errors.size()])
		print(format_tokens(toks))
		for e in lx.errors:
			print("  ERROR line %d col %d: %s" % [e["line"], e["col"], e["message"]])
	print("")
	print("=== done: %d tokens, %d errors across %d samples ===" % [total_tokens, total_errors, samples.size()])
