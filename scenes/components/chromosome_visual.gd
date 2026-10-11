# chromosome_visual.gd
# A chromosome drawn as a coloured bar with one band per allele. Each band has the allele's colour, its own
# shape (filled = dominant, outlined = recessive) and, while labels are on, its symbol and name ("R Round").
# Used in the Gene Bank and, with slot_type set, as a Reactor slot that may be empty.
# Focusable: click, tap, Enter or Space activates it; hover or focus asks for its description.
# Educational: Shows that genes are physically linked on chromosomes
class_name ChromosomeVisual
extends Control

# === SIGNALS ===
signal activated(visual: ChromosomeVisual)
signal described(visual: ChromosomeVisual)

# === CONSTANTS ===
const BAR_SIZE: Vector2 = Vector2(104.0, 108.0)
const BAND_HEIGHT: float = 30.0
const CAPTION_HEIGHT: float = 22.0
const INK: Color = Color(0.13, 0.14, 0.18)
const FOCUS_COLOR: Color = Color(0.95, 0.55, 0.05)

# === PUBLIC VARIABLES ===
var chromosome: Chromosome = null
## Reactor slot only: the chromosome type it takes (1-3), or 0 for the Extra slot (any type). -1 in the Gene Bank.
var slot_type: int = -1
var show_labels: bool = true
## Text under the bar when it is an empty slot ("Pair 1", "Extra")
var slot_caption: String = ""

# === PRIVATE VARIABLES ===
var _hovered: bool = false


# === LIFECYCLE METHODS ===
func _ready() -> void:
	focus_mode = Control.FOCUS_ALL
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	custom_minimum_size = Vector2(BAR_SIZE.x + 6.0, BAR_SIZE.y + CAPTION_HEIGHT + 4.0)
	focus_entered.connect(_on_focus_changed)
	focus_exited.connect(_on_focus_changed)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


# === PUBLIC METHODS ===
func set_chromosome(chr: Chromosome) -> void:
	chromosome = chr
	queue_redraw()


func set_labels(visible_labels: bool) -> void:
	show_labels = visible_labels
	queue_redraw()


func is_slot() -> bool:
	return slot_type >= 0


## What the status line says about this chromosome or slot
func description() -> String:
	if chromosome != null:
		var where: String = " (in the Reactor: activate to take it out)" if is_slot() else ""
		return chromosome.describe() + where
	if slot_type == 0:
		return "Extra slot: an extra copy of any chromosome goes here."
	return "Empty slot for chromosome %d: pick one from the Gene Bank." % slot_type


## Draws an allele's shape centred at `center`. Filled for a dominant allele, outlined for a recessive one.
static func draw_allele_shape(ci: CanvasItem, shape: String, center: Vector2, r: float, filled: bool) -> void:
	var w: float = 2.0
	match shape:
		"circle":
			if filled:
				ci.draw_circle(center, r, INK)
			else:
				ci.draw_arc(center, r - 1.0, 0.0, TAU, 24, INK, w)
		"square":
			_poly(ci, PackedVector2Array([center + Vector2(-r, -r), center + Vector2(r, -r), center + Vector2(r, r), center + Vector2(-r, r)]), filled)
		"star":
			var pts: Array[Vector2] = []
			for i: int in range(10):
				var rad: float = r if i % 2 == 0 else r * 0.45
				var a: float = -PI / 2.0 + float(i) * PI / 5.0
				pts.append(center + Vector2(cos(a), sin(a)) * rad)
			_poly(ci, PackedVector2Array(pts), filled)
		"dash":
			_poly(ci, PackedVector2Array([center + Vector2(-r, -r * 0.35), center + Vector2(r, -r * 0.35), center + Vector2(r, r * 0.35), center + Vector2(-r, r * 0.35)]), filled)
		"triangle":
			_poly(ci, PackedVector2Array([center + Vector2(0, -r), center + Vector2(r, r * 0.8), center + Vector2(-r, r * 0.8)]), filled)
		"dome":
			var dome: Array[Vector2] = []
			for i: int in range(13):
				var a: float = PI + float(i) * PI / 12.0
				dome.append(center + Vector2(0, r * 0.5) + Vector2(cos(a), sin(a)) * r)
			_poly(ci, PackedVector2Array(dome), filled)
		"wave":
			# A smooth lozenge
			_poly(ci, PackedVector2Array([center + Vector2(0, -r), center + Vector2(r, 0), center + Vector2(0, r), center + Vector2(-r, 0)]), filled)
		"bumps":
			for dx: float in [-r * 0.62, 0.0, r * 0.62]:
				var c: Vector2 = center + Vector2(dx, 0.0 if dx == 0.0 else r * 0.25)
				if filled:
					ci.draw_circle(c, r * 0.42, INK)
				else:
					ci.draw_arc(c, r * 0.42, 0.0, TAU, 16, INK, w)
		"tall_bar":
			_poly(ci, PackedVector2Array([center + Vector2(-r * 0.3, -r), center + Vector2(r * 0.3, -r), center + Vector2(r * 0.3, r), center + Vector2(-r * 0.3, r)]), filled)
		"short_bar":
			_poly(ci, PackedVector2Array([center + Vector2(-r * 0.3, 0.0), center + Vector2(r * 0.3, 0.0), center + Vector2(r * 0.3, r), center + Vector2(-r * 0.3, r)]), filled)
		"big_eye", "small_eye":
			var er: float = r if shape == "big_eye" else r * 0.55
			if filled:
				ci.draw_circle(center, er, INK)
				ci.draw_circle(center, er * 0.35, Color.WHITE)
			else:
				ci.draw_arc(center, er - 1.0, 0.0, TAU, 20, INK, w)
				ci.draw_circle(center, er * 0.3, INK)
		_:
			ci.draw_circle(center, r, INK)


# === PRIVATE METHODS ===
static func _poly(ci: CanvasItem, points: PackedVector2Array, filled: bool) -> void:
	var packed: PackedVector2Array = points.duplicate()
	if filled:
		ci.draw_colored_polygon(packed, INK)
	else:
		packed.append(points[0])
		ci.draw_polyline(packed, INK, 2.0)


func _draw() -> void:
	var font: Font = get_theme_default_font()
	var bar: Rect2 = Rect2(Vector2((size.x - BAR_SIZE.x) * 0.5, 2.0), BAR_SIZE)
	var caption_y: float = bar.end.y + 17.0
	if chromosome == null:
		# Empty slot: dashed outline and its caption
		var dashed: Color = Color(0.4, 0.5, 0.5, 0.8)
		var corners: Array[Vector2] = [bar.position, Vector2(bar.end.x, bar.position.y), bar.end, Vector2(bar.position.x, bar.end.y), bar.position]
		for i: int in range(4):
			draw_dashed_line(corners[i], corners[i + 1], dashed, 2.0, 6.0)
		var empty_text: String = "Extra" if slot_type == 0 else "empty"
		draw_string(font, Vector2(bar.position.x, bar.get_center().y + 5.0), empty_text, HORIZONTAL_ALIGNMENT_CENTER, bar.size.x, 14, Color(0.4, 0.45, 0.45))
		draw_string(font, Vector2(0, caption_y), slot_caption, HORIZONTAL_ALIGNMENT_CENTER, size.x, 14, Color(0.3, 0.35, 0.35))
		_draw_focus(bar)
		return

	var body: StyleBoxFlat = StyleBoxFlat.new()
	body.bg_color = chromosome.type_color
	body.set_corner_radius_all(22)
	draw_style_box(body, bar)
	if _hovered:
		var glow: StyleBoxFlat = StyleBoxFlat.new()
		glow.bg_color = Color(1.0, 1.0, 1.0, 0.18)
		glow.set_corner_radius_all(22)
		draw_style_box(glow, bar)

	var band_w: float = bar.size.x - 10.0
	var top: float = bar.position.y + 16.0
	for i: int in range(chromosome.alleles.size()):
		var allele: Allele = chromosome.alleles[i]
		var band: Rect2 = Rect2(bar.position.x + 5.0, top + float(i) * (BAND_HEIGHT + 8.0), band_w, BAND_HEIGHT)
		draw_rect(band.grow(1.5), Color(0.1, 0.1, 0.1, 0.55))
		draw_rect(band, allele.color)
		if show_labels:
			draw_allele_shape(self, allele.shape, Vector2(band.position.x + 12.0, band.get_center().y), 8.0, allele.is_dominant)
			draw_string(font, Vector2(band.position.x + 23.0, band.get_center().y + 5.0),
					"%s %s" % [allele.get_symbol(), allele.value], HORIZONTAL_ALIGNMENT_LEFT, band.size.x - 25.0, 13, INK)
		else:
			draw_allele_shape(self, allele.shape, band.get_center(), 10.0, allele.is_dominant)

	draw_string(font, Vector2(0, caption_y), chromosome.id, HORIZONTAL_ALIGNMENT_CENTER, size.x, 15, Color(0.2, 0.25, 0.25))
	_draw_focus(bar)


func _draw_focus(bar: Rect2) -> void:
	if has_focus():
		var ring: StyleBoxFlat = StyleBoxFlat.new()
		ring.draw_center = false
		ring.border_color = FOCUS_COLOR
		ring.set_border_width_all(4)
		ring.set_corner_radius_all(24)
		draw_style_box(ring, bar.grow(4.0))


func _gui_input(event: InputEvent) -> void:
	var mouse: InputEventMouseButton = event as InputEventMouseButton
	if mouse != null and mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT:
		activated.emit(self)
		accept_event()
	elif event.is_action_pressed("ui_accept"):
		activated.emit(self)
		accept_event()


func _on_focus_changed() -> void:
	if has_focus():
		described.emit(self)
	queue_redraw()


func _on_mouse_entered() -> void:
	_hovered = true
	described.emit(self)
	queue_redraw()


func _on_mouse_exited() -> void:
	_hovered = false
	queue_redraw()
