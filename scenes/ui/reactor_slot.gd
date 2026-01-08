# reactor_slot.gd
# Individual slot in the Reactor where chromosomes are placed
# Educational: Students assemble a complete karyotype by filling these slots
class_name ReactorSlot
extends PanelContainer

# === SIGNALS ===
signal chromosome_removed(chromosome: Chromosome)
signal slot_clicked()

# === EXPORTS ===
@export var chromosome_type: int = 1
@export var slot_index: String = "a"  # "a" or "b" within the pair

# === NODE REFERENCES ===
@onready var label: Label = $VBoxContainer/Label
@onready var chromosome_holder: CenterContainer = $VBoxContainer/ChromosomeHolder

# === CONSTANTS ===
const CHROMOSOME_VISUAL_SCENE: PackedScene = preload("res://scenes/components/chromosome_visual.tscn")

# === STATE ===
var chromosome: Chromosome = null
var chromosome_visual: ChromosomeVisual = null

# === LIFECYCLE ===

func _ready() -> void:
	_update_label()
	mouse_filter = Control.MOUSE_FILTER_STOP


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event
		if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT:
			if chromosome != null:
				# Remove chromosome from slot
				var removed: Chromosome = chromosome
				clear()
				chromosome_removed.emit(removed)
			else:
				slot_clicked.emit()
			accept_event()


# === PUBLIC METHODS ===

## Check if slot is empty
func is_empty() -> bool:
	return chromosome == null


## Place a chromosome in this slot
func set_chromosome(chr: Chromosome) -> bool:
	if chr.type != chromosome_type:
		push_warning("Cannot place chromosome type %d in slot for type %d" % [chr.type, chromosome_type])
		return false
	
	# Clear existing
	if chromosome_visual:
		chromosome_visual.queue_free()
		chromosome_visual = null
	
	chromosome = chr
	
	# Create visual
	chromosome_visual = CHROMOSOME_VISUAL_SCENE.instantiate()
	chromosome_visual.is_in_reactor = true
	chromosome_holder.add_child(chromosome_visual)
	chromosome_visual.set_chromosome(chromosome)
	chromosome_visual.left_clicked.connect(_on_chromosome_left_clicked)
	
	_update_appearance()
	return true


## Get the chromosome in this slot
func get_chromosome() -> Chromosome:
	return chromosome


## Clear the slot
func clear() -> void:
	if chromosome_visual:
		chromosome_visual.queue_free()
		chromosome_visual = null
	chromosome = null
	_update_appearance()


# === PRIVATE METHODS ===

func _update_label() -> void:
	label.text = "%d%s" % [chromosome_type, slot_index.to_upper()]


func _update_appearance() -> void:
	if chromosome != null:
		# Filled state - greenish tint
		modulate = Color(0.9, 1.0, 0.9)
	else:
		# Empty state
		modulate = Color.WHITE


func _on_chromosome_left_clicked(_clicked: Chromosome) -> void:
	if chromosome == null:
		return
	var removed: Chromosome = chromosome
	clear()
	chromosome_removed.emit(removed)
