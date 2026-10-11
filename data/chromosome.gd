# chromosome.gd
# Resource class representing a chromosome with linked alleles
# Educational: Chromosomes physically link genes together - this is the core teaching concept
class_name Chromosome
extends Resource

# === PROPERTIES ===

## Chromosome type (1, 2, or 3 for Bio-Mites)
@export var type: int = 1

## Unique identifier for this chromosome variant (e.g., "1A", "1B")
@export var id: String = ""

## Ordered array of alleles on this chromosome
## Educational: The ORDER matters - genes have fixed positions (loci) on chromosomes
@export var alleles: Array[Allele] = []


# === COMPUTED PROPERTIES ===

## Get the display color for this chromosome type
var type_color: Color:
	get:
		return GameConstants.get_chromosome_color(type)


# === METHODS ===

## Create a Chromosome from dictionary data (from JSON)
static func from_dict(chr_type: int, data: Dictionary) -> Chromosome:
	var chromosome: Chromosome = Chromosome.new()
	chromosome.type = chr_type
	chromosome.id = data.get("id", "")
	
	# Parse alleles from dictionary
	var allele_data_array: Array = data.get("alleles", [])
	for allele_data: Dictionary in allele_data_array:
		var allele: Allele = Allele.from_dict(allele_data)
		chromosome.alleles.append(allele)
	
	return chromosome


## Get the allele for a specific trait on this chromosome
func get_allele_for_trait(trait_name: String) -> Allele:
	for allele: Allele in alleles:
		if allele.trait_name == trait_name:
			return allele
	return null


## One-line description for the status line, e.g. "1A: Round (R, dominant) + Neon (N, dominant)"
func describe() -> String:
	var parts: Array[String] = []
	for allele: Allele in alleles:
		parts.append("%s (%s, %s)" % [allele.value, allele.get_symbol(), "dominant" if allele.is_dominant else "recessive"])
	return "%s: %s" % [id, " + ".join(parts)]


## Create a deep copy of this chromosome
func duplicate_chromosome() -> Chromosome:
	var copy: Chromosome = Chromosome.new()
	copy.type = type
	copy.id = id
	
	for allele: Allele in alleles:
		copy.alleles.append(allele.duplicate_allele())
	
	return copy


func _to_string() -> String:
	var allele_strs: Array[String] = []
	for allele: Allele in alleles:
		allele_strs.append(allele.get_symbol())
	return "Chr%d-%s [%s]" % [type, id, ", ".join(allele_strs)]
