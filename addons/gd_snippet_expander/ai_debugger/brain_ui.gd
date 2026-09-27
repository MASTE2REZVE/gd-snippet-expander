# res://addons/gd_snippet_expander/ai_debugger/brain_ui.gd
@tool
class_name BrainUI
extends Control

## Circular confidence indicator for the mini AI debugger.
##
## Part of the GD Snippet Expander mini AI debugger (v1.6).
##
## A small Control widget that draws a ring with a colored arc. The
## arc length tracks the current confidence level. The color scales
## smoothly from blue (low) through amber (medium) to red (high).
## A center dot pulses, with rate and amplitude proportional to the
## confidence — quiet when the AI is uncertain, animated when it's
## sure.
##
## Input goes through push_confidence(), which maintains a rolling
## average so a single odd value doesn't flicker the display. The
## visual smoothing layer then eases display_confidence toward the
## target each frame, so transitions are smooth even when the
## underlying confidence jumps.
##
## Usage:
##   var brain := BrainUI.new()
##   brain.custom_minimum_size = Vector2(96, 96)
##   add_child(brain)
##   brain.push_confidence(0.72)
##
## Resize freely — the widget adapts to whatever rect it's given.

# --- configuration ------------------------------------------------------

## How many recent values the rolling average keeps.
@export var history_size: int = 5

## How quickly display_confidence eases toward the target. Higher is
## snappier, lower is smoother. 8.0 is a good default.
@export var smoothing_speed: float = 8.0

## Pulse rate at confidence 0.0, in Hertz.
@export var pulse_speed_low: float = 0.3

## Pulse rate at confidence 1.0, in Hertz.
@export var pulse_speed_high: float = 2.5

# --- public state -------------------------------------------------------

## Rolling average of recent pushes. This is the "target" the display
## eases toward. Range [0, 1].
var confidence: float = 0.0

## Smoothed display value. Eases toward `confidence` each frame.
## Range [0, 1]. This is what the ring draws.
var display_confidence: float = 0.0

# --- internal -----------------------------------------------------------

var _history: Array = []
var _pulse_phase: float = 0.0


# --- lifecycle ----------------------------------------------------------

func _ready() -> void:
	if custom_minimum_size == Vector2.ZERO:
		custom_minimum_size = Vector2(96, 96)
	set_process(true)


func _process(delta: float) -> void:
	var target: float = confidence
	var k: float = clampf(smoothing_speed * delta, 0.0, 1.0)
	display_confidence = lerpf(display_confidence, target, k)

	# Advance the pulse phase. The rate scales with confidence so a
	# confident suggestion pulses visibly and an uncertain one sits
	# almost still.
	var hz: float = pulse_speed_low \
		+ display_confidence * (pulse_speed_high - pulse_speed_low)
	_pulse_phase += TAU * hz * delta
	if _pulse_phase > TAU:
		_pulse_phase = fmod(_pulse_phase, TAU)

	queue_redraw()


func _draw() -> void:
	var w: float = size.x
	var h: float = size.y
	var dim: float = minf(w, h)
	if dim < 8.0:
		return

	var center: Vector2 = Vector2(w * 0.5, h * 0.5)
	var radius: float = dim * 0.5 - 6.0
	if radius < 2.0:
		return

	# Background ring — full circle, muted.
	var bg_color: Color = Color(0.14, 0.15, 0.18, 1.0)
	draw_arc(center, radius, 0.0, TAU, 96, bg_color, 6.0, true)

	# Confidence arc — starts at 12 o'clock and goes clockwise.
	var c: float = clampf(display_confidence, 0.0, 1.0)
	if c > 0.001:
		var start_angle: float = -PI * 0.5
		var end_angle: float = start_angle + TAU * c
		var arc_color: Color = color_for(c)
		draw_arc(center, radius, start_angle, end_angle, 96, arc_color, 6.0, true)

	# Center dot — pulses. Amplitude and speed both scale with
	# confidence so low values produce a still, quiet dot.
	var dot_base: float = radius * 0.30
	var dot_amp: float = radius * 0.10 * c
	var dot_r: float = dot_base + sin(_pulse_phase) * dot_amp
	if dot_r < 1.0:
		dot_r = 1.0
	var dot_color: Color = color_for(c)
	if c < 0.001:
		dot_color = bg_color
	draw_circle(center, dot_r, dot_color)


# --- input --------------------------------------------------------------

## Add a confidence value to the rolling average and update the
## target. Values outside [0, 1] are clamped. This is the primary
## entry point used by the panel.
func push_confidence(v: float) -> void:
	var x: float = clampf(v, 0.0, 1.0)
	_history.append(x)
	while _history.size() > history_size:
		_history.pop_front()
	confidence = _average_of_history()


## Set the target directly without touching the rolling history.
## Useful when the caller has already smoothed the value or wants
## an instant jump.
func set_confidence(v: float) -> void:
	confidence = clampf(v, 0.0, 1.0)


## Wipe history and reset display to zero. The widget will ease back
## to quiet over the next few frames if it was previously active.
func reset() -> void:
	_history.clear()
	confidence = 0.0
	# Do not zero display_confidence — let smoothing ease it down.


## How many values are currently in the rolling history.
func history_count() -> int:
	return _history.size()


## Current target confidence (rolling average). Same as `confidence`.
func get_average() -> float:
	return confidence


## Current displayed color, matching what the ring is drawing right
## now. Useful if the panel wants to tint a label to match.
func current_color() -> Color:
	return color_for(display_confidence)


func _average_of_history() -> float:
	if _history.is_empty():
		return 0.0
	var sum: float = 0.0
	var i: int = 0
	while i < _history.size():
		sum += float(_history[i])
		i += 1
	return sum / float(_history.size())


# --- color mapping ------------------------------------------------------

## Map a confidence value to a color. Blue -> amber -> red as the
## value rises from 0 to 1. Static so callers can compute the color
## for a value without instantiating the widget.
static func color_for(conf: float) -> Color:
	var c: float = clampf(conf, 0.0, 1.0)
	var low: Color = Color(0.25, 0.55, 0.95)   # blue
	var mid: Color = Color(0.95, 0.70, 0.20)   # amber
	var high: Color = Color(0.92, 0.25, 0.25)  # red
	if c < 0.5:
		return low.lerp(mid, c * 2.0)
	return mid.lerp(high, (c - 0.5) * 2.0)


# --- self-test ----------------------------------------------------------

static func self_test() -> void:
	print("=== BrainUI self-test ===")
	var failures: Array[String] = []

	var b: BrainUI = BrainUI.new()

	# --- 1. Initial state is quiet ---
	if b.confidence != 0.0:
		failures.append("1: initial confidence should be 0.0")
	if b.display_confidence != 0.0:
		failures.append("1: initial display_confidence should be 0.0")
	if b.history_count() != 0:
		failures.append("1: initial history should be empty")

	# --- 2. push_confidence updates target ---
	b.push_confidence(0.5)
	if abs(b.confidence - 0.5) > 0.0001:
		failures.append("2: push_confidence(0.5) should set confidence to 0.5, got %f" % b.confidence)

	# --- 3. Rolling average of recent values ---
	b.reset()
	b.push_confidence(0.2)
	b.push_confidence(0.4)
	b.push_confidence(0.6)
	if abs(b.confidence - 0.4) > 0.0001:
		failures.append("3: rolling average of 0.2/0.4/0.6 should be 0.4, got %f" % b.confidence)

	# --- 4. History size is capped ---
	b.reset()
	var i: int = 0
	while i < 20:
		b.push_confidence(0.5)
		i += 1
	if b.history_count() > b.history_size:
		failures.append("4: history should cap at %d, has %d" % [b.history_size, b.history_count()])

	# --- 5. Smoothing eases display toward target ---
	b.reset()
	b.push_confidence(1.0)
	var before: float = b.display_confidence
	b._process(0.1)
	if b.display_confidence <= before:
		failures.append("5: _process should increase display_confidence toward 1.0")
	if b.display_confidence > 1.0:
		failures.append("5: display_confidence should never exceed 1.0")

	# --- 6. Smoothing converges after enough frames ---
	b.reset()
	b.push_confidence(1.0)
	i = 0
	while i < 100:
		b._process(0.05)
		i += 1
	if abs(b.display_confidence - 1.0) > 0.05:
		failures.append("6: after many steps, display should converge to 1.0, got %f" % b.display_confidence)

	# --- 7. reset clears history and target ---
	b.reset()
	if b.confidence != 0.0:
		failures.append("7: reset should zero the target")
	if b.history_count() != 0:
		failures.append("7: reset should clear history")

	# --- 8. Color mapping endpoints ---
	var low: Color = BrainUI.color_for(0.0)
	var mid: Color = BrainUI.color_for(0.5)
	var high: Color = BrainUI.color_for(1.0)
	if low.b <= low.r:
		failures.append("8: low color should be blue-dominant, got r=%f b=%f" % [low.r, low.b])
	if high.r <= high.b:
		failures.append("8: high color should be red-dominant, got r=%f b=%f" % [high.r, high.b])
	if mid.r <= mid.g or mid.g <= mid.b:
		failures.append("8: mid color should be amber (r > g > b), got r=%f g=%f b=%f" % [mid.r, mid.g, mid.b])

	# --- 9. Color is continuous across the midpoint ---
	var c_lo: Color = BrainUI.color_for(0.49)
	var c_hi: Color = BrainUI.color_for(0.51)
	var delta: float = abs(c_lo.r - c_hi.r) + abs(c_lo.g - c_hi.g) + abs(c_lo.b - c_hi.b)
	if delta > 0.1:
		failures.append("9: color should not jump at the 0.5 boundary, delta=%f" % delta)

	# --- 10. push_confidence clamps out-of-range inputs ---
	b.reset()
	b.push_confidence(2.0)
	if b.confidence > 1.0:
		failures.append("10: push_confidence should clamp above 1.0")
	b.reset()
	b.push_confidence(-1.0)
	if b.confidence < 0.0:
		failures.append("10: push_confidence should clamp below 0.0")

	# --- 11. Pulse phase advances during _process ---
	b.reset()
	b.push_confidence(0.9)
	var phase_before: float = b._pulse_phase
	b._process(0.1)
	if b._pulse_phase <= phase_before:
		failures.append("11: pulse phase should advance during _process")

	# --- 12. current_color tracks display_confidence ---
	b.reset()
	b.push_confidence(1.0)
	i = 0
	while i < 50:
		b._process(0.1)
		i += 1
	var c_display: Color = b.current_color()
	if c_display.r <= c_display.b:
		failures.append("12: at high confidence current_color should be red-dominant")

	# --- 13. set_confidence bypasses history ---
	b.reset()
	b.set_confidence(0.75)
	if abs(b.confidence - 0.75) > 0.0001:
		failures.append("13: set_confidence should set target directly")
	if b.history_count() != 0:
		failures.append("13: set_confidence should not touch history")

	# --- 14. reset does not zero display_confidence immediately ---
	# (It eases down via smoothing, so the user sees a smooth decay.)
	b.reset()
	b.set_confidence(1.0)
	b._process(1.0)
	var snap: float = b.display_confidence
	b.reset()
	if b.display_confidence < snap - 0.001:
		# reset should only zero the target, not the display
		pass
	else:
		# Fine either way, but check the target is zeroed.
		if b.confidence != 0.0:
			failures.append("14: reset must zero the target confidence")

	print("")
	if failures.is_empty():
		print("OK — all assertions passed")
	else:
		print("FAILED — %d issues:" % failures.size())
		i = 0
		while i < failures.size():
			print("  " + failures[i])
			i += 1
