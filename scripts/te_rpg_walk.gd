extends RefCounted
## Complete Te paintings: contacts alternate with real passing/reaching poses.
const ATLAS: Texture2D = preload("res://assets/characters/open_world/te-rpg-v18.png")
const SIDE_ATLAS: Texture2D = preload("res://assets/characters/open_world/te-side-v20.png")
const SIDE_STRIDE := 156.0
const CELL := Vector2(400,560)
const ANCHOR := Vector2(200,520)
const SOURCE_HEIGHT := 480.0
const WALK_FRAMES := 6
const STRIDE := 112.0

static func supports(row: int) -> bool:
	return row==0 or row==2

static func frame_for(moving: bool, distance: float) -> int:
	return 1+posmod(floori(distance/STRIDE*WALK_FRAMES),WALK_FRAMES) if moving else 0

static func region_for(row: int, moving: bool, distance: float) -> Rect2:
	return Rect2(Vector2(frame_for(moving,distance)*CELL.x,0 if row==0 else CELL.y),CELL)

static func draw_pose(canvas: CanvasItem, row: int, moving: bool, distance: float, height: float, motion_speed := -1.0) -> void:
	var factor := height/SOURCE_HEIGHT
	if row==2 and moving:
		var frame := posmod(floori(distance/SIDE_STRIDE*WALK_FRAMES),WALK_FRAMES)
		canvas.draw_texture_rect_region(SIDE_ATLAS,Rect2(-ANCHOR*factor,CELL*factor),Rect2(Vector2(frame*CELL.x,0),CELL))
		return
	canvas.draw_texture_rect_region(ATLAS,Rect2(-ANCHOR*factor,CELL*factor),region_for(row,moving,distance))
