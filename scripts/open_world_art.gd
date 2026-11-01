extends RefCounted
# Original faces, a continuous neck/collar and normalized arm widths.
# Runtime draws one complete sprite; no separate head/neck layers.
const ATLASES: Array[Texture2D] = [preload("res://assets/characters/open_world/te-walk-v14.png"),preload("res://assets/characters/open_world/jo-walk-v14.png")]
const TE_SOUTH: Texture2D = preload("res://assets/characters/open_world/te-south-forearm-balance.png")
const WorldScale = preload("res://scripts/world_scale.gd")
const HEIGHTS: Array[float] = WorldScale.PERSON_HEIGHTS
const STRIDE := 112.0
const GAIT_FRAMES := 8
# Two head turns alternate with the steps; authored gait silhouettes are retained.
# Fixed source heights and registered crowns keep direction changes consistent.
const SOURCE_HEIGHTS: Array[float] = [876.0,852.0,848.0,848.0,928.0]
const TE: Array[Rect2] = [
	Rect2(200,164,367,876),Rect2(1012,164,352,876),Rect2(1812,164,352,876),Rect2(2599,164,377,876),Rect2(3399,164,377,876),Rect2(4208,164,352,876),Rect2(5008,164,352,876),Rect2(5806,164,349,876),Rect2(6606,164,349,876),
	Rect2(210,1308,356,852),Rect2(981,1308,415,852),Rect2(1781,1308,415,852),Rect2(2599,1308,369,852),Rect2(3399,1308,369,852),Rect2(4135,1308,497,852),Rect2(4935,1308,497,852),Rect2(5787,1308,402,852),Rect2(6587,1308,402,852),
	Rect2(265,2432,271,848),Rect2(960,2432,517,848),Rect2(1760,2432,517,848),Rect2(2643,2432,289,848),Rect2(3443,2432,289,848),Rect2(4128,2432,518,848),Rect2(4928,2432,518,848),Rect2(5814,2432,382,848),Rect2(6614,2432,382,848),
	Rect2(225,3552,327,848),Rect2(993,3552,404,848),Rect2(1793,3552,404,848),Rect2(2576,3552,412,848),Rect2(3376,3552,412,848),Rect2(4151,3552,491,848),Rect2(4951,3552,491,848),Rect2(5760,3552,471,848),Rect2(6560,3552,471,848),
	Rect2(210,4592,394,928),Rect2(1008,4592,394,928),Rect2(1808,4592,394,928),Rect2(2588,4592,424,928),Rect2(3388,4592,424,928),Rect2(4205,4592,402,928),Rect2(5005,4592,402,928),Rect2(5805,4592,408,928),Rect2(6605,4592,408,928)]
const TE_ANCHORS: Array[Vector2] = [
	Vector2(200,876),Vector2(188,876),Vector2(188,876),Vector2(201,876),Vector2(201,876),Vector2(192,876),Vector2(192,876),Vector2(194,876),Vector2(194,876),
	Vector2(190,852),Vector2(219,852),Vector2(219,852),Vector2(201,852),Vector2(201,852),Vector2(265,852),Vector2(265,852),Vector2(213,852),Vector2(213,852),
	Vector2(135,848),Vector2(240,848),Vector2(240,848),Vector2(157,848),Vector2(157,848),Vector2(272,848),Vector2(272,848),Vector2(186,848),Vector2(186,848),
	Vector2(175,848),Vector2(207,848),Vector2(207,848),Vector2(224,848),Vector2(224,848),Vector2(249,848),Vector2(249,848),Vector2(240,848),Vector2(240,848),
	Vector2(190,928),Vector2(192,928),Vector2(192,928),Vector2(212,928),Vector2(212,928),Vector2(195,928),Vector2(195,928),Vector2(195,928),Vector2(195,928)]
const JO: Array[Rect2] = [
	Rect2(225,164,348,876),Rect2(1025,164,352,876),Rect2(1825,164,352,876),Rect2(2601,164,396,876),Rect2(3401,164,396,876),Rect2(4225,164,351,876),Rect2(5025,164,351,876),Rect2(5820,164,355,876),Rect2(6620,164,355,876),
	Rect2(215,1308,332,852),Rect2(985,1308,392,852),Rect2(1785,1308,392,852),Rect2(2593,1308,364,852),Rect2(3393,1308,364,852),Rect2(4121,1308,516,852),Rect2(4921,1308,516,852),Rect2(5763,1308,420,852),Rect2(6563,1308,420,852),
	Rect2(279,2432,248,848),Rect2(953,2432,432,848),Rect2(1753,2432,432,848),Rect2(2639,2432,284,848),Rect2(3439,2432,284,848),Rect2(4057,2432,588,848),Rect2(4857,2432,588,848),Rect2(5783,2432,388,848),Rect2(6583,2432,388,848),
	Rect2(220,3552,304,848),Rect2(964,3552,428,848),Rect2(1764,3552,428,848),Rect2(2556,3552,412,848),Rect2(3356,3552,412,848),Rect2(4106,3552,524,848),Rect2(4906,3552,524,848),Rect2(5720,3552,500,848),Rect2(6520,3552,500,848),
	Rect2(216,4592,364,928),Rect2(1018,4592,364,928),Rect2(1818,4592,364,928),Rect2(2594,4592,404,928),Rect2(3394,4592,404,928),Rect2(4222,4592,364,928),Rect2(5022,4592,364,928),Rect2(5764,4592,448,928),Rect2(6564,4592,448,928)]
const JO_ANCHORS: Array[Vector2] = [
	Vector2(175,876),Vector2(175,876),Vector2(175,876),Vector2(199,876),Vector2(199,876),Vector2(175,876),Vector2(175,876),Vector2(180,876),Vector2(180,876),
	Vector2(185,852),Vector2(215,852),Vector2(215,852),Vector2(207,852),Vector2(207,852),Vector2(279,852),Vector2(279,852),Vector2(237,852),Vector2(237,852),
	Vector2(121,848),Vector2(247,848),Vector2(247,848),Vector2(161,848),Vector2(161,848),Vector2(343,848),Vector2(343,848),Vector2(217,848),Vector2(217,848),
	Vector2(180,848),Vector2(236,848),Vector2(236,848),Vector2(244,848),Vector2(244,848),Vector2(294,848),Vector2(294,848),Vector2(280,848),Vector2(280,848),
	Vector2(184,928),Vector2(182,928),Vector2(182,928),Vector2(206,928),Vector2(206,928),Vector2(178,928),Vector2(178,928),Vector2(236,928),Vector2(236,928)]

static func direction_row(facing: Vector2) -> int:
	var angle := atan2(absf(facing.x),facing.y)
	return clampi(roundi(angle/(PI/4.0)),0,4)

static func frame_for(moving: bool, distance: float) -> int:
	return 1+posmod(floori(distance/STRIDE*GAIT_FRAMES),GAIT_FRAMES) if moving else 0

static func pose_region(kind: int, row: int, frame: int) -> Rect2:
	return TE[row*(GAIT_FRAMES+1)+frame] if kind==0 else JO[row*(GAIT_FRAMES+1)+frame]

static func pose_scale(kind: int, row: int) -> float:
	return HEIGHTS[kind]/SOURCE_HEIGHTS[row]

static func draw_pose(canvas: CanvasItem, kind: int, facing: Vector2, moving: bool, distance: float, origin := Vector2.ZERO) -> void:
	var row := direction_row(facing)
	var frame := frame_for(moving,distance)
	var region := pose_region(kind,row,frame)
	var scale_value: float = pose_scale(kind,row)
	var anchor := TE_ANCHORS[row*9+frame] if kind==0 else JO_ANCHORS[row*9+frame]
	canvas.draw_set_transform(origin,0,Vector2(-1 if facing.x<0 else 1,1))
	if kind==0 and row==0:
		var south_scale := HEIGHTS[0]/438.0
		var south_frame := 1+floori(float(frame-1)/2.0) if moving else 0
		canvas.draw_texture_rect_region(TE_SOUTH,Rect2(Vector2(-200,-520)*south_scale,Vector2(400,560)*south_scale),Rect2(south_frame*400,0,400,560))
	else:
		canvas.draw_texture_rect_region(ATLASES[kind],Rect2(-anchor*scale_value,region.size*scale_value),region)
	canvas.draw_set_transform(Vector2.ZERO)
