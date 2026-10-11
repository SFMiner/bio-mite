# main.gd
# Bio-Mite Architect: the whole screen, built in code. Students pick chromosomes from the Gene Bank into the
# Reactor (two slots per pair, plus an Extra slot from Level 3), fuse them and compare the Bio-Mite with the
# level goal. Panels: Hint and Chromosome facts. Keys: Tab / Enter / Space, L shows or hides band labels,
# Escape closes a panel or leaves the game (sims.mr-miner.com keyboard exit).
# Educational: Orchestrates the genetics puzzle game flow
extends Control

# === CONSTANTS ===
const BASE_SIZE: Vector2 = Vector2(1280.0, 720.0)
## Smallest UI scale in CSS px per base px: text never drops below about 85% in a small frame
const MIN_UI_SCALE: float = 0.85
const BG: Color = Color(0.85, 0.88, 0.9)
const TEXT: Color = Color(0.2, 0.25, 0.25)
const GOOD: Color = Color(0.1, 0.5, 0.15)
const BAD: Color = Color(0.7, 0.25, 0.1)
const KEY_HELP: String = "Tab: move   ·   Enter or Space: choose   ·   L: show or hide band labels   ·   Esc: close a panel or leave"
const RULE_NOTE: String = "That rule is for Bio-Mites. Some living things on Earth have one copy of each chromosome, many copies, or one extra. Open Chromosome facts to learn more."

# === PUBLIC VARIABLES ===
var levels: LevelManager
var keyboard: KeyboardNav
var labels_visible: bool = true
var level_buttons: Array[Button] = []
var hint_button: Button
var facts_button: Button
var labels_button: Button
var level_label: Label
var goal_label: Label
var status_label: Label
var bank_visuals: Array[ChromosomeVisual] = []
var slots: Array[ChromosomeVisual] = []
var count_label: Label
var fuse_button: Button
var clear_button: Button
var impossible_button: Button
var next_button: Button
var bio_mite: BioMite
var result_label: Label
var result_note: Label
var trait_grid: GridContainer
var genotype_key: Label
var overlay: Control
var overlay_title: Label
var overlay_close: Button
var finished_all: bool = false

# === PRIVATE VARIABLES ===
var _bank_box: HFlowContainer
var _slots_box: HFlowContainer
var _overlay_panel: PanelContainer
var _overlay_scroll: ScrollContainer
var _overlay_content: VBoxContainer
var _overlay_controls: Array[Control] = []
var _focus_before_overlay: Control
var _applying_scale: bool = false
var _section_normal: StyleBoxFlat
var _section_focus: StyleBoxFlat
var _current_style: StyleBoxFlat
var _done_style: StyleBoxFlat


# === LIFECYCLE METHODS ===
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	levels = LevelManager.new()
	keyboard = KeyboardNav.new()
	keyboard.name = "KeyboardNav"
	keyboard.escape_handler = _on_escape
	add_child(keyboard)
	_make_styles()
	_build()
	get_tree().root.size_changed.connect(_apply_scale)
	_apply_scale()
	load_level(1)


func _unhandled_input(event: InputEvent) -> void:
	var key: InputEventKey = event as InputEventKey
	if key != null and key.pressed and not key.echo and key.keycode == KEY_L \
			and not key.ctrl_pressed and not key.alt_pressed and not key.meta_pressed:
		toggle_labels()
		get_viewport().set_input_as_handled()


# === PUBLIC METHODS ===
func load_level(level_num: int) -> void:
	if not levels.load_level(level_num):
		return
	finished_all = false
	level_label.text = "Level %d of %d: %s" % [level_num, levels.level_count(), levels.get_level_name()]
	goal_label.text = "Goal: " + levels.get_goal_text()
	_rebuild_bank()
	_rebuild_slots(levels.has_extra_slot())
	impossible_button.visible = levels.offers_impossible()
	_clear_result()
	_set_status("Point at a chromosome, or Tab to it, to read its alleles. Click it or press Enter to add it to the Reactor.")
	_refresh_level_buttons()
	_update_reactor()


## Adds a copy of a chromosome to the first free slot for its pair, or the Extra slot. Returns false when full.
func add_to_reactor(chr: Chromosome) -> bool:
	var target: ChromosomeVisual = null
	for slot: ChromosomeVisual in slots:
		if slot.slot_type == chr.type and slot.chromosome == null:
			target = slot
			break
	if target == null:
		for slot: ChromosomeVisual in slots:
			if slot.slot_type == 0 and slot.chromosome == null:
				target = slot
				break
	if target == null:
		_set_status("Both chromosome %d slots are full%s. Click a chromosome in the Reactor to take it out." % [
				chr.type, " and so is the Extra slot" if levels.has_extra_slot() else ""])
		return false
	target.set_chromosome(chr.duplicate_chromosome())
	_set_status("Added %s to the Reactor." % chr.id + (" It went in the Extra slot." if target.slot_type == 0 else ""))
	_update_reactor()
	return true


## Chromosomes in the Reactor by type: {1: [...], 2: [...], 3: [...]}
func get_karyotype() -> Dictionary:
	var karyotype: Dictionary = {}
	for chr_type: int in GameConstants.CHROMOSOME_TYPES:
		karyotype[chr_type] = []
	for slot: ChromosomeVisual in slots:
		if slot.chromosome != null:
			(karyotype[slot.chromosome.type] as Array).append(slot.chromosome)
	return karyotype


func clear_reactor() -> void:
	for slot: ChromosomeVisual in slots:
		slot.set_chromosome(null)
	_update_reactor()


func fuse() -> void:
	var karyotype: Dictionary = get_karyotype()
	var validation: GeneticCalculator.ValidationResult = GeneticCalculator.validate_karyotype(karyotype)
	_fill_traits({}, {})
	if not validation.is_valid:
		bio_mite.visible = true
		bio_mite.set_failed()
		if validation.error_type == "trisomy" and levels.get_special_goal() == "trisomy_experiment":
			levels.complete_current_level()
			_show_result("You found it! With 3 copies of chromosome %d, this Bio-Mite can't develop. Bio-Mites need exactly 2 copies of every chromosome." % validation.chromosome_type, GOOD)
			result_note.text = RULE_NOTE
			_show_next()
		else:
			_show_result(validation.error_message, BAD)
			result_note.text = RULE_NOTE
		_refresh_level_buttons()
		_rebuild_keyboard()
		return

	var phenotype: Dictionary = GeneticCalculator.calculate_phenotype(karyotype)
	bio_mite.visible = true
	bio_mite.set_phenotype(phenotype)
	_fill_traits(phenotype, GeneticCalculator.get_genotype_display(karyotype))
	if levels.get_special_goal() == "trisomy_experiment":
		_show_result("This Bio-Mite has 2 copies of everything, so it developed. Now add a third copy of any chromosome in the Extra slot and fuse again.", TEXT)
	elif levels.check_goal(phenotype):
		levels.complete_current_level()
		_show_result("Success! Your Bio-Mite matches the goal.", GOOD)
		_show_next()
	else:
		_show_result("This Bio-Mite doesn't match the goal yet. Compare its traits with the goal and try again.", BAD)
	_refresh_level_buttons()
	_rebuild_keyboard()


func report_impossible() -> void:
	_fill_traits({}, {})
	bio_mite.clear()
	bio_mite.visible = false
	if levels.report_impossible():
		_show_result("Right: these chromosomes can't make that Bio-Mite.", GOOD)
		result_note.text = levels.get_impossible_explanation()
		_show_next()
	else:
		_show_result("Not quite: this Bio-Mite can be built. Look again at what each chromosome carries.", BAD)
	_refresh_level_buttons()
	_rebuild_keyboard()


func next_level() -> void:
	if finished_all or not levels.has_next_level():
		if finished_all:
			load_level(1)
		else:
			finished_all = true
			_clear_result()
			bio_mite.visible = false
			_show_result("You finished all %d levels!" % levels.level_count(), GOOD)
			result_note.text = "You used dominant and recessive alleles, found what an extra chromosome does, and saw how linked genes travel together."
			next_button.text = "Start again at Level 1"
			next_button.visible = true
			_rebuild_keyboard()
		return
	load_level(levels.current_level + 1)


func toggle_labels() -> void:
	labels_visible = not labels_visible
	for v: ChromosomeVisual in bank_visuals + slots:
		v.set_labels(labels_visible)
	labels_button.text = "Labels: on (L)" if labels_visible else "Labels: off (L)"


func show_hint() -> void:
	_open_overlay("Hint: Level %d" % levels.current_level, [["", levels.get_hint()]])


func show_facts() -> void:
	_open_overlay(ChromosomeFacts.TITLE, ChromosomeFacts.SECTIONS)


func is_overlay_open() -> bool:
	return overlay.visible


func close_overlay() -> void:
	if not overlay.visible:
		return
	overlay.visible = false
	_rebuild_keyboard()
	if _focus_before_overlay != null and is_instance_valid(_focus_before_overlay) and _focus_before_overlay.is_visible_in_tree():
		_focus_before_overlay.grab_focus()


# === PRIVATE METHODS: results ===
func _show_result(text: String, color: Color) -> void:
	result_label.text = text
	result_label.add_theme_color_override("font_color", color)


func _show_next() -> void:
	next_button.text = "Next level" if levels.has_next_level() else "Finish"
	next_button.visible = true


func _clear_result() -> void:
	bio_mite.clear()
	bio_mite.visible = true
	_fill_traits({}, {})
	result_label.text = ""
	result_note.text = ""
	next_button.visible = false


## Trait table: trait, genotype (Rr) and what it looks like
func _fill_traits(phenotype: Dictionary, genotype: Dictionary) -> void:
	for child: Node in trait_grid.get_children():
		trait_grid.remove_child(child)
		child.queue_free()
	if phenotype.is_empty():
		trait_grid.visible = false
		genotype_key.visible = false
		return
	trait_grid.visible = true
	genotype_key.visible = true
	for head: String in ["Trait", "Genotype", "Looks like"]:
		var h: Label = _label(head, 14)
		h.add_theme_color_override("font_color", Color(0.4, 0.45, 0.45))
		trait_grid.add_child(h)
	for chr_type: int in GameConstants.CHROMOSOME_TYPES:
		for trait_name: String in GameConstants.get_traits_for_chromosome(chr_type):
			if not phenotype.has(trait_name):
				continue
			var info: Dictionary = genotype.get(trait_name, {})
			trait_grid.add_child(_label(trait_name, 15))
			trait_grid.add_child(_label(String(info.get("pair_notation", "")), 15))
			trait_grid.add_child(_label(String(phenotype[trait_name]), 15))


# === PRIVATE METHODS: bank and reactor ===
func _rebuild_bank() -> void:
	for child: Node in _bank_box.get_children():
		_bank_box.remove_child(child)
		child.queue_free()
	bank_visuals.clear()
	var library: Dictionary = levels.get_chromosome_library()
	for chr_type: int in GameConstants.CHROMOSOME_TYPES:
		var key: String = str(chr_type)
		if not library.has(key):
			continue
		var group: VBoxContainer = VBoxContainer.new()
		group.add_child(_label("Chromosome %d" % chr_type, 15))
		var row: HBoxContainer = HBoxContainer.new()
		row.add_theme_constant_override("separation", 4)
		group.add_child(row)
		for data: Dictionary in library[key]:
			var v: ChromosomeVisual = ChromosomeVisual.new()
			v.set_chromosome(Chromosome.from_dict(chr_type, data))
			v.show_labels = labels_visible
			v.activated.connect(_on_bank_activated)
			v.described.connect(_on_described)
			row.add_child(v)
			bank_visuals.append(v)
		_bank_box.add_child(group)


func _rebuild_slots(extra: bool) -> void:
	for child: Node in _slots_box.get_children():
		_slots_box.remove_child(child)
		child.queue_free()
	slots.clear()
	for chr_type: int in GameConstants.CHROMOSOME_TYPES:
		var group: VBoxContainer = VBoxContainer.new()
		var title: Label = _label("Pair %d" % chr_type, 15)
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		group.add_child(title)
		var row: HBoxContainer = HBoxContainer.new()
		row.add_theme_constant_override("separation", 2)
		group.add_child(row)
		for n: int in range(GameConstants.CHROMOSOMES_PER_TYPE):
			row.add_child(_make_slot(chr_type, "copy %d" % (n + 1)))
		_slots_box.add_child(group)
	if extra:
		var group: VBoxContainer = VBoxContainer.new()
		var title: Label = _label("Extra", 15)
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		group.add_child(title)
		group.add_child(_make_slot(0, "any type"))
		_slots_box.add_child(group)


func _make_slot(slot_type: int, caption: String) -> ChromosomeVisual:
	var v: ChromosomeVisual = ChromosomeVisual.new()
	v.slot_type = slot_type
	v.slot_caption = caption
	v.show_labels = labels_visible
	v.activated.connect(_on_slot_activated)
	v.described.connect(_on_described)
	slots.append(v)
	return v


func _update_reactor() -> void:
	var karyotype: Dictionary = get_karyotype()
	var parts: Array[String] = []
	var can_fuse: bool = true
	for chr_type: int in GameConstants.CHROMOSOME_TYPES:
		var count: int = (karyotype[chr_type] as Array).size()
		parts.append("Chromosome %d: %d" % [chr_type, count])
		if count == 0:
			can_fuse = false
	count_label.text = "Copies   " + "   ".join(parts)
	fuse_button.disabled = not can_fuse
	fuse_button.tooltip_text = "" if can_fuse else "Add at least one copy of each chromosome first"
	for slot: ChromosomeVisual in slots:
		slot.queue_redraw()
	_rebuild_keyboard()


func _set_status(text: String) -> void:
	status_label.text = text


func _refresh_level_buttons() -> void:
	for i: int in range(level_buttons.size()):
		var b: Button = level_buttons[i]
		var n: int = i + 1
		if n == levels.current_level:
			b.add_theme_stylebox_override("normal", _current_style)
		elif levels.is_level_completed(n):
			b.add_theme_stylebox_override("normal", _done_style)
		else:
			b.remove_theme_stylebox_override("normal")
		var state: String = " (current)" if n == levels.current_level else (" (done)" if levels.is_level_completed(n) else "")
		b.tooltip_text = "Level %d%s" % [n, state]


# === PRIVATE METHODS: keyboard ===
## Tab order: level buttons, Hint, Facts, Labels, Gene Bank, Reactor slots, Reactor buttons, Next level.
func _rebuild_keyboard() -> void:
	if overlay != null and overlay.visible:
		return
	var order: Array[Control] = []
	for b: Button in level_buttons:
		order.append(b)
	order.append_array([hint_button, facts_button, labels_button])
	for v: ChromosomeVisual in bank_visuals:
		order.append(v)
	for v: ChromosomeVisual in slots:
		order.append(v)
	for b: Button in [fuse_button, clear_button, impossible_button, next_button]:
		if b.visible:
			order.append(b)
	keyboard.setup(order)


func _on_escape() -> bool:
	if overlay.visible:
		close_overlay()
		return true
	return false


# === PRIVATE METHODS: overlay (Hint, Chromosome facts) ===
func _open_overlay(title: String, sections: Array) -> void:
	_focus_before_overlay = get_viewport().gui_get_focus_owner()
	overlay_title.text = title
	for child: Node in _overlay_content.get_children():
		_overlay_content.remove_child(child)
		child.queue_free()
	_overlay_controls.clear()
	for section: Array in sections:
		var box: PanelContainer = PanelContainer.new()
		box.add_theme_stylebox_override("panel", _section_normal)
		box.focus_mode = Control.FOCUS_ALL
		box.focus_entered.connect(func() -> void: box.add_theme_stylebox_override("panel", _section_focus))
		box.focus_exited.connect(func() -> void: box.add_theme_stylebox_override("panel", _section_normal))
		var inner: VBoxContainer = VBoxContainer.new()
		box.add_child(inner)
		if not String(section[0]).is_empty():
			var heading: Label = _label(String(section[0]), 18)
			heading.add_theme_color_override("font_color", Color(0.15, 0.4, 0.4))
			inner.add_child(heading)
		var body: Label = _label(String(section[1]), 16)
		body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		body.custom_minimum_size = Vector2(200, 0)
		inner.add_child(body)
		_overlay_content.add_child(box)
		_overlay_controls.append(box)
	_overlay_controls.append(overlay_close)
	_size_overlay()
	overlay.visible = true
	_overlay_scroll.scroll_vertical = 0
	keyboard.setup(_overlay_controls, true)
	overlay_close.grab_focus()


func _size_overlay() -> void:
	var view: Vector2 = get_viewport_rect().size
	_overlay_panel.custom_minimum_size = Vector2(minf(720.0, view.x - 24.0), 0.0)
	_overlay_scroll.custom_minimum_size = Vector2(0.0, maxf(160.0, minf(480.0, view.y - 150.0)))


# === PRIVATE METHODS: building ===
func _make_styles() -> void:
	_section_normal = StyleBoxFlat.new()
	_section_normal.bg_color = Color(1, 1, 1, 0.0)
	_section_normal.set_content_margin_all(8)
	_section_normal.set_border_width_all(3)
	_section_normal.border_color = Color(1, 1, 1, 0.0)
	_section_normal.set_corner_radius_all(6)
	_section_focus = _section_normal.duplicate() as StyleBoxFlat
	_section_focus.border_color = KeyboardNav.FOCUS_COLOR
	_current_style = StyleBoxFlat.new()
	_current_style.bg_color = Color(0.85, 0.5, 0.1)
	_current_style.set_corner_radius_all(6)
	_current_style.set_border_width_all(2)
	_current_style.border_color = Color(0.6, 0.33, 0.05)
	_done_style = _current_style.duplicate() as StyleBoxFlat
	_done_style.bg_color = Color(0.3, 0.6, 0.35)
	_done_style.border_color = Color(0.2, 0.42, 0.25)


func _label(text: String, font_size: int = 16) -> Label:
	var l: Label = Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	return l


## Lets a label wrap so it never forces the page wider than a phone
func _wrap(l: Label) -> Label:
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(120, 0)
	return l


func _button(text: String, handler: Callable) -> Button:
	var b: Button = Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 40)
	b.add_theme_font_size_override("font_size", 16)
	b.pressed.connect(handler)
	return b


func _panel() -> VBoxContainer:
	var panel: PanelContainer = PanelContainer.new()
	var margin: MarginContainer = MarginContainer.new()
	for edge: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + edge, 8)
	panel.add_child(margin)
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	margin.add_child(box)
	return box


func _panel_of(box: VBoxContainer) -> PanelContainer:
	return box.get_parent().get_parent() as PanelContainer


func _build() -> void:
	var bg: ColorRect = ColorRect.new()
	bg.color = BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	add_child(scroll)
	var margin: MarginContainer = MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for edge: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + edge, 10)
	scroll.add_child(margin)
	var page: VBoxContainer = VBoxContainer.new()
	page.add_theme_constant_override("separation", 8)
	margin.add_child(page)

	# Header: title, levels, Hint, Chromosome facts, labels
	var header: HFlowContainer = HFlowContainer.new()
	header.add_theme_constant_override("h_separation", 8)
	header.add_theme_constant_override("v_separation", 6)
	page.add_child(header)
	var title: Label = _label("Bio-Mite Architect", 26)
	title.add_theme_color_override("font_color", Color(0.15, 0.38, 0.38))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var levels_box: HBoxContainer = HBoxContainer.new()
	levels_box.add_child(_label("Level", 16))
	for i: int in range(levels.level_count()):
		var n: int = i + 1
		var b: Button = _button(str(n), func() -> void: load_level(n))
		b.custom_minimum_size = Vector2(40, 40)
		levels_box.add_child(b)
		level_buttons.append(b)
	header.add_child(levels_box)
	hint_button = _button("Hint", show_hint)
	header.add_child(hint_button)
	facts_button = _button("Chromosome facts", show_facts)
	header.add_child(facts_button)
	labels_button = _button("Labels: on (L)", toggle_labels)
	labels_button.tooltip_text = "Show or hide the words on the chromosome bands (key: L)"
	header.add_child(labels_button)

	# Level and goal
	var goal_box: VBoxContainer = _panel()
	page.add_child(_panel_of(goal_box))
	level_label = _wrap(_label("", 18))
	goal_box.add_child(level_label)
	goal_label = _label("", 18)
	goal_label.add_theme_color_override("font_color", GOOD)
	goal_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	goal_box.add_child(goal_label)

	# Two columns: Gene Bank and Reactor on the left, Results on the right (they wrap in a narrow frame)
	var columns: HFlowContainer = HFlowContainer.new()
	columns.add_theme_constant_override("h_separation", 8)
	columns.add_theme_constant_override("v_separation", 8)
	page.add_child(columns)
	var left: VBoxContainer = VBoxContainer.new()
	left.add_theme_constant_override("separation", 8)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.custom_minimum_size = Vector2(330, 0)
	columns.add_child(left)

	# Gene Bank
	var bank: VBoxContainer = _panel()
	left.add_child(_panel_of(bank))
	bank.add_child(_wrap(_label("Gene Bank: click a chromosome (or press Enter) to add a copy to the Reactor", 16)))
	_bank_box = HFlowContainer.new()
	_bank_box.add_theme_constant_override("h_separation", 28)
	_bank_box.add_theme_constant_override("v_separation", 8)
	bank.add_child(_bank_box)
	status_label = _label("", 15)
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.add_theme_color_override("font_color", Color(0.25, 0.3, 0.45))
	bank.add_child(status_label)

	var reactor: VBoxContainer = _panel()
	left.add_child(_panel_of(reactor))
	reactor.add_child(_wrap(_label("Reactor: build a Bio-Mite here (click a chromosome to take it out)", 16)))
	_slots_box = HFlowContainer.new()
	_slots_box.add_theme_constant_override("h_separation", 16)
	reactor.add_child(_slots_box)
	count_label = _wrap(_label("", 15))
	reactor.add_child(count_label)
	var buttons: HFlowContainer = HFlowContainer.new()
	buttons.add_theme_constant_override("h_separation", 8)
	buttons.add_theme_constant_override("v_separation", 6)
	reactor.add_child(buttons)
	fuse_button = _button("Fuse", fuse)
	fuse_button.custom_minimum_size = Vector2(110, 40)
	buttons.add_child(fuse_button)
	clear_button = _button("Clear all", clear_reactor)
	buttons.add_child(clear_button)
	impossible_button = _button("It's impossible", report_impossible)
	impossible_button.tooltip_text = "Press this if you think no set of these chromosomes can make the goal"
	buttons.add_child(impossible_button)

	var results: VBoxContainer = _panel()
	var results_panel: PanelContainer = _panel_of(results)
	results_panel.custom_minimum_size = Vector2(350, 0)
	columns.add_child(results_panel)
	results.add_child(_label("Results", 16))
	bio_mite = BioMite.new()
	bio_mite.custom_minimum_size = Vector2(150, 150)
	results.add_child(bio_mite)
	trait_grid = GridContainer.new()
	trait_grid.columns = 3
	trait_grid.add_theme_constant_override("h_separation", 16)
	trait_grid.add_theme_constant_override("v_separation", 0)
	results.add_child(trait_grid)
	genotype_key = _label("Same letters (RR, rr): homozygous.  Different letters (Rr): heterozygous.", 13)
	genotype_key.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	genotype_key.custom_minimum_size = Vector2(300, 0)
	genotype_key.add_theme_color_override("font_color", Color(0.4, 0.45, 0.45))
	results.add_child(genotype_key)
	result_label = _label("", 17)
	result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result_label.custom_minimum_size = Vector2(300, 0)
	results.add_child(result_label)
	result_note = _label("", 15)
	result_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result_note.custom_minimum_size = Vector2(300, 0)
	results.add_child(result_note)
	next_button = _button("Next level", next_level)
	next_button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	results.add_child(next_button)

	var help: Label = _label(KEY_HELP, 14)
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	help.add_theme_color_override("font_color", Color(0.35, 0.4, 0.4))
	page.add_child(help)

	_build_overlay()


func _build_overlay() -> void:
	overlay = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.visible = false
	add_child(overlay)
	var dim: ColorRect = ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.0, 0.45)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(dim)
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	var box: VBoxContainer = _panel()
	_overlay_panel = _panel_of(box)
	center.add_child(_overlay_panel)
	overlay_title = _label("", 22)
	overlay_title.add_theme_color_override("font_color", Color(0.15, 0.38, 0.38))
	box.add_child(overlay_title)
	_overlay_scroll = ScrollContainer.new()
	_overlay_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_overlay_scroll.follow_focus = true
	box.add_child(_overlay_scroll)
	_overlay_content = VBoxContainer.new()
	_overlay_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_overlay_scroll.add_child(_overlay_content)
	overlay_close = _button("Close (Esc)", close_overlay)
	overlay_close.size_flags_horizontal = Control.SIZE_SHRINK_END
	box.add_child(overlay_close)


## Keeps text readable in a small frame (an iframe 360 px tall, a phone): the base view grows instead of
## shrinking below MIN_UI_SCALE, the panels wrap (HFlowContainer) and the page scrolls.
func _apply_scale() -> void:
	if _applying_scale:
		return
	_applying_scale = true
	var win: Window = get_window()
	var window_size: Vector2 = Vector2(win.size)
	if window_size.x >= 1.0 and window_size.y >= 1.0:
		var fit: float = minf(window_size.x / BASE_SIZE.x, window_size.y / BASE_SIZE.y)
		var s: float = maxf(fit, MIN_UI_SCALE * DisplayServer.screen_get_scale())
		win.content_scale_size = Vector2i((window_size / s).floor())
	if overlay != null and overlay.visible:
		_size_overlay()
	_applying_scale = false


# === SIGNAL CALLBACKS ===
func _on_bank_activated(v: ChromosomeVisual) -> void:
	if v.chromosome != null:
		add_to_reactor(v.chromosome)


func _on_slot_activated(v: ChromosomeVisual) -> void:
	if v.chromosome == null:
		_set_status(v.description())
		return
	var id: String = v.chromosome.id
	v.set_chromosome(null)
	_set_status("Took %s out of the Reactor." % id)
	_update_reactor()


func _on_described(v: ChromosomeVisual) -> void:
	_set_status(v.description())
