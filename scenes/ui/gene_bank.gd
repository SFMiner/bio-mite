# gene_bank.gd
# Horizontal scrolling library of available chromosomes
# Educational: Students browse here to find chromosomes with the alleles they need
extends PanelContainer

# === SIGNALS ===
signal chromosome_selected(chromosome: Chromosome)
signal chromosome_inspect_requested(chromosome: Chromosome)

# === NODE REFERENCES ===
@onready var scroll_container: ScrollContainer = $VBoxContainer/ScrollContainer
@onready var chromosome_container: HBoxContainer = $VBoxContainer/ScrollContainer/HBoxContainer
@onready var title_label: Label = $VBoxContainer/TitleBar/TitleLabel

# === CONSTANTS ===
const CHROMOSOME_VISUAL_SCENE: PackedScene = preload("res://scenes/components/chromosome_visual.tscn")

# === STATE ===
var chromosomes: Array[Chromosome] = []

# === LIFECYCLE ===

func _ready() -> void:
	title_label.text = "🧬 Gene Bank"
	print ("infpopup ready")



# === PUBLIC METHODS ===

## Populate the bank with chromosomes from level data
func load_chromosomes(library_data: Dictionary) -> void:
	_clear_chromosomes()
	
	# Process each chromosome type
	for chr_type_str: String in library_data:
		var chr_type: int = int(chr_type_str)
		var chr_array: Array = library_data[chr_type_str]
		
		# Add separator label for this chromosome type
		var separator: Label = Label.new()
		separator.text = "Chr %d" % chr_type
		separator.add_theme_font_size_override("font_size", 12)
		separator.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		separator.custom_minimum_size.x = 40
		chromosome_container.add_child(separator)
		
		# Add each chromosome variant
		for chr_data: Dictionary in chr_array:
			var chromosome: Chromosome = Chromosome.from_dict(chr_type, chr_data)
			chromosomes.append(chromosome)
			_add_chromosome_visual(chromosome)
		
		# Add spacer between types
		var spacer: Control = Control.new()
		spacer.custom_minimum_size.x = 20
		chromosome_container.add_child(spacer)


## Clear all chromosomes
func clear() -> void:
	_clear_chromosomes()


# === PRIVATE METHODS ===

func _clear_chromosomes() -> void:
	chromosomes.clear()
	for child: Node in chromosome_container.get_children():
		child.queue_free()


func _add_chromosome_visual(chromosome: Chromosome) -> void:
	var visual: ChromosomeVisual = CHROMOSOME_VISUAL_SCENE.instantiate()
	visual.set_chromosome(chromosome)
	visual.left_clicked.connect(_on_chromosome_left_clicked)
	visual.right_clicked.connect(_on_chromosome_right_clicked)
	chromosome_container.add_child(visual)


# === SIGNAL CALLBACKS ===

func _on_chromosome_left_clicked(chromosome: Chromosome) -> void:
	# Clone the chromosome and emit for reactor
	var clone: Chromosome = chromosome.duplicate_chromosome()
	chromosome_selected.emit(clone)


func _on_chromosome_right_clicked(chromosome: Chromosome) -> void:
	chromosome_inspect_requested.emit(chromosome)
