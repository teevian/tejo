extends RefCounted
# Five authored viewpoints, mirrored to eight directions. Each row contains
# an idle pose followed by eight painted walking frames.
const ATLASES: Array[Texture2D] = [preload("res://assets/characters/open_world/te-walk-v2.png"),preload("res://assets/characters/open_world/jo-walk-v2.png")]
const WorldScale = preload("res://scripts/world_scale.gd")
const HEIGHTS: Array[float] = WorldScale.PERSON_HEIGHTS
const STRIDE := 176.0
const GAIT_FRAMES := 8
# Complete silhouette bounds: the atlas spacing is hand painted, not a uniform grid.
const TE: Array[Rect2] = [
	Rect2(23,16,114,211),Rect2(185,18,108,215),Rect2(343,17,112,221),Rect2(491,17,111,221),Rect2(644,13,105,224),Rect2(787,17,108,221),Rect2(944,16,112,220),Rect2(1099,17,111,221),Rect2(1251,17,105,222),
	Rect2(26,245,108,213),Rect2(189,246,109,215),Rect2(345,248,116,215),Rect2(495,246,112,214),Rect2(649,245,102,216),Rect2(785,247,112,215),Rect2(945,247,116,215),Rect2(1098,248,115,212),Rect2(1256,243,98,220),
	Rect2(35,469,93,218),Rect2(170,472,134,213),Rect2(334,472,129,214),Rect2(498,470,109,215),Rect2(641,467,100,220),Rect2(784,471,119,215),Rect2(938,472,120,214),Rect2(1095,471,118,216),Rect2(1241,469,111,211),
	Rect2(22,689,124,217),Rect2(184,690,121,216),Rect2(346,692,119,219),Rect2(498,689,124,221),Rect2(654,687,108,220),Rect2(797,691,115,217),Rect2(952,690,116,221),Rect2(1104,693,123,218),Rect2(1253,688,110,220),
	Rect2(22,915,115,212),Rect2(179,916,116,209),Rect2(337,915,115,216),Rect2(490,915,118,218),Rect2(639,915,118,217),Rect2(786,917,113,213),Rect2(942,915,115,212),Rect2(1097,917,118,215),Rect2(1246,915,112,213)]
const JO: Array[Rect2] = [
	Rect2(36,36,112,219),Rect2(177,35,111,224),Rect2(321,33,117,226),Rect2(469,33,121,226),Rect2(621,29,114,230),Rect2(768,30,122,229),Rect2(923,33,120,226),Rect2(1075,33,113,225),Rect2(1223,30,115,229),
	Rect2(37,264,109,214),Rect2(187,263,103,215),Rect2(337,264,116,215),Rect2(487,263,114,216),Rect2(636,261,111,218),Rect2(788,262,115,217),Rect2(940,263,117,216),Rect2(1094,264,108,215),Rect2(1241,259,108,220),
	Rect2(49,481,85,224),Rect2(178,481,120,216),Rect2(323,482,124,220),Rect2(475,484,127,219),Rect2(633,483,117,219),Rect2(784,481,117,219),Rect2(933,484,121,218),Rect2(1083,483,122,219),Rect2(1234,479,109,222),
	Rect2(37,706,112,209),Rect2(187,706,120,212),Rect2(343,703,105,214),Rect2(485,707,111,211),Rect2(628,704,117,201),Rect2(780,702,116,215),Rect2(933,703,114,214),Rect2(1085,704,110,213),Rect2(1235,703,106,215),
	Rect2(36,918,113,208),Rect2(185,919,116,211),Rect2(334,918,113,214),Rect2(482,919,114,213),Rect2(630,917,116,212),Rect2(780,917,118,216),Rect2(935,918,115,214),Rect2(1081,918,113,214),Rect2(1230,918,114,213)]

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
	# Keep one uniform scale per character across every view and walking frame.
	var scale_value: float = HEIGHTS[kind]/(TE[0].size.y if kind==0 else JO[0].size.y)
	var anchor := Vector2(region.size.x*0.5,region.size.y)
	canvas.draw_set_transform(origin,0,Vector2(-1 if facing.x<0 else 1,1))
	canvas.draw_texture_rect_region(ATLASES[kind],Rect2(-anchor*scale_value,region.size*scale_value),region)
	canvas.draw_set_transform(Vector2.ZERO)
