extends RefCounted
# Five authored viewpoints, mirrored to eight directions. Te's gaits share
# each view's resting head and torso, retaining the original painted limbs,
# foot anchors and key timing. Jo uses the original complete painted sprites.
const ATLASES: Array[Texture2D] = [preload("res://assets/characters/open_world/te-walk-v4.png"),preload("res://assets/characters/open_world/jo-walk-v5.png")]
const WorldScale = preload("res://scripts/world_scale.gd")
const TeFrontGait = preload("res://scripts/te_front_gait.gd")
const TeNorthGait = preload("res://scripts/te_north_gait.gd")
const TeSideGait = preload("res://scripts/te_side_gait.gd")
const TeDiagonalGait = preload("res://scripts/te_diagonal_gait.gd")
const HEIGHTS: Array[float] = WorldScale.PERSON_HEIGHTS
const STRIDE := 112.0
const GAIT_FRAMES := 8
# Four complete painted key poses, each held for two phase ticks.
# Contact A, passing A, contact B, passing B. Resting pose is separate.
const TE: Array[Rect2] = [
	Rect2(42,26,96,219),Rect2(223,26,94,219),Rect2(223,26,94,219),Rect2(399,26,102,219),Rect2(399,26,102,219),Rect2(583,26,94,219),Rect2(583,26,94,219),Rect2(766,26,89,219),Rect2(766,26,89,219),
	Rect2(44,292,92,213),Rect2(218,292,105,213),Rect2(218,292,105,213),Rect2(405,292,90,213),Rect2(405,292,90,213),Rect2(562,292,136,213),Rect2(562,292,136,213),Rect2(760,292,101,213),Rect2(760,292,101,213),
	Rect2(57,553,67,212),Rect2(199,553,142,212),Rect2(199,553,142,212),Rect2(412,553,76,212),Rect2(412,553,76,212),Rect2(557,553,146,212),Rect2(557,553,146,212),Rect2(761,553,98,212),Rect2(761,553,98,212),
	Rect2(49,813,82,212),Rect2(221,813,99,212),Rect2(221,813,99,212),Rect2(398,813,105,212),Rect2(398,813,105,212),Rect2(564,813,133,212),Rect2(564,813,133,212),Rect2(747,813,127,212),Rect2(747,813,127,212),
	Rect2(41,1053,98,232),Rect2(222,1053,97,232),Rect2(222,1053,97,232),Rect2(395,1053,110,232),Rect2(395,1053,110,232),Rect2(582,1053,97,232),Rect2(582,1053,97,232),Rect2(758,1053,104,232),Rect2(758,1053,104,232)]
const JO: Array[Rect2] = [
	Rect2(47,26,87,219),Rect2(227,26,87,219),Rect2(227,26,87,219),Rect2(401,26,99,219),Rect2(401,26,99,219),Rect2(587,26,87,219),Rect2(587,26,87,219),Rect2(766,26,88,219),Rect2(766,26,88,219),
	Rect2(49,292,83,213),Rect2(221,292,98,213),Rect2(221,292,98,213),Rect2(405,292,91,213),Rect2(405,292,91,213),Rect2(566,292,129,213),Rect2(566,292,129,213),Rect2(758,292,105,213),Rect2(758,292,105,213),
	Rect2(59,553,63,212),Rect2(216,553,108,212),Rect2(216,553,108,212),Rect2(415,553,71,212),Rect2(415,553,71,212),Rect2(557,553,147,212),Rect2(557,553,147,212),Rect2(762,553,97,212),Rect2(762,553,97,212),
	Rect2(52,813,76,212),Rect2(217,813,107,212),Rect2(217,813,107,212),Rect2(399,813,103,212),Rect2(399,813,103,212),Rect2(565,813,131,212),Rect2(565,813,131,212),Rect2(748,813,125,212),Rect2(748,813,125,212),
	Rect2(45,1053,91,232),Rect2(225,1053,91,232),Rect2(225,1053,91,232),Rect2(400,1053,101,232),Rect2(400,1053,101,232),Rect2(585,1053,91,232),Rect2(585,1053,91,232),Rect2(754,1053,112,232),Rect2(754,1053,112,232)]

static func direction_row(facing: Vector2) -> int:
	var angle := atan2(absf(facing.x),facing.y)
	return clampi(roundi(angle/(PI/4.0)),0,4)

static func frame_for(moving: bool, distance: float) -> int:
	return 1+posmod(floori(distance/STRIDE*GAIT_FRAMES),GAIT_FRAMES) if moving else 0

static func pose_region(kind: int, row: int, frame: int) -> Rect2:
	return TE[row*(GAIT_FRAMES+1)+frame] if kind==0 else JO[row*(GAIT_FRAMES+1)+frame]

static func draw_pose(canvas: CanvasItem, kind: int, facing: Vector2, moving: bool, distance: float, origin := Vector2.ZERO) -> void:
	var row := direction_row(facing)
	var region := pose_region(kind,row,frame_for(moving,distance))
	var scale_value: float = HEIGHTS[kind]/(TE[0].size.y if kind==0 else JO[0].size.y)
	var anchor := Vector2(region.size.x*0.5,region.size.y)
	canvas.draw_set_transform(origin,0,Vector2(-1 if facing.x<0 else 1,1))
	if kind==0 and row==0 and moving:
		TeFrontGait.draw_pose(canvas,region,scale_value)
	elif kind==0 and row==4 and moving:
		TeNorthGait.draw_pose(canvas,region,scale_value)
	elif kind==0 and row==2 and moving:
		TeSideGait.draw_pose(canvas,region,scale_value)
	elif kind==0 and (row==1 or row==3) and moving:
		TeDiagonalGait.draw_pose(canvas,row,region,scale_value)
	else:
		canvas.draw_texture_rect_region(ATLASES[kind],Rect2(-anchor*scale_value,region.size*scale_value),region)
	canvas.draw_set_transform(Vector2.ZERO)
