shader_type canvas_item;

uniform float ray_intensity : hint_range(0.0, 1.0) = 0.15;
uniform float ray_speed : hint_range(0.0, 2.0) = 0.3;
uniform vec4 ray_color : source_color = vec4(1.0, 0.9, 0.7, 1.0);
uniform float ray_count : hint_range(1.0, 20.0) = 6.0;
uniform vec2 ray_origin = vec2(0.5, 0.0);

void fragment() {
	vec2 uv = UV - ray_origin;
	float angle = atan(uv.y, uv.x);
	float dist = length(uv);

	// Create rays
	float rays = sin(angle * ray_count + TIME * ray_speed) * 0.5 + 0.5;
	rays = pow(rays, 3.0); // Sharpen rays

	// Fade rays with distance from origin
	float fade = 1.0 - smoothstep(0.0, 1.2, dist);
	fade *= smoothstep(0.0, 0.3, dist); // Fade near center too

	// Vertical fade (rays come from top)
	fade *= 1.0 - UV.y;

	float intensity = rays * fade * ray_intensity;

	COLOR = vec4(ray_color.rgb, intensity);
}
