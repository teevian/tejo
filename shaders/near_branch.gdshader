shader_type canvas_item;
// Slight optical softness on nearby branches; opaque interiors stay opaque.
vec4 premultiply_paint(vec4 c) {
 c.a=smoothstep(0.02,0.12,c.a);
 return vec4(c.rgb*c.a,c.a);
}
void fragment() {
 vec2 d=TEXTURE_PIXEL_SIZE*1.1;
 vec4 paint=premultiply_paint(texture(TEXTURE,UV))*0.4;
 paint+=premultiply_paint(texture(TEXTURE,UV+vec2(d.x,0.0)))*0.15;
 paint+=premultiply_paint(texture(TEXTURE,UV-vec2(d.x,0.0)))*0.15;
 paint+=premultiply_paint(texture(TEXTURE,UV+vec2(0.0,d.y)))*0.15;
 paint+=premultiply_paint(texture(TEXTURE,UV-vec2(0.0,d.y)))*0.15;
 COLOR=vec4(paint.rgb/max(paint.a,0.001),paint.a);
}
