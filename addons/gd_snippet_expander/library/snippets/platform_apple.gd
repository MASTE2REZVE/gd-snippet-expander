@tool
extends RefCounted


func get_data() -> Dictionary:
	return {
		"version": 2,
		"snippets": {
			"apple_detect": {
				"phrases": ["ios detect", "macos detect", "apple platform", "check ios macos"],
				"code": """enum ApplePlatform { NONE, IOS, MACOS, TVOS }

func get_apple_platform() -> int:
	var name := OS.get_name()
	match name:
		"iOS":
			return ApplePlatform.IOS
		"macOS":
			return ApplePlatform.MACOS
		_:
			return ApplePlatform.NONE

func is_ios() -> bool:
	return OS.get_name() == "iOS"

func is_macos() -> bool:
	return OS.get_name() == "macOS"

func is_apple() -> bool:
	return is_ios() or is_macos()

func is_desktop_apple() -> bool:
	return is_macos()

func is_mobile_apple() -> bool:
	return is_ios()

func get_apple_version_string() -> String:
	if not is_apple():
		return ""
	return OS.get_version()
""",
				"params": [],
				"category": "platform",
				"subcategory": "apple",
				"platforms": ["mobile", "desktop"],
				"dimension": "any",
				"difficulty": "beginner",
				"details": {
					"what": "Detects iOS and macOS separately from the general mobile/desktop categories. Useful when you need Apple-specific behavior (store APIs, native dialogs).",
					"where": "Add to a game manager or autoload. Combine with platform_detect for the higher-level view.",
					"before": "None.",
					"after": "Use is_ios() to gate iOS-specific UI, is_macos() for Mac-specific keyboard shortcuts (Cmd instead of Ctrl).",
					"why_optimized": "OS.get_name is a cached string. String comparison on a match statement is O(1).",
					"mistakes": "Using OS.has_feature('mobile') alone doesn't tell you if it's iOS. iOS and Android both report mobile. Use OS.get_name() for Apple-specific checks.",
					"related": ["platform_detect", "ios_safe_area_helper", "macos_native_fullscreen", "apple_export_tips"]
				}
			},
			"ios_safe_area_helper": {
				"phrases": ["ios safe area", "dynamic island", "home indicator", "iphone safe area"],
				"code": """extends Control

# iOS-specific safe area handling. Dynamic Island, notch, and home
# indicator inset the safe area far more than Android notches.

@export var extra_top_margin: float = 0.0
@export var extra_bottom_margin: float = 0.0

func _ready() -> void:
	apply_ios_safe_area()
	get_tree().root.size_changed.connect(apply_ios_safe_area)

func apply_ios_safe_area() -> void:
	var safe := DisplayServer.get_display_safe_area()
	var window := DisplayServer.window_get_size()
	if window.x <= 0 or window.y <= 0:
		return
	var scale_factor: Vector2 = Vector2(get_viewport_rect().size) / Vector2(window)
	var safe_pos: Vector2 = Vector2(safe.position) * scale_factor
	var safe_size: Vector2 = Vector2(safe.size) * scale_factor
	# On iOS, add extra top margin for Dynamic Island and extra bottom
	# margin for the home indicator — both are slightly deeper than the
	# raw safe area reports on older OS versions.
	position = safe_pos + Vector2(0, extra_top_margin)
	size = safe_size - Vector2(0, extra_top_margin + extra_bottom_margin)

func get_home_indicator_height() -> float:
	# Rough estimate for iPhone home indicator in points. Multiplied by
	# the display scale to get pixels.
	if not OS.get_name() == "iOS":
		return 0.0
	var screen_scale := DisplayServer.screen_get_scale()
	return 34.0 * float(screen_scale)

func get_dynamic_island_height() -> float:
	if not OS.get_name() == "iOS":
		return 0.0
	var screen_scale := DisplayServer.screen_get_scale()
	return 59.0 * float(screen_scale)
""",
				"params": ["extra_top_margin", "extra_bottom_margin"],
				"category": "platform",
				"subcategory": "apple",
				"platforms": ["mobile"],
				"dimension": "ui",
				"difficulty": "intermediate",
				"param_info": {
					"extra_top_margin": {
						"default": 0.0,
						"range": [0.0, 100.0],
						"what": "Extra padding above the safe area, in pixels.",
						"typical": "0 default / 20 for Dynamic Island phones / 40 very cautious",
						"increase": "More padding at top.",
						"decrease": "Less."
					},
					"extra_bottom_margin": {
						"default": 0.0,
						"range": [0.0, 100.0],
						"what": "Extra padding below the safe area, in pixels.",
						"typical": "0 default / 20 above home indicator / 40 for touch-heavy games",
						"increase": "More padding at bottom.",
						"decrease": "Less."
					}
				},
				"details": {
					"what": "Safe area adjustment tuned for iOS. The Dynamic Island on iPhone 14+ extends deeper than the raw safe area reports, and the home indicator needs a bit of extra room at the bottom.",
					"where": "Attach to the root Control of your HUD. Same role as safe_area_ui but with iOS-specific defaults.",
					"before": "iOS export. Test on a real device or simulator — the desktop preview doesn't show safe areas.",
					"after": "On Android or desktop, this still runs but the extra margins default to 0, so it behaves like the generic safe_area_ui snippet.",
					"why_optimized": "Only recalculates on viewport resize. Uses DisplayServer.screen_get_scale to convert from logical points to pixels.",
					"mistakes": "Hardcoding the Dynamic Island dimensions in pixels without multiplying by screen scale produces wrong padding on different iPhone models.",
					"related": ["safe_area_ui", "apple_detect", "platform_detect"]
				}
			},
			"macos_native_fullscreen": {
				"phrases": ["macos fullscreen", "mac native fullscreen", "mac fullscreen button", "green button fullscreen"],
				"code": """extends Node

# macOS supports two fullscreen modes:
#   WINDOW_MODE_FULLSCREEN          — borderless window covering the screen
#   WINDOW_MODE_EXCLUSIVE_FULLSCREEN — native macOS fullscreen (green button)
#
# The native version plays nicer with Mission Control, Stage Manager,
# and external displays. On Windows and Linux only the borderless mode
# is available.

func enter_native_fullscreen() -> void:
	if OS.get_name() == "macOS":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

func exit_fullscreen() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func is_in_fullscreen() -> bool:
	var mode := DisplayServer.window_get_mode()
	return mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN

func is_native_fullscreen() -> bool:
	return DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN

func toggle_fullscreen() -> void:
	if is_in_fullscreen():
		exit_fullscreen()
	else:
		enter_native_fullscreen()
""",
				"params": [],
				"category": "platform",
				"subcategory": "apple",
				"platforms": ["desktop"],
				"dimension": "any",
				"difficulty": "beginner",
				"details": {
					"what": "Fullscreen toggle that uses native macOS fullscreen on Mac and borderless fullscreen elsewhere. Native mode integrates with Mission Control and Spaces.",
					"where": "Add to a settings menu or an autoload named 'Display'.",
					"before": "None.",
					"after": "Save the fullscreen state in settings_save and restore on next launch.",
					"why_optimized": "One DisplayServer call. Feature check happens once per toggle, not per frame.",
					"mistakes": "Using EXCLUSIVE_FULLSCREEN on Windows is not supported — the fallback to regular FULLSCREEN handles this automatically.",
					"related": ["fullscreen_toggle", "apple_detect", "settings_save", "options_menu"]
				}
			},
			"apple_export_tips": {
				"phrases": ["apple export", "ios export", "macos export", "apple notarization", "ios provisioning"],
				"code": """# Apple export checklist for Godot 4 games.
#
# iOS
# ---
# 1. Requires an Apple Developer account ($99/year).
# 2. Enable 'iOS' export template in Editor -> Manage Export Templates.
# 3. In Project -> Export -> iOS:
#      - Bundle Identifier: com.yourcompany.yourgame
#      - Team ID: your 10-character Apple Team ID
#      - Signing: Automatic (recommended) or Manual
# 4. Export produces a .ipa or .xcworkspace.
# 5. Use Xcode to build and deploy to a device or the App Store.
#
# Touch input works out of the box — no extra setup. Use the
# touch_controls.gd snippets for on-screen joysticks and buttons.
# Safe area matters more on iOS: enable ios_safe_area_helper.
#
# macOS
# -----
# 1. No developer account required for personal use.
# 2. Enable 'macOS' export template.
# 3. In Project -> Export -> macOS:
#      - Bundle Identifier: com.yourcompany.yourgame
#      - Codesign: for distribution via the Mac App Store
#      - Notarization: for direct distribution (Apple checks it)
# 4. Without notarization, users see "unidentified developer" warning.
# 5. Notarization requires an Apple Developer account.
#
# Universal binary (Intel + Apple Silicon)
# ----------------------------------------
# Godot's macOS export template is universal by default in 4.4+.
# No extra configuration needed.
#
# Common gotchas
# --------------
# - iOS builds can't be tested on the desktop preview. Real device or
#   simulator required.
# - High-DPI Retina displays: set Stretch Mode to canvas_items and
#   aspect to expand. Set Render Scale to 1.0 or 2.0 for crispness.
# - The green button on macOS title bars is native fullscreen, which
#   pauses the game in some Godot versions. Handle with
#   NOTIFICATION_WM_WINDOW_FOCUS_OUT.
# - iOS silent switch mutes game audio by default. If your game needs
#   audio despite the switch, that's a native plugin, not Godot.
""",
				"params": [],
				"category": "platform",
				"subcategory": "apple",
				"platforms": ["mobile", "desktop"],
				"dimension": "any",
				"difficulty": "intermediate",
				"details": {
					"what": "Comment-only reference for exporting Godot games to iOS and macOS. Covers developer accounts, export settings, code signing, notarization, and common gotchas.",
					"where": "Read before starting an Apple export. Nothing to attach.",
					"before": "None.",
					"after": "For app store submission, read Apple's Human Interface Guidelines separately — they cover UI conventions beyond what Godot provides.",
					"why_optimized": "N/A — this is documentation, not code.",
					"mistakes": "Assuming the desktop preview matches iOS behavior. Safe areas, notch handling, silent switch, and touch input all behave differently on device.",
					"related": ["apple_detect", "ios_safe_area_helper", "macos_native_fullscreen", "platform_detect"]
				}
			}
		}
	}
