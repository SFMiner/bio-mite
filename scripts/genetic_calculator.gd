# genetic_calculator.gd
# Handles Mendelian inheritance calculations
# Educational: Demonstrates how genotype (allele pairs) determines phenotype (visible traits)
class_name GeneticCalculator
extends RefCounted


## Result of validating a karyotype
class ValidationResult:
	var is_valid: bool = false
	var error_message: String = ""
	var error_type: String = ""  # "monosomy", "trisomy", "missing_type"
	
	static func valid() -> ValidationResult:
		var result: ValidationResult = ValidationResult.new()
		result.is_valid = true
		return result
	
	static func invalid(message: String, type: String = "") -> ValidationResult:
		var result: ValidationResult = ValidationResult.new()
		result.is_valid = false
		result.error_message = message
		result.error_type = type
		return result


## Validate that a karyotype has exactly 2 chromosomes of each type (diploid)
## Educational: Organisms need balanced chromosome numbers - trisomy/monosomy are lethal
static func validate_karyotype(karyotype: Dictionary) -> ValidationResult:
	# karyotype format: { 1: [chr, chr], 2: [chr, chr], 3: [chr, chr] }
	
	for chr_type: int in GameConstants.CHROMOSOME_TYPES:
		if not karyotype.has(chr_type):
			return ValidationResult.invalid(
				"Missing chromosome type %d!" % chr_type,
				"missing_type"
			)
		
		var chromosomes: Array = karyotype[chr_type]
		var count: int = chromosomes.size()
		
		if count < GameConstants.CHROMOSOMES_PER_TYPE:
			return ValidationResult.invalid(
				"Monosomy detected! Chromosome %d has only %d copy (need %d)." % [
					chr_type, count, GameConstants.CHROMOSOMES_PER_TYPE
				],
				"monosomy"
			)
		
		if count > GameConstants.CHROMOSOMES_PER_TYPE:
			return ValidationResult.invalid(
				"Trisomy detected! Chromosome %d has %d copies (max %d).\n\nThis organism cannot survive!" % [
					chr_type, count, GameConstants.CHROMOSOMES_PER_TYPE
				],
				"trisomy"
			)
	
	return ValidationResult.valid()


## Calculate phenotype from a valid karyotype
## Educational: For each trait, we look at the allele pair and apply dominance rules
static func calculate_phenotype(karyotype: Dictionary) -> Dictionary:
	var phenotype: Dictionary = {}
	
	# Process each chromosome type
	for chr_type: int in GameConstants.CHROMOSOME_TYPES:
		if not karyotype.has(chr_type) or karyotype[chr_type].size() != 2:
			continue
		
		var chr_pair: Array = karyotype[chr_type]
		var chr_a: Chromosome = chr_pair[0]
		var chr_b: Chromosome = chr_pair[1]
		
		# Get all traits on this chromosome type
		var traits: Array[String] = GameConstants.get_traits_for_chromosome(chr_type)
		
		for trait_name: String in traits:
			var allele_a: Allele = chr_a.get_allele_for_trait(trait_name)
			var allele_b: Allele = chr_b.get_allele_for_trait(trait_name)
			
			if allele_a and allele_b:
				var expressed_trait: String = _resolve_dominance(trait_name, allele_a, allele_b)
				phenotype[trait_name] = expressed_trait
	
	return phenotype


## Get detailed genotype information for display
## Educational: Shows the allele pairs with dominance notation (e.g., "Rr" for heterozygous)
static func get_genotype_display(karyotype: Dictionary) -> Dictionary:
	var genotype_info: Dictionary = {}
	
	for chr_type: int in GameConstants.CHROMOSOME_TYPES:
		if not karyotype.has(chr_type) or karyotype[chr_type].size() != 2:
			continue
		
		var chr_pair: Array = karyotype[chr_type]
		var chr_a: Chromosome = chr_pair[0]
		var chr_b: Chromosome = chr_pair[1]
		
		var traits: Array[String] = GameConstants.get_traits_for_chromosome(chr_type)
		
		for trait_name: String in traits:
			var allele_a: Allele = chr_a.get_allele_for_trait(trait_name)
			var allele_b: Allele = chr_b.get_allele_for_trait(trait_name)
			
			if allele_a and allele_b:
				genotype_info[trait_name] = {
					"allele1": allele_a.value,
					"allele2": allele_b.value,
					"pair_notation": GameConstants.format_allele_pair(
						trait_name, allele_a.value, allele_b.value
					),
					"is_homozygous": allele_a.value == allele_b.value
				}
	
	return genotype_info


## Apply Mendelian dominance rules to determine expressed trait
## Educational: 
##   - Dominant + Dominant → Dominant
##   - Dominant + Recessive → Dominant  
##   - Recessive + Recessive → Recessive
static func _resolve_dominance(trait_name: String, allele_a: Allele, allele_b: Allele) -> String:
	var a_dominant: bool = allele_a.is_dominant
	var b_dominant: bool = allele_b.is_dominant
	
	# If either allele is dominant, the dominant phenotype is expressed
	if a_dominant or b_dominant:
		# Return the dominant allele's value
		if a_dominant:
			return allele_a.value
		else:
			return allele_b.value
	else:
		# Both recessive - recessive phenotype is expressed
		# (Both should have the same recessive value, but use allele_a's)
		return allele_a.value
