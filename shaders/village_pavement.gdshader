shader_type canvas_item;
void fragment() {
	vec4 paint = texture(TEXTURE,UV);
	float stone = dot(paint.rgb,vec3(0.299,0.587,0.114));
	paint.rgb = mix(paint.rgb,vec3(stone)*vec3(1.04,1.02,0.97),0.62);
	COLOR = paint;
}
