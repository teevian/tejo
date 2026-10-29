shader_type canvas_item;
uniform sampler2D screen_paint : hint_screen_texture, repeat_disable, filter_linear;
uniform float flow_time = 0.0;
varying vec2 world_point;
void vertex() {
 world_point = (MODEL_MATRIX * vec4(VERTEX,0.0,1.0)).xy;
}
float hash(float p) { return fract(sin(p*127.1)*43758.5453); }
void fragment() {
 vec4 base = texture(screen_paint,SCREEN_UV);
 // Only the blue-grey water pigments move; warm rocks and banks stay still.
 float water = smoothstep(0.008,0.08,base.b-base.r)*smoothstep(-0.02,0.06,base.g-base.r);
 float banks = 1.0-smoothstep(0.58,1.0,abs(UV.x));
 float bridge = smoothstep(104.0,132.0,abs(world_point.y-920.0));
 bridge *= smoothstep(100.0,130.0,abs(world_point.y-2280.0));
 float deck_y = 4470.0+(world_point.x-2940.0)*0.24;
 bridge *= smoothstep(125.0,155.0,abs(world_point.y-deck_y));
 float mask = water*banks*bridge;
 // Advect long painted streaks downstream at 190 world units per second.
 // The longitudinal coordinate follows the river ribbon through every bend.
 float downstream = world_point.y-flow_time*190.0;
 float across = UV.x*7.0+sin(downstream*0.035+UV.x*9.0)*0.32;
 float lane = floor(across);
 float seed = hash(lane);
 float lengthwise = downstream/68.0+seed*13.0;
 float cell = floor(lengthwise);
 float progress = fract(lengthwise);
 float center = 0.5+sin(cell*3.7+seed*12.0)*0.17;
 float thread = 1.0-smoothstep(0.04,0.38,abs(fract(across)-center));
 float head = smoothstep(0.02,0.18,progress);
 float tail = 1.0-smoothstep(0.45,0.98,progress);
 float streak = thread*head*tail;
 float broad = sin(downstream*0.045+UV.x*13.0)*0.5+0.5;
 vec3 current = mix(base.rgb*0.72,base.rgb*1.12,broad);
 current = mix(current,vec3(0.70,0.88,0.87),streak*0.48);
 COLOR = vec4(current,mask);
}
