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


## Genotype symbol: the trait's letter, uppercase if dominant (R), lowercase if recessive (r)
func get_symbol() -> String:
	return GameConstants.allele_symbol(trait_name, value)


## Shape drawn on this allele's band
var shape: String:
	get:
		return GameConstants.get_allele_shape(value)


## Create a duplicate of this allele
func duplicate_allele() -> Allele:
	var copy: Allele = Allele.new()
	copy.trait_name = trait_name
	copy.value = value
	return copy


func _to_string() -> String:
	return "%s: %s (%s)" % [trait_name, value, "dominant" if is_dominant else "recessive"]
