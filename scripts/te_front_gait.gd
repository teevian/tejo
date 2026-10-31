extends RefCounted
## The front gait retains the original moving arms and legs. Its head and shirt
## come from one approved resting pose, so four different drawings cannot morph
## the character's face, shoulder width or torso during a step.
const ATLAS: Texture2D = preload("res://assets/characters/open_world/te-walk-v4.png")
const SOURCE_FEET := Vector2(90,245)
const LIMBS_START := 117.0
const CORE: Array[Vector2] = [
	Vector2(60,26),Vector2(124,26),Vector2(124,88),Vector2(132,98),
	Vector2(137,123),Vector2(123,128),Vector2(117,125),Vector2(119,140),
	Vector2(117,163),Vector2(64,163),Vector2(63,140),Vector2(65,125),
	Vector2(59,128),Vector2(43,123),Vector2(48,99),Vector2(60,90)]

static func draw_pose(canvas: CanvasItem, region: Rect2, scale_value: float) -> void:
	# Use the exact source coordinates and foot anchor of the old walking frame.
	var moving := Rect2(region.position.x,LIMBS_START,region.size.x,region.end.y-LIMBS_START)
	var destination := Rect2(Vector2(-region.size.x*.5,LIMBS_START-region.end.y)*scale_value,moving.size*scale_value)
	canvas.draw_texture_rect_region(ATLAS,destination,moving)
	var vertices := PackedVector2Array()
	var uv := PackedVector2Array()
	for point in CORE:
		vertices.append((point-SOURCE_FEET)*scale_value)
		uv.append(point/ATLAS.get_size())
	canvas.draw_polygon(vertices,PackedColorArray([Color.WHITE]),uv,ATLAS)
