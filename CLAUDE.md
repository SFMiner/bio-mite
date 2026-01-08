# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Bio-Mite Architect** is an educational puzzle game built in Godot 4.5 that teaches Mendelian genetics, chromosome linkage, and genetic inheritance concepts. Players assemble chromosomes to create organisms ("Bio-Mites") with specific traits.

## Running the Project

- **Open in Godot Editor**: Open the project folder in Godot 4.5+ (GL Compatibility renderer)
- **Run the game**: Press F5 in Godot Editor or click the Play button
- **Main scene**: `res://scenes/main.tscn`

## Architecture Overview

### Core Educational Concept
The game teaches that **genes are physically linked on chromosomes** - you cannot separate alleles that exist on the same chromosome without recombination. This is the central teaching mechanic.

### Data Model Hierarchy
```
Chromosome (class_name in data/chromosome.gd)
  └─ Contains ordered Array[Allele]
       └─ Each Allele (class_name in data/allele.gd) has:
          - trait_name (e.g., "Body Shape")
          - value (e.g., "Round" or "Square")
```

Bio-Mites have 3 chromosome pairs (diploid 2n=6):
- **Chromosome 1**: Body Shape (locus 0) + Glow (locus 1)
- **Chromosome 2**: Antennae (locus 0) + Texture (locus 1)
- **Chromosome 3**: Legs (locus 0) + Eyes (locus 1)

### Key Autoload Singletons
- **GameConstants** (`autoload/game_constants.gd`): Defines all traits, dominance relationships, chromosome colors, and utility functions for genetic notation
- **LevelManager** (`autoload/level_manager.gd`): Loads levels from JSON, tracks progress, validates goals, handles "impossible" level detection

### Game Flow
1. **LevelManager** loads a level from `data/levels/level_definitions.json`
2. **Main** (`scenes/main.gd`) orchestrates the UI by connecting signals between:
   - **GeneBank** (`scenes/ui/gene_bank.gd`): Displays available chromosomes for selection
   - **Reactor** (`scenes/ui/reactor.gd`): 6-slot assembly area (2 slots per chromosome type)
   - **ResultsPanel** (`scenes/ui/results_panel.gd`): Shows phenotype/genotype results
3. Player clicks chromosomes in GeneBank to add to Reactor slots
4. Player clicks "Fuse Chromosomes" button
5. **GeneticCalculator** (`scripts/genetic_calculator.gd`) validates karyotype and calculates phenotype using Mendelian dominance rules
6. ResultsPanel displays whether goal was achieved

### Genetic Calculation Logic
`GeneticCalculator.calculate_phenotype()` applies dominance rules:
- For each trait, looks at allele pair from homologous chromosomes
- If either allele is dominant → express dominant phenotype
- If both recessive → express recessive phenotype
- Returns Dictionary of trait_name → expressed_value

### Level Definitions
Levels are defined in `data/levels/level_definitions.json`:
- **Level 1-2**: Basic dominance concepts
- **Level 3**: Special trisomy experiment (special_goal: "trisomy_experiment")
- **Level 4**: Introduces linked trait awareness
- **Level 5**: The "impossible" level - teaches that certain combinations cannot exist due to linkage (is_impossible: true)

## Code Conventions

- **GDScript type hints**: All code uses static typing (`: Type` annotations)
- **Class names**: Use `class_name` for resource classes (Chromosome, Allele, GeneticCalculator)
- **Node references**: Use `@onready` for scene tree node references
- **Signals**: Declared at top of scripts with `signal` keyword
- **Educational comments**: Many functions include `## Educational:` doc comments explaining the genetics concept being taught

## Important Implementation Notes

- Chromosomes are **duplicated/cloned** when moved from GeneBank to Reactor (see `gene_bank.gd:83`)
- Reactor slots are type-specific - each chromosome type has exactly 2 dedicated slots
- The "Report Impossible" button appears in Level 4+ and is the correct answer for Level 5
- Validation happens in two stages:
  1. Structural validation (monosomy/trisomy detection) in `GeneticCalculator.validate_karyotype()`
  2. Goal matching in `LevelManager.check_goal()`
