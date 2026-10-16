shader_type spatial;
render_mode cull_disabled, specular_disabled;
uniform sampler2D albedo_texture : source_color, filter_nearest, repeat_enable;
uniform vec4 tint : source_color = vec4(1.0);
uniform float saturation : hint_range(0.0, 2.0) = 1.4;

void fragment() {
	vec3 base = texture(albedo_texture, UV).rgb * tint.rgb;
	float luminance = dot(base, vec3(0.2126, 0.7152, 0.0722));
	base = clamp(mix(vec3(luminance), base, saturation), vec3(0.0), vec3(1.0));
	ALBEDO = base;
	// Soft colored fill keeps the shadow side readable like painted anime cels.
	EMISSION = base * vec3(0.14, 0.10, 0.17);
	ROUGHNESS = 1.0;
}

void light() {
	float diffuse = max(dot(normalize(NORMAL), normalize(LIGHT)), 0.0);
	float band = diffuse < 0.22 ? 0.10 : (diffuse < 0.6 ? 0.55 : 1.0);
	DIFFUSE_LIGHT += LIGHT_COLOR * ATTENUATION * band / PI;
}
