shader_type canvas_item;
render_mode unshaded;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;
uniform float dream : hint_range(0.0,1.0) = 0.0;
uniform float depth : hint_range(0.0,1.0) = 0.0;
uniform float dream_time = 0.0;
uniform float energy = 0.0;
uniform float bass = 0.0;
uniform float air = 0.0;
uniform float beat = 0.0;
uniform float track_variant = 0.0;

float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float line(float d, float width) { return exp(-abs(d)/width); }

void fragment() {
	vec2 uv = SCREEN_UV;
	float aspect = SCREEN_PIXEL_SIZE.y/SCREEN_PIXEL_SIZE.x;
	float variant = track_variant;
	float t = dream_time*mix(1.0,0.68,variant);
	float immersion = dream*(0.20+depth*0.80);
	vec2 drift = vec2(sin(uv.y*13.0+t*0.18),cos(uv.x*11.0-t*0.14));
	float periphery = smoothstep(0.17,0.63,length(uv-0.5));
	vec2 sample_uv = clamp(uv+drift*immersion*(0.0025+depth*0.0035+beat*0.0008)*mix(1.0,0.8,variant),vec2(0.001),vec2(0.999));
	vec3 original = texture(screen_texture,uv).rgb;
	vec3 paint = texture(screen_texture,sample_uv).rgb;
	vec2 fringe = vec2(SCREEN_PIXEL_SIZE.x*(1.0+depth*3.5),0.0)*immersion*periphery;
	paint.r = mix(paint.r,texture(screen_texture,clamp(sample_uv+fringe,vec2(0.001),vec2(0.999))).r,depth*0.5);
	paint.b = mix(paint.b,texture(screen_texture,clamp(sample_uv-fringe,vec2(0.001),vec2(0.999))).b,depth*0.5);
	vec2 radius = SCREEN_PIXEL_SIZE*(3.0+depth*5.0);
	vec3 glow = texture(screen_texture,sample_uv+radius*vec2(1.0,1.0)).rgb;
	glow += texture(screen_texture,sample_uv+radius*vec2(-1.0,1.0)).rgb;
	glow += texture(screen_texture,sample_uv+radius*vec2(1.0,-1.0)).rgb;
	glow += texture(screen_texture,sample_uv-radius).rgb;
	glow *= 0.25;
	float luminance = dot(paint,vec3(0.2126,0.7152,0.0722));
	float wash = 0.5+0.5*sin(uv.x*4.0+uv.y*2.2+t*0.055);
	vec3 lilac = mix(vec3(0.17,0.07,0.32),vec3(0.07,0.22,0.35),wash);
	vec3 neon_mid = mix(vec3(0.68,0.26,0.66),vec3(0.21,0.73,0.79),wash);
	vec3 rose = mix(vec3(1.0,0.70,0.88),vec3(0.63,0.98,0.98),wash);
	lilac = mix(lilac,mix(vec3(0.10,0.09,0.35),vec3(0.25,0.09,0.39),wash),variant);
	neon_mid = mix(neon_mid,mix(vec3(0.37,0.44,0.91),vec3(0.82,0.39,0.73),wash),variant);
	rose = mix(rose,mix(vec3(0.71,0.83,1.0),vec3(1.0,0.79,0.65),wash),variant);
	vec3 palette = mix(lilac,neon_mid,smoothstep(0.02,0.56,luminance));
	palette = mix(palette,rose,smoothstep(0.42,0.94,luminance));
	vec3 graded = mix(mix(paint,glow,depth*0.16),palette,0.20+depth*0.58);
	graded *= mix(vec3(1.07,0.93,1.10),vec3(0.92,1.05,1.12),wash);
	graded += max(glow-vec3(0.38),vec3(0.0))*(0.16+depth*0.35+beat*0.12);
	// Broad flowing aurora, colour following the song's energy rather than flashing.
	float ribbon = uv.y-(0.36+sin(uv.x*5.0+t*0.10)*0.12);
	float ribbon2 = uv.y-(0.62+cos(uv.x*4.0-t*0.08)*0.15);
	vec3 haze = vec3(0.70,0.18,0.66)*exp(-ribbon*ribbon*15.0);
	haze += vec3(0.10,0.66,0.79)*exp(-ribbon2*ribbon2*19.0);
	graded += haze*(0.02+depth*0.15)*(0.65+energy*0.35);
	float silk = exp(-abs(ribbon)*170.0)+exp(-abs(ribbon2)*150.0);
	graded += mix(vec3(0.80,0.28,0.82),vec3(0.24,0.91,1.0),wash)*silk*depth*(0.08+beat*0.10);
	// The second song carries broad radial waves and diagonal curtains of light.
	vec2 radial = (uv-vec2(0.5,0.54))*vec2(aspect,1.0);
	float radius_wave = length(radial);
	float ripple = pow(0.5+0.5*sin(radius_wave*39.0-t*1.8),10.0);
	float curtain = pow(0.5+0.5*sin(uv.x*9.0+uv.y*3.0+sin(uv.y*5.0+t*0.14)*1.9-t*0.21),8.0);
	vec3 second_light = mix(vec3(0.32,0.49,1.0),vec3(1.0,0.54,0.80),wash);
	graded += second_light*(ripple*(0.035+beat*0.09)+curtain*(0.035+bass*0.065))*variant*depth;
	// Sparse drifting lights and soft bokeh become visible deeper into the track.
	vec2 stars = uv*vec2(24.0*aspect,24.0)+vec2(t*0.035,-t*0.075);
	vec2 cell = floor(stars);
	vec2 spot = fract(stars)-vec2(hash(cell),hash(cell+17.7));
	float seed = hash(cell+41.0);
	float star = exp(-dot(spot,spot)*420.0)*step(0.94,seed);
	float halo = exp(-dot(spot,spot)*14.0)*step(0.96,seed);
	vec3 neon = mix(vec3(0.22,0.95,1.0),vec3(1.0,0.35,0.74),seed);
	graded += neon*(star*(0.38+beat*0.45)+halo*(0.11+bass*0.09+air*0.03))*depth;
	// Quiet neon contours and a receding grid at the edges of the dream.
	float edge = length(uv-0.5);
	float lower = smoothstep(0.60,0.98,uv.y);
	float perspective = 1.0/max(0.17,uv.y-0.41);
	float gx = abs(fract((uv.x-0.5)*perspective*4.0)-0.5);
	float gy = abs(fract(perspective*1.7+t*0.07)-0.5);
	float grid = max(line(gx,0.012),line(gy,0.016))*lower;
	graded += vec3(0.22,0.63,0.95)*grid*depth*(0.14+beat*0.15);
	vec2 centred = (uv-vec2(0.5,0.56))*vec2(aspect,1.0);
	float ring = line(length(centred)-(0.33+0.02*sin(t*0.15)),0.0025);
	graded += vec3(0.75,0.35,0.94)*ring*beat*depth*0.11;
	graded *= 1.0-smoothstep(0.28,0.77,edge)*depth*0.10;
	COLOR = vec4(mix(original,graded,immersion),1.0);
}
