# Changelog

All notable changes to GD Snippet Expander are documented in this
file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

Nothing yet.

## [1.2.0] - 2026-09-24

Library expansion. Adds animation, shaders, particle effects, and
several effect blueprints. Adds a Library Report tool.

### Added

#### Animation snippets (14)
- AnimationPlayer basics: `animation_play`, `animation_loop`,
  `animation_queue`, `animation_signal`, `animation_speed`.
- Tween sequences: `tween_sequence`, `tween_parallel`,
  `tween_callback`.
- AnimationTree: `animation_tree_setup`, `animation_tree_state`,
  `animation_tree_param`, `animation_blend_2d`,
  `animation_state_machine_2d`, `animation_oneshot`.

#### Shader snippets (6)
- `shader_dissolve` — noise-based dissolve with burning edge.
- `shader_flash` — tint toward a color for damage feedback.
- `shader_outline` — 8-direction outline around opaque pixels.
- `shader_damage_flicker` — invincibility flicker.
- `shader_crt` — full-screen CRT with scanlines and curvature.
- `shader_wave` — sine-wave vertex distortion.

#### Particle snippets (6)
- `particle_explosion` — one-shot burst, self-deletes.
- `particle_trail` — trailing emitter for moving objects.
- `particle_dust` — dust puff for landings and footsteps.
- `particle_sparkle` — ambient pickup sparkles.
- `particle_smoke` — continuous upward smoke.
- All are programmatic — no scene file needed.

#### Blueprints (9)
- `animated_player_2d` — CharacterBody2D with AnimatedSprite2D
  and AnimationPlayer.
- `animated_player_3d` — CharacterBody3D with model and
  AnimationPlayer.
- `screen_effect_layer` — CanvasLayer + ColorRect ready for a
  fullscreen shader.
- `impact_effect` — particles + sound, self-deletes on hit.
- `death_effect` — burst + smoke + sound for enemy deaths.
- `projectile_with_trail` — Area2D bullet with a particle trail
  and optional glow.
- `enemy_spawner` — Timer-driven enemy spawn point.
- `damage_popup_scene` — floating damage number with tween
  animation.
- `boss_health_bar` — full boss bar with name label and damage
  lag effect.

#### Library Report
- New menu command: **Project → Tools → Library Report...**
- Shows total counts, progress toward targets (450 snippets /
  80 blueprints / 15 templates), and every entry grouped by
  category and subcategory.
- Copy to clipboard or save to a text file.
- Loads from the real `GDASELibrary` so counts are always
  deduplicated and accurate.

#### Library maintenance
- Added `library/zz_subcategories_extra.gd` to fill a gap in the
  subcategory overrides (`camera_look_at_mouse` was showing as
  uncategorized).

### Changed
- README rewritten to cover animation, shaders, particles, and
  the Library Report tool.
- Library totals: 137 snippets, 29 blueprints, 5 templates.

## [1.1.0] - 2026-09-23

Quality-of-life update. Adds favorites, suggestions, a two-tier
browse tree, save-as-blueprint, blueprint import/export, and Godot
version awareness.

### Added

#### Two-tier Browse tree
- Library entries now carry an optional `subcategory` field.
  Categories like Movement split into 2D and 3D; Camera splits
  into 2D and 3D; UI splits into HUD, Menus, Dialog, and so on.
- The Browse tab renders category → subcategory → Blueprints /
  Snippets → entry. Entries without a subcategory appear directly
  under their category.
- Every existing entry has been assigned a subcategory.
- Acronyms (AI, UI, HUD, RPG, FPS, NPC, and others) display in
  their correct casing instead of being title-cased.

#### Favorites
- Star button in the input row next to Copy. Click to add or
  remove the current match from favorites.
- Favorites appear as clickable chips in a row above the tabs.
  Click a chip to jump straight to that entry.
- Persisted in the settings file, survives across sessions.
- Works for both snippets and blueprints.

#### Suggestions
- "Try next:" row that appears after you insert or build
  something. Suggests up to 3 snippets from categories you
  haven't explored yet, in a priority order starting with
  movement and camera.
- Click a suggestion chip to jump to it.
- Hidden when there is nothing to suggest.

#### Save-as-Blueprint
- New menu command: **Project → Tools → Save Selected Node as
  Blueprint...**
- Saves any node tree in your scene as a reusable blueprint in
  your user library. Captures node type, name, position,
  collision shapes, primitive meshes, and a curated set of common
  properties (text, color, anchors, fov, wait times, audio bus).
- Nested children are supported to any depth.
- A dialog collects the ID, title, phrases, category, and
  subcategory. Input is validated (lowercase IDs, phrases
  required).
- Saved blueprints appear in the Browse tab under their category
  and can be built back into any scene.

#### Blueprint Import / Export
- **Tools → Custom Blueprints: Import / Export** — two buttons
  in the Tools tab.
- **Export** writes all your user blueprints to a JSON file at
  any path you choose.
- **Import** reads a file, validates the format, and merges the
  blueprints into your user library.
- Imports never overwrite existing entries — conflicting IDs get
  an `_imported` suffix.
- The file carries a `format` marker so other tools can recognize
  it.

#### Version awareness
- The plugin reads your Godot version at load.
- If you're on a version older than 4.4, the status line shows an
  error.
- If you're on a version newer than 4.7.2 (the tested version),
  the status line shows a warning so you know to report bugs if
  anything breaks.
- Nothing is blocked — this is informational only.

#### Library API additions
- `get_subcategory(id)` and `get_blueprint_subcategory(id)`.
- `get_browse_tree()` returns a nested structure suitable for a
  two-tier tree view.
- `get_suggestions(max_count)` returns snippet IDs from
  unexplored categories.
- `add_user_blueprint(id, data)` and
  `remove_user_blueprint(id)`.
- The merge logic is now additive: when a library file sends only
  some fields for an existing ID, they're merged into the
  existing entry instead of replacing it. This is what makes the
  subcategory override file work.

## [1.0.1] - 2026-09-22

Bug fixes for two issues found after the initial release.

### Fixed
- The phrase input box no longer overwrites itself with the
  matched phrase while you're typing. The input now only gets
  auto-filled when you explicitly jump to an entry via a chip,
  a browse item, or a result list selection.
- Rebuilding a template after deleting all its nodes now works.
  Previously the second apply did nothing because the selection
  still pointed at a freed node. The builder now validates the
  parent before using it.

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
  - 2D: platformer player, top-down player, platformer ground,
    camera follow, patrol enemy, coin pickup, TileMap level.
  - UI: pause menu, main menu, health bar, settings menu,
    game over screen, score HUD, dialog box.
- Blueprints auto-generate a script when the entry specifies one.
- Blueprint building is wrapped in a single undo step.
- Newly-built blueprints are selected in the Scene tree.

#### Teaching
- Details tab on every snippet: WHAT, WHERE, BEFORE, AFTER, WHY
  THIS IS OPTIMIZED, and COMMON MISTAKES.
- Params tab on every snippet with tunable values: default,
  range, what it does, typical values, and what happens when you
  increase or decrease it.
- 111 snippets fully enriched with details and param info across
  movement, camera, health, combat, AI, pickup, UI, save, audio,
  scene, and utility categories.
- Related chips under the preview — quick-jump to related
  snippets or next-step blueprints.
- Missing input action warnings. If a snippet or blueprint needs
  an input action that isn't in the project's Input Map, a yellow
  banner names what's missing.

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
- **Browse** — a category tree of the whole library. Click any
  item to load it in Preview.
- **Learn** — node inspector. Select a node in the Scene tree,
  press Refresh, and read what it does, what children it needs,
  common mistakes, and a link to Godot's docs. Covers ~28 common
  game-dev node types with a fallback for anything else.
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
  - CharacterBody2D or CharacterBody3D without a CollisionShape.
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
- Install and remove from the Tools tab, each wrapped in one
  undo step.

#### Wizard
- First-run dialog offering starter templates. Runs once, then
  remembers via settings.

#### Node inspector
- Click any node in your Scene tree, press Refresh in the Learn
  tab, and read what it is, what children it needs, what it's
  usually paired with, common mistakes, and a link to the
  official Godot docs.

#### Settings
- `user://gd_snippet_expander/settings.json` stores the display
  mode, favorites list, recents list, and the wizard completion
  flag.
- Settings are saved automatically on every change.

#### Compatibility
- Godot 4.4 or newer. Tested against 4.7.2 stable.
- No external dependencies. No autoloads. No GDExtension.
- User library is plain JSON with no plugin-specific state, so
  other tools can read or append to it.

[Unreleased]: https://github.com/MASTE2REZVE/gd-snippet-expander/compare/v1.2.0...HEAD
[1.2.0]: https://github.com/MASTE2REZVE/gd-snippet-expander/releases/tag/v1.2.0
[1.1.0]: https://github.com/MASTE2REZVE/gd-snippet-expander/releases/tag/v1.1.0
[1.0.1]: https://github.com/MASTE2REZVE/gd-snippet-expander/releases/tag/v1.0.1
[1.0.0]: https://github.com/MASTE2REZVE/gd-snippet-expander/releases/tag/v1.0.0