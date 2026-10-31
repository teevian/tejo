shader_type canvas_item;
uniform float eye_open : hint_range(0.0,1.0) = 1.0;
varying vec4 vertex_tint;
// Exact iris ellipses in the original painted atlas: flight, front, profile, rear.
const vec4 EYES[9] = vec4[9](
	vec4(988.0,264.0,12.0,13.0), vec4(1440.0,284.0,11.0,12.0), vec4(1878.0,273.0,12.0,12.0),
	vec4(193.0,623.0,17.0,18.0), vec4(283.0,621.0,17.0,18.0),
	vec4(649.0,621.0,18.0,20.0), vec4(716.0,616.0,5.0,13.0),
	vec4(1072.0,619.0,13.0,19.0), vec4(1458.0,628.0,5.0,14.0)
);
void vertex() { vertex_tint = COLOR; }
void fragment() {
	vec4 paint = texture(TEXTURE,UV);
	vec2 atlas_size = 1.0/TEXTURE_PIXEL_SIZE;
	vec2 pixel = UV*atlas_size;
	for (int i=0; i<9; i++) {
		vec2 p = (pixel-EYES[i].xy)/EYES[i].zw;
		float radius = length(p);
		if (radius>1.15) { continue; }
		float edge = 1.0-smoothstep(1.0,1.15,radius);
		// Preserve the original dark pupil, catchlight and painted iris texture.
		float iris = smoothstep(0.46,0.67,radius)*(1.0-smoothstep(0.90,1.05,radius));
		vec3 gold = vec3(0.86,0.69,0.22)*(0.78+paint.r*0.35);
		paint.rgb = mix(paint.rgb,gold,iris*0.88);
		// Sample neighboring brow feathers to close the lid without a flat paint patch.
		vec2 lid_pixel = EYES[i].xy+vec2(p.x*EYES[i].z,-EYES[i].w*1.42+p.y*2.0);
		vec3 lid = texture(TEXTURE,lid_pixel/atlas_size).rgb;
		float crease = (1.0-smoothstep(0.04,0.13,abs(p.y-0.1*(p.x*p.x-1.0))))*(1.0-smoothstep(0.75,0.95,abs(p.x)));
		lid *= 1.0-crease*0.7;
		float closed = (1.0-smoothstep(0.0,0.12,eye_open))+smoothstep(eye_open,eye_open+0.10,abs(p.y))*(1.0-eye_open);
		paint.rgb = mix(paint.rgb,lid,clamp(closed,0.0,1.0)*edge);
	}
	COLOR = vertex_tint*paint;
}
