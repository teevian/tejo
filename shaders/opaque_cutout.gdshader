shader_type canvas_item;
// Keep painted surfaces opaque; only silhouette gaps and antialiased edges are clear.
void fragment() {
	vec4 paint = texture(TEXTURE, UV);
	COLOR = vec4(paint.rgb, smoothstep(0.02, 0.12, paint.a));
}
