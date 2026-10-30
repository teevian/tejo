shader_type canvas_item;
uniform vec2 tile_origin;
uniform bool southern_stream;
uniform bool scenery_surface = false;
void fragment() {
 vec2 sample_uv = UV;
 if (southern_stream) {
  float bend = 0.055 * (1.0-smoothstep(0.0,0.28,UV.y));
  float bank = smoothstep(0.0,0.12,UV.x)*(1.0-smoothstep(0.60,0.90,UV.x));
  sample_uv.x -= bend*bank;
 }
 vec4 paint = texture(TEXTURE,clamp(sample_uv,vec2(0.0),vec2(1.0)));
 vec2 feather = vec2(64.0/2400.0,64.0/1800.0);
 float a=1.0;
 if (!scenery_surface) {
  if (tile_origin.x>0.0) a*=smoothstep(-feather.x,feather.x,UV.x);
  if (tile_origin.x<1.0) a*=1.0-smoothstep(1.0-feather.x,1.0+feather.x,UV.x);
  if (tile_origin.y>0.0) a*=smoothstep(-feather.y,feather.y,UV.y);
  if (tile_origin.y<1.0) a*=1.0-smoothstep(1.0-feather.y,1.0+feather.y,UV.y);
 }
 float damp = tile_origin.x<0.5 && tile_origin.y<0.5 ? 0.26 : 0.0;
 COLOR=vec4(mix(paint.rgb,paint.rgb*vec3(0.73,0.89,0.92),damp),paint.a*a);
}
