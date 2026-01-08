# chromosome_visual.gd
# Visual representation of a chromosome with colored allele bands
# Educational: Shows that genes are physically linked on chromosomes
class_name ChromosomeVisual
extends Control

# === SIGNALS ===
signal left_clicked(chromosome: Chromosome)
signal right_clicked(chromosome: Chromosome)

# === PROPERTIES ===
var chromosome: Chromosome = null
var is_in_reactor: bool = false

# Visual customization
@export var pill_width: float = 50.0
@export var pill_height: float = 150.0
@export var band_height: float = 28.0
@export var band_margin: float = 8.0
@export var corner_radius: float = 20.0

# === LIFECYCLE ===

func _ready() -> void:
	# Enable mouse 'input'
	print ("chromosome_visual ready")
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(pill_width + 10, pill_height + 10)


func _draw() -> void:
	if chromosome == null:
		return
	
	var center_x: float = size.x / 2.0
	var start_y: float = (size.y - pill_height) / 2.0
	
	# Draw chromosome body (pill shape using rounded rectangle)
	var body_rect: Rect2 = Rect2(
		center_x - pill_width / 2.0,
		start_y,
		pill_width,
		pill_height
	)
	
	# Get chromosome type color
	var body_color: Color = chromosome.type_color
	
	# Draw main body
	draw_rect(body_rect, body_color, true)
	
	# Draw rounded caps
	var cap_radius: float = pill_width / 2.0
	draw_circle(Vector2(center_x, start_y + cap_radius), cap_radius, body_color)
	draw_circle(Vector2(center_x, start_y + pill_height - cap_radius), cap_radius, body_color)
	
	# Draw allele bands
	var band_start_y: float = start_y + cap_radius + band_margin
	var band_width: float = pill_width - 10.0
	
	for i: int in range(chromosome.alleles.size()):
		var allele: Allele = chromosome.alleles[i]
		var band_y: float = band_start_y + i * (band_height + 6.0)
		
		var band_rect: Rect2 = Rect2(
			center_x - band_width / 2.0,
			band_y,
			band_width,
			band_height
		)
		
		# Draw band background (darker outline)
		var outline_rect: Rect2 = band_rect.grow(2)
		draw_rect(outline_rect, Color(0.2, 0.2, 0.2, 0.5), true)
		
		# Draw allele band with its color
		draw_rect(band_rect, allele.color, true)
		
		# Draw dominance indicator (filled circle for dominant, hollow for recessive)
		var indicator_pos: Vector2 = Vector2(
			center_x,
			band_y + band_height / 2.0
		)
		if allele.is_dominant:
			draw_circle(indicator_pos, 6.0, Color.WHITE)
			draw_circle(indicator_pos, 4.0, Color(0.2, 0.2, 0.2))
		else:
			draw_circle(indicator_pos, 6.0, Color(0.2, 0.2, 0.2))
			draw_circle(indicator_pos, 4.0, Color.WHITE)
	
	# Draw chromosome ID label
	var label_pos: Vector2 = Vector2(
		center_x,
		start_y + pill_height + 5
	)
	draw_string(
		ThemeDB.fallback_font,
		label_pos,
		chromosome.id,
		HORIZONTAL_ALIGNMENT_CENTER,
		-1,
		14,
		Color(0.3, 0.3, 0.3)
	)
	
	# Highlight if hovered
	if is_hovered():
		var highlight_rect: Rect2 = Rect2(
			center_x - pill_width / 2.0 - 3,
			start_y - 3,
			pill_width + 6,
			pill_height + 6
		)
		draw_rect(highlight_rect, Color(1.0, 0.9, 0.3, 0.3), true)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		var mouse_event: InputEventMouseButton = event
		if mouse_event.button_index == MOUSE_BUTTON_LEFT:
			left_clicked.emit(chromosome)
			accept_event()
		elif mouse_event.button_index == MOUSE_BUTTON_RIGHT:
			right_clicked.emit(chromosome)
			accept_event()


func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_ENTER or what == NOTIFICATION_MOUSE_EXIT:
		queue_redraw()


# === PUBLIC METHODS ===

## Set the chromosome data and redraw
func set_chromosome(chr: Chromosome) -> void:
	chromosome = chr
	queue_redraw()


## Check if mouse is hovering
func is_hovered() -> bool:
	var mouse_pos: Vector2 = get_local_mouse_position()
	return Rect2(Vector2.ZERO, size).has_point(mouse_pos)
