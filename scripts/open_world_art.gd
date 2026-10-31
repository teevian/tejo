extends RefCounted
# Repaired whole-body poses and the approved dark-haired head are baked together.
# Runtime draws one complete sprite, with no separate head or limb pieces.
const ATLASES: Array[Texture2D] = [preload("res://assets/characters/open_world/te-walk-v9.png"),preload("res://assets/characters/open_world/jo-walk-v9.png")]
const WorldScale = preload("res://scripts/world_scale.gd")
const HEIGHTS: Array[float] = WorldScale.PERSON_HEIGHTS
const STRIDE := 112.0
const GAIT_FRAMES := 8
# Four complete painted key poses, each held for two phase ticks.
# Contact A, passing A, contact B, passing B. Resting pose is separate.
const TE: Array[Rect2] = [
	Rect2(218,164,367,876),Rect2(1031,164,349,876),Rect2(1031,164,349,876),Rect2(1819,164,376,876),Rect2(1819,164,376,876),Rect2(2628,164,348,876),Rect2(2628,164,348,876),Rect2(3426,164,345,876),Rect2(3426,164,345,876),
	Rect2(228,1308,356,852),Rect2(999,1308,415,852),Rect2(999,1308,415,852),Rect2(1818,1308,368,852),Rect2(1818,1308,368,852),Rect2(2553,1308,497,852),Rect2(2553,1308,497,852),Rect2(3405,1308,402,852),Rect2(3405,1308,402,852),
	Rect2(259,2432,278,848),Rect2(958,2432,517,848),Rect2(958,2432,517,848),Rect2(1841,2432,296,848),Rect2(1841,2432,296,848),Rect2(2526,2432,518,848),Rect2(2526,2432,518,848),Rect2(3412,2432,382,848),Rect2(3412,2432,382,848),
	Rect2(245,3552,327,848),Rect2(1013,3552,404,848),Rect2(1013,3552,404,848),Rect2(1796,3552,412,848),Rect2(1796,3552,412,848),Rect2(2571,3552,491,848),Rect2(2571,3552,491,848),Rect2(3380,3552,471,848),Rect2(3380,3552,471,848),
	Rect2(204,4592,394,928),Rect2(1002,4592,394,928),Rect2(1002,4592,394,928),Rect2(1782,4592,424,928),Rect2(1782,4592,424,928),Rect2(2599,4592,402,928),Rect2(2599,4592,402,928),Rect2(3399,4592,408,928),Rect2(3399,4592,408,928)]
const TE_ANCHORS: Array[Vector2] = [
	Vector2(182,876),Vector2(169,876),Vector2(169,876),Vector2(181,876),Vector2(181,876),Vector2(172,876),Vector2(172,876),Vector2(174,876),Vector2(174,876),
	Vector2(172,852),Vector2(201,852),Vector2(201,852),Vector2(182,852),Vector2(182,852),Vector2(247,852),Vector2(247,852),Vector2(195,852),Vector2(195,852),
	Vector2(141,848),Vector2(242,848),Vector2(242,848),Vector2(159,848),Vector2(159,848),Vector2(274,848),Vector2(274,848),Vector2(188,848),Vector2(188,848),
	Vector2(155,848),Vector2(187,848),Vector2(187,848),Vector2(204,848),Vector2(204,848),Vector2(229,848),Vector2(229,848),Vector2(220,848),Vector2(220,848),
	Vector2(196,928),Vector2(198,928),Vector2(198,928),Vector2(218,928),Vector2(218,928),Vector2(201,928),Vector2(201,928),Vector2(201,928),Vector2(201,928)]
const JO: Array[Rect2] = [
	Rect2(226,164,348,876),Rect2(1026,164,348,876),Rect2(1026,164,348,876),Rect2(1802,164,396,876),Rect2(1802,164,396,876),Rect2(2626,164,348,876),Rect2(2626,164,348,876),Rect2(3424,164,352,876),Rect2(3424,164,352,876),
	Rect2(234,1308,332,852),Rect2(1004,1308,392,852),Rect2(1004,1308,392,852),Rect2(1818,1308,364,852),Rect2(1818,1308,364,852),Rect2(2542,1308,516,852),Rect2(2542,1308,516,852),Rect2(3390,1308,420,852),Rect2(3390,1308,420,852),
	Rect2(274,2432,250,848),Rect2(984,2432,432,848),Rect2(984,2432,432,848),Rect2(1858,2432,290,848),Rect2(1858,2432,290,848),Rect2(2506,2432,588,848),Rect2(2506,2432,588,848),Rect2(3406,2432,388,848),Rect2(3406,2432,388,848),
	Rect2(248,3552,307,848),Rect2(986,3552,428,848),Rect2(986,3552,428,848),Rect2(1794,3552,412,848),Rect2(1794,3552,412,848),Rect2(2538,3552,524,848),Rect2(2538,3552,524,848),Rect2(3350,3552,500,848),Rect2(3350,3552,500,848),
	Rect2(218,4592,364,928),Rect2(1018,4592,364,928),Rect2(1018,4592,364,928),Rect2(1798,4592,404,928),Rect2(1798,4592,404,928),Rect2(2618,4592,364,928),Rect2(2618,4592,364,928),Rect2(3376,4592,448,928),Rect2(3376,4592,448,928)]
const JO_ANCHORS: Array[Vector2] = [
	Vector2(174,876),Vector2(174,876),Vector2(174,876),Vector2(198,876),Vector2(198,876),Vector2(174,876),Vector2(174,876),Vector2(176,876),Vector2(176,876),
	Vector2(166,852),Vector2(196,852),Vector2(196,852),Vector2(182,852),Vector2(182,852),Vector2(258,852),Vector2(258,852),Vector2(210,852),Vector2(210,852),
	Vector2(126,848),Vector2(216,848),Vector2(216,848),Vector2(142,848),Vector2(142,848),Vector2(294,848),Vector2(294,848),Vector2(194,848),Vector2(194,848),
	Vector2(152,848),Vector2(214,848),Vector2(214,848),Vector2(206,848),Vector2(206,848),Vector2(262,848),Vector2(262,848),Vector2(250,848),Vector2(250,848),
	Vector2(182,928),Vector2(182,928),Vector2(182,928),Vector2(202,928),Vector2(202,928),Vector2(182,928),Vector2(182,928),Vector2(224,928),Vector2(224,928)]

static func direction_row(facing: Vector2) -> int:
	var angle := atan2(absf(facing.x),facing.y)
	return clampi(roundi(angle/(PI/4.0)),0,4)

static func frame_for(moving: bool, distance: float) -> int:
	return 1+posmod(floori(distance/STRIDE*GAIT_FRAMES),GAIT_FRAMES) if moving else 0

static func pose_region(kind: int, row: int, frame: int) -> Rect2:
	return TE[row*(GAIT_FRAMES+1)+frame] if kind==0 else JO[row*(GAIT_FRAMES+1)+frame]

static func draw_pose(canvas: CanvasItem, kind: int, facing: Vector2, moving: bool, distance: float, origin := Vector2.ZERO) -> void:
	var row := direction_row(facing)
	var frame := frame_for(moving,distance)
	var region := pose_region(kind,row,frame)
	var scale_value: float = HEIGHTS[kind]/876.0
	var anchor := TE_ANCHORS[row*9+frame] if kind==0 else JO_ANCHORS[row*9+frame]
	canvas.draw_set_transform(origin,0,Vector2(-1 if facing.x<0 else 1,1))
	canvas.draw_texture_rect_region(ATLASES[kind],Rect2(-anchor*scale_value,region.size*scale_value),region)
	canvas.draw_set_transform(Vector2.ZERO)
