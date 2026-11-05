shader_type canvas_item;
// Keep generated cutout alpha clean while retaining colours of chalk, text and water.
void fragment() {
	float source_alpha = texture(TEXTURE, UV).a;
	float tint_alpha = clamp(COLOR.a / max(source_alpha, 0.0001), 0.0, 1.0);
	COLOR = vec4(COLOR.rgb, smoothstep(0.02, 0.12, source_alpha) * tint_alpha);
}
