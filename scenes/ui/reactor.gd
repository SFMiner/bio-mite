# reactor.gd
# The assembly area where students build their organism's karyotype
# Educational: Students must fill all 6 slots (2 of each type) to create a diploid organism
extends PanelContainer

# === SIGNALS ===
signal karyotype_changed(karyotype: Dictionary)
signal fuse_requested()
signal impossible_reported()

# === NODE REFERENCES ===
@onready var slots_container: HBoxContainer = $VBoxContainer/SlotsContainer
@onready var fuse_button: Button = $VBoxContainer/ButtonContainer/FuseButton
@onready var clear_button: Button = $VBoxContainer/ButtonContainer/ClearButton
@onready var impossible_button: Button = $VBoxContainer/ButtonContainer/ImpossibleButton
@onready var status_label: Label = $VBoxContainer/StatusLabel

# === CONSTANTS ===
const REACTOR_SLOT_SCENE: PackedScene = preload("res://scenes/ui/reactor_slot.tscn")

# === STATE ===
var slots: Array[ReactorSlot] = []

# === LIFECYCLE ===

func _ready() -> void:
	_create_slots()
	_connect_buttons()
	_update_status()
	print ("reactor ready")



# === PUBLIC METHODS ===

## Try to add a chromosome to the first available slot of its type
func add_chromosome(chromosome: Chromosome) -> bool:
	# Find first empty slot of matching type
	for slot: ReactorSlot in slots:
		if slot.chromosome_type == chromosome.type and slot.is_empty():
			var success: bool = slot.set_chromosome(chromosome)
			if success:
				_update_status()
				karyotype_changed.emit(get_karyotype())
				return true
	
	# No empty slot found for this type
	return false


## Get the current karyotype (dictionary of chromosome arrays by type)
func get_karyotype() -> Dictionary:
	var karyotype: Dictionary = {}
	
	for chr_type: int in GameConstants.CHROMOSOME_TYPES:
		karyotype[chr_type] = []
	
	for slot: ReactorSlot in slots:
		if not slot.is_empty():
			var chr: Chromosome = slot.get_chromosome()
			karyotype[chr.type].append(chr)
	
	return karyotype


## Check if the karyotype is complete (exactly 2 of each type)
func is_complete() -> bool:
	var karyotype: Dictionary = get_karyotype()
	for chr_type: int in GameConstants.CHROMOSOME_TYPES:
		if karyotype[chr_type].size() != GameConstants.CHROMOSOMES_PER_TYPE:
			return false
	return true


## Clear all slots
func clear_all() -> void:
	for slot: ReactorSlot in slots:
		slot.clear()
	_update_status()
	karyotype_changed.emit(get_karyotype())


## Show or hide the "Report Impossible" button
func set_impossible_button_visible(visible: bool) -> void:
	impossible_button.visible = visible


# === PRIVATE METHODS ===

func _create_slots() -> void:
	# Create 6 slots: 2 for each chromosome type (1a, 1b, 2a, 2b, 3a, 3b)
	for chr_type: int in GameConstants.CHROMOSOME_TYPES:
		# Add pair container
		var pair_container: VBoxContainer = VBoxContainer.new()
		pair_container.alignment = BoxContainer.ALIGNMENT_CENTER
		
		# Pair label
		var pair_label: Label = Label.new()
		pair_label.text = "Pair %d" % chr_type
		pair_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		pair_label.add_theme_font_size_override("font_size", 14)
		pair_container.add_child(pair_label)
		
		# Slots in horizontal arrangement
		var slot_pair: HBoxContainer = HBoxContainer.new()
		slot_pair.alignment = BoxContainer.ALIGNMENT_CENTER
		slot_pair.add_theme_constant_override("separation", 10)
		
		for slot_letter: String in ["a", "b"]:
			var slot: ReactorSlot = REACTOR_SLOT_SCENE.instantiate()
			slot.chromosome_type = chr_type
			slot.slot_index = slot_letter
			slot.chromosome_removed.connect(_on_chromosome_removed)
			slot_pair.add_child(slot)
			slots.append(slot)
		
		pair_container.add_child(slot_pair)
		slots_container.add_child(pair_container)
		
		# Add spacer between pairs (except after last)
		if chr_type < GameConstants.CHROMOSOME_TYPES.size():
			var spacer: Control = Control.new()
			spacer.custom_minimum_size.x = 30
			slots_container.add_child(spacer)


func _connect_buttons() -> void:
	fuse_button.pressed.connect(_on_fuse_pressed)
	clear_button.pressed.connect(_on_clear_pressed)
	impossible_button.pressed.connect(_on_impossible_pressed)


func _update_status() -> void:
	var karyotype: Dictionary = get_karyotype()
	var status_parts: Array[String] = []
	
	for chr_type: int in GameConstants.CHROMOSOME_TYPES:
		var count: int = karyotype[chr_type].size()
		var needed: int = GameConstants.CHROMOSOMES_PER_TYPE
		var status: String = "✓" if count == needed else "%d/%d" % [count, needed]
		status_parts.append("Chr%d: %s" % [chr_type, status])
	
	status_label.text = " | ".join(status_parts)
	
	# Enable fuse button only if we have at least one chromosome per type
	var can_fuse: bool = true
	for chr_type: int in GameConstants.CHROMOSOME_TYPES:
		if karyotype[chr_type].size() == 0:
			can_fuse = false
			break
	
	fuse_button.disabled = not can_fuse


# === SIGNAL CALLBACKS ===

func _on_chromosome_removed(chromosome: Chromosome) -> void:
	_update_status()
	karyotype_changed.emit(get_karyotype())


func _on_fuse_pressed() -> void:
	fuse_requested.emit()


func _on_clear_pressed() -> void:
	clear_all()


func _on_impossible_pressed() -> void:
	impossible_reported.emit()
