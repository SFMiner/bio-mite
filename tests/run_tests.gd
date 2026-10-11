# Bio-Mite Architect checks: genetics, every level's solvability, text safety for web, and the screen
# (adding, fusing, the Extra slot, labels, panels, keyboard exit).
# ../../Godot_v4.5-stable_win64.exe --headless --path . --script res://tests/run_tests.gd
extends SceneTree

var _passed: int = 0
var _failed: int = 0


func _initialize() -> void:
	_test_notation()
	_test_validation()
	_test_levels_solvable()
	_test_text_is_web_safe()
	await _test_screen()
	print("Bio-Mite checks: %d passed, %d failed" % [_passed, _failed])
	quit(1 if _failed > 0 else 0)


func _check(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
	else:
		_failed += 1
		push_error("FAILED: " + label)


func _chr(chr_type: int, values: Array) -> Chromosome:
	var traits: Array[String] = GameConstants.get_traits_for_chromosome(chr_type)
	var alleles: Array = []
	for i: int in range(values.size()):
		alleles.append({"trait": traits[i], "value": values[i]})
	return Chromosome.from_dict(chr_type, {"id": "t", "alleles": alleles})


func _test_notation() -> void:
	_check(GameConstants.format_allele_pair("Body Shape", "Round", "Square") == "Rr", "Round/Square is Rr")
	_check(GameConstants.format_allele_pair("Body Shape", "Square", "Round") == "Rr", "dominant allele is written first")
	_check(GameConstants.format_allele_pair("Body Shape", "Square", "Square") == "rr", "Square/Square is rr")
	_check(GameConstants.format_allele_pair("Glow", "Neon", "Neon") == "NN", "Neon/Neon is NN")
	_check(GameConstants.format_allele_pair("Antennae", "Pointed", "Rounded") == "Pp", "Pointed/Rounded is Pp (not Pr)")
	_check(GameConstants.format_allele_pair("Legs", "Short", "Long") == "Ll", "Short/Long is Ll (not Ls)")
	var letters: Dictionary = {}
	for trait_name: String in GameConstants.TRAIT_DEFINITIONS:
		var def: Dictionary = GameConstants.TRAIT_DEFINITIONS[trait_name]
		letters[def["letter"]] = true
		_check(GameConstants.ALLELE_SHAPES.has(def["dominant"]) and GameConstants.ALLELE_SHAPES.has(def["recessive"]), "%s alleles have shapes" % trait_name)
		_check(GameConstants.get_allele_shape(def["dominant"]) != GameConstants.get_allele_shape(def["recessive"]), "%s alleles have different shapes" % trait_name)
	_check(letters.size() == GameConstants.TRAIT_DEFINITIONS.size(), "each trait has its own letter")
	var shapes: Dictionary = {}
	for value: String in GameConstants.ALLELE_SHAPES:
		shapes[GameConstants.ALLELE_SHAPES[value]] = true
	_check(shapes.size() == GameConstants.ALLELE_SHAPES.size(), "every allele has a different shape")


func _test_validation() -> void:
	var one: Chromosome = _chr(1, ["Round", "Neon"])
	var two: Chromosome = _chr(2, ["Pointed", "Smooth"])
	var three: Chromosome = _chr(3, ["Long", "Big"])
	var ok: GeneticCalculator.ValidationResult = GeneticCalculator.validate_karyotype({1: [one, one], 2: [two, two], 3: [three, three]})
	_check(ok.is_valid, "two of each is valid")
	var tri: GeneticCalculator.ValidationResult = GeneticCalculator.validate_karyotype({1: [one, one, one], 2: [two, two], 3: [three, three]})
	_check(not tri.is_valid and tri.error_type == "trisomy" and tri.chromosome_type == 1, "three copies is trisomy of chromosome 1")
	_check(tri.error_message.contains("Bio-Mite"), "the trisomy message is about Bio-Mites")
	var mono: GeneticCalculator.ValidationResult = GeneticCalculator.validate_karyotype({1: [one, one], 2: [two], 3: [three, three]})
	_check(not mono.is_valid and mono.error_type == "monosomy" and mono.chromosome_type == 2, "one copy is monosomy")
	var square: Chromosome = _chr(1, ["Square", "Dull"])
	var pheno: Dictionary = GeneticCalculator.calculate_phenotype({1: [one, square], 2: [two, two], 3: [three, three]})
	_check(pheno["Body Shape"] == "Round" and pheno["Glow"] == "Neon", "one dominant allele shows the dominant trait")
	pheno = GeneticCalculator.calculate_phenotype({1: [square, square], 2: [two, two], 3: [three, three]})
	_check(pheno["Body Shape"] == "Square" and pheno["Glow"] == "Dull", "two recessive alleles show the recessive trait")


## Every pair-filling from the level's library, two per type (copies are unlimited)
func _all_karyotypes(library: Dictionary) -> Array[Dictionary]:
	var pairs: Dictionary = {}
	for chr_type: int in GameConstants.CHROMOSOME_TYPES:
		var options: Array = []
		var list: Array = library[str(chr_type)]
		for i: int in range(list.size()):
			for j: int in range(i, list.size()):
				options.append([Chromosome.from_dict(chr_type, list[i]), Chromosome.from_dict(chr_type, list[j])])
		pairs[chr_type] = options
	var result: Array[Dictionary] = []
	for a: Array in pairs[1]:
		for b: Array in pairs[2]:
			for c: Array in pairs[3]:
				result.append({1: a, 2: b, 3: c})
	return result


func _test_levels_solvable() -> void:
	var levels: LevelManager = LevelManager.new()
	_check(levels.level_count() == 5, "five levels")
	for n: int in range(1, levels.level_count() + 1):
		_check(levels.load_level(n), "level %d loads" % n)
		var reachable: bool = false
		for karyotype: Dictionary in _all_karyotypes(levels.get_chromosome_library()):
			if levels.check_goal(GeneticCalculator.calculate_phenotype(karyotype)):
				reachable = true
				break
		if levels.get_special_goal() == "trisomy_experiment":
			_check(levels.has_extra_slot(), "level %d (trisomy) has the Extra slot" % n)
			_check(not reachable, "level %d has no phenotype goal to match" % n)
		elif levels.is_level_impossible():
			_check(not reachable, "level %d really is impossible" % n)
			_check(levels.offers_impossible(), "level %d offers It's impossible" % n)
			_check(levels.get_impossible_explanation().contains("crossing over"), "level %d explains crossing over" % n)
		else:
			_check(reachable, "level %d can be solved" % n)
	levels.load_level(4)
	_check(not levels.report_impossible() and not levels.is_level_completed(4), "saying level 4 is impossible is wrong")
	levels.load_level(5)
	_check(levels.report_impossible() and levels.is_level_completed(5), "saying level 5 is impossible is right")


## Web exports can't show emoji or most symbols: every text file must stay in plain Latin and punctuation
func _test_text_is_web_safe() -> void:
	var files: Array[String] = ["res://data/levels/level_definitions.json"]
	for dir: String in ["res://scripts", "res://scenes", "res://scenes/components", "res://data"]:
		for f: String in DirAccess.get_files_at(dir):
			if f.ends_with(".gd") or f.ends_with(".tscn"):
				files.append(dir + "/" + f)
	var bad: Array[String] = []
	for path: String in files:
		var text: String = FileAccess.get_file_as_string(path)
		for i: int in range(text.length()):
			var code: int = text.unicode_at(i)
			# Allow Latin-1 (middle dot) and general punctuation (dashes, quotes); nothing from symbols or emoji
			if code > 0x206F:
				bad.append("%s: U+%04X" % [path, code])
				break
	_check(bad.is_empty(), "no emoji or symbols in game text " + str(bad))
	_check(ChromosomeFacts.full_text().contains("Down syndrome") and ChromosomeFacts.full_text().contains("honeybee"),
			"Chromosome facts covers human trisomy and haploid insects")


func _key(code: Key, shift: bool = false) -> void:
	var press: InputEventKey = InputEventKey.new()
	press.keycode = code
	press.physical_keycode = code
	press.shift_pressed = shift
	press.pressed = true
	get_root().push_input(press)
	var release: InputEventKey = press.duplicate() as InputEventKey
	release.pressed = false
	get_root().push_input(release)
	await process_frame


func _bank(main: Node, id: String) -> Chromosome:
	for v: ChromosomeVisual in main.bank_visuals:
		if v.chromosome.id == id:
			return v.chromosome
	return null


func _test_screen() -> void:
	var main: Node = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	get_root().add_child(main)
	await process_frame
	await process_frame
	var nav: KeyboardNav = main.keyboard
	_check(main.levels.current_level == 1 and main.labels_visible, "starts on Level 1 with labels on")
	_check(main.fuse_button.disabled, "Fuse waits for chromosomes")

	# Level 1: fill, then a third chromosome 1 has nowhere to go
	for id: String in ["1A", "1B", "2A", "2B", "3A", "3B"]:
		_check(main.add_to_reactor(_bank(main, id)), "adds " + id)
	_check(not main.add_to_reactor(_bank(main, "1A")), "Level 1 has no Extra slot: a third chromosome 1 is refused")
	_check(not main.fuse_button.disabled, "Fuse is ready")
	main.fuse()
	_check(main.levels.is_level_completed(1) and main.next_button.visible, "Pointed antennae completes Level 1")
	_check(main.trait_grid.visible and main.trait_grid.get_child_count() == 21, "trait table shows 6 traits")

	# Taking one out by activating its slot
	var filled: ChromosomeVisual = main.slots[0]
	filled.activated.emit(filled)
	_check(filled.chromosome == null and main.get_karyotype()[1].size() == 1, "activating a filled slot takes it out")

	# Level 3: the Extra slot and the trisomy experiment
	main.load_level(3)
	_check(main.slots.size() == 7 and main.slots[6].slot_type == 0, "Level 3 adds the Extra slot")
	for id: String in ["1A", "1B", "2A", "2B", "3A", "3B"]:
		main.add_to_reactor(_bank(main, id))
	main.fuse()
	_check(not main.levels.is_level_completed(3) and main.bio_mite.phenotype.size() == 6, "two of everything develops but doesn't finish Level 3")
	_check(main.add_to_reactor(_bank(main, "1C")) and main.slots[6].chromosome != null, "a third chromosome goes in the Extra slot")
	main.fuse()
	_check(main.levels.is_level_completed(3) and main.bio_mite.failed, "the extra chromosome completes Level 3; the Bio-Mite doesn't develop")
	_check(main.result_note.text.contains("That rule is for Bio-Mites"), "the result says the rule is for Bio-Mites")

	# Level 4 and 5: It's impossible
	main.load_level(4)
	_check(main.impossible_button.visible, "Level 4 offers It's impossible")
	main.report_impossible()
	_check(not main.levels.is_level_completed(4), "Level 4 is possible")
	main.load_level(5)
	main.report_impossible()
	_check(main.levels.is_level_completed(5) and main.result_note.text.contains("crossing over"), "Level 5 is impossible and explains crossing over")
	main.next_level()
	_check(main.finished_all and main.next_button.visible, "after Level 5 the game says all levels are done")
	main.next_level()
	_check(main.levels.current_level == 1 and not main.finished_all, "Start again goes back to Level 1")

	# Labels: the L key
	await _key(KEY_L)
	_check(not main.labels_visible and not main.bank_visuals[0].show_labels and main.labels_button.text.contains("off"), "L hides the band labels")
	await _key(KEY_L)
	_check(main.labels_visible and main.bank_visuals[0].show_labels, "L shows them again")

	# Keyboard: Tab walks every control, then leaves
	main.clear_reactor()
	get_root().gui_release_focus()
	var expected: int = nav.controls().size()
	_check(expected == 5 + 3 + main.bank_visuals.size() + main.slots.size() + 2, "Tab order: levels, Hint, Facts, Labels, bank, slots, Fuse, Clear (%d)" % expected)
	var before: int = nav.leave_count
	var stops: int = 0
	for i: int in range(expected + 3):
		await _key(KEY_TAB)
		if get_root().gui_get_focus_owner() == null:
			break
		stops += 1
	_check(stops == expected and nav.leave_count == before + 1, "Tab reaches %d controls then leaves (got %d)" % [expected, stops])
	before = nav.leave_count
	var back: int = 0
	for i: int in range(expected + 3):
		await _key(KEY_TAB, true)
		if get_root().gui_get_focus_owner() == null:
			break
		back += 1
	_check(back == expected and nav.leave_count == before + 1, "Shift+Tab walks back then leaves (got %d)" % back)

	# Enter on a focused bank chromosome adds it
	var first: ChromosomeVisual = main.bank_visuals[0]
	first.grab_focus()
	await _key(KEY_ENTER)
	_check(main.get_karyotype()[1].size() == 1, "Enter on a Gene Bank chromosome adds it")
	before = nav.leave_count
	await _key(KEY_ESCAPE)
	_check(nav.leave_count == before + 1 and get_root().gui_get_focus_owner() == null, "Escape leaves the game")

	# Chromosome facts: Tab cycles inside, Escape closes it without leaving
	main.facts_button.grab_focus()
	main.show_facts()
	await process_frame
	_check(main.is_overlay_open() and get_root().gui_get_focus_owner() == main.overlay_close, "Chromosome facts opens with Close focused")
	before = nav.leave_count
	var inside: bool = true
	for i: int in range(10):
		await _key(KEY_TAB)
		var f: Control = get_root().gui_get_focus_owner()
		if f == null or not main.overlay.is_ancestor_of(f):
			inside = false
	_check(inside and nav.leave_count == before, "Tab stays inside the open panel")
	await _key(KEY_ESCAPE)
	_check(not main.is_overlay_open() and nav.leave_count == before, "Escape closes the panel without leaving")
	_check(get_root().gui_get_focus_owner() == main.facts_button, "focus returns to the Chromosome facts button")
	main.show_hint()
	_check(main.is_overlay_open() and main.overlay_title.text.begins_with("Hint"), "Hint opens a panel")
	main.close_overlay()

	main.queue_free()
	await process_frame
