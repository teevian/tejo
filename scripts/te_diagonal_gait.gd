extends RefCounted
## Each diagonal keeps its own resting head, shoulders and torso. Separate
## original arm cutouts prevent wider source shirts leaking around that core.
const ATLAS: Texture2D = preload("res://assets/characters/open_world/te-walk-v4.png")
const SOUTH_FEET := Vector2(90,505)
const NORTH_FEET := Vector2(90,1025)
const SOUTH_LOWER := 420.0
const NORTH_LOWER := 944.0
const SOUTH_CORE: Array[Vector2] = [
	Vector2(59,292),Vector2(130,292),Vector2(130,350),Vector2(126,359),
	Vector2(129,375),Vector2(129,383),Vector2(115,387),Vector2(113,382),
	Vector2(114,396),Vector2(113,420),Vector2(68,420),Vector2(68,404),
	Vector2(68,385),Vector2(57,383),Vector2(46,379),Vector2(48,365),Vector2(59,353)]
const NORTH_CORE: Array[Vector2] = [
	Vector2(60,813),Vector2(136,813),Vector2(136,874),Vector2(115,881),
	Vector2(124,893),Vector2(128,911),Vector2(119,919),Vector2(105,921),
	Vector2(104,915),Vector2(107,931),Vector2(106,944),Vector2(68,944),
	Vector2(68,925),Vector2(68,907),Vector2(59,905),Vector2(50,901),Vector2(51,886),Vector2(62,877)]
# Coordinates stay in the original atlas. Arms and lower bodies keep the exact
# original anchor, scale and articulation; the fixed shirt covers their roots.
const SOUTH_ARMS: Array = [
	[[Vector2(227,379),Vector2(246,384),Vector2(245,391),Vector2(241,409),Vector2(239,420),Vector2(218,420),Vector2(219,395)],
	 [Vector2(285,366),Vector2(301,360),Vector2(310,388),Vector2(322,410),Vector2(323,420),Vector2(302,420),Vector2(303,402),Vector2(292,390)]],
	[[Vector2(405,379),Vector2(430,383),Vector2(431,403),Vector2(426,420),Vector2(405,420)],
	 [Vector2(474,375),Vector2(490,375),Vector2(495,396),Vector2(495,420),Vector2(477,420)]],
	[[Vector2(562,403),Vector2(581,379),Vector2(591,365),Vector2(612,380),Vector2(596,398),Vector2(590,416),Vector2(574,420),Vector2(562,420)],
	 [Vector2(656,368),Vector2(676,370),Vector2(684,392),Vector2(699,407),Vector2(699,420),Vector2(675,420),Vector2(668,404),Vector2(659,391)]],
	[[Vector2(760,377),Vector2(781,380),Vector2(782,399),Vector2(781,420),Vector2(760,420)],
	 [Vector2(836,372),Vector2(852,372),Vector2(854,391),Vector2(861,400),Vector2(861,420),Vector2(840,420),Vector2(839,401),Vector2(832,391)]]]
const NORTH_ARMS: Array = [
	[[Vector2(231,901),Vector2(245,906),Vector2(245,911),Vector2(240,929),Vector2(242,944),Vector2(221,944),Vector2(220,933),Vector2(225,917)],
	 [Vector2(292,896),Vector2(310,896),Vector2(315,917),Vector2(324,934),Vector2(324,944),Vector2(304,944),Vector2(299,931),Vector2(292,923),Vector2(288,910)]],
	[[Vector2(412,901),Vector2(425,907),Vector2(422,918),Vector2(417,931),Vector2(420,944),Vector2(398,944),Vector2(397,934),Vector2(404,916)],
	 [Vector2(473,910),Vector2(489,906),Vector2(495,923),Vector2(508,938),Vector2(508,944),Vector2(486,944),Vector2(476,933),Vector2(472,923)]],
	[[Vector2(564,935),Vector2(576,919),Vector2(591,900),Vector2(610,905),Vector2(603,916),Vector2(591,934),Vector2(593,944),Vector2(565,944)],
	 [Vector2(649,915),Vector2(675,908),Vector2(680,912),Vector2(690,905),Vector2(697,910),Vector2(698,924),Vector2(690,932),Vector2(671,934),Vector2(654,926)]],
	[[Vector2(747,934),Vector2(760,915),Vector2(771,901),Vector2(790,907),Vector2(781,922),Vector2(770,936),Vector2(771,944),Vector2(747,944)],
	 [Vector2(830,914),Vector2(852,906),Vector2(859,908),Vector2(869,904),Vector2(875,914),Vector2(874,929),Vector2(865,935),Vector2(845,933),Vector2(831,925)]]]

static func paint(canvas: CanvasItem, points: Array, anchor: Vector2, scale_value: float) -> void:
	var vertices := PackedVector2Array()
	var uv := PackedVector2Array()
	for point in points:
		vertices.append((point-anchor)*scale_value)
		uv.append(point/ATLAS.get_size())
	canvas.draw_polygon(vertices,PackedColorArray([Color.WHITE]),uv,ATLAS)

static func draw_pose(canvas: CanvasItem, row: int, region: Rect2, scale_value: float) -> void:
	var south := row==1
	var lower := SOUTH_LOWER if south else NORTH_LOWER
	var feet := Vector2(region.get_center().x,region.end.y)
	var key := clampi(floori(region.get_center().x/180.0)-1,0,3)
	var moving := Rect2(region.position.x,lower,region.size.x,region.end.y-lower)
	canvas.draw_texture_rect_region(ATLAS,Rect2(Vector2(-region.size.x*.5,lower-region.end.y)*scale_value,moving.size*scale_value),moving)
	var arms: Array = SOUTH_ARMS[key] if south else NORTH_ARMS[key]
	for arm in arms:
		paint(canvas,arm,feet,scale_value)
	paint(canvas,SOUTH_CORE if south else NORTH_CORE,SOUTH_FEET if south else NORTH_FEET,scale_value)
