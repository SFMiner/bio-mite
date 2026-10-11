# level_manager.gd
# Level data and progress for Bio-Mite Architect. Owned by the main view (not an autoload), so tests can
# create their own.
# Educational: Tracks student progress through increasingly complex genetics concepts
class_name LevelManager
extends RefCounted

# === CONSTANTS ===
const LEVELS_PATH: String = "res://data/levels/level_definitions.json"

# === STATE ===
var all_level_data: Dictionary = {}
var current_level: int = 1
var current_level_data: Dictionary = {}
var levels_completed: Array[int] = []


func _init() -> void:
	_load_level_data()


# === PUBLIC METHODS ===

func level_count() -> int:
	return (all_level_data.get("levels", {}) as Dictionary).size()


## Load a specific level; returns false for an unknown level
func load_level(level_num: int) -> bool:
	var levels: Dictionary = all_level_data.get("levels", {})
	var level_key: String = str(level_num)
	if not levels.has(level_key):
		push_error("Level data not found for level: %d" % level_num)
		return false
	current_level = level_num
	current_level_data = levels[level_key]
	return true


func get_level_name() -> String:
	return current_level_data.get("name", "Unknown Level")


func get_goal_text() -> String:
	return current_level_data.get("goal_text", "")


func get_hint() -> String:
	return current_level_data.get("hint", "")


func get_goal_phenotype() -> Dictionary:
	return current_level_data.get("goal_phenotype", {})


func is_level_impossible() -> bool:
	return current_level_data.get("is_impossible", false)


func get_impossible_explanation() -> String:
	return current_level_data.get("impossible_explanation", "")


## Special goals: "trisomy_experiment" (Level 3) is met by fusing a Bio-Mite with an extra chromosome
func get_special_goal() -> String:
	return current_level_data.get("special_goal", "")


## Whether the Reactor shows its Extra slot (a third copy of any chromosome)
func has_extra_slot() -> bool:
	return current_level_data.get("extra_slot", false)


## Whether the "It's impossible" button is offered
func offers_impossible() -> bool:
	return current_level_data.get("offer_impossible", false)


## Chromosome library: keys "1", "2", "3" mapping to arrays of chromosome data
func get_chromosome_library() -> Dictionary:
	return current_level_data.get("chromosome_library", {})


## Does a phenotype match the level goal?
## Educational: This is where we verify the student achieved the genetic target
func check_goal(phenotype: Dictionary) -> bool:
	var goal: Dictionary = get_goal_phenotype()
	if goal.is_empty():
		return false
	for trait_name: String in goal:
		if phenotype.get(trait_name, "") != goal[trait_name]:
			return false
	return true


## The student says the goal can't be built. Returns whether they are right; completes the level if so.
func report_impossible() -> bool:
	if is_level_impossible():
		complete_current_level()
		return true
	return false


func has_next_level() -> bool:
	return current_level < level_count()


func is_level_completed(level_num: int) -> bool:
	return level_num in levels_completed


func complete_current_level() -> void:
	if current_level not in levels_completed:
		levels_completed.append(current_level)


# === PRIVATE METHODS ===

func _load_level_data() -> void:
	var file: FileAccess = FileAccess.open(LEVELS_PATH, FileAccess.READ)
	if file == null:
		push_error("Failed to open level data file: " + LEVELS_PATH)
		return
	var json: JSON = JSON.new()
	if json.parse(file.get_as_text()) == OK:
		all_level_data = json.data
	else:
		push_error("Failed to parse level data: " + json.get_error_message())
