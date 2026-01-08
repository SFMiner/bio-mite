# bio_mite.gd
# Visual rendering of a Bio-Mite based on its phenotype
# Educational: Shows how genotype translates to physical appearance (phenotype)
class_name BioMite
extends Control

# === PROPERTIES ===
var phenotype: Dictionary = {}

# Visual sizes
const BODY_SIZE: Vector2 = Vector2(120, 100)
const EYE_SIZE_BIG: float = 20.0
const EYE_SIZE_SMALL: float = 12.0
const LEG_LENGTH_LONG: float = 50.0
const LEG_LENGTH_SHORT: float = 25.0
const ANTENNA_LENGTH: float = 40.0

# === LIFECYCLE ===

func _ready() -> void:
	custom_minimum_size = Vector2(250, 250)
	print ("niomite ready")


func _draw() -> void:
	if phenotype.is_empty():
		_draw_placeholder()
		return
	
	var center: Vector2 = size / 2.0
	
	# Get phenotype values with defaults
	var body_shape: String = phenotype.get("Body Shape", "Round")
	var glow: String = phenotype.get("Glow", "Dull")
	var antennae: String = phenotype.get("Antennae", "Rounded")
	var texture: String = phenotype.get("Texture", "Smooth")
	var legs: String = phenotype.get("Legs", "Long")
	var eyes: String = phenotype.get("Eyes", "Big")
	
	# Draw glow effect if Neon
	if glow == "Neon":
		_draw_glow(center)
	
	# Draw legs first (behind body)
	_draw_legs(center, legs)
	
	# Draw antennae (behind body)
	_draw_antennae(center, antennae)
	
	# Draw body
	_draw_body(center, body_shape, texture)
	
	# Draw eyes (on top)
	_draw_eyes(center, eyes)


# === DRAWING METHODS ===

func _draw_placeholder() -> void:
	var center: Vector2 = size / 2.0
	draw_string(
		ThemeDB.fallback_font,
		center + Vector2(-60, 0),
		"Fuse chromosomes\nto create a Bio-Mite!",
		HORIZONTAL_ALIGNMENT_CENTER,
		200,
		16,
		Color(0.5, 0.5, 0.5)
	)


func _draw_glow(center: Vector2) -> void:
	# Draw pulsing glow effect
	var glow_color: Color = Color(0.4, 1.0, 0.4, 0.3)
	for i: int in range(3, 0, -1):
		var glow_size: float = 80.0 + i * 15.0
		var alpha: float = 0.15 / float(i)
		draw_circle(center, glow_size, Color(glow_color.r, glow_color.g, glow_color.b, alpha))


func _draw_body(center: Vector2, shape: String, texture: String) -> void:
	var body_color: Color = Color(0.5, 0.8, 0.8)  # Teal base
	
	if shape == "Round":
		# Elliptical body
		_draw_ellipse(center, BODY_SIZE.x / 2.0, BODY_SIZE.y / 2.0, body_color)
	else:
		# Square body with rounded corners
		var rect: Rect2 = Rect2(
			center - BODY_SIZE / 2.0,
			BODY_SIZE
		)
		draw_rect(rect, body_color, true)
		# Draw corner roundings
		draw_rect(rect, Color(0.3, 0.5, 0.5), false, 3.0)
	
	# Draw texture overlay
	if texture == "Bumpy":
		_draw_bumps(center)


func _draw_ellipse(center: Vector2, rx: float, ry: float, color: Color) -> void:
	var points: PackedVector2Array = PackedVector2Array()
	var segments: int = 32
	
	for i: int in range(segments + 1):
		var angle: float = TAU * i / segments
		points.append(center + Vector2(cos(angle) * rx, sin(angle) * ry))
	
	draw_colored_polygon(points, color)
	# Outline
	for i: int in range(points.size() - 1):
		draw_line(points[i], points[i + 1], Color(0.3, 0.5, 0.5), 3.0)


func _draw_bumps(center: Vector2) -> void:
	# Draw small circles for bumpy texture
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
	var eye_spacing: float = 25.0
	var eye_y_offset: float = -15.0
	
	var left_eye: Vector2 = center + Vector2(-eye_spacing, eye_y_offset)
	var right_eye: Vector2 = center + Vector2(eye_spacing, eye_y_offset)
	
	# Eye whites
	draw_circle(left_eye, eye_size, Color.WHITE)
	draw_circle(right_eye, eye_size, Color.WHITE)
	
	# Eye outlines
	draw_arc(left_eye, eye_size, 0, TAU, 32, Color(0.2, 0.2, 0.2), 2.0)
	draw_arc(right_eye, eye_size, 0, TAU, 32, Color(0.2, 0.2, 0.2), 2.0)
	
	# Pupils
	var pupil_size: float = eye_size * 0.5
	draw_circle(left_eye, pupil_size, Color(0.1, 0.1, 0.1))
	draw_circle(right_eye, pupil_size, Color(0.1, 0.1, 0.1))
	
	# Highlights
	var highlight_offset: Vector2 = Vector2(-eye_size * 0.2, -eye_size * 0.2)
	draw_circle(left_eye + highlight_offset, eye_size * 0.2, Color.WHITE)
	draw_circle(right_eye + highlight_offset, eye_size * 0.2, Color.WHITE)


func _draw_legs(center: Vector2, leg_type: String) -> void:
	var leg_length: float = LEG_LENGTH_LONG if leg_type == "Long" else LEG_LENGTH_SHORT
	var leg_color: Color = Color(0.4, 0.6, 0.6)
	var leg_width: float = 6.0
	
	# 6 legs total (3 on each side)
	var body_edge: float = BODY_SIZE.x / 2.0
	var y_positions: Array[float] = [-20.0, 0.0, 20.0]
	
	for y_off: float in y_positions:
		var start_y: float = center.y + y_off + 20.0
		
		# Left leg
		var left_start: Vector2 = Vector2(center.x - body_edge, start_y)
		var left_end: Vector2 = left_start + Vector2(-leg_length, leg_length * 0.5)
		draw_line(left_start, left_end, leg_color, leg_width)
		draw_circle(left_end, 4.0, leg_color)
		
		# Right leg
		var right_start: Vector2 = Vector2(center.x + body_edge, start_y)
		var right_end: Vector2 = right_start + Vector2(leg_length, leg_length * 0.5)
		draw_line(right_start, right_end, leg_color, leg_width)
		draw_circle(right_end, 4.0, leg_color)


func _draw_antennae(center: Vector2, antenna_type: String) -> void:
	var antenna_color: Color = Color(0.5, 0.7, 0.7)
	var base_y: float = center.y - BODY_SIZE.y / 2.0 - 5.0
	var antenna_width: float = 4.0
	
	# Left antenna
	var left_base: Vector2 = Vector2(center.x - 15.0, base_y)
	var left_tip: Vector2 = left_base + Vector2(-20.0, -ANTENNA_LENGTH)
	draw_line(left_base, left_tip, antenna_color, antenna_width)
	
	# Right antenna
	var right_base: Vector2 = Vector2(center.x + 15.0, base_y)
	var right_tip: Vector2 = right_base + Vector2(20.0, -ANTENNA_LENGTH)
	draw_line(right_base, right_tip, antenna_color, antenna_width)
	
	# Antenna tips
	if antenna_type == "Pointed":
		# Triangular tips
		var tip_size: float = 10.0
		_draw_triangle(left_tip, tip_size, -0.7, antenna_color)
		_draw_triangle(right_tip, tip_size, 0.7, antenna_color)
	else:
		# Rounded tips (circles)
		draw_circle(left_tip, 8.0, antenna_color)
		draw_circle(right_tip, 8.0, antenna_color)


func _draw_triangle(center: Vector2, size: float, rotation: float, color: Color) -> void:
	var points: PackedVector2Array = PackedVector2Array()
	for i: int in range(3):
		var angle: float = rotation + TAU * i / 3.0 - PI / 2.0
		points.append(center + Vector2(cos(angle), sin(angle)) * size)
	draw_colored_polygon(points, color)


# === PUBLIC METHODS ===

## Set the phenotype and redraw the Bio-Mite
func set_phenotype(new_phenotype: Dictionary) -> void:
	phenotype = new_phenotype
	queue_redraw()


## Clear the display
func clear() -> void:
	phenotype = {}
	queue_redraw()
