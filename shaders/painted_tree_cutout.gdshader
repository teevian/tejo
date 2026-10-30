shader_type canvas_item;
uniform sampler2D tree_mask : filter_linear;
void fragment() {
 vec4 paint = texture(TEXTURE,UV);
 vec4 mask = texture(tree_mask,UV);
 // The vector mask protects bark. Foliage colour only fills the canopy regions;
 // orange/brown soil and neutral ground pebbles stay in the ground layer.
 float green = paint.g-max(paint.r*0.92,paint.b*0.80);
 float chroma = max(paint.r,max(paint.g,paint.b))-min(paint.r,min(paint.g,paint.b));
 float leaf = smoothstep(-0.006,0.018,green)*smoothstep(0.035,0.085,chroma);
 float alpha = max(mask.r,mask.g*leaf)*mask.a;
 COLOR = vec4(paint.rgb,paint.a*alpha);
}
