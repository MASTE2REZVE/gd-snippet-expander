# Changelog

All notable changes to GD Snippet Expander are documented in this
file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

Nothing yet.

## [1.0.0] - 2026-09-22

Initial release.

### Added

#### Core
- A bottom-panel editor plugin for the Godot 4 script editor.
- Plain-English phrase search.
- Snippet insertion at the caret in the currently-open `.gd` file.
- Snippet insertion wrapped in a single undo step — one Ctrl+Z
  removes the whole snippet.
- Copy to clipboard button for the current snippet or blueprint
  tree.
- Bundled library with 111 snippets and 20 blueprints.
- Category-based library loader. Each category lives in its own
  GDScript file under `library/`.
- User library at `user://gd_snippet_expander/user_library.json`
  overrides bundled entries by ID.
- Works offline. No network calls, no AI provider, no accounts.
- Android-tested. Built and tested on a tablet running Godot
  4.7.2 stable.

#### Blueprints
- Blueprints: library entries that build a working node tree
  into the current scene instead of inserting code.
- 20 blueprints across 3D, 2D, and UI:
  - 3D: player, ground plane, third-person camera rig,
	directional light, chasing enemy, coin pickup.
  - 2D: platformer player, top-down player, platformer
	ground, camera follow, patrol enemy, coin pickup,
	TileMap level.
  - UI: pause menu, main menu, health bar, settings menu,
	game over screen, score HUD, dialog box.
- Blueprints auto-generate a script when the entry specifies one.
- Blueprint building is wrapped in a single undo step.
- Newly-built blueprints are selected in the Scene tree.

#### Teaching
- Details tab on every snippet: WHAT, WHERE, BEFORE, AFTER,
  WHY THIS IS OPTIMIZED, and COMMON MISTAKES.
- Params tab on every snippet with tunable values: default,
  range, what it does, typical values, and what happens when
  you increase or decrease it.
- 111 snippets fully enriched with details and param info
  across movement, camera, health, combat, AI, pickup, UI,
  save, audio, scene, and utility categories.
- Related chips under the preview — quick-jump to related
  snippets or next-step blueprints.
- Missing input action warnings. If a snippet or blueprint
  needs an input action that isn't in the project's Input Map,
  a yellow banner names what's missing.

#### Display modes
- Three display modes for snippets:
  - **Code only** — raw code, no comments.
  - **Code + details** — code with a comment header generated
	from the snippet's details (WHAT / WHERE / BEFORE / AFTER /
	param notes / common mistakes).
  - **Full details** — raw code, plus the separate Details and
	Params tabs.
- Mode is saved between sessions.

#### Search and matching
- Unified search across snippets and blueprints.
- Six-tier matching: exact → query contains phrase → phrase
  contains query → phrase-level fuzzy → token-level fuzzy →
  multi-result list.
- Input normalization: lowercased, trimmed, punctuation
  stripped, whitespace collapsed.
- Token-level fuzzy matching catches typos like `movment` →
  `movement`, `camra` → `camera`, `jupm` → `jump`.
- Multi-result dropdown when several results tie on score.

#### Panel tabs
- **Preview** — the main search and preview view.
- **Browse** — a category tree of the whole library. Click
  any item to load it in Preview.
- **Learn** — node inspector. Select a node in the Scene tree,
  press Refresh, and read what it does, what children it needs,
  common mistakes, and a link to Godot's docs. Covers ~28
  common game-dev node types with a fallback for anything else.
- **Tools** — starter templates, scene checker, and debug
  overlay.

#### Starter templates
- 5 templates, one-click scene setup:
  - 2D Platformer Starter
  - 3D FPS Starter
  - Top-Down RPG Starter
  - 3D Third-Person Starter
  - 2D Top-Down Combat Starter
- Templates build their blueprints in order and report which
  snippets still need manual placement.

#### Scene checker
- Scans the open scene for common beginner mistakes:
  - CharacterBody2D or CharacterBody3D without a
    CollisionShape.
  - StaticBody without a CollisionShape.
  - Area2D or Area3D without a CollisionShape.
  - Camera2D or Camera3D as a direct child of a character.
  - Menu CanvasLayer without `process_mode = ALWAYS`.
  - CollisionShape with no Shape resource assigned.
  - Timer that nothing starts.
- Reports each issue with node name, explanation, and fix.

#### Debug overlay
- Optional in-scene overlay showing FPS, draw calls, static
  memory, and node count.
- Press F3 in-game to toggle visibility.
- Install and remove from the Tools tab, each wrapped in
  one undo step.

#### Wizard
- First-run dialog offering starter templates. Runs once,
  then remembers via settings.

#### Node inspector
- Click any node in your Scene tree, press Refresh in the
  Learn tab, and read what it is, what children it needs,
  what it's usually paired with, common mistakes, and a link
  to the official Godot docs.

#### Settings
- `user://gd_snippet_expander/settings.json` stores the
  display mode, favorites list, recents list, and the wizard
  completion flag.
- Settings are saved automatically on every change.

#### Compatibility
- Godot 4.4 or newer. Tested against 4.7.2 stable.
- No external dependencies. No autoloads. No GDExtension.
- User library is plain JSON with no plugin-specific state,
  so other tools can read or append to it.

[Unreleased]: https://github.com/MASTE2REZVE/gd-snippet-expander/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/MASTE2REZVE/gd-snippet-expander/releases/tag/v1.0.0