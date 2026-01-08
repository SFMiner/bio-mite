# results_panel.gd
# Displays the resulting Bio-Mite and its phenotype information
# Educational: Shows the connection between genotype (allele pairs) and phenotype (traits)
extends PanelContainer

# === SIGNALS ===
signal continue_requested()

# === NODE REFERENCES ===
@onready var bio_mite_display: BioMite = $VBoxContainer/ContentContainer/BioMiteHolder/BioMite
@onready var phenotype_label: RichTextLabel = $VBoxContainer/ContentContainer/InfoContainer/PhenotypeLabel
@onready var genotype_label: RichTextLabel = $VBoxContainer/ContentContainer/InfoContainer/GenotypeLabel
@onready var result_label: Label = $VBoxContainer/ResultLabel
@onready var continue_button: Button = $VBoxContainer/ContinueButton
@onready var content_container: HBoxContainer = $VBoxContainer/ContentContainer

# === STATE ===
var current_phenotype: Dictionary = {}

# === LIFECYCLE ===

func _ready() -> void:
	continue_button.pressed.connect(_on_continue_pressed)
	clear()
	print ("infpopup ready")



# === PUBLIC METHODS ===

## Show successful fusion result
func show_result(phenotype: Dictionary, genotype_info: Dictionary, is_goal_match: bool) -> void:
	current_phenotype = phenotype
	content_container.visible = true
	
	# Update Bio-Mite display
	bio_mite_display.set_phenotype(phenotype)
	
	# Build phenotype text
	var pheno_text: String = "[b]Phenotype (Visible Traits)[/b]\n"
	for trait_name: String in phenotype:
		pheno_text += "• %s: %s\n" % [trait_name, phenotype[trait_name]]
	phenotype_label.text = pheno_text
	
	# Build genotype text
	var geno_text: String = "[b]Genotype (Allele Pairs)[/b]\n"
	for trait_name: String in genotype_info:
		var info: Dictionary = genotype_info[trait_name]
		var homo_text: String = "(homozygous)" if info["is_homozygous"] else "(heterozygous)"
		geno_text += "• %s: %s %s\n" % [trait_name, info["pair_notation"], homo_text]
	genotype_label.text = geno_text
	
	# Update result message
	if is_goal_match:
		result_label.text = "🎉 SUCCESS! Your Bio-Mite matches the goal!"
		result_label.add_theme_color_override("font_color", Color(0.2, 0.7, 0.2))
		continue_button.visible = true
		continue_button.text = "Next Level →"
	else:
		result_label.text = "This Bio-Mite doesn't match the goal. Try again!"
		result_label.add_theme_color_override("font_color", Color(0.7, 0.4, 0.2))
		continue_button.visible = false


## Show genetic error (trisomy/monosomy)
func show_error(error_message: String, error_type: String) -> void:
	content_container.visible = true
	bio_mite_display.clear()
	phenotype_label.text = ""
	genotype_label.text = ""
	
	if error_type == "trisomy":
		result_label.text = "☠️ GENETIC ERROR!\n" + error_message
		
		# Special handling for Level 3 (trisomy experiment)
		if LevelManager.get_special_goal() == "trisomy_experiment":
			result_label.text += "\n\n🎓 You discovered: Organisms need exactly 2 copies of each chromosome!"
			result_label.add_theme_color_override("font_color", Color(0.2, 0.6, 0.2))
			continue_button.visible = true
			continue_button.text = "Next Level →"
		else:
			result_label.add_theme_color_override("font_color", Color(0.8, 0.2, 0.2))
			continue_button.visible = false
	else:
		result_label.text = "⚠️ Incomplete Karyotype\n" + error_message
		result_label.add_theme_color_override("font_color", Color(0.7, 0.5, 0.2))
		continue_button.visible = false


## Show "impossible reported correctly" feedback
func show_impossible_correct(explanation: String) -> void:
	content_container.visible = true
	bio_mite_display.clear()
	phenotype_label.text = ""
	genotype_label.text = "[b]Explanation[/b]\n" + explanation
	
	result_label.text = "🎓 CORRECT! You identified that this combination is IMPOSSIBLE!"
	result_label.add_theme_color_override("font_color", Color(0.2, 0.7, 0.2))
	continue_button.visible = true
	continue_button.text = "Congratulations! 🏆"


## Show "impossible reported incorrectly" feedback
func show_impossible_incorrect() -> void:
	content_container.visible = true
	bio_mite_display.clear()
	phenotype_label.text = ""
	genotype_label.text = ""
	
	result_label.text = "❌ Not quite! This combination IS possible.\nLook more carefully at the chromosomes."
	result_label.add_theme_color_override("font_color", Color(0.8, 0.4, 0.2))
	continue_button.visible = false


## Clear the panel
func clear() -> void:
	current_phenotype = {}
	bio_mite_display.clear()
	phenotype_label.text = ""
	genotype_label.text = ""
	result_label.text = ""
	continue_button.visible = false
	content_container.visible = false


## Check if there's a next level to show appropriate button
func set_has_next_level(has_next: bool) -> void:
	if has_next:
		continue_button.text = "Next Level →"
	else:
		continue_button.text = "Congratulations! 🏆"


# === SIGNAL CALLBACKS ===

func _on_continue_pressed() -> void:
	continue_requested.emit()
