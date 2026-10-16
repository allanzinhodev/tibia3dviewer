shader_type spatial;
render_mode unshaded, cull_disabled;
uniform sampler2D albedo_texture : source_color, filter_nearest, repeat_enable;
uniform vec4 tint : source_color = vec4(1.0);

void fragment() {
	vec3 base = texture(albedo_texture, UV).rgb * tint.rgb;
	float light = clamp(dot(normalize(NORMAL), normalize(vec3(-0.4, -0.6, 1.0))), 0.0, 1.0);
	float band = floor(light * 3.0) / 3.0;
	ALBEDO = base * (0.65 + 0.35 * band);
}
