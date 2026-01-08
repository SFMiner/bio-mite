# game_constants.gd
# Global constants and utility functions for Bio-Mite Architect
# Teaches: Chromosome structure, genetic linkage, Mendelian inheritance
extends Node

# === CONSTANTS ===

# Chromosome types (Bio-Mites have 3 chromosome pairs = diploid 2n=6)
const CHROMOSOME_TYPES: Array[int] = [1, 2, 3]

# Number of chromosomes needed per type for viable organism
const CHROMOSOMES_PER_TYPE: int = 2

# UI sizing
const CHROMOSOME_WIDTH: int = 60
const CHROMOSOME_HEIGHT: int = 180
const ALLELE_BAND_HEIGHT: int = 30
const SLOT_SIZE: Vector2 = Vector2(80, 200)

# Colors for chromosome types (teal-based palette)
const CHROMOSOME_TYPE_COLORS: Dictionary = {
	1: Color("#4a9e9e"),  # Teal
	2: Color("#6b4a9e"),  # Purple
	3: Color("#9e6b4a"),  # Amber
}

# Trait definitions - maps trait names to their possible values
# Educational note: Each chromosome carries multiple linked genes
# Position in array determines locus position on chromosome
const TRAIT_DEFINITIONS: Dictionary = {
	# Chromosome 1 traits (linked: body shape and glow)
	"Body Shape": {
		"chromosome": 1,
		"locus": 0,
		"dominant": "Round",
		"recessive": "Square"
	},
	"Glow": {
		"chromosome": 1,
		"locus": 1,
		"dominant": "Neon",
		"recessive": "Dull"
	},
	# Chromosome 2 traits (linked: antennae and texture)
	"Antennae": {
		"chromosome": 2,
		"locus": 0,
		"dominant": "Pointed",
		"recessive": "Rounded"
	},
	"Texture": {
		"chromosome": 2,
		"locus": 1,
		"dominant": "Smooth",
		"recessive": "Bumpy"
	},
	# Chromosome 3 traits (linked: legs and eyes)
	"Legs": {
		"chromosome": 3,
		"locus": 0,
		"dominant": "Long",
		"recessive": "Short"
	},
	"Eyes": {
		"chromosome": 3,
		"locus": 1,
		"dominant": "Big",
		"recessive": "Small"
	}
}

# Allele display colors (for the bands on chromosomes)
const ALLELE_COLORS: Dictionary = {
	# Body Shape
	"Round": Color("#ff6b6b"),      # Coral red
	"Square": Color("#ffd93d"),     # Yellow
	# Glow
	"Neon": Color("#6bff6b"),       # Bright green
	"Dull": Color("#a0a0a0"),       # Gray
	# Antennae
	"Pointed": Color("#6b6bff"),    # Blue
	"Rounded": Color("#ff6bff"),    # Magenta
	# Texture
	"Smooth": Color("#6bffff"),     # Cyan
	"Bumpy": Color("#ff9f6b"),      # Orange
	# Legs
	"Long": Color("#c86bff"),       # Purple
	"Short": Color("#ffb6c1"),      # Light pink
	# Eyes
	"Big": Color("#98fb98"),        # Pale green
	"Small": Color("#dda0dd"),      # Plum
}


# === UTILITY FUNCTIONS ===

## Get all traits on a specific chromosome type
func get_traits_for_chromosome(chr_type: int) -> Array[String]:
	var traits: Array[String] = []
	for trait_name: String in TRAIT_DEFINITIONS:
		if TRAIT_DEFINITIONS[trait_name]["chromosome"] == chr_type:
			traits.append(trait_name)
	# Sort by locus position for consistent ordering
	traits.sort_custom(func(a: String, b: String) -> bool:
		return TRAIT_DEFINITIONS[a]["locus"] < TRAIT_DEFINITIONS[b]["locus"]
	)
	return traits


## Check if an allele value is dominant for its trait
func is_dominant(trait_name: String, allele_value: String) -> bool:
	if not TRAIT_DEFINITIONS.has(trait_name):
		push_error("Unknown trait: " + trait_name)
		return false
	return TRAIT_DEFINITIONS[trait_name]["dominant"] == allele_value


## Get the color for an allele value
func get_allele_color(allele_value: String) -> Color:
	if ALLELE_COLORS.has(allele_value):
		return ALLELE_COLORS[allele_value]
	return Color.WHITE


## Get chromosome type color
func get_chromosome_color(chr_type: int) -> Color:
	if CHROMOSOME_TYPE_COLORS.has(chr_type):
		return CHROMOSOME_TYPE_COLORS[chr_type]
	return Color.GRAY


## Format allele pair for display (dominant first)
## Educational: Convention shows dominant allele first (e.g., "Rr" not "rR")
func format_allele_pair(trait_name: String, allele1: String, allele2: String) -> String:
	var is_allele1_dominant: bool = is_dominant(trait_name, allele1)
	var is_allele2_dominant: bool = is_dominant(trait_name, allele2)
	
	# Get first letter of each allele for shorthand
	var letter1: String = allele1[0]
	var letter2: String = allele2[0]
	
	# Dominant uses uppercase, recessive uses lowercase
	var symbol1: String = letter1.to_upper() if is_allele1_dominant else letter1.to_lower()
	var symbol2: String = letter2.to_upper() if is_allele2_dominant else letter2.to_lower()
	
	# Always show dominant allele first in pair
	if is_allele1_dominant and not is_allele2_dominant:
		return symbol1 + symbol2  # Rr
	elif is_allele2_dominant and not is_allele1_dominant:
		return symbol2 + symbol1  # Rr (swap order)
	else:
		# Both same dominance (RR or rr) - order doesn't matter
		return symbol1 + symbol2
