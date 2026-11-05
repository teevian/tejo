shader_type canvas_item;
// Final atlas alpha contains low-opacity extraction noise outside the painted figures.
// Threshold matches the silhouette measured for UVs; original PNGs remain untouched.
void fragment() {
	vec4 paint = texture(TEXTURE, UV);
	float tint_alpha = clamp(COLOR.a / max(paint.a, 0.0001), 0.0, 1.0);
	COLOR = vec4(paint.rgb, smoothstep(0.35, 0.72, paint.a) * tint_alpha);
}
