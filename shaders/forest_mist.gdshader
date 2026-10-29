shader_type canvas_item;
uniform float strength = 0.16;
float wave(vec2 p) {
 return sin(p.x*5.0+sin(p.y*4.0))*0.5+0.5;
}
void fragment() {
 vec2 p=UV*3.0+vec2(TIME*0.012,TIME*0.005);
 float edge = smoothstep(0.0,0.23,UV.x)*(1.0-smoothstep(0.77,1.0,UV.x))*smoothstep(0.0,0.2,UV.y)*(1.0-smoothstep(0.8,1.0,UV.y));
 float fog = (wave(p)*0.55+wave(p*1.7)*0.45)*edge*strength;
 COLOR=vec4(vec3(0.64,0.76,0.72),fog);
}
