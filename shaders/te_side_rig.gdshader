shader_type canvas_item;
varying vec4 piece_tint;
void vertex() {
	piece_tint = COLOR;
}
float warm_skin(vec3 c) {
	return smoothstep(0.25,0.35,c.r)*smoothstep(0.12,0.20,(c.r-c.g)/max(c.r,0.001));
}
void fragment() {
	vec4 paint = texture(TEXTURE,UV);
	float alpha = smoothstep(0.02,0.12,paint.a);
	// Forearm polygons overlap the old shorts in the source photograph.
	// Clip cloth by hue without changing the approved painted skin itself.
	if (piece_tint.a<0.5) {
		float skin = warm_skin(paint.rgb);
		alpha *= skin;
	}
	COLOR = vec4(paint.rgb*piece_tint.rgb,alpha);
}
