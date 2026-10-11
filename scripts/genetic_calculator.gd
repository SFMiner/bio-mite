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
	var chromosome_type: int = 0

	static func valid() -> ValidationResult:
		var result: ValidationResult = ValidationResult.new()
		result.is_valid = true
		return result

	static func invalid(message: String, type: String = "", chr_type: int = 0) -> ValidationResult:
		var result: ValidationResult = ValidationResult.new()
		result.is_valid = false
		result.error_message = message
		result.error_type = type
		result.chromosome_type = chr_type
		return result


## Validate that a karyotype has exactly 2 chromosomes of each type (diploid)
## Educational: in this game a Bio-Mite needs exactly 2 copies of each chromosome. That is a rule of the
## Bio-Mite, not of all life: the game's "Chromosome facts" panel covers haploid, polyploid and trisomic organisms.
static func validate_karyotype(karyotype: Dictionary) -> ValidationResult:
	# karyotype format: { 1: [chr, chr], 2: [chr, chr], 3: [chr, chr] }
	var rule: String = "A Bio-Mite needs exactly %d copies of every chromosome, so this one can't develop." % GameConstants.CHROMOSOMES_PER_TYPE
	for chr_type: int in GameConstants.CHROMOSOME_TYPES:
		if not karyotype.has(chr_type) or (karyotype[chr_type] as Array).is_empty():
			return ValidationResult.invalid("Chromosome %d is missing." % chr_type, "missing_type", chr_type)
		var count: int = (karyotype[chr_type] as Array).size()
		if count < GameConstants.CHROMOSOMES_PER_TYPE:
			return ValidationResult.invalid("Chromosome %d has only 1 copy. %s" % [chr_type, rule], "monosomy", chr_type)
		if count > GameConstants.CHROMOSOMES_PER_TYPE:
			return ValidationResult.invalid("Chromosome %d has %d copies. %s" % [chr_type, count, rule], "trisomy", chr_type)
	return ValidationResult.valid()


## Calculate phenotype from a valid karyotype
## Educational: For each trait, we look at the allele pair and apply dominance rules
static func calculate_phenotype(karyotype: Dictionary) -> Dictionary:
	var phenotype: Dictionary = {}
	for chr_type: int in GameConstants.CHROMOSOME_TYPES:
		if not karyotype.has(chr_type) or (karyotype[chr_type] as Array).size() != 2:
			continue
		var chr_a: Chromosome = karyotype[chr_type][0]
		var chr_b: Chromosome = karyotype[chr_type][1]
		for trait_name: String in GameConstants.get_traits_for_chromosome(chr_type):
			var allele_a: Allele = chr_a.get_allele_for_trait(trait_name)
			var allele_b: Allele = chr_b.get_allele_for_trait(trait_name)
			if allele_a and allele_b:
				phenotype[trait_name] = _resolve_dominance(allele_a, allele_b)
	return phenotype


## Genotype per trait for display
## Educational: Shows the allele pairs with dominance notation (e.g., "Rr" for heterozygous)
static func get_genotype_display(karyotype: Dictionary) -> Dictionary:
	var genotype_info: Dictionary = {}
	for chr_type: int in GameConstants.CHROMOSOME_TYPES:
		if not karyotype.has(chr_type) or (karyotype[chr_type] as Array).size() != 2:
			continue
		var chr_a: Chromosome = karyotype[chr_type][0]
		var chr_b: Chromosome = karyotype[chr_type][1]
		for trait_name: String in GameConstants.get_traits_for_chromosome(chr_type):
			var allele_a: Allele = chr_a.get_allele_for_trait(trait_name)
			var allele_b: Allele = chr_b.get_allele_for_trait(trait_name)
			if allele_a and allele_b:
				genotype_info[trait_name] = {
					"allele1": allele_a.value,
					"allele2": allele_b.value,
					"pair_notation": GameConstants.format_allele_pair(trait_name, allele_a.value, allele_b.value),
					"is_homozygous": allele_a.value == allele_b.value,
				}
	return genotype_info


## Apply Mendelian dominance rules to determine the expressed trait
## Educational: Dominant + anything shows the dominant trait; only two recessive alleles show the recessive one
static func _resolve_dominance(allele_a: Allele, allele_b: Allele) -> String:
	if allele_a.is_dominant:
		return allele_a.value
	if allele_b.is_dominant:
		return allele_b.value
	return allele_a.value
