shader_type spatial;
render_mode unshaded, cull_front, shadows_disabled;
uniform float thickness = 0.014;
uniform vec4 ink : source_color = vec4(0.12, 0.035, 0.19, 1.0);

void vertex() {
	VERTEX += NORMAL * thickness;
}

void fragment() {
	ALBEDO = ink.rgb;
}
