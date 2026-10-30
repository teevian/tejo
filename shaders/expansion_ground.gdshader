shader_type canvas_item;
uniform bool mirror_x = false;
uniform bool mirror_y = false;
uniform vec2 uv_extent = vec2(1.0);
void fragment() {
 vec2 uv = fract(UV);
 if(mirror_x) uv.x=1.0-uv.x;
 if(mirror_y) uv.y=1.0-uv.y;
 vec4 paint=texture(TEXTURE,uv);
 // Region sprites overscan the source texture. Feather at the real quad edges,
 // including that overscan, so adjacent tiles overlap instead of leaving gaps.
 vec2 local_uv=UV/uv_extent;
 vec2 edge=min(local_uv,vec2(1.0)-local_uv);
 COLOR=vec4(paint.rgb,paint.a*smoothstep(0.0,0.025,min(edge.x,edge.y)));
}
