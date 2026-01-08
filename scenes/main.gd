# main.gd
# Main game controller for Bio-Mite Architect
# Educational: Orchestrates the genetics puzzle game flow
extends Control

# === NODE REFERENCES ===
@onready var gene_bank: PanelContainer = $VBoxContainer/TopSection/GeneBank
@onready var reactor: PanelContainer = $VBoxContainer/MiddleSection/Reactor
@onready var results_panel: PanelContainer = $VBoxContainer/MiddleSection/ResultsPanel
@onready var info_popup: PopupPanel = $InfoPopup
@onready var level_label: Label = $VBoxContainer/HeaderBar/HBoxContainer/LevelLabel
@onready var goal_label: Label = $VBoxContainer/HeaderBar/HBoxContainer/GoalLabel
@onready var hint_button: Button = $VBoxContainer/HeaderBar/HBoxContainer/HintButton
@onready var hint_popup: PopupPanel = $HintPopup
@onready var hint_text: Label = $HintPopup/MarginContainer/VBoxContainer/HintText
@onready var hint_close: Button = $HintPopup/MarginContainer/VBoxContainer/CloseButton

# === LIFECYCLE ===

func _ready() -> void:
	_connect_signals()
	_start_game()
	print ("Main scene ready")


# === PRIVATE METHODS ===

func _connect_signals() -> void:
	# Gene bank signals
	gene_bank.chromosome_selected.connect(_on_chromosome_selected)
	gene_bank.chromosome_inspect_requested.connect(_on_chromosome_inspect)
	
	# Reactor signals
	reactor.fuse_requested.connect(_on_fuse_requested)
	reactor.impossible_reported.connect(_on_impossible_reported)
	
	# Results panel signals
	results_panel.continue_requested.connect(_on_continue_requested)
	
	# Level manager signals
	LevelManager.level_loaded.connect(_on_level_loaded)
	LevelManager.goal_achieved.connect(_on_goal_achieved)
	LevelManager.impossible_reported_correctly.connect(_on_impossible_correct)
	LevelManager.impossible_reported_incorrectly.connect(_on_impossible_incorrect)
	
	# Hint button
	hint_button.pressed.connect(_show_hint)
	hint_close.pressed.connect(func() -> void: hint_popup.hide())


func _start_game() -> void:
	LevelManager.load_level(1)


func _on_level_loaded(level_num: int) -> void:
	# Update header
	level_label.text = "Level %d: %s" % [level_num, LevelManager.get_level_name()]
	goal_label.text = "🎯 Goal: %s" % LevelManager.get_goal_text()
	
	# Load chromosomes into gene bank
	var library: Dictionary = LevelManager.get_chromosome_library()
	gene_bank.load_chromosomes(library)
	
	# Clear reactor and results
	reactor.clear_all()
	results_panel.clear()
	
	# Show/hide impossible button based on level
	reactor.set_impossible_button_visible(LevelManager.is_level_impossible() or level_num >= 4)


func _on_chromosome_selected(chromosome: Chromosome) -> void:
	var added: bool = reactor.add_chromosome(chromosome)
	if not added:
		# Could show feedback that slots are full
		pass


func _on_chromosome_inspect(chromosome: Chromosome) -> void:
	var mouse_pos: Vector2 = get_global_mouse_position()
	info_popup.show_chromosome_info(chromosome, mouse_pos)


func _on_fuse_requested() -> void:
	var karyotype: Dictionary = reactor.get_karyotype()
	
	# Validate karyotype
	var validation: GeneticCalculator.ValidationResult = GeneticCalculator.validate_karyotype(karyotype)
	
	if not validation.is_valid:
		# Show error
		results_panel.show_error(validation.error_message, validation.error_type)
		
		# Check for Level 3 trisomy experiment success
		if validation.error_type == "trisomy" and LevelManager.get_special_goal() == "trisomy_experiment":
			LevelManager.report_success({})
		return
	
	# Calculate phenotype
	var phenotype: Dictionary = GeneticCalculator.calculate_phenotype(karyotype)
	var genotype_info: Dictionary = GeneticCalculator.get_genotype_display(karyotype)
	
	# Check against goal
	var is_goal_match: bool = LevelManager.check_goal(phenotype)
	
	# Show results
	results_panel.set_has_next_level(LevelManager.has_next_level())
	results_panel.show_result(phenotype, genotype_info, is_goal_match)
	
	# Report success if matched
	if is_goal_match:
		LevelManager.report_success(phenotype)


func _on_impossible_reported() -> void:
	LevelManager.report_impossible()


func _on_goal_achieved() -> void:
	# Already handled in show_result
	pass


func _on_impossible_correct() -> void:
	var explanation: String = LevelManager.get_impossible_explanation()
	results_panel.show_impossible_correct(explanation)


func _on_impossible_incorrect() -> void:
	results_panel.show_impossible_incorrect()


func _on_continue_requested() -> void:
	if LevelManager.has_next_level():
		LevelManager.next_level()
	else:
		# Game complete!
		goal_label.text = "🏆 Congratulations! You've completed all levels!"


func _show_hint() -> void:
	hint_text.text = LevelManager.get_hint()
	
	# Center popup
	var screen_size: Vector2 = get_viewport_rect().size
	var popup_size: Vector2 = Vector2(400, 150)
	hint_popup.position = Vector2i(
		int((screen_size.x - popup_size.x) / 2),
		int((screen_size.y - popup_size.y) / 2)
	)
	hint_popup.popup()
