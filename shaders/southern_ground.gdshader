shader_type canvas_item;
void fragment() {
 vec4 paint = texture(TEXTURE, UV);
 // The wet hollow is cooler; the exposed granite slope catches warmer light.
 float shade = mix(0.76,0.94,smoothstep(0.28,0.9,UV.x));
 vec3 wet = paint.rgb * vec3(0.81,0.96,0.97) * shade;
 COLOR = vec4(wet, smoothstep(0.0,0.065,UV.y));
}
