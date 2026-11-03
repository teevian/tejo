extends RefCounted
## Six complete painted run keys per authored view; mirror the five views to eight.
const Walk = preload("res://scripts/open_world_art.gd")
const ATLASES: Array[Texture2D] = [
	preload("res://assets/characters/running/te-run.png"),
	preload("res://assets/characters/running/jo-run.png")
]
const CELL := Vector2(576,560)
const ANCHOR := Vector2(288,520)
const FRAMES := 6
const STRIDE := 176.0

static func frame_for(distance: float) -> int:
	return posmod(floori(distance/STRIDE*FRAMES),FRAMES)

static func pose_region(row: int, key: int) -> Rect2:
	return Rect2(clampi(key,0,FRAMES-1)*CELL.x,clampi(row,0,4)*CELL.y,CELL.x,CELL.y)

static func draw_pose(canvas: CanvasItem, kind: int, facing: Vector2, distance: float) -> void:
	var scale_value: float = Walk.HEIGHTS[kind]/Walk.SOURCE_HEIGHT
	canvas.draw_set_transform(Vector2.ZERO,0,Vector2(-1 if facing.x<0 else 1,1))
	canvas.draw_texture_rect_region(ATLASES[kind],Rect2(-ANCHOR*scale_value,CELL*scale_value),pose_region(Walk.direction_row(facing),frame_for(distance)))
	canvas.draw_set_transform(Vector2.ZERO)
