shader_type canvas_item;
render_mode unshaded;
uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;
uniform float pixel_size : hint_range(1.0, 12.0) = 4.0;
uniform float color_steps : hint_range(3.0, 32.0) = 12.0;
uniform bool enabled = true;

void fragment() {
	vec2 grid = SCREEN_PIXEL_SIZE * pixel_size;
	vec2 uv = (floor(SCREEN_UV / grid) + 0.5) * grid;
	vec3 color = textureLod(screen_texture, enabled ? uv : SCREEN_UV, 0.0).rgb;
	if (enabled) {
		color = floor(color * color_steps + 0.5) / color_steps;
	}
	COLOR = vec4(color, 1.0);
}
