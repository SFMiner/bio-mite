# CLAUDE.md

Single copy of the project conventions; AGENTS.md only points here. Features, layout, tests and export: `README.md`.

## Project
**Bio-Mite Architect**: a genetics puzzle for grades 6+ on sims.mr-miner.com (Godot 4.5, GL Compatibility, lean 2D
web template). Author Sean Miner, MIT. Overhauled 2026-10-11 (code-built UI, keyboard exit, science fixes).

## Rules
- **Science wording (Sean, 2026-10-11):** "exactly 2 copies of each chromosome" is a Bio-Mite rule; say so wherever it
  appears and point to Chromosome facts, since Earth life includes haploid, polyploid and trisomic organisms. Level 5 is
  impossible only because the game has no crossing over; keep the explanation saying that.
- Genotype notation is one letter per gene (`TRAIT_DEFINITIONS[...]["letter"]`): Rr, never the first letters of two
  allele names (the original showed "Rs", "Pr").
- Every allele has its own band shape (filled dominant, outlined recessive) so colour is never the only cue; labels
  are on by default and the L key hides them. Keep shapes distinct within a chromosome when adding alleles.
- No autoloads: `GameConstants` is a static class and `LevelManager` a RefCounted owned by `scenes/main.gd`, so the
  headless test script can use them by name.
- Tab order is `_rebuild_keyboard()` in `scenes/main.gd`; it is rebuilt whenever a button shows or hides. Panels
  (Hint, Chromosome facts) are in-page overlays, not Windows: Tab cycles inside, Escape closes.
- Plain Labels only (no RichTextLabel / Popup windows), so the 2D template works; `tests/run_tests.gd` fails on any
  character above U+206F in scripts or level data.
- New level fields: `extra_slot` (show the Extra slot) and `offer_impossible` (show "It's impossible"). The test tries
  every pairing to confirm each level is solvable, or truly impossible when `is_impossible` is set.
