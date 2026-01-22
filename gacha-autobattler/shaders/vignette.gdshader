shader_type canvas_item;

uniform float vignette_intensity : hint_range(0.0, 1.0) = 0.4;
uniform float vignette_opacity : hint_range(0.0, 1.0) = 0.5;
uniform vec4 vignette_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float vignette_softness : hint_range(0.0, 1.0) = 0.5;

void fragment() {
	// Calculate vignette based on UV position
	vec2 uv = UV - 0.5;
	float dist = length(uv * vec2(1.0, 0.75)); // Oval shape

	// Smooth vignette falloff
	float vignette = smoothstep(vignette_intensity - vignette_softness, vignette_intensity, dist);

	// Output dark edges with transparency
	COLOR = vec4(vignette_color.rgb, vignette * vignette_opacity);
}
