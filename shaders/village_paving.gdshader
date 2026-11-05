shader_type canvas_item;
render_mode unshaded;

// UVs are measured in world pixels: x across the street, y along its course.
uniform vec4 stone_color : source_color = vec4(0.55, 0.55, 0.51, 1.0);
uniform vec4 joint_color : source_color = vec4(0.34, 0.35, 0.32, 1.0);
uniform vec2 block_size = vec2(19.0, 15.0);
uniform float joint_width = 0.7;
float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}
void fragment() {
	vec2 p = UV / TEXTURE_PIXEL_SIZE;
	vec2 worn = p + vec2(sin(p.y * 0.31) * 0.35, sin(p.x * 0.27) * 0.42);
	float row = floor(worn.y / block_size.y);
	vec2 stagger = vec2(mod(row, 2.0) * 0.5 + (hash(vec2(row, 4.0)) - 0.5) * 0.12, 0.0);
	vec2 grid = worn / block_size + stagger;
	vec2 cell = floor(grid);
	vec2 local = fract(grid);
	// Small, irregular joints retain the scale and wear of hand-laid stone.
	float ripple = sin(p.y * 0.61 + hash(cell) * 6.28) * 0.17;
	vec2 q = abs((local - 0.5) * block_size) - block_size * 0.5 + vec2(1.7);
	float distance_to_joint = 1.7 - length(max(q, vec2(0.0))) - min(max(q.x, q.y), 0.0) + ripple;
	float mortar = smoothstep(joint_width * 0.45, joint_width + 0.65, distance_to_joint);
	float bevel = smoothstep(joint_width + 0.5, joint_width + 1.8, distance_to_joint);
	float grain = dot(texture(TEXTURE, UV * 2.1).rgb, vec3(0.3, 0.5, 0.2));
	float variation = (hash(cell) - 0.5) * 0.12 + (grain - 0.5) * 0.28;
	vec3 face = stone_color.rgb + variation + (1.0 - bevel) * 0.035;
	COLOR = vec4(mix(joint_color.rgb, face, mortar), stone_color.a);
}
