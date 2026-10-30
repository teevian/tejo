shader_type canvas_item;
render_mode unshaded;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform vec4 daylight : source_color = vec4(1.0);
void fragment() {
	COLOR = vec4(texture(screen_texture, SCREEN_UV).rgb * daylight.rgb, 1.0);
}
