extends RefCounted
const ATLASES: Array[Texture2D] = [preload("res://assets/characters/open_world/te-directions.png"), preload("res://assets/characters/open_world/jo-directions.png")]
const SCALE := 0.48
# One scale per atlas, never stretch a pose to its bounding-box height.
const TE: Array[Rect2] = [
	Rect2(105,33,185,363),Rect2(410,33,187,392),Rect2(684,34,181,386),Rect2(961,33,190,392),
	Rect2(135,429,141,383),Rect2(394,429,221,367),Rect2(693,429,190,376),Rect2(973,428,229,377),
	Rect2(103,820,187,367),Rect2(397,819,199,390),Rect2(689,818,191,393),Rect2(981,819,192,400)]
const JO: Array[Rect2] = [
	Rect2(81,32,180,375),Rect2(401,31,182,382),Rect2(693,33,195,378),Rect2(993,31,194,380),
	Rect2(107,439,122,371),Rect2(390,438,199,366),Rect2(701,437,188,369),Rect2(1003,437,204,365),
	Rect2(86,826,182,365),Rect2(397,824,180,385),Rect2(691,823,193,387),Rect2(989,822,197,388)]

static func direction_row(facing: Vector2) -> int:
	if absf(facing.y) > absf(facing.x) * 0.8:
		return 2 if facing.y < 0 else 0
	return 1

static func draw_pose(canvas: CanvasItem, kind: int, facing: Vector2, moving: bool, distance: float) -> void:
	var row := direction_row(facing)
	var cycle: Array[int] = [1,2,3,2]
	var frame := row * 4 + (cycle[int(distance / 18.0) % 4] if moving else 0)
	var region := TE[frame] if kind == 0 else JO[frame]
	var flip := -1.0 if row == 1 and facing.x < 0 else 1.0
	canvas.draw_set_transform(Vector2.ZERO, 0, Vector2(flip,1))
	var dimensions := region.size * SCALE
	canvas.draw_texture_rect_region(ATLASES[kind], Rect2(Vector2(-dimensions.x * 0.5, -dimensions.y), dimensions), region)
	canvas.draw_set_transform(Vector2.ZERO)
