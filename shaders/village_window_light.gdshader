shader_type canvas_item;
render_mode unshaded;
uniform float amount = 0.0;
void fragment() {
	vec4 original = texture(TEXTURE, UV);
	float luma = dot(original.rgb, vec3(0.3,0.5,0.2));
	// Paint only the dark glass; retain the original pale mullions and stone frame.
	float glass = 1.0 - smoothstep(0.34,0.68,luma);
	vec3 warm = mix(vec3(1.0,0.69,0.29),original.rgb,0.12);
	COLOR = vec4(warm,glass*amount*original.a);
}
