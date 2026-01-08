# level_manager.gd
# Manages level progression, goals, and chromosome library for each level
# Educational: Tracks student progress through increasingly complex genetics concepts
extends Node

# === SIGNALS ===
signal level_loaded(level_num: int)
signal level_completed(level_num: int)
signal goal_achieved()
signal impossible_reported_correctly()
signal impossible_reported_incorrectly()

# === CONSTANTS ===
const LEVELS_PATH: String = "res://data/levels/level_definitions.json"
const TOTAL_LEVELS: int = 5

# === STATE ===
var all_level_data: Dictionary = {}
var current_level: int = 1
var current_level_data: Dictionary = {}
var levels_completed: Array[int] = []

# === LIFECYCLE ===

func _ready() -> void:
	_load_level_data()


# === PUBLIC METHODS ===

## Load a specific level
func load_level(level_num: int) -> bool:
	if level_num < 1 or level_num > TOTAL_LEVELS:
		push_error("Invalid level number: %d" % level_num)
		return false
	
	var level_key: String = str(level_num)
	if not all_level_data.has("levels") or not all_level_data["levels"].has(level_key):
		push_error("Level data not found for level: %d" % level_num)
		return false
	
	current_level = level_num
	current_level_data = all_level_data["levels"][level_key]
	level_loaded.emit(level_num)
	return true


## Get the current level's name
func get_level_name() -> String:
	return current_level_data.get("name", "Unknown Level")


## Get the current level's goal text
func get_goal_text() -> String:
	return current_level_data.get("goal_text", "")


## Get the current level's hint
func get_hint() -> String:
	return current_level_data.get("hint", "")


## Get the target phenotype dictionary for current level
func get_goal_phenotype() -> Dictionary:
	return current_level_data.get("goal_phenotype", {})


## Check if current level is marked as impossible
func is_level_impossible() -> bool:
	return current_level_data.get("is_impossible", false)


## Get explanation for why level is impossible (for Level 5)
func get_impossible_explanation() -> String:
	return current_level_data.get("impossible_explanation", "")


## Check if level has special goal (like trisomy experiment)
func get_special_goal() -> String:
	return current_level_data.get("special_goal", "")


## Get chromosome library for current level
## Returns: Dictionary with keys "1", "2", "3" mapping to arrays of chromosome data
func get_chromosome_library() -> Dictionary:
	return current_level_data.get("chromosome_library", {})


## Check if a phenotype matches the level goal
## Educational: This is where we verify the student achieved the genetic target
func check_goal(phenotype: Dictionary) -> bool:
	var goal: Dictionary = get_goal_phenotype()
	
	# Empty goal means any valid organism passes (for trisomy level)
	if goal.is_empty():
		return true
	
	# Check each required trait
	for trait_name: String in goal:
		if not phenotype.has(trait_name):
			return false
		if phenotype[trait_name] != goal[trait_name]:
			return false
	
	return true


## Called when player reports the level as impossible
func report_impossible() -> void:
	if is_level_impossible():
		# Correct! The level truly is impossible
		impossible_reported_correctly.emit()
		_complete_current_level()
	else:
		# Incorrect - the level is actually solvable
		impossible_reported_incorrectly.emit()


## Called when player successfully creates matching organism
func report_success(phenotype: Dictionary) -> void:
	if check_goal(phenotype):
		goal_achieved.emit()
		_complete_current_level()


## Advance to next level
func next_level() -> bool:
	if current_level < TOTAL_LEVELS:
		return load_level(current_level + 1)
	return false


## Check if there's a next level available
func has_next_level() -> bool:
	return current_level < TOTAL_LEVELS


## Get completion status
func get_completed_levels() -> Array[int]:
	return levels_completed.duplicate()


## Check if a specific level is completed
func is_level_completed(level_num: int) -> bool:
	return level_num in levels_completed


# === PRIVATE METHODS ===

func _load_level_data() -> void:
	var file: FileAccess = FileAccess.open(LEVELS_PATH, FileAccess.READ)
	if file:
		var json_text: String = file.get_as_text()
		file.close()
		
		var json: JSON = JSON.new()
		var error: Error = json.parse(json_text)
		
		if error == OK:
			all_level_data = json.data
		else:
			push_error("Failed to parse level data: " + json.get_error_message())
	else:
		push_error("Failed to open level data file: " + LEVELS_PATH)


func _complete_current_level() -> void:
	if current_level not in levels_completed:
		levels_completed.append(current_level)
	level_completed.emit(current_level)
