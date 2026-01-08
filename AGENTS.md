# Repository Guidelines

## Project Structure & Module Organization
- `scenes/`: Godot scenes and UI components (`scenes/main.tscn`, `scenes/ui/`, `scenes/components/`).
- `scripts/`: Gameplay logic helpers (e.g., `scripts/genetic_calculator.gd`).
- `data/`: Core data models and level data (`data/allele.gd`, `data/chromosome.gd`, `data/levels/level_definitions.json`).
- `autoload/`: Singleton services (`autoload/game_constants.gd`, `autoload/level_manager.gd`).
- `themes/`: UI theme resources (`themes/lab_theme.tres`).
- Root config: `project.godot`, `export_presets.cfg`, `icon.svg`.

## Build, Test, and Development Commands
- Open in Godot 4.5+ and run the main scene `res://scenes/main.tscn`.
- In the editor, press `F5` (or Play) to run the game.
- This repo does not include scripted build/test commands; use Godot Editor for run/debug.

## Coding Style & Naming Conventions
- GDScript uses static typing (`: Type`) and `class_name` for resources.
- Use `@onready` for node references, and declare `signal` blocks near the top.
- Prefer descriptive node paths and names that match scene structure.
- Indentation: tabs (default Godot style). Keep line lengths reasonable and comments concise.

## Testing Guidelines
- No automated tests are present in this repository.
- Validate changes by running the project and exercising the relevant UI flows.

## Commit & Pull Request Guidelines
- No Git history exists yet in this repository, so no established commit convention.
- Suggested format: short, imperative messages (e.g., `Add reactor slot removal`).
- PRs (if used) should include: clear description, affected scenes/scripts, and screenshots/GIFs for UI changes.

## Configuration & Architecture Notes
- Main entry point: `scenes/main.tscn`.
- Level data lives in `data/levels/level_definitions.json`.
- Use the `autoload/` singletons for shared constants and level state.
