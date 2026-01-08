# info_popup.gd
# Popup panel showing chromosome details when right-clicked
# Educational: Students can inspect chromosomes to see linked alleles
extends PopupPanel

# === NODE REFERENCES ===
@onready var info_label: RichTextLabel = $MarginContainer/VBoxContainer/InfoLabel
@onready var close_button: Button = $MarginContainer/VBoxContainer/CloseButton

# === LIFECYCLE ===

func _ready() -> void:
	print ("infpopup ready")
	close_button.pressed.connect(hide)


# === PUBLIC METHODS ===

## Show info for a chromosome
func show_chromosome_info(chromosome: Chromosome, global_pos: Vector2) -> void:
	# Build info text
	var text: String = "[b]Chromosome %d (%s)[/b]\n\n" % [chromosome.type, chromosome.id]
	text += "[u]Linked Alleles:[/u]\n\n"
	
	for allele: Allele in chromosome.alleles:
		var dom_indicator: String = "[color=#4a4]●[/color]" if allele.is_dominant else "[color=#888]○[/color]"
		var dom_text: String = "[color=#4a4](dominant)[/color]" if allele.is_dominant else "[color=#888](recessive)[/color]"
		text += "%s [b]%s:[/b] %s %s\n" % [dom_indicator, allele.trait_name, allele.value, dom_text]
	
	text += "\n[i]These alleles are LINKED - they travel together![/i]"
	
	info_label.text = text
	
	# Position popup near click but on screen
	var popup_size: Vector2 = Vector2(300, 200)
	var screen_size: Vector2 = get_viewport().get_visible_rect().size
	
	var pos_x: float = clampf(global_pos.x, 0, screen_size.x - popup_size.x)
	var pos_y: float = clampf(global_pos.y, 0, screen_size.y - popup_size.y)
	
	position = Vector2i(int(pos_x), int(pos_y))
	popup()
