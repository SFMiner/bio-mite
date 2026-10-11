# bio_mite.gd
# Visual rendering of a Bio-Mite based on its phenotype, laid out in a 250 x 250 design square and scaled
# to fit. After a fuse that couldn't develop it draws an undeveloped egg instead.
# Educational: Shows how genotype translates to physical appearance (phenotype)
class_name BioMite
extends Control

# === PROPERTIES ===
var phenotype: Dictionary = {}
## True after a fuse that couldn't develop (wrong chromosome number)
var failed: bool = false

# === CONSTANTS ===
const DESIGN: float = 250.0
const BODY_SIZE: Vector2 = Vector2(120, 100)
const EYE_SIZE_BIG: float = 20.0
const EYE_SIZE_SMALL: float = 12.0
const LEG_LENGTH_LONG: float = 50.0
const LEG_LENGTH_SHORT: float = 25.0
const ANTENNA_LENGTH: float = 40.0
const OUTLINE: Color = Color(0.3, 0.5, 0.5)

# === LIFECYCLE ===

func _ready() -> void:
	custom_minimum_size = Vector2(190, 190)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var k: float = minf(size.x, size.y) / DESIGN
	draw_set_transform((size - Vector2(DESIGN, DESIGN) * k) * 0.5, 0.0, Vector2(k, k))
	if failed:
		_draw_failed()
		return
	if phenotype.is_empty():
		_draw_placeholder()
		return

	var center: Vector2 = Vector2(DESIGN, DESIGN) / 2.0
	if phenotype.get("Glow", "Dull") == "Neon":
		_draw_glow(center)
	_draw_legs(center, phenotype.get("Legs", "Long"))
	_draw_antennae(center, phenotype.get("Antennae", "Rounded"))
	_draw_body(center, phenotype.get("Body Shape", "Round"), phenotype.get("Texture", "Smooth"))
	_draw_eyes(center, phenotype.get("Eyes", "Big"))


# === PUBLIC METHODS ===

## Set the phenotype and redraw the Bio-Mite
func set_phenotype(new_phenotype: Dictionary) -> void:
	phenotype = new_phenotype
	failed = false
	queue_redraw()


## Show an egg that couldn't develop
func set_failed() -> void:
	phenotype = {}
	failed = true
	queue_redraw()


func clear() -> void:
	phenotype = {}
	failed = false
	queue_redraw()


# === DRAWING METHODS ===

func _draw_placeholder() -> void:
	var font: Font = get_theme_default_font()
	draw_string(font, Vector2(0, 118), "Fuse chromosomes", HORIZONTAL_ALIGNMENT_CENTER, DESIGN, 18, Color(0.45, 0.5, 0.5))
	draw_string(font, Vector2(0, 142), "to make a Bio-Mite", HORIZONTAL_ALIGNMENT_CENTER, DESIGN, 18, Color(0.45, 0.5, 0.5))


## A grey egg with a crack
func _draw_failed() -> void:
	var c: Vector2 = Vector2(DESIGN, DESIGN) / 2.0 + Vector2(0, -10)
	_draw_ellipse(c, 55.0, 70.0, Color(0.78, 0.78, 0.75))
	var crack: PackedVector2Array = PackedVector2Array([c + Vector2(-30, -20), c + Vector2(-12, -6), c + Vector2(-20, 8), c + Vector2(0, 18), c + Vector2(-6, 32), c + Vector2(14, 44)])
	draw_polyline(crack, Color(0.35, 0.35, 0.35), 3.0)
	draw_string(get_theme_default_font(), Vector2(0, 240), "Didn't develop", HORIZONTAL_ALIGNMENT_CENTER, DESIGN, 18, Color(0.55, 0.3, 0.25))


func _draw_glow(center: Vector2) -> void:
	for i: int in range(3, 0, -1):
		var glow_size: float = 80.0 + i * 15.0
		draw_circle(center, glow_size, Color(0.4, 1.0, 0.4, 0.15 / float(i)))


func _draw_body(center: Vector2, shape: String, texture: String) -> void:
	var body_color: Color = Color(0.5, 0.8, 0.8)
	if shape == "Round":
		_draw_ellipse(center, BODY_SIZE.x / 2.0, BODY_SIZE.y / 2.0, body_color)
	else:
		var rect: Rect2 = Rect2(center - BODY_SIZE / 2.0, BODY_SIZE)
		draw_rect(rect, body_color, true)
		draw_rect(rect, OUTLINE, false, 3.0)
	if texture == "Bumpy":
		_draw_bumps(center)


func _draw_ellipse(center: Vector2, rx: float, ry: float, color: Color) -> void:
	var points: PackedVector2Array = PackedVector2Array()
	var segments: int = 32
	for i: int in range(segments + 1):
		var angle: float = TAU * i / segments
		points.append(center + Vector2(cos(angle) * rx, sin(angle) * ry))
	draw_colored_polygon(points, color)
	draw_polyline(points, OUTLINE, 3.0)


func _draw_bumps(center: Vector2) -> void:
	var bump_color: Color = Color(0.4, 0.7, 0.7)
	var positions: Array[Vector2] = [
		Vector2(-30, -20), Vector2(30, -20),
		Vector2(-20, 10), Vector2(20, 10),
		Vector2(0, -30), Vector2(0, 25),
		Vector2(-35, 5), Vector2(35, 5)
	]
	for pos: Vector2 in positions:
		draw_circle(center + pos, 8.0, bump_color)


func _draw_eyes(center: Vector2, eye_type: String) -> void:
	var eye_size: float = EYE_SIZE_BIG if eye_type == "Big" else EYE_SIZE_SMALL
	for side: float in [-25.0, 25.0]:
		var eye: Vector2 = center + Vector2(side, -15.0)
		draw_circle(eye, eye_size, Color.WHITE)
		draw_arc(eye, eye_size, 0, TAU, 32, Color(0.2, 0.2, 0.2), 2.0)
		draw_circle(eye, eye_size * 0.5, Color(0.1, 0.1, 0.1))
		draw_circle(eye + Vector2(-eye_size * 0.2, -eye_size * 0.2), eye_size * 0.2, Color.WHITE)


func _draw_legs(center: Vector2, leg_type: String) -> void:
	var leg_length: float = LEG_LENGTH_LONG if leg_type == "Long" else LEG_LENGTH_SHORT
	var leg_color: Color = Color(0.4, 0.6, 0.6)
	var body_edge: float = BODY_SIZE.x / 2.0
	# 6 legs total (3 on each side)
	for y_off: float in [-20.0, 0.0, 20.0]:
		var start_y: float = center.y + y_off + 20.0
		for side: float in [-1.0, 1.0]:
			var leg_start: Vector2 = Vector2(center.x + side * body_edge, start_y)
			var leg_end: Vector2 = leg_start + Vector2(side * leg_length, leg_length * 0.5)
			draw_line(leg_start, leg_end, leg_color, 6.0)
			draw_circle(leg_end, 4.0, leg_color)


func _draw_antennae(center: Vector2, antenna_type: String) -> void:
	var antenna_color: Color = Color(0.5, 0.7, 0.7)
	var base_y: float = center.y - BODY_SIZE.y / 2.0 - 5.0
	for side: float in [-1.0, 1.0]:
		var base: Vector2 = Vector2(center.x + side * 15.0, base_y)
		var tip: Vector2 = base + Vector2(side * 20.0, -ANTENNA_LENGTH)
		draw_line(base, tip, antenna_color, 4.0)
		if antenna_type == "Pointed":
			_draw_triangle(tip, 10.0, side * 0.7, antenna_color)
		else:
			draw_circle(tip, 8.0, antenna_color)


func _draw_triangle(center: Vector2, tri_size: float, tri_rotation: float, color: Color) -> void:
	var points: PackedVector2Array = PackedVector2Array()
	for i: int in range(3):
		var angle: float = tri_rotation + TAU * i / 3.0 - PI / 2.0
		points.append(center + Vector2(cos(angle), sin(angle)) * tri_size)
	draw_colored_polygon(points, color)
