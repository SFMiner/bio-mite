# allele.gd
# Resource class representing a single allele (variant of a gene)
# Educational: An allele is one version of a gene at a specific locus
class_name Allele
extends Resource

# === PROPERTIES ===

## The name of the trait this allele affects (e.g., "Body Shape")
@export var trait_name: String = ""

## The specific value/variant (e.g., "Round" or "Square")
@export var value: String = ""


# === COMPUTED PROPERTIES ===

## Whether this allele is the dominant variant for its trait
var is_dominant: bool:
	get:
		return GameConstants.is_dominant(trait_name, value)


## The display color for this allele's band on a chromosome
var color: Color:
	get:
		return GameConstants.get_allele_color(value)


# === METHODS ===

## Create an Allele from dictionary data (from JSON)
static func from_dict(data: Dictionary) -> Allele:
	var allele: Allele = Allele.new()
	allele.trait_name = data.get("trait", "")
	allele.value = data.get("value", "")
	return allele


## Get shorthand notation (uppercase if dominant, lowercase if recessive)
func get_symbol() -> String:
	var first_letter: String = value[0] if value.length() > 0 else "?"
	if is_dominant:
		return first_letter.to_upper()
	else:
		return first_letter.to_lower()


## Create a duplicate of this allele
func duplicate_allele() -> Allele:
	var copy: Allele = Allele.new()
	copy.trait_name = trait_name
	copy.value = value
	return copy


func _to_string() -> String:
	return "%s: %s (%s)" % [trait_name, value, "dominant" if is_dominant else "recessive"]
