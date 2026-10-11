# keyboard_nav.gd
# Keyboard use and the keyboard exit for sims.mr-miner.com (sims-site SPEC section 6): Tab walks the controls
# in order; Tab past the last, Shift+Tab before the first, or Escape leave the game. While a panel (Hint,
# Chromosome facts) is open, Tab cycles inside it and Escape closes it instead.
# Adapted from water-balance's KeyboardNav.
class_name KeyboardNav
extends Node

# === CONSTANTS ===
const FOCUS_COLOR: Color = Color(0.95, 0.55, 0.05)

# === PUBLIC VARIABLES ===
## Times the keyboard left the game; read by tests.
var leave_count: int = 0
## Called on Escape before leaving; returns true if it handled Escape (e.g. closed a panel).
var escape_handler: Callable = Callable()

# === PRIVATE VARIABLES ===
var _controls: Array[Control] = []
var _wrap: bool = false
var _ring: StyleBoxFlat


# === LIFECYCLE METHODS ===
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ring = StyleBoxFlat.new()
	_ring.draw_center = false
	_ring.border_color = FOCUS_COLOR
	_ring.set_border_width_all(4)
	_ring.set_corner_radius_all(6)
	_ring.set_expand_margin_all(3.0)


# === PUBLIC METHODS ===
## Controls in Tab order. With wrap, Tab cycles (inside a panel) instead of leaving the game.
## Call again whenever the set of visible controls changes; links are relative NodePaths, so call it
## after the layout is final.
func setup(controls: Array[Control], wrap: bool = false) -> void:
	_controls = controls
	_wrap = wrap
	for i: int in range(_controls.size()):
		var c: Control = _controls[i]
		c.focus_mode = Control.FOCUS_ALL
		c.focus_next = c.get_path_to(_controls[(i + 1) % _controls.size()])
		c.focus_previous = c.get_path_to(_controls[(i - 1 + _controls.size()) % _controls.size()])
		if c is Button:
			c.add_theme_stylebox_override("focus", _ring)


func controls() -> Array[Control]:
	return _controls


## Drops focus and asks the sims site's play page to take the keyboard back. On its own page there is no parent.
func leave_game() -> void:
	get_viewport().gui_release_focus()
	leave_count += 1
	if OS.has_feature("web"):
		JavaScriptBridge.eval(
				"if (window.parent !== window) window.parent.postMessage({type: 'sims:leave-game'}, location.origin)")


# === PRIVATE METHODS ===
func _input(event: InputEvent) -> void:
	# In _input, not _unhandled_input: the GUI takes Tab for its own focus movement before that.
	if _controls.is_empty() or not (event is InputEventKey and event.pressed):
		return
	var focus: Control = get_viewport().gui_get_focus_owner()
	var inside: bool = focus != null and focus in _controls
	var leave: bool = false
	if event.is_action_pressed("ui_cancel"):
		if escape_handler.is_valid() and escape_handler.call():
			get_viewport().set_input_as_handled()
			return
		leave = true
	# Exact match (third argument): without it ui_focus_next also matches Shift+Tab
	elif event.is_action_pressed("ui_focus_next", true, true):
		if not inside:
			_controls[0].grab_focus()
			get_viewport().set_input_as_handled()
			return
		if focus == _controls[-1]:
			if _wrap:
				_controls[0].grab_focus()
				get_viewport().set_input_as_handled()
				return
			leave = true
	elif event.is_action_pressed("ui_focus_prev", true, true):
		if not inside:
			_controls[-1].grab_focus()
			get_viewport().set_input_as_handled()
			return
		if focus == _controls[0]:
			if _wrap:
				_controls[-1].grab_focus()
				get_viewport().set_input_as_handled()
				return
			leave = true
	if leave:
		leave_game()
		get_viewport().set_input_as_handled()
