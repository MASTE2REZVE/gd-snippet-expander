@tool
extends RefCounted


func get_data() -> Dictionary:
	return {
		"version": 2,
		"snippets": {
			"shader_dissolve": {
				"phrases": ["dissolve shader", "dissolve effect", "burn away", "fade dissolve"],
				"code": """// Save as: dissolve.gdshader
// Attach via: Sprite2D.material -> New ShaderMaterial -> Shader

shader_type canvas_item;

uniform float dissolve_amount : hint_range(0.0, 1.0) = 0.0;
uniform vec4 edge_color : source_color = vec4(1.0, 0.5, 0.0, 1.0);
uniform float edge_width : hint_range(0.0, 0.2) = 0.05;
uniform sampler2D noise_texture : hint_default_white;

void fragment() {
	float noise = texture(noise_texture, UV).r;
	float edge = smoothstep(dissolve_amount, dissolve_amount + edge_width, noise);
	vec4 tex = texture(TEXTURE, UV);
	COLOR = tex;
	COLOR.a *= edge;
	float burn = 1.0 - smoothstep(dissolve_amount - 0.05, dissolve_amount, noise);
	COLOR.rgb = mix(COLOR.rgb, edge_color.rgb, burn);
}
""",
				"params": ["dissolve_amount", "edge_color", "edge_width"],
				"category": "shader",
				"subcategory": "effect",
				"dimension": "2d",
				"difficulty": "intermediate",
				"param_info": {
					"dissolve_amount": {
						"default": 0.0,
						"range": [0.0, 1.0],
						"what": "How much of the sprite has dissolved. 0 is intact, 1 is gone.",
						"typical": "0.0 visible / animate 0 to 1 to dissolve",
						"increase": "More of the sprite disappears.",
						"decrease": "Less of it disappears."
					},
					"edge_color": {
						"default": [1.0, 0.5, 0.0, 1.0],
						"range": [],
						"what": "Color of the glowing edge as the sprite dissolves.",
						"typical": "orange fire / red blood / purple magic / white clean",
						"increase": "N/A",
						"decrease": "N/A"
					},
					"edge_width": {
						"default": 0.05,
						"range": [0.0, 0.2],
						"what": "Thickness of the glowing edge.",
						"typical": "0.02 thin / 0.05 standard / 0.1 thick",
						"increase": "Bigger burning edge.",
						"decrease": "Sharper cutoff."
					}
				},
				"details": {
					"what": "Dissolves a sprite using a noise texture. Great for death, teleport, and pickup effects.",
					"where": "Create a ShaderMaterial, assign to Sprite2D.material, point the shader at this file. Then animate 'dissolve_amount' via a Tween.",
					"before": "You need a noise texture. Enable NoiseTexture2D in the material's noise_texture slot (default is white which works).",
					"after": "Tween the dissolve_amount: var t := create_tween(); t.tween_method(func(v): material.set_shader_parameter('dissolve_amount', v), 0.0, 1.0, 0.8)",
					"why_optimized": "Single-pass fragment shader, one texture lookup for noise, one for the sprite.",
					"mistakes": "Setting the material on the CanvasItem's material slot instead of the Sprite2D's material slot makes it affect children too.",
					"related": ["shader_flash", "shader_outline", "particle_explosion"]
				}
			},
			"shader_flash": {
				"phrases": ["flash shader", "damage flash", "white flash", "hit flash"],
				"code": """// Save as: flash.gdshader

shader_type canvas_item;

uniform vec4 flash_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float flash_amount : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	COLOR = tex;
	COLOR.rgb = mix(COLOR.rgb, flash_color.rgb, flash_amount);
	COLOR.a = tex.a;
}
""",
				"params": ["flash_color", "flash_amount"],
				"category": "shader",
				"subcategory": "effect",
				"dimension": "2d",
				"difficulty": "beginner",
				"param_info": {
					"flash_color": {
						"default": [1, 1, 1, 1],
						"range": [],
						"what": "Color to flash the sprite toward.",
						"typical": "white damage / red fire / blue ice / green poison",
						"increase": "N/A",
						"decrease": "N/A"
					},
					"flash_amount": {
						"default": 0.0,
						"range": [0.0, 1.0],
						"what": "How strong the flash is. 0 is normal, 1 is fully colored.",
						"typical": "0.0 idle / flash 0.8 then back to 0.0 over 0.15s",
						"increase": "Stronger flash.",
						"decrease": "Weaker flash."
					}
				},
				"details": {
					"what": "Tints a sprite toward a color. The classic damage-feedback effect.",
					"where": "Assign the material to Sprite2D.material. Tween flash_amount.",
					"before": "None.",
					"after": "On hit: var t := create_tween(); t.tween_method(func(v): material.set_shader_parameter('flash_amount', v), 0.9, 0.0, 0.15)",
					"why_optimized": "mix() is a single hardware instruction. Zero cost.",
					"mistakes": "Setting flash_amount to 1.0 permanently makes the sprite solid color. Always tween back to 0.",
					"related": ["shader_dissolve", "shader_outline", "health_system"]
				}
			},
			"shader_outline": {
				"phrases": ["outline shader", "sprite outline", "border effect"],
				"code": """// Save as: outline.gdshader

shader_type canvas_item;

uniform vec4 outline_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float outline_size : hint_range(0.0, 8.0) = 2.0;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	vec2 size = TEXTURE_PIXEL_SIZE * outline_size;
	float a = tex.a;
	a = max(a, texture(TEXTURE, UV + vec2(-size.x, 0.0)).a);
	a = max(a, texture(TEXTURE, UV + vec2( size.x, 0.0)).a);
	a = max(a, texture(TEXTURE, UV + vec2(0.0, -size.y)).a);
	a = max(a, texture(TEXTURE, UV + vec2(0.0,  size.y)).a);
	a = max(a, texture(TEXTURE, UV + size).a);
	a = max(a, texture(TEXTURE, UV - size).a);
	a = max(a, texture(TEXTURE, UV + vec2(size.x, -size.y)).a);
	a = max(a, texture(TEXTURE, UV + vec2(-size.x, size.y)).a);
	vec4 final;
	if (tex.a > 0.1) {
		final = tex;
	} else {
		final = vec4(outline_color.rgb, outline_color.a * a);
	}
	COLOR = final;
}
""",
				"params": ["outline_color", "outline_size"],
				"category": "shader",
				"subcategory": "effect",
				"dimension": "2d",
				"difficulty": "intermediate",
				"param_info": {
					"outline_color": {
						"default": [0, 0, 0, 1],
						"range": [],
						"what": "Color of the outline.",
						"typical": "black default / yellow selection / red enemy / cyan highlight",
						"increase": "N/A",
						"decrease": "N/A"
					},
					"outline_size": {
						"default": 2.0,
						"range": [0.0, 8.0],
						"what": "Thickness of the outline in pixels.",
						"typical": "1 thin / 2 standard / 4 thick / 6+ chunky",
						"increase": "Thicker border.",
						"decrease": "Thinner border. Zero disables it."
					}
				},
				"details": {
					"what": "Adds a colored outline around the opaque parts of a sprite.",
					"where": "Assign to Sprite2D.material. Set outline_color and outline_size in the Inspector.",
					"before": "The sprite should have transparent regions around the visible pixels.",
					"after": "Animate outline_size or outline_color for a selection / hit effect.",
					"why_optimized": "Nine texture lookups per pixel — cheap on modern hardware. Uses max() to combine rather than branching.",
					"mistakes": "On very large sprites, thick outlines get expensive. Keep outline_size modest.",
					"related": ["shader_flash", "shader_dissolve", "sprite_hover"]
				}
			},
			"shader_damage_flicker": {
				"phrases": ["damage flicker", "invincibility flicker", "iframes flicker", "hit flicker"],
				"code": """// Save as: flicker.gdshader

shader_type canvas_item;

uniform float flicker_speed : hint_range(1.0, 30.0) = 12.0;
uniform float flicker_strength : hint_range(0.0, 1.0) = 0.5;
uniform float time_offset = 0.0;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	float wave = sin((TIME + time_offset) * flicker_speed);
	float alpha = 1.0 - (flicker_strength * (wave * 0.5 + 0.5));
	COLOR = vec4(tex.rgb, tex.a * alpha);
}
""",
				"params": ["flicker_speed", "flicker_strength"],
				"category": "shader",
				"subcategory": "effect",
				"dimension": "2d",
				"difficulty": "beginner",
				"param_info": {
					"flicker_speed": {
						"default": 12.0,
						"range": [1.0, 30.0],
						"what": "How fast the alpha oscillates.",
						"typical": "6 slow / 12 standard / 20 rapid",
						"increase": "Faster flicker.",
						"decrease": "Slower, more visible pulse."
					},
					"flicker_strength": {
						"default": 0.5,
						"range": [0.0, 1.0],
						"what": "How far the alpha dips. 0 means no flicker.",
						"typical": "0.3 subtle / 0.5 standard / 0.8 strong",
						"increase": "Fades further toward invisible.",
						"decrease": "Less noticeable."
					}
				},
				"details": {
					"what": "Makes a sprite flicker between visible and semi-transparent. Standard invincibility feedback.",
					"where": "Assign to Sprite2D.material. Enable the shader only during invincibility (via material or set_shader_parameter).",
					"before": "None.",
					"after": "Toggle visibility of the material, or tween flicker_strength from 0.5 to 0 when invincibility ends.",
					"why_optimized": "sin() is one GPU instruction. No branching.",
					"mistakes": "Leaving the shader on permanently makes the sprite pulse forever. Disable it after invincibility ends.",
					"related": ["shader_flash", "invincibility_frames", "shader_dissolve"]
				}
			},
			"shader_crt": {
				"phrases": ["crt shader", "retro tv", "scanline effect", "old tv shader"],
				"code": """// Save as: crt.gdshader
// Apply to a full-screen ColorRect in a CanvasLayer at layer 100.

shader_type canvas_item;

uniform float scanline_count : hint_range(100.0, 1200.0) = 400.0;
uniform float scanline_strength : hint_range(0.0, 0.5) = 0.1;
uniform float curvature : hint_range(0.0, 0.3) = 0.05;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.4;
uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 centered = uv * 2.0 - 1.0;
	centered *= 1.0 + curvature * dot(centered, centered);
	vec2 curved_uv = centered * 0.5 + 0.5;
	if (curved_uv.x < 0.0 || curved_uv.x > 1.0 || curved_uv.y < 0.0 || curved_uv.y > 1.0) {
		COLOR = vec4(0.0, 0.0, 0.0, 1.0);
	} else {
		vec3 col = texture(screen_texture, curved_uv).rgb;
		float scan = sin(curved_uv.y * scanline_count) * 0.5 + 0.5;
		col *= 1.0 - scanline_strength * scan;
		float d = length(centered);
		col *= 1.0 - vignette_strength * smoothstep(0.5, 1.2, d);
		COLOR = vec4(col, 1.0);
	}
}
""",
				"params": ["scanline_count", "scanline_strength", "curvature", "vignette_strength"],
				"category": "shader",
				"subcategory": "screen",
				"dimension": "any",
				"difficulty": "intermediate",
				"param_info": {
					"scanline_count": {
						"default": 400.0,
						"range": [100.0, 1200.0],
						"what": "How many scanlines across the screen vertically.",
						"typical": "250 chunky / 400 standard / 800 fine",
						"increase": "More, thinner scanlines.",
						"decrease": "Fewer, thicker scanlines."
					},
					"scanline_strength": {
						"default": 0.1,
						"range": [0.0, 0.5],
						"what": "How dark the scanlines get.",
						"typical": "0.05 subtle / 0.1 standard / 0.25 heavy",
						"increase": "More prominent scanlines.",
						"decrease": "Fainter."
					},
					"curvature": {
						"default": 0.05,
						"range": [0.0, 0.3],
						"what": "How much the screen bulges like a tube TV.",
						"typical": "0.03 subtle / 0.05 standard / 0.15+ extreme",
						"increase": "More barrel distortion.",
						"decrease": "Flatter screen."
					},
					"vignette_strength": {
						"default": 0.4,
						"range": [0.0, 1.0],
						"what": "How dark the corners get.",
						"typical": "0.2 subtle / 0.4 standard / 0.7 moody",
						"increase": "Darker corners.",
						"decrease": "Brighter edges."
					}
				},
				"details": {
					"what": "Full-screen CRT effect: scanlines, barrel distortion, vignette.",
					"where": "Add a CanvasLayer at layer 100 with a full-size ColorRect. Assign a ShaderMaterial with this shader to the ColorRect.",
					"before": "The ColorRect must cover the full viewport. Set its anchors to fill.",
					"after": "Animate scanline_strength for a degauss effect, or curvature for a menu transition.",
					"why_optimized": "Single fullscreen pass. Screen texture is read once.",
					"mistakes": "Forgetting to enable 'Use Screen Texture' won't cause an error but produces a black screen. Set it in the material.",
					"related": ["shader_dissolve", "fade_in_ui", "debug_overlay"]
				}
			},
			"shader_wave": {
				"phrases": ["wave shader", "water distortion", "heat haze shader", "underwater effect"],
				"code": """// Save as: wave.gdshader

shader_type canvas_item;

uniform float wave_amplitude : hint_range(0.0, 0.1) = 0.01;
uniform float wave_frequency : hint_range(1.0, 50.0) = 10.0;
uniform float wave_speed : hint_range(0.0, 5.0) = 2.0;

void vertex() {
	VERTEX.y += sin(UV.x * wave_frequency + TIME * wave_speed) * wave_amplitude * 100.0;
}

void fragment() {
	COLOR = texture(TEXTURE, UV);
}
""",
				"params": ["wave_amplitude", "wave_frequency", "wave_speed"],
				"category": "shader",
				"subcategory": "effect",
				"dimension": "2d",
				"difficulty": "beginner",
				"param_info": {
					"wave_amplitude": {
						"default": 0.01,
						"range": [0.0, 0.1],
						"what": "How far the surface moves up and down.",
						"typical": "0.005 subtle / 0.01 standard / 0.05 extreme",
						"increase": "Bigger waves.",
						"decrease": "Flatter."
					},
					"wave_frequency": {
						"default": 10.0,
						"range": [1.0, 50.0],
						"what": "How many waves fit across the width.",
						"typical": "5 broad / 10 standard / 30 ripples",
						"increase": "More, tighter waves.",
						"decrease": "Fewer, wider waves."
					},
					"wave_speed": {
						"default": 2.0,
						"range": [0.0, 5.0],
						"what": "How fast the waves scroll.",
						"typical": "1 gentle / 2 standard / 4 fast",
						"increase": "Faster scroll.",
						"decrease": "Slower."
					}
				},
				"details": {
					"what": "Distorts a sprite's vertices with a sine wave. Water, banners, jelly enemies.",
					"where": "Assign to Sprite2D.material.",
					"before": "None.",
					"after": "For a horizontal wave instead, add VERTEX.x += sin(UV.y * ...) * ...",
					"why_optimized": "vertex() runs per-vertex, not per-pixel. Very cheap.",
					"mistakes": "Very large amplitude on a low-poly quad causes visible triangles. Use more subdivisions on PlaneMesh or a higher-resolution sprite.",
					"related": ["shader_dissolve", "shader_outline", "camera_shake"]
				}
			}
		}
	}
