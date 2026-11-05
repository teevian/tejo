shader_type canvas_item;
render_mode unshaded;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform vec4 daylight : source_color = vec4(1.0);
uniform vec2 local_light_center = vec2(0.5);
uniform vec2 local_light_radius = vec2(1.0);
uniform float local_light_amount = 0.0;
void fragment() {
	float distance_to_bar = length((SCREEN_UV - local_light_center) / max(local_light_radius, vec2(0.001)));
	float warm_pool = (1.0 - smoothstep(0.18, 1.0, distance_to_bar)) * local_light_amount;
	vec3 grade = mix(daylight.rgb, vec3(0.94, 0.79, 0.61), warm_pool);
	COLOR = vec4(texture(screen_texture, SCREEN_UV).rgb * grade, 1.0);
}
