# res://addons/gd_snippet_expander/ai_debugger/gdscript_parser.gd
@tool
class_name GDScriptParser
extends RefCounted

## Parses a GDScript token stream into a lightweight AST.
##
## Part of the GD Snippet Expander mini AI debugger (v1.6).
## Consumes output from GDScriptLexer. Emits an AST as nested
## Dictionaries so the whole thing is JSON-serializable and
## trivially inspectable in the Output panel.
##
## AST nodes are dictionaries with at minimum:
##   "kind"  String  node type name
##   "line"  int     1-based source line
##   "col"   int     1-based source column
##
## The parser is error-tolerant: on unexpected input it records an
## error and attempts to resync at the next NEWLINE or DEDENT, so a
## single malformed statement does not kill the whole parse.
##
## Usage:
##   var lx := GDScriptLexer.new()
##   var toks := lx.tokenize(source_text)
##   var pr := GDScriptParser.new()
##   var ast := pr.parse(toks)
##   for e in pr.errors:
##       print("line %d: %s" % [e.line, e.message])

const T_KEYWORD := GDScriptLexer.TokenType.KEYWORD
const T_IDENT := GDScriptLexer.TokenType.IDENTIFIER
const T_NUMBER := GDScriptLexer.TokenType.NUMBER
const T_STRING := GDScriptLexer.TokenType.STRING
const T_SYMBOL := GDScriptLexer.TokenType.SYMBOL
const T_NEWLINE := GDScriptLexer.TokenType.NEWLINE
const T_INDENT := GDScriptLexer.TokenType.INDENT
const T_DEDENT := GDScriptLexer.TokenType.DEDENT
const T_EOF := GDScriptLexer.TokenType.EOF

const _ASSIGN_OPS := [
	"=", "+=", "-=", "*=", "/=", "%=",
	"**=", "&=", "|=", "^=", "<<=", ">>=",
]

# --- public output ------------------------------------------------------

var errors: Array = []          # each: {line:int, col:int, message:String}

# --- internal state -----------------------------------------------------

var _tokens: Array = []
var _pos: int = 0
var _source_path: String = ""


## Parses a token array. Returns the root Program node.
func parse(tokens_in: Array, source_path: String = "") -> Dictionary:
	_tokens = tokens_in
	_pos = 0
	_source_path = source_path
	errors = []
	var program := _parse_program()
	return program


## Convenience: lex + parse a file in one call.
func parse_file(path: String) -> Dictionary:
	var lx := GDScriptLexer.new()
	var toks := lx.tokenize_file(path)
	for e in lx.errors:
		errors.append(e)
	if toks.is_empty():
		return {"kind": "Program", "line": 0, "col": 0, "declarations": []}
	return parse(toks, path)


# --- token helpers ------------------------------------------------------

func _peek(offset: int = 0) -> Dictionary:
	var i := _pos + offset
	if i < 0 or i >= _tokens.size():
		return {"type": T_EOF, "value": "", "line": 0, "col": 0}
	return _tokens[i]


func _peek_type(offset: int = 0) -> int:
	return _peek(offset)["type"]


func _peek_value(offset: int = 0) -> String:
	return _peek(offset)["value"]


func _at_end() -> bool:
	return _peek_type() == T_EOF


func _advance() -> Dictionary:
	var t := _peek()
	if t["type"] != T_EOF:
		_pos += 1
	return t


func _check(type: int, value: String = "") -> bool:
	var t := _peek()
	if t["type"] != type:
		return false
	if value != "" and t["value"] != value:
		return false
	return true


func _check_kw(value: String) -> bool:
	return _check(T_KEYWORD, value)


func _check_sym(value: String) -> bool:
	return _check(T_SYMBOL, value)


func _match(type: int, value: String = "") -> bool:
	if _check(type, value):
		_advance()
		return true
	return false


func _match_kw(value: String) -> bool:
	return _match(T_KEYWORD, value)


func _match_sym(value: String) -> bool:
	return _match(T_SYMBOL, value)


func _expect_sym(value: String) -> bool:
	if _match_sym(value):
		return true
	_error("Expected '%s', got '%s'." % [value, _peek_value()])
	return false


func _expect_kw(value: String) -> bool:
	if _match_kw(value):
		return true
	_error("Expected keyword '%s', got '%s'." % [value, _peek_value()])
	return false


func _skip_newlines() -> void:
	while _check(T_NEWLINE):
		_advance()


# --- error handling -----------------------------------------------------

func _error(message: String) -> void:
	var t := _peek()
	errors.append({"line": t["line"], "col": t["col"], "message": message})


## Skips tokens until the next NEWLINE at bracket-depth 0, or a DEDENT,
## or EOF. Used to resync after a malformed statement.
func _resync() -> void:
	while not _at_end():
		var tt := _peek_type()
		if tt == T_NEWLINE or tt == T_DEDENT or tt == T_EOF:
			return
		_advance()


# --- program / top-level -----------------------------------------------

func _parse_program() -> Dictionary:
	var program := {
		"kind": "Program",
		"line": 1,
		"col": 1,
		"path": _source_path,
		"declarations": [],
	}
	while not _at_end():
		_skip_newlines()
		if _at_end():
			break
		# A stray DEDENT at top level means the lexer saw an indentation
		# mismatch — skip it and keep going.
		if _check(T_DEDENT) or _check(T_INDENT):
			_advance()
			continue
		var decl := _parse_toplevel_decl()
		if decl.is_empty():
			_resync()
			continue
		program["declarations"].append(decl)
	return program


## Parses one top-level item: leading annotations + one declaration,
## or falls through to a statement parse so the debugger can still
## inspect malformed files (real scripts don't allow top-level code,
## but we want the AST anyway).
func _parse_toplevel_decl() -> Dictionary:
	var annotations: Array = []
	while _check_sym("@"):
		annotations.append(_parse_annotation())

	var t := _peek()

	if t["type"] == T_KEYWORD:
		match t["value"]:
			"class_name":
				return _parse_class_name(annotations)
			"extends":
				return _parse_extends(annotations)
			"signal":
				return _parse_signal(annotations)
			"enum":
				return _parse_enum(annotations)
			"const":
				return _parse_const(annotations)
			"var":
				return _parse_var(annotations, false)
			"func":
				return _parse_func(annotations, false)
			"static":
				if _peek_value(1) == "func":
					_advance()
					return _parse_func(annotations, true)
			"class":
				return _parse_inner_class(annotations)

	if not annotations.is_empty():
		# Annotation with nothing attached — emit it standalone so the
		# classifier can still see it.
		return {
			"kind": "StandaloneAnnotations",
			"line": annotations[0]["line"],
			"col": annotations[0]["col"],
			"annotations": annotations,
		}

	# Not a declaration — parse as a top-level statement or expression.
	# This keeps malformed files parseable so the classifier can still
	# see structure instead of bailing.
	return _parse_statement()


# --- annotations -------------------------------------------------------

## Parses "@name" or "@name(args)". Returns:
##   {"kind":"Annotation", "name":String, "args":[expr...], "line":int, "col":int}
func _parse_annotation() -> Dictionary:
	var at := _advance()  # '@'
	if not _check(T_IDENT) and not _check(T_KEYWORD):
		_error("Expected annotation name after '@'.")
		return {"kind": "Annotation", "name": "", "args": [], "line": at["line"], "col": at["col"]}
	var name_tok := _advance()
	var node := {
		"kind": "Annotation",
		"name": name_tok["value"],
		"args": [],
		"line": at["line"],
		"col": at["col"],
	}
	if _match_sym("("):
		if not _check_sym(")"):
			node["args"].append(_parse_expression())
			while _match_sym(","):
				if _check_sym(")"):
					break
				node["args"].append(_parse_expression())
		_expect_sym(")")
	return node


# --- class_name / extends ----------------------------------------------

func _parse_class_name(_annotations: Array) -> Dictionary:
	var kw := _advance()
	var node := {"kind": "ClassDef", "name": "", "line": kw["line"], "col": kw["col"]}
	if _check(T_IDENT):
		node["name"] = _advance()["value"]
	else:
		_error("Expected class name after 'class_name'.")
	_match(T_NEWLINE)
	return node


func _parse_extends(annotations: Array) -> Dictionary:
	var kw := _advance()
	var node := {
		"kind": "Extends",
		"base": "",
		"line": kw["line"],
		"col": kw["col"],
		"annotations": annotations,
	}
	# Base can be: Node, Node2D, "res://foo.gd", preload("..."), etc.
	if _check(T_IDENT):
		node["base"] = _advance()["value"]
		# Dotted path like Some.Nested.Class
		while _match_sym("."):
			node["base"] += "." + _advance()["value"]
	elif _check(T_STRING):
		node["base"] = _advance()["value"]
	elif _check_kw("preload"):
		# preload("...") — advance past the call, capture the string arg.
		_advance()
		_match_sym("(")
		if _check(T_STRING):
			node["base"] = _advance()["value"]
		_match_sym(")")
	else:
		_error("Expected base type after 'extends'.")
	_match(T_NEWLINE)
	return node


# --- signal / enum ------------------------------------------------------

func _parse_signal(annotations: Array) -> Dictionary:
	var kw := _advance()
	var node := {
		"kind": "SignalDecl",
		"name": "",
		"params": [],
		"line": kw["line"],
		"col": kw["col"],
		"annotations": annotations,
	}
	if _check(T_IDENT):
		node["name"] = _advance()["value"]
	else:
		_error("Expected signal name.")
	if _match_sym("("):
		while not _check_sym(")") and not _at_end():
			var p := {"name": "", "type": ""}
			if _check(T_IDENT):
				p["name"] = _advance()["value"]
			if _match_sym(":"):
				p["type"] = _parse_type_hint()
			node["params"].append(p)
			if not _match_sym(","):
				break
		_expect_sym(")")
	_match(T_NEWLINE)
	return node


func _parse_enum(annotations: Array) -> Dictionary:
	var kw := _advance()
	var node := {
		"kind": "EnumDecl",
		"name": "",
		"values": [],
		"line": kw["line"],
		"col": kw["col"],
		"annotations": annotations,
	}
	if _check(T_IDENT):
		node["name"] = _advance()["value"]
	if not _expect_sym("{"):
		_match(T_NEWLINE)
		return node
	while not _check_sym("}") and not _at_end():
		_skip_newlines()
		if _check_sym("}"):
			break
		var entry := {"name": "", "value": null}
		if _check(T_IDENT):
			entry["name"] = _advance()["value"]
		else:
			_error("Expected enum value name.")
			break
		if _match_sym("="):
			entry["value"] = _parse_expression()
		node["values"].append(entry)
		if not _match_sym(","):
			break
	_expect_sym("}")
	_match(T_NEWLINE)
	return node


# --- const / var --------------------------------------------------------

func _parse_const(annotations: Array) -> Dictionary:
	var kw := _advance()
	var node := _parse_var_decl_body(annotations, false)
	node["kind"] = "ConstDecl"
	node["line"] = kw["line"]
	node["col"] = kw["col"]
	return node


func _parse_var(annotations: Array, _static: bool) -> Dictionary:
	var kw := _advance()
	var node := _parse_var_decl_body(annotations, false)
	node["kind"] = "VarDecl"
	node["line"] = kw["line"]
	node["col"] = kw["col"]
	return node


## Shared body for `var` and `const`. Node is pre-created with kind
## filled in by the caller.
func _parse_var_decl_body(annotations: Array, _is_static: bool) -> Dictionary:
	var node := {
		"name": "",
		"type": "",
		"inferred": false,
		"value": null,
		"line": 0,
		"col": 0,
		"annotations": annotations,
	}
	if _check(T_IDENT):
		node["name"] = _advance()["value"]
	else:
		_error("Expected variable name.")
		_match(T_NEWLINE)
		return node
	# Type hint via single colon.
	if _match_sym(":"):
		node["type"] = _parse_type_hint()
	# Initializer.
	if _match_sym("="):
		node["value"] = _parse_expression()
	elif _match_sym(":="):
		node["inferred"] = true
		node["value"] = _parse_expression()
	_match(T_NEWLINE)
	return node


# --- func ---------------------------------------------------------------

func _parse_func(annotations: Array, is_static: bool) -> Dictionary:
	var kw := _advance()  # 'func'
	var node := {
		"kind": "FuncDecl",
		"name": "",
		"params": [],
		"return_type": "",
		"body": null,
		"static": is_static,
		"line": kw["line"],
		"col": kw["col"],
		"annotations": annotations,
	}
	if _check(T_IDENT):
		node["name"] = _advance()["value"]
	else:
		_error("Expected function name.")
	if _check_sym("("):
		node["params"] = _parse_params()
	else:
		_error("Expected '(' after function name.")
	if _match_sym("->"):
		node["return_type"] = _parse_type_hint()
	# Body: ':' NEWLINE INDENT ... DEDENT
	if _match_sym(":"):
		node["body"] = _parse_block()
	else:
		_error("Expected ':' before function body.")
	return node


func _parse_params() -> Array:
	var params: Array = []
	_expect_sym("(")
	while not _check_sym(")") and not _at_end():
		var p := {
			"name": "",
			"type": "",
			"inferred": false,
			"default": null,
			"annotations": [],
		}
		# Param-level annotations, e.g. @export_range(0, 10) var x
		while _check_sym("@"):
			p["annotations"].append(_parse_annotation())
		if _check(T_IDENT):
			p["name"] = _advance()["value"]
		else:
			_error("Expected parameter name.")
			break
		if _match_sym(":"):
			p["type"] = _parse_type_hint()
		if _match_sym("="):
			p["default"] = _parse_expression()
		elif _match_sym(":="):
			p["inferred"] = true
			p["default"] = _parse_expression()
		params.append(p)
		if not _match_sym(","):
			break
	_expect_sym(")")
	return params


# --- inner class (rare) -------------------------------------------------

func _parse_inner_class(annotations: Array) -> Dictionary:
	var kw := _advance()  # 'class'
	var node := {
		"kind": "InnerClassDecl",
		"name": "",
		"extends": "",
		"body": null,
		"line": kw["line"],
		"col": kw["col"],
		"annotations": annotations,
	}
	if _check(T_IDENT):
		node["name"] = _advance()["value"]
	if _match_kw("extends"):
		if _check(T_IDENT):
			node["extends"] = _advance()["value"]
	if _match_sym(":"):
		node["body"] = _parse_block()
	return node


# --- type hints ---------------------------------------------------------

## Parses a type reference after ':' or '->'. Supports:
##   int
##   Node2D
##   Array[int]
##   Dictionary[String, int]
## Returns "" if no recognizable type is present.
func _parse_type_hint() -> String:
	var t := _peek()
	if t["type"] != T_IDENT and not (t["type"] == T_KEYWORD and t["value"] == "void"):
		_error("Expected type name, got '%s'." % t["value"])
		return ""
	var base: String = _advance()["value"]
	if _match_sym("["):
		var parts: Array[String] = []
		while not _check_sym("]") and not _at_end():
			var sub := _parse_type_hint()
			if sub == "":
				break
			parts.append(sub)
			if not _match_sym(","):
				break
		_expect_sym("]")
		return "%s[%s]" % [base, ", ".join(parts)]
	return base
	# =======================================================================
# PART 2 — statements, expressions, self-test
# =======================================================================


# --- blocks -------------------------------------------------------------

## Parses a block after ':'. Two forms:
##   multi-line: NEWLINE INDENT stmt+ DEDENT
##   single-line: stmt
func _parse_block() -> Dictionary:
	var node := {"kind": "Block", "line": _peek()["line"], "col": _peek()["col"], "statements": []}
	if _match(T_NEWLINE):
		if not _check(T_INDENT):
			# Empty block (unusual but legal in a stub body).
			return node
		_advance()  # INDENT
		while not _check(T_DEDENT) and not _at_end():
			_skip_newlines()
			if _check(T_DEDENT) or _at_end():
				break
			var before := _pos
			var stmt := _parse_statement()
			if not stmt.is_empty():
				node["statements"].append(stmt)
			if _pos == before:
				# No progress — force advance to avoid an infinite loop.
				_advance()
		if _check(T_DEDENT):
			_advance()
	else:
		# Single-line body: `if x: return`
		var stmt := _parse_statement()
		if not stmt.is_empty():
			node["statements"].append(stmt)
	return node


# --- statements ---------------------------------------------------------

func _parse_statement() -> Dictionary:
	var t := _peek()
	var line: int = t["line"]
	var col: int = t["col"]

	if t["type"] == T_KEYWORD:
		match t["value"]:
			"if":
				return _parse_if()
			"for":
				return _parse_for()
			"while":
				return _parse_while()
			"match":
				return _parse_match()
			"return":
				return _parse_return()
			"pass":
				_advance()
				_match(T_NEWLINE)
				return {"kind": "PassStmt", "line": line, "col": col}
			"break":
				_advance()
				_match(T_NEWLINE)
				return {"kind": "BreakStmt", "line": line, "col": col}
			"continue":
				_advance()
				_match(T_NEWLINE)
				return {"kind": "ContinueStmt", "line": line, "col": col}
			"breakpoint":
				_advance()
				_match(T_NEWLINE)
				return {"kind": "BreakpointStmt", "line": line, "col": col}
			"assert":
				return _parse_assert()
			"var":
				return _parse_var([], false)
			"const":
				return _parse_const([])
			"signal":
				return _parse_signal([])
			"func":
				return _parse_func([], false)
			"class":
				return _parse_inner_class([])
			"static":
				if _peek_value(1) == "func":
					_advance()
					return _parse_func([], true)
				if _peek_value(1) == "var":
					_advance()
					return _parse_var([], true)

	# Expression statement — possibly an assignment.
	var expr := _parse_expression()
	if expr.is_empty():
		return {}
	# Assignment operators:  =  +=  -=  *=  /=  %=  **=  &=  |=  ^=  <<=  >>=
	if _peek_type() == T_SYMBOL and _ASSIGN_OPS.has(_peek_value()):
		var op_tok := _advance()
		var rhs := _parse_expression()
		_match(T_NEWLINE)
		return {
			"kind": "AssignStmt",
			"target": expr,
			"op": op_tok["value"],
			"value": rhs,
			"line": expr.get("line", line),
			"col": expr.get("col", col),
		}
	_match(T_NEWLINE)
	return {"kind": "ExprStmt", "line": expr.get("line", line), "col": expr.get("col", col), "expr": expr}


# --- if / elif / else ---------------------------------------------------

func _parse_if() -> Dictionary:
	var kw := _advance()  # 'if'
	var node := {
		"kind": "IfStmt",
		"condition": null,
		"body": null,
		"elifs": [],
		"else_body": null,
		"line": kw["line"],
		"col": kw["col"],
	}
	node["condition"] = _parse_expression()
	if not _expect_sym(":"):
		_match(T_NEWLINE)
		return node
	node["body"] = _parse_block()
	while _check_kw("elif"):
		_advance()
		var ec := _parse_expression()
		_expect_sym(":")
		var eb := _parse_block()
		node["elifs"].append({"condition": ec, "body": eb})
	if _check_kw("else"):
		_advance()
		_expect_sym(":")
		node["else_body"] = _parse_block()
	return node


# --- for / while --------------------------------------------------------

func _parse_for() -> Dictionary:
	var kw := _advance()  # 'for'
	var node := {
		"kind": "ForStmt",
		"var_name": "",
		"var_type": "",
		"iterable": null,
		"body": null,
		"line": kw["line"],
		"col": kw["col"],
	}
	if _check(T_IDENT):
		node["var_name"] = _advance()["value"]
	else:
		_error("Expected loop variable name.")
	if _match_sym(":"):
		node["var_type"] = _parse_type_hint()
	if not _expect_kw("in"):
		_match(T_NEWLINE)
		return node
	node["iterable"] = _parse_expression()
	_expect_sym(":")
	node["body"] = _parse_block()
	return node


func _parse_while() -> Dictionary:
	var kw := _advance()  # 'while'
	var node := {
		"kind": "WhileStmt",
		"condition": null,
		"body": null,
		"line": kw["line"],
		"col": kw["col"],
	}
	node["condition"] = _parse_expression()
	if not _expect_sym(":"):
		return node
	node["body"] = _parse_block()
	return node


# --- match --------------------------------------------------------------

func _parse_match() -> Dictionary:
	var kw := _advance()  # 'match'
	var node := {
		"kind": "MatchStmt",
		"subject": null,
		"cases": [],
		"line": kw["line"],
		"col": kw["col"],
	}
	node["subject"] = _parse_expression()
	if not _expect_sym(":"):
		return node
	if not _match(T_NEWLINE):
		# Single-line match — very unusual; bail cleanly.
		_resync()
		return node
	if not _check(T_INDENT):
		return node
	_advance()  # INDENT
	while not _check(T_DEDENT) and not _at_end():
		_skip_newlines()
		if _check(T_DEDENT) or _at_end():
			break
		var before := _pos
		var case_node := _parse_match_case()
		if not case_node.is_empty():
			node["cases"].append(case_node)
		if _pos == before:
			_advance()
	if _check(T_DEDENT):
		_advance()
	return node


func _parse_match_case() -> Dictionary:
	var node := {
		"kind": "MatchCase",
		"patterns": [],
		"guard": null,
		"body": null,
		"line": _peek()["line"],
		"col": _peek()["col"],
	}
	# One or more patterns separated by ','.
	while true:
		var p := _peek()
		if p["type"] == T_IDENT and p["value"] == "_":
			_advance()
			node["patterns"].append({"kind": "Wildcard", "line": p["line"], "col": p["col"]})
		else:
			var expr := _parse_expression()
			if expr.is_empty():
				_error("Expected match pattern.")
				break
			node["patterns"].append(expr)
		if not _match_sym(","):
			break
	# Optional guard.
	if _match_kw("when"):
		node["guard"] = _parse_expression()
	if not _expect_sym(":"):
		return node
	node["body"] = _parse_block()
	return node


# --- return / assert ----------------------------------------------------

func _parse_return() -> Dictionary:
	var kw := _advance()  # 'return'
	var node := {"kind": "ReturnStmt", "value": null, "line": kw["line"], "col": kw["col"]}
	if not _check(T_NEWLINE) and not _check(T_DEDENT) and not _at_end():
		node["value"] = _parse_expression()
	_match(T_NEWLINE)
	return node


func _parse_assert() -> Dictionary:
	var kw := _advance()  # 'assert'
	var node := {"kind": "AssertStmt", "condition": null, "message": null, "line": kw["line"], "col": kw["col"]}
	_expect_sym("(")
	node["condition"] = _parse_expression()
	if _match_sym(","):
		node["message"] = _parse_expression()
	_expect_sym(")")
	_match(T_NEWLINE)
	return node


# --- expressions (precedence-climbing) ---------------------------------

func _parse_expression() -> Dictionary:
	return _parse_ternary()


## GDScript ternary: `value_if_true if cond else value_if_false`.
func _parse_ternary() -> Dictionary:
	var expr := _parse_or()
	if _check_kw("if"):
		var kw := _advance()
		var cond := _parse_or()
		var else_expr: Dictionary = {}
		if _match_kw("else"):
			else_expr = _parse_ternary()
		else:
			_error("Expected 'else' in ternary expression.")
		return {
			"kind": "Ternary",
			"cond": cond,
			"then_expr": expr,
			"else_expr": else_expr,
			"line": kw["line"],
			"col": kw["col"],
		}
	return expr


func _parse_or() -> Dictionary:
	var left := _parse_and()
	while _check_kw("or"):
		var op := _advance()
		left = _binary("or", left, _parse_and(), op)
	return left


func _parse_and() -> Dictionary:
	var left := _parse_not()
	while _check_kw("and"):
		var op := _advance()
		left = _binary("and", left, _parse_not(), op)
	return left


func _parse_not() -> Dictionary:
	if _check_kw("not"):
		var op := _advance()
		return {
			"kind": "UnaryOp", "op": "not",
			"operand": _parse_not(),
			"line": op["line"], "col": op["col"],
		}
	return _parse_comparison()


func _parse_comparison() -> Dictionary:
	var left := _parse_bitor()
	while true:
		var t := _peek()
		if t["type"] == T_SYMBOL and (t["value"] == "==" or t["value"] == "!=" or t["value"] == "<" or t["value"] == ">" or t["value"] == "<=" or t["value"] == ">="):
			_advance()
			left = _binary(t["value"], left, _parse_bitor(), t)
		elif t["type"] == T_KEYWORD and t["value"] == "in":
			_advance()
			left = _binary("in", left, _parse_bitor(), t)
		elif t["type"] == T_KEYWORD and t["value"] == "is":
			_advance()
			var tname := _parse_type_hint()
			left = {"kind": "IsExpr", "expr": left, "type": tname, "line": t["line"], "col": t["col"]}
		elif t["type"] == T_KEYWORD and t["value"] == "as":
			_advance()
			var tname := _parse_type_hint()
			left = {"kind": "CastExpr", "expr": left, "type": tname, "line": t["line"], "col": t["col"]}
		else:
			break
	return left


func _parse_bitor() -> Dictionary:
	var left := _parse_bitxor()
	while _check_sym("|"):
		var op := _advance()
		left = _binary("|", left, _parse_bitxor(), op)
	return left


func _parse_bitxor() -> Dictionary:
	var left := _parse_bitand()
	while _check_sym("^"):
		var op := _advance()
		left = _binary("^", left, _parse_bitand(), op)
	return left


func _parse_bitand() -> Dictionary:
	var left := _parse_shift()
	while _check_sym("&"):
		var op := _advance()
		left = _binary("&", left, _parse_shift(), op)
	return left


func _parse_shift() -> Dictionary:
	var left := _parse_addsub()
	while _check_sym("<<") or _check_sym(">>"):
		var op := _advance()
		left = _binary(op["value"], left, _parse_addsub(), op)
	return left


func _parse_addsub() -> Dictionary:
	var left := _parse_muldiv()
	while _check_sym("+") or _check_sym("-"):
		var op := _advance()
		left = _binary(op["value"], left, _parse_muldiv(), op)
	return left


func _parse_muldiv() -> Dictionary:
	var left := _parse_unary()
	while _check_sym("*") or _check_sym("/") or _check_sym("%"):
		var op := _advance()
		left = _binary(op["value"], left, _parse_unary(), op)
	return left


func _parse_unary() -> Dictionary:
	if _check_sym("-") or _check_sym("+") or _check_sym("~"):
		var op := _advance()
		return {
			"kind": "UnaryOp", "op": op["value"],
			"operand": _parse_unary(),
			"line": op["line"], "col": op["col"],
		}
	return _parse_power()


func _parse_power() -> Dictionary:
	var base := _parse_postfix()
	if _check_sym("**"):
		var op := _advance()
		# Right-associative; RHS may take a unary prefix.
		var exp := _parse_unary()
		return _binary("**", base, exp, op)
	return base


func _parse_postfix() -> Dictionary:
	var expr := _parse_primary()
	while true:
		if _check_sym("."):
			var dot := _advance()
			if not (_check(T_IDENT) or _check(T_KEYWORD)):
				_error("Expected member name after '.'.")
				break
			var name: String = _advance()["value"]
			expr = {"kind": "Attribute", "target": expr, "name": name, "line": dot["line"], "col": dot["col"]}
		elif _check_sym("["):
			var open := _advance()
			var idx := _parse_expression()
			if _check_sym(".."):
				var op := _advance()
				var end_expr: Dictionary = {}
				if not _check_sym("]"):
					end_expr = _parse_expression()
				_expect_sym("]")
				expr = {"kind": "Slice", "target": expr, "start": idx, "end": end_expr, "line": open["line"], "col": open["col"]}
			else:
				_expect_sym("]")
				expr = {"kind": "Subscript", "target": expr, "index": idx, "line": open["line"], "col": open["col"]}
		elif _check_sym("("):
			expr = _parse_call(expr)
		else:
			break
	return expr


func _parse_call(callee: Dictionary) -> Dictionary:
	var open := _advance()  # '('
	var node := {
		"kind": "Call",
		"callee": callee,
		"args": [],
		"kwargs": [],
		"line": open["line"],
		"col": open["col"],
	}
	while not _check_sym(")") and not _at_end():
		# Keyword argument: name = value
		if _check(T_IDENT) and _peek_value(1) == "=":
			var kw_name: String = _advance()["value"]
			_advance()  # '='
			var kw_val := _parse_expression()
			node["kwargs"].append({"name": kw_name, "value": kw_val})
		else:
			node["args"].append(_parse_expression())
		if not _match_sym(","):
			break
	_expect_sym(")")
	return node


func _parse_primary() -> Dictionary:
	var t := _peek()
	var line: int = t["line"]
	var col: int = t["col"]

	if t["type"] == T_NUMBER:
		_advance()
		return {"kind": "Literal", "literal_type": "number", "value": t["value"], "line": line, "col": col}

	if t["type"] == T_STRING:
		_advance()
		return {"kind": "Literal", "literal_type": "string", "value": t["value"], "line": line, "col": col}

	if t["type"] == T_KEYWORD:
		match t["value"]:
			"true":
				_advance()
				return {"kind": "Literal", "literal_type": "bool", "value": "true", "line": line, "col": col}
			"false":
				_advance()
				return {"kind": "Literal", "literal_type": "bool", "value": "false", "line": line, "col": col}
			"null":
				_advance()
				return {"kind": "Literal", "literal_type": "null", "value": "null", "line": line, "col": col}
			"self":
				_advance()
				return {"kind": "SelfExpr", "line": line, "col": col}
			"super":
				_advance()
				var sup := {"kind": "SuperExpr", "line": line, "col": col}
				if _check_sym("("):
					return _parse_call(sup)
				return sup
			"await":
				_advance()
				var inner := _parse_unary()
				return {"kind": "AwaitExpr", "expr": inner, "line": line, "col": col}
			"preload":
				_advance()
				var ident := {"kind": "Identifier", "name": "preload", "line": line, "col": col}
				if _check_sym("("):
					return _parse_call(ident)
				return ident
			"func":
				return _parse_lambda()

	if t["type"] == T_IDENT:
		_advance()
		return {"kind": "Identifier", "name": t["value"], "line": line, "col": col}

	if _check_sym("("):
		_advance()
		var inner := _parse_expression()
		_expect_sym(")")
		return {"kind": "Group", "expr": inner, "line": line, "col": col}

	if _check_sym("["):
		return _parse_array_literal()

	if _check_sym("{"):
		return _parse_dict_literal()

	_error("Unexpected token '%s' in expression." % t["value"])
	return {}


func _parse_array_literal() -> Dictionary:
	var open := _advance()  # '['
	var node := {"kind": "ArrayLit", "elements": [], "line": open["line"], "col": open["col"]}
	while not _check_sym("]") and not _at_end():
		var el := _parse_expression()
		if el.is_empty():
			break
		node["elements"].append(el)
		if not _match_sym(","):
			break
	_expect_sym("]")
	return node


func _parse_dict_literal() -> Dictionary:
	var open := _advance()  # '{'
	var node := {"kind": "DictLit", "entries": [], "line": open["line"], "col": open["col"]}
	while not _check_sym("}") and not _at_end():
		var key := _parse_expression()
		if key.is_empty():
			break
		# Accept both `"k": v` (Python-style) and `k = v` (Lua-style).
		if _match_sym(":") or _match_sym("="):
			var val := _parse_expression()
			node["entries"].append({"key": key, "value": val})
		else:
			_error("Expected ':' or '=' in dictionary entry.")
			break
		if not _match_sym(","):
			break
	_expect_sym("}")
	return node


func _parse_lambda() -> Dictionary:
	var kw := _advance()  # 'func'
	var node := {
		"kind": "Lambda",
		"params": [],
		"return_type": "",
		"body": null,
		"line": kw["line"],
		"col": kw["col"],
	}
	if _check_sym("("):
		node["params"] = _parse_params()
	if _match_sym("->"):
		node["return_type"] = _parse_type_hint()
	if _match_sym(":"):
		node["body"] = _parse_block()
	return node


func _binary(op: String, left: Dictionary, right: Dictionary, tok: Dictionary) -> Dictionary:
	return {
		"kind": "BinaryOp",
		"op": op,
		"left": left,
		"right": right,
		"line": tok.get("line", 0),
		"col": tok.get("col", 0),
	}


# --- self-test ----------------------------------------------------------

## Lexes + parses a handful of representative GDScript samples and
## prints the resulting AST. Run once after adding the file. The pass
## condition is "0 parse errors" on the final summary line.
static func self_test() -> void:
	var samples := [
		["empty", ""],
		["extends + class_name", "extends Node2D\nclass_name Foo\n"],
		["var + const", "var speed := 200.0\nconst MAX := 10\n"],
		["typed var + annotation", "var hp: int = 100\n@export var label: String = \"x\"\n"],
		["func no body", "func _ready() -> void:\n\tpass\n"],
		["func with params", "func hurt(amount: int, source: Node = null) -> bool:\n\treturn amount > 0\n"],
		["if / elif / else", "if a > 1:\n\tx = 1\nelif a == 1:\n\tx = 2\nelse:\n\tx = 3\n"],
		["for loop", "for i in range(10):\n\tprint(i)\n"],
		["while loop", "while not done:\n\tstep()\n"],
		["match", "match state:\n\t0:\n\t\tprint(\"zero\")\n\t1, 2:\n\t\tprint(\"small\")\n\t_:\n\t\tprint(\"big\")\n"],
		["precedence", "var x = 1 + 2 * 3 - 4 / 2\n"],
		["method chain", "var y = obj.get_node(\"Player\").position.x\n"],
		["call with kwargs", "play(\"jump\", 1.5, loop = true)\n"],
		["array / dict", "var a = [1, 2, 3]\nvar d = {\"key\": \"value\", \"n\": 1}\n"],
		["ternary", "var label = \"big\" if n > 10 else \"small\"\n"],
		["signal", "signal health_changed(old_hp, new_hp)\n"],
		["enum", "enum State { IDLE, WALK, RUN }\n"],
		["lambda", "var f = func(x):\n\treturn x * 2\n"],
		["assignment", "x = 5\nhp -= 10\nspeed *= 1.5\n"],
		["assign to attribute", "self.position.x = 100\n"],
	]
	var total_decls := 0
	var total_errors := 0
	print("=== GDScriptParser self-test ===")
	for s in samples:
		var lx := GDScriptLexer.new()
		var toks: Array = lx.tokenize(s[1])
		var pr := GDScriptParser.new()
		var ast: Dictionary = pr.parse(toks, "<test>")
		var dc: int = ast.get("declarations", []).size()
		total_decls += dc
		total_errors += pr.errors.size()
		print("")
		print("-- %s -- (%d decls, %d errors)" % [s[0], dc, pr.errors.size()])
		if pr.errors.is_empty():
			print(JSON.stringify(ast, "  "))
		else:
			print("  [AST omitted due to errors]")
			for e in pr.errors:
				print("  PARSE ERROR line %d col %d: %s" % [e["line"], e["col"], e["message"]])
	print("")
	print("=== done: %d decls, %d parse errors across %d samples ===" % [total_decls, total_errors, samples.size()])
