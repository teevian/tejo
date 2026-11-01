shader_type canvas_item;
render_mode unshaded;
uniform sampler2D escarpment : filter_linear_mipmap;
uniform float summit_reveal = 0.0;
uniform vec2 view_origin;
uniform vec2 view_size = vec2(1280.0,720.0);
uniform float camera_y = 4000.0;
uniform float yaw = 0.0;
varying vec2 world;
float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float noise(vec2 p) {
	vec2 i=floor(p),f=fract(p); f=f*f*(3.0-2.0*f);
	return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);
}
void vertex() { world=(MODEL_MATRIX*vec4(VERTEX,0.0,1.0)).xy; }
void fragment() {
	vec2 screen=(world-view_origin)/view_size;
	float ascent=clamp((4720.0-camera_y)/3400.0,0.0,1.0);
	// A distant continuous rock face, with slow parallax and no repeated seams.
	vec2 uv=screen*vec2(0.82,0.72)+vec2(0.09+sin(yaw)*0.055,0.04+ascent*0.17+cos(yaw)*0.015);
	vec3 rock=texture(escarpment,uv).rgb;
	rock=mix(rock,vec3(0.37,0.42,0.37),0.10)*0.80;
	float rim=1480.0+sin(world.x*0.012)*22.0+noise(vec2(world.x*0.008,0.0))*50.0;
	float sky=1.0-smoothstep(rim-8.0,rim+10.0,world.y);
	COLOR=vec4(rock,1.0-sky*summit_reveal);
}
