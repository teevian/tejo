extends "res://scripts/painted_occluder.gd"
## Authored solid bases and opaque, alpha-cut painted architecture share foot depth.
var label := ""
var entry_id := ""
var entry_position := Vector2.ZERO
var visual_size := Vector2.ZERO

func build(texture: Texture2D, source: Rect2, at: Vector2, width: float, bases: Array, paint: ShaderMaterial, mirror := false) -> void:
	var factor := width/source.size.x
	visual_size = source.size*factor
	var rect := Rect2(at-Vector2(visual_size.x*0.5,visual_size.y),visual_size)
	var uv := PackedVector2Array([source.position,source.position+Vector2(source.size.x,0),source.end,source.position+Vector2(0,source.size.y)])
	if mirror: uv = PackedVector2Array([source.position+Vector2(source.size.x,0),source.position,source.position+Vector2(0,source.size.y),source.end])
	var points := PackedVector2Array([rect.position,rect.position+Vector2(rect.size.x,0),rect.end,rect.position+Vector2(0,rect.size.y)])
	configure_mapped(texture,uv,points,at)
	surface.material = paint
	for base: Rect2 in bases:
		add_footprint(PackedVector2Array([base.position,base.position+Vector2(base.size.x,0),base.end,base.position+Vector2(0,base.size.y)]))
	entry_position = at+Vector2(0,35)
