# Bio-Mite Architect

A genetics puzzle for grades 6 and up. Students build a Bio-Mite (a made-up creature with 3 pairs of
chromosomes, 2n = 6) by choosing chromosomes from a Gene Bank, fuse them, and compare the result with each
level's goal. The five levels cover dominant and recessive alleles, what an extra chromosome does, linked genes,
and a goal that linkage makes impossible (with crossing over explained). Godot 4.5, GL Compatibility, built for
sims.mr-miner.com. Author Sean Miner; MIT license.

## Features
- [x] Five levels from `data/levels/level_definitions.json`: Simple Dominance, The Recessive Challenge,
      The Extra Chromosome, Linked Traits, The Impossible Link
- [x] Level buttons 1-5 (current level orange, finished levels green); Hint panel per level
- [x] Gene Bank: click, tap or press Enter on a chromosome to add a copy to the Reactor; pointing at or
      tabbing to a chromosome describes its alleles in a status line
- [x] Reactor: two slots per pair; from Level 3 an Extra slot takes a third copy of any chromosome
- [x] Fuse: the Bio-Mite drawn from its traits, a trait table (genotype such as Rr, and what it looks like) with a
      homozygous / heterozygous key; a wrong chromosome number shows an egg that didn't develop
- [x] Genotype notation uses one letter per gene (Rr, Nn, Pp, Ss, Ll, Bb), dominant first
- [x] Allele bands: colour, a shape for each allele (filled = dominant, outlined = recessive) and a label
      ("R Round"); labels on by default, the L key or the Labels button hides them (shapes stay, so colour is
      never the only cue)
- [x] "Exactly 2 copies" is stated as a Bio-Mite rule, with a note that Earth life varies
- [x] Chromosome facts panel: Bio-Mites vs Earth life, haploid (gametes, honeybee drones, mosses), polyploid
      (wheat, strawberries, bananas, daylilies, gray treefrog), trisomy (Down syndrome, trisomy 18 and 13,
      XXY, jimsonweed), monosomy (Turner syndrome), linked genes and crossing over
- [x] Level 5's "It's impossible" explanation says why, and that crossing over can separate linked genes in real
      life (the game doesn't model it)
- [x] Finished screen after Level 5 with "Start again at Level 1"
- [x] Keyboard: Tab through every control with an orange focus ring; Enter or Space chooses; Tab past the last,
      Shift+Tab before the first, or Escape leaves the game (`sims:leave-game`, sims-site SPEC section 6);
      in a panel, Tab cycles inside and Escape closes it
- [x] Small frames and phones: text stays at least 85% size, the columns and rows wrap and the page scrolls
- [x] No emoji or symbols (a test scans every script and the level file)
- [x] Web export with the lean 2D template: `..\exports\bio-mite\` (22.3 MB wasm, 68 KB pck)
- [ ] Classroom try-out on Chromebooks
- [x] Published on sims.mr-miner.com (2026-10-11): https://sims.mr-miner.com/play/bio-mite
- [ ] Possible later level: crossing over (the game's chromosomes always stay whole)

## Layout
- `scenes/main.gd`: the whole screen, built in code (header, Gene Bank, Reactor, Results, Hint / facts panel)
- `scenes/components/chromosome_visual.gd`: a chromosome or Reactor slot, its band shapes and labels
- `scenes/components/bio_mite.gd`: the creature drawing
- `scripts/`: `game_constants.gd` (traits, letters, colours, shapes), `genetic_calculator.gd`,
  `level_manager.gd`, `chromosome_facts.gd` (panel text), `keyboard_nav.gd`
- `data/`: `allele.gd`, `chromosome.gd`, `levels/level_definitions.json`

## Tests
From this folder (bash):

```bash
../../Godot_v4.5-stable_win64.exe --headless --path . --editor --quit-after 200 > /dev/null 2>&1
../../Godot_v4.5-stable_win64.exe --headless --path . --script res://tests/run_tests.gd
```

`run_tests.gd` (79 checks): notation, shapes, validation, every level solvable or truly impossible (all
chromosome pairings tried), no emoji, and the screen (adding, the Extra slot, Level 3 and 5, labels key, panels,
Tab / Shift+Tab / Escape exit). Screenshot (windowed): `BM_LEVEL=5 BM_PICK=1A,1B,2A,2B,3A,3B BM_FUSE=1
BM_OUT=<png> ../../Godot_v4.5-stable_win64.exe --path . --resolution 1280x720 --script res://tools/screenshot.gd`.

## Export
`python ..\..\godot-2d-web-template\check_web_template.py bio-mite` reports the 2D template. Export:
`../../Godot_v4.5-stable_win64.exe --headless --path . --export-release "Web" ../exports/bio-mite/index.html`.
The preset includes `data/levels/*.json` and excludes `tests/`, `tools/` and Markdown.
