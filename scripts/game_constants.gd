# game_constants.gd
# Constants and pure helpers for Bio-Mite Architect: traits, dominance, notation, colours and band shapes.
# Teaches: Chromosome structure, genetic linkage, Mendelian inheritance
# A static class, not an autoload, so headless test scripts can use it by name.
class_name GameConstants
extends RefCounted

# === CONSTANTS ===

## Chromosome types (Bio-Mites have 3 chromosome pairs = diploid 2n=6)
const CHROMOSOME_TYPES: Array[int] = [1, 2, 3]

## Copies of each chromosome a Bio-Mite needs to develop (a rule of this game's organism, not of all life)
const CHROMOSOMES_PER_TYPE: int = 2

## Colours for chromosome types
const CHROMOSOME_TYPE_COLORS: Dictionary = {
	1: Color("#4a9e9e"),  # Teal
	2: Color("#6b4a9e"),  # Purple
	3: Color("#9e6b4a"),  # Amber
}

## Trait definitions. "locus" is the band position on the chromosome; "letter" is the genotype symbol
## (uppercase dominant, lowercase recessive, the same letter for both alleles: Rr, not Rs).
const TRAIT_DEFINITIONS: Dictionary = {
	# Chromosome 1 traits (linked: body shape and glow)
	"Body Shape": {"chromosome": 1, "locus": 0, "dominant": "Round", "recessive": "Square", "letter": "R"},
	"Glow": {"chromosome": 1, "locus": 1, "dominant": "Neon", "recessive": "Dull", "letter": "N"},
	# Chromosome 2 traits (linked: antennae and texture)
	"Antennae": {"chromosome": 2, "locus": 0, "dominant": "Pointed", "recessive": "Rounded", "letter": "P"},
	"Texture": {"chromosome": 2, "locus": 1, "dominant": "Smooth", "recessive": "Bumpy", "letter": "S"},
	# Chromosome 3 traits (linked: legs and eyes)
	"Legs": {"chromosome": 3, "locus": 0, "dominant": "Long", "recessive": "Short", "letter": "L"},
	"Eyes": {"chromosome": 3, "locus": 1, "dominant": "Big", "recessive": "Small", "letter": "B"},
}

## Allele band colours. Each allele also has its own shape (ALLELE_SHAPES), so colour is never the only cue.
const ALLELE_COLORS: Dictionary = {
	"Round": Color("#ff8a80"),
	"Square": Color("#ffd93d"),
	"Neon": Color("#7dff7d"),
	"Dull": Color("#b4b4b4"),
	"Pointed": Color("#9a9aff"),
	"Rounded": Color("#ff9cff"),
	"Smooth": Color("#7fffff"),
	"Bumpy": Color("#ffb07f"),
	"Long": Color("#d39aff"),
	"Short": Color("#ffc4cc"),
	"Big": Color("#a8f5a8"),
	"Small": Color("#e3b5e3"),
}

## Shape drawn on each allele's band (see ChromosomeVisual.draw_allele_shape). Shapes echo the trait
## (a square for Square, a triangle for Pointed); dominant shapes are filled, recessive ones outlined.
const ALLELE_SHAPES: Dictionary = {
	"Round": "circle",
	"Square": "square",
	"Neon": "star",
	"Dull": "dash",
	"Pointed": "triangle",
	"Rounded": "dome",
	"Smooth": "wave",
	"Bumpy": "bumps",
	"Long": "tall_bar",
	"Short": "short_bar",
	"Big": "big_eye",
	"Small": "small_eye",
}


# === UTILITY FUNCTIONS ===

## All traits on a chromosome type, in locus order
static func get_traits_for_chromosome(chr_type: int) -> Array[String]:
	var traits: Array[String] = []
	for trait_name: String in TRAIT_DEFINITIONS:
		if int(TRAIT_DEFINITIONS[trait_name]["chromosome"]) == chr_type:
			traits.append(trait_name)
	traits.sort_custom(func(a: String, b: String) -> bool:
		return int(TRAIT_DEFINITIONS[a]["locus"]) < int(TRAIT_DEFINITIONS[b]["locus"])
	)
	return traits


## Whether an allele value is dominant for its trait
static func is_dominant(trait_name: String, allele_value: String) -> bool:
	if not TRAIT_DEFINITIONS.has(trait_name):
		push_error("Unknown trait: " + trait_name)
		return false
	return TRAIT_DEFINITIONS[trait_name]["dominant"] == allele_value


## Genotype symbol for one allele: the trait's letter, uppercase if dominant (R), lowercase if recessive (r)
static func allele_symbol(trait_name: String, allele_value: String) -> String:
	if not TRAIT_DEFINITIONS.has(trait_name):
		return "?"
	var letter: String = String(TRAIT_DEFINITIONS[trait_name]["letter"])
	return letter.to_upper() if is_dominant(trait_name, allele_value) else letter.to_lower()


static func get_allele_color(allele_value: String) -> Color:
	return ALLELE_COLORS.get(allele_value, Color.WHITE)


static func get_allele_shape(allele_value: String) -> String:
	return String(ALLELE_SHAPES.get(allele_value, "circle"))


static func get_chromosome_color(chr_type: int) -> Color:
	return CHROMOSOME_TYPE_COLORS.get(chr_type, Color.GRAY)


## Allele pair in genotype notation, dominant first: RR, Rr or rr
## Educational: both alleles of a gene share one letter; the case shows which version it is
static func format_allele_pair(trait_name: String, allele1: String, allele2: String) -> String:
	var symbol1: String = allele_symbol(trait_name, allele1)
	var symbol2: String = allele_symbol(trait_name, allele2)
	if not is_dominant(trait_name, allele1) and is_dominant(trait_name, allele2):
		return symbol2 + symbol1
	return symbol1 + symbol2
