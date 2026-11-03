extends RefCounted
## Approved complete character sprites: five authored views, mirrored to eight directions.
const TE_CLOTHES: Texture2D = preload("res://assets/characters/open_world/te-walk-friendly-painted-face.png")
const JO_CLOTHES: Texture2D = preload("res://assets/characters/open_world/jo-walk-south-painted-face.png")
const ATLASES: Array[Texture2D] = [TE_CLOTHES,JO_CLOTHES]
const WorldScale = preload("res://scripts/world_scale.gd")
const HEIGHTS: Array[float] = WorldScale.PERSON_HEIGHTS
const STRIDE := 112.0
const GAIT_FRAMES := 8
const CELL := Vector2(400,560)
const FOOT_ANCHOR := Vector2(200,520)
const SOURCE_HEIGHT := 438.0

static func direction_row(facing: Vector2) -> int:
	var angle := atan2(absf(facing.x),facing.y)
	return clampi(roundi(angle/(PI/4.0)),0,4)

static func frame_for(moving: bool, distance: float) -> int:
	return 1+posmod(floori(distance/STRIDE*GAIT_FRAMES),GAIT_FRAMES) if moving else 0

static func pose_region(_kind: int, row: int, frame: int) -> Rect2:
	var column := 1+floori(float(frame-1)/2.0) if frame>0 else 0
	return Rect2(column*CELL.x,row*CELL.y,CELL.x,CELL.y)

static func pose_scale(kind: int, _row: int) -> float:
	return HEIGHTS[kind]/SOURCE_HEIGHT

static func draw_pose(canvas: CanvasItem, kind: int, facing: Vector2, moving: bool, distance: float, origin := Vector2.ZERO) -> void:
	var row := direction_row(facing)
	var frame := frame_for(moving,distance)
	var scale_value := pose_scale(kind,row)
	canvas.draw_set_transform(origin,0,Vector2(-1 if facing.x<0 else 1,1))
	canvas.draw_texture_rect_region(ATLASES[kind],Rect2(-FOOT_ANCHOR*scale_value,CELL*scale_value),pose_region(kind,row,frame))
	canvas.draw_set_transform(Vector2.ZERO)
