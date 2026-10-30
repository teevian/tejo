shader_type canvas_item;
void fragment() {
 vec4 paint = texture(TEXTURE, UV);
 COLOR = vec4(paint.rgb * vec3(0.87,0.94,0.91), paint.a * smoothstep(0.0,60.0/3660.0,UV.x));
}
