extends RefCounted
## Keep Te's back-facing head, shoulders and shirt from the resting painting.
## The original north-facing keys still supply every moving arm and leg.
const ATLAS: Texture2D = preload("res://assets/characters/open_world/te-walk-v4.png")
const SOURCE_FEET := Vector2(90,1285)
const LIMBS_START := 1148.0
const CORE: Array[Vector2] = [
	Vector2(60,1053),Vector2(124,1053),Vector2(124,1122),Vector2(132,1135),
	Vector2(137,1158),Vector2(121,1163),Vector2(115,1160),Vector2(118,1181),
	Vector2(118,1193),Vector2(63,1193),Vector2(62,1181),Vector2(65,1161),
	Vector2(60,1164),Vector2(43,1157),Vector2(48,1132),Vector2(60,1121)]

static func draw_pose(canvas: CanvasItem, region: Rect2, scale_value: float) -> void:
	# Retain the original frame's foot anchor, including half-pixel centres.
	var moving := Rect2(region.position.x,LIMBS_START,region.size.x,region.end.y-LIMBS_START)
	var destination := Rect2(Vector2(-region.size.x*.5,LIMBS_START-region.end.y)*scale_value,moving.size*scale_value)
	canvas.draw_texture_rect_region(ATLAS,destination,moving)
	var vertices := PackedVector2Array()
	var uv := PackedVector2Array()
	for point in CORE:
		vertices.append((point-SOURCE_FEET)*scale_value)
		uv.append(point/ATLAS.get_size())
	canvas.draw_polygon(vertices,PackedColorArray([Color.WHITE]),uv,ATLAS)
