shader_type spatial;
render_mode unshaded, cull_disabled;
uniform sampler2D albedo_texture : source_color, filter_nearest, repeat_enable;
varying vec3 world_normal;
void vertex() {
    world_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
}
void fragment() {
    vec3 base = texture(albedo_texture, UV).rgb;
    float light = dot(normalize(world_normal), normalize(vec3(-0.6, 0.8, 0.5)));
    float shade = light < 0.05 ? 0.78 : 1.0;
    ALBEDO = base * shade;
}
