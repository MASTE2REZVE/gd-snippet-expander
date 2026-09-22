# GD Snippet Expander

Type a plain English phrase, get working GDScript inserted at your
cursor — or get a whole node tree built into your scene. Offline,
instant, free. No AI provider required.

A Godot 4 editor plugin that lives in the bottom panel of the
script editor. It teaches while it works: every snippet and
blueprint explains what it does, where it goes, what to set up
first, and what usually goes wrong.

## Why

Writing boilerplate GDScript over and over is boring. Building the
same `CharacterBody3D` + `CollisionShape3D` + `Camera3D` hierarchy
is boring. Typing `3d character` and getting both done is faster
than remembering every API call and every required child node.

- Offline. Works on a plane.
- Instant. No round-trips.
- Free. MIT licensed.
- Teaches. Every snippet has WHAT, WHERE, BEFORE, AFTER, WHY
  THIS IS OPTIMIZED, and COMMON MISTAKES sections. Every tunable
  parameter has a default, a range, typical values, and what
  happens when you increase or decrease it.
- Extensible. Add your own snippets and blueprints in a plain
  GDScript file.
- Android-friendly. Built and tested on a tablet.

## Requirements

- Godot 4.4 or newer (tested against 4.7.2 stable)
- No external dependencies. No autoloads. No GDExtension.

## Installation

### Manually
1. Download or clone this repo.
2. Copy the folder `addons/gd_snippet_expander/` into your own
   project's `addons/` directory.
3. Open your project in Godot.
4. Go to **Project → Project Settings → Plugins**.
5. Find **GD Snippet Expander**, tick **Enable**.
6. A new tab called **Snippet Expander** appears in the bottom
   panel of the script editor.

On first run, a wizard offers starter templates — 2D platformer,
3D FPS, top-down RPG, and more.

## The four tabs

### Preview
The main view. Type a phrase, see the code or blueprint, insert
or build it.

### Browse
A category tree of everything in the library. Click any item to
load it in Preview.

### Learn
Select a node in your Scene tree, click Refresh, and read what it
does, what children it needs, and common mistakes. Good for
figuring out unfamiliar nodes.

### Tools
- **Starter templates** — one-click scene setups.
- **Scene checker** — scans your scene for common mistakes
  (CharacterBody with no CollisionShape, pause menu that won't
  unpause, etc.).
- **Debug overlay** — installs an FPS / draw call / memory overlay
  into the current scene. Press F3 in-game to toggle.

## Two kinds of things: snippets and blueprints

**Snippets** are blocks of GDScript. Insert one and the code goes
at your cursor in the currently-open `.gd` file.

**Blueprints** are node trees. Build one and the plugin adds a
root node with its children, attaches a generated script, and
selects the whole thing in the Scene tree. One undo step — Ctrl+Z
removes the entire subtree.

The Insert button changes to **Build** when you've matched a
blueprint instead of a snippet.

## Modes

Three display modes, chosen with the buttons below the input:

- **Code only** — raw code, nothing else.
- **Code + details** — code with a comment header (WHAT / WHERE /
  BEFORE / AFTER / params / common mistakes) prepended.
- **Full details** — raw code, plus separate Details and Params
  tabs.

Your choice is remembered between sessions.

## Example phrases

| Phrase | What you get |
|---|---|
| `move forward` | CharacterBody3D movement script |
| `platformer movement` | Side-scroller with gravity and jump |
| `dash` | Directional dash ability |
| `coyote time` | Grace period after leaving a ledge |
| `health system` | Signals, take_damage, heal, death |
| `enemy patrol` | Waypoint-based AI |
| `pause menu` | CanvasLayer pause overlay |
| `save game` | JSON save to user:// |
| `raycast 3d` | Physics raycast with tunable range |
| `3d character` | *Blueprint* — full 3D player tree |
| `ground plane` | *Blueprint* — walkable 3D ground |
| `patrol enemy` | *Blueprint* — 2D patrolling enemy |
| `pause menu blueprint` | *Blueprint* — pause menu scene |

The bundled library has 111 snippets and 20 blueprints, plus 5
starter templates.

## Matching behavior

Input is normalized (lowercased, trimmed, punctuation stripped,
whitespace collapsed). Then six tiers, in order:

1. Exact match.
2. Query contains phrase.
3. Phrase contains query.
4. Phrase-level fuzzy (edit distance).
5. Token-level fuzzy — catches typos like `movment` → `movement`.
6. Multi-result list when several results tie.

If nothing matches, the status line says so.

## Adding your own snippets and blueprints

The plugin reads from:

- `addons/gd_snippet_expander/library/*.gd` — bundled library,
  one file per category.
- `user://gd_snippet_expander/user_library.json` — your own
  additions, never overwritten by updates.

**Your entries override bundled ones with the same ID.**

### User library format

```json
{
  "version": 2,
  "snippets": {
    "my_custom_thing": {
      "phrases": ["do the thing", "thing doer"],
      "code": "func do_thing() -> void:\n\tprint(\"hello\")\n",
      "params": [],
      "category": "utility",
      "details": {
        "what": "Prints hello.",
        "where": "Any script.",
        "before": "None.",
        "after": "None.",
		"why_optimized": "It's one line.",
		"mistakes": "None."
      }
    }
  }
}
```

Only `phrases` and `code` are required. Every other field is
optional — missing fields just show fewer details.

### Where is `user://`?

- Linux: `~/.local/share/godot/app_userdata/<project_name>/`
- Android: `/data/data/org.godotengine.<project>/files/`
- Windows: `%APPDATA%\Godot\app_userdata\<project_name>\`

Find it in Godot with **Project → Open User Data Folder**.

## Compatibility with other plugins

The user library is a plain JSON file with no plugin-specific
state. Any other tool can read or append to it. No autoloads, no
global signals, no cross-plugin coupling.

## Uninstalling

1. Disable the plugin in **Project Settings → Plugins**.
2. Delete `addons/gd_snippet_expander/` from your project.
3. Optionally delete `user://gd_snippet_expander/` and the
   `gdse_generated/` folder at project root.

## Contributing

Issues and pull requests welcome. To add a snippet to the bundled
library, edit the matching file in `library/` and open a PR.

## License

MIT. See [LICENSE](LICENSE).

## Changelog

See [CHANGELOG.md](CHANGELOG.md).

## Support

See [DONATE.md](DONATE.md) if you want to buy me a coffee.
