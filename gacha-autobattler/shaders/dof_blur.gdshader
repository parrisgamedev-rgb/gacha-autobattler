shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform float blur_amount : hint_range(0.0, 5.0) = 1.5;
uniform float focus_center : hint_range(0.0, 1.0) = 0.5;
uniform float focus_range : hint_range(0.0, 1.0) = 0.35;
uniform float blur_curve : hint_range(0.5, 3.0) = 1.5;

void fragment() {
	vec2 uv = SCREEN_UV;

	// Calculate distance from focus center (vertical focus)
	float dist_from_focus = abs(uv.y - focus_center);
	float blur_factor = smoothstep(focus_range * 0.5, focus_range, dist_from_focus);
	blur_factor = pow(blur_factor, blur_curve);

	// Also add slight horizontal edge blur
	float h_dist = abs(uv.x - 0.5) * 0.5;
	float h_blur = smoothstep(0.3, 0.5, h_dist);
	blur_factor = max(blur_factor, h_blur * 0.5);

	float final_blur = blur_amount * blur_factor;

	// Sample with blur
	vec2 pixel_size = 1.0 / vec2(textureSize(SCREEN_TEXTURE, 0));
	vec4 color = vec4(0.0);

	if (final_blur < 0.1) {
		// No blur needed
		color = texture(SCREEN_TEXTURE, uv);
	} else {
		// Box blur with variable kernel based on blur amount
		float total_weight = 0.0;
		int samples = int(ceil(final_blur * 2.0));
		samples = clamp(samples, 1, 4);

		for (int x = -samples; x <= samples; x++) {
			for (int y = -samples; y <= samples; y++) {
				vec2 offset = vec2(float(x), float(y)) * pixel_size * final_blur;
				float weight = 1.0 - length(vec2(x, y)) / float(samples + 1);
				weight = max(weight, 0.0);
				color += texture(SCREEN_TEXTURE, uv + offset) * weight;
				total_weight += weight;
			}
		}
		color /= total_weight;
	}

	COLOR = color;
}
