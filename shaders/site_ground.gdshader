shader_type canvas_item;
void fragment() {
 vec4 paint = texture(TEXTURE,UV);
 vec2 edge = min(UV,vec2(1.0)-UV);
 float blend = smoothstep(0.0,0.045,min(edge.x,edge.y));
 COLOR = vec4(paint.rgb,paint.a*blend);
}
