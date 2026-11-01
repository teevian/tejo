shader_type spatial;
render_mode cull_back;
uniform sampler2D granite : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec3 tint : source_color = vec3(0.96,0.95,0.89);
uniform float seed = 0.0;
uniform float fragility = 0.0;
varying vec3 stone_position;
varying vec3 stone_normal;

float hash(vec3 p) { return fract(sin(dot(p,vec3(127.1,311.7,74.7)))*43758.5453); }
float noise3(vec3 p) {
	vec3 i=floor(p), f=fract(p); f=f*f*(3.0-2.0*f);
	return mix(mix(mix(hash(i),hash(i+vec3(1,0,0)),f.x),mix(hash(i+vec3(0,1,0)),hash(i+vec3(1,1,0)),f.x),f.y),mix(mix(hash(i+vec3(0,0,1)),hash(i+vec3(1,0,1)),f.x),mix(hash(i+vec3(0,1,1)),hash(i+vec3(1,1,1)),f.x),f.y),f.z);
}
float fbm(vec3 p) { return noise3(p)*0.57+noise3(p*2.07)*0.28+noise3(p*4.13)*0.15; }
vec3 patch(vec2 uv) {
	vec2 warp=vec2(noise3(vec3(uv*0.73,1.0)),noise3(vec3(uv*0.73,7.0)))*0.08;
	return mix(texture(granite,uv+warp).rgb,texture(granite,uv*1.73+vec2(0.37,0.61)).rgb,0.30);
}
void vertex() {
	stone_position=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
	stone_normal=normalize(MODEL_NORMAL_MATRIX*NORMAL);
}
void fragment() {
	vec3 p=stone_position;
	vec3 weights=pow(abs(normalize(stone_normal)),vec3(5.0));
	weights/=max(weights.x+weights.y+weights.z,0.0001);
	vec3 detail=patch(p.zy/180.0)*weights.x+patch(p.xz/180.0)*weights.y+patch(p.xy/180.0)*weights.z;
	float luminosity=dot(detail,vec3(0.299,0.587,0.114));
	detail=mix(vec3(luminosity),detail,0.25);
	float mineral=fbm(p*0.014+vec3(seed));
	vec3 stone=mix(vec3(0.30,0.31,0.30),vec3(0.51,0.52,0.49),mineral);
	stone=mix(stone,detail*(0.86+mineral*0.30),0.78);
	float grain=noise3(p*1.65);
	stone+=(grain-0.5)*0.035;
	float quartz=smoothstep(0.70,0.83,noise3(p*0.95))*0.018;
	stone+=vec3(quartz*0.95,quartz,quartz*0.92);
	float joint=p.y*0.0057+p.x*0.0028+p.z*0.0019+noise3(p*0.009)*0.16;
	float fracture=abs(fract(joint)-0.5);
	float seam=(1.0-smoothstep(0.0014,0.005,fracture))*smoothstep(0.33,0.62,fbm(p*0.008+12.0));
	stone*=1.0-seam*(0.28+fragility*0.22);
	float lichen=smoothstep(0.56,0.69,fbm(p*0.035+32.0));
	float sunward=clamp(stone_normal.y*0.5+0.6,0.0,1.0);
	stone=mix(stone,vec3(0.55,0.58,0.44),lichen*0.58*sunward);
	float iron=smoothstep(0.56,0.74,fbm(p*0.008+72.0));
	stone=mix(stone,stone*vec3(1.10,0.96,0.86),iron*0.28);
	ALBEDO=stone*tint;
	ROUGHNESS=0.94;
	SPECULAR=0.18;
	// Small mineral relief in view space, independent of mesh orientation.
	float relief=noise3(p*0.30)*0.18+noise3(p*0.8)*0.04;
	vec3 dx=dFdx(VERTEX), dy=dFdy(VERTEX);
	vec3 r1=cross(dy,NORMAL), r2=cross(NORMAL,dx);
	float determinant=dot(dx,r1);
	vec3 gradient=sign(determinant)*(dFdx(relief)*r1+dFdy(relief)*r2);
	NORMAL=normalize(abs(determinant)*NORMAL-gradient*0.18);
}
