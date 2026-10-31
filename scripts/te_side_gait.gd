extends RefCounted
## One side-facing head and shirt, with the original painted limb articulations.
## Art mirrors this composition for the left walk, just like the original atlas.
const ATLAS: Texture2D = preload("res://assets/characters/open_world/te-walk-v4.png")
const SOURCE_FEET := Vector2(90.5,765)
const SHOULDER := Vector2(82,650)
const WAIST_Y := 676.0
# The idle arm hides part of the shirt. Fill that small area with unobscured
# cloth from the contact painting, then retain the visible idle shirt around it.
const SHIRT: Array[Vector2] = [Vector2(61,643),Vector2(107,643),Vector2(107,673),Vector2(104,678),Vector2(65,678),Vector2(61,674)]
const UPPER: Array[Vector2] = [Vector2(57,553),Vector2(124,553),Vector2(124,615),Vector2(108,624),Vector2(107,644),Vector2(97,647),Vector2(93,650),Vector2(74,650),Vector2(70,647),Vector2(59,647),Vector2(57,630)]
const BACK: Array[Vector2] = [Vector2(59,640),Vector2(72,644),Vector2(70,655),Vector2(73,675),Vector2(73,678),Vector2(62,678)]
const FRONT: Array[Vector2] = [Vector2(102,642),Vector2(108,642),Vector2(108,674),Vector2(104,678),Vector2(102,665)]
# Each key retains its own shorts, legs and feet. Only the waistband bridges
# the inconsistent source shirt lengths; everything below that seam is rigid.
const WAISTS: Array[Rect2] = [Rect2(248,677,45,10),Rect2(424,678,42,10),Rect2(603,694,54,10),Rect2(790,679,39,10)]
const WAIST_BOTTOMS: Array[Vector2] = [Vector2(247,299),Vector2(424,467),Vector2(593,665),Vector2(790,837)]
const LOWER: Array = [
	[Vector2(247,687),Vector2(299,687),Vector2(306,705),Vector2(341,705),Vector2(341,765),Vector2(199,765),Vector2(199,705),Vector2(239,705)],
	[Vector2(424,688),Vector2(467,688),Vector2(469,705),Vector2(488,705),Vector2(488,765),Vector2(412,765),Vector2(412,705),Vector2(424,705)],
	[Vector2(593,704),Vector2(665,704),Vector2(703,705),Vector2(703,765),Vector2(557,765),Vector2(557,705),Vector2(592,705)],
	[Vector2(790,689),Vector2(837,689),Vector2(846,700),Vector2(859,705),Vector2(859,765),Vector2(761,765),Vector2(761,705),Vector2(790,705)]]
const ARM_ROOTS: Array[Vector2] = [Vector2(246,637),Vector2(448,654),Vector2(652,665),Vector2(819,654)]
const NEAR_ARMS: Array = [
	[Vector2(235,629),Vector2(257,638),Vector2(248,655),Vector2(244,670),Vector2(244,681),Vector2(247,690),Vector2(243,699),Vector2(232,702),Vector2(221,694),Vector2(222,686),Vector2(226,681),Vector2(226,662),Vector2(229,646)],
	[Vector2(437,648),Vector2(460,647),Vector2(461,661),Vector2(471,674),Vector2(482,680),Vector2(488,688),Vector2(480,697),Vector2(471,699),Vector2(464,692),Vector2(460,686),Vector2(449,678),Vector2(441,669)],
	[Vector2(639,665),Vector2(650,663),Vector2(665,656),Vector2(674,667),Vector2(685,672),Vector2(692,668),Vector2(700,668),Vector2(706,675),Vector2(706,687),Vector2(701,694),Vector2(689,695),Vector2(681,691),Vector2(667,692),Vector2(653,684),Vector2(644,677)],
	[Vector2(807,654),Vector2(831,649),Vector2(833,659),Vector2(844,663),Vector2(852,660),Vector2(858,664),Vector2(860,674),Vector2(854,681),Vector2(844,683),Vector2(832,680),Vector2(819,678),Vector2(810,669)]]
const FAR_ROOTS: Array[Vector2] = [Vector2(291,646),Vector2.ZERO,Vector2(596,644),Vector2(785,636)]
const FAR_ARMS: Array = [
	[Vector2(289,640),Vector2(299,650),Vector2(313,660),Vector2(321,667),Vector2(321,676),Vector2(313,679),Vector2(303,674),Vector2(294,665),Vector2(289,660)],
	[],
	[Vector2(590,635),Vector2(607,646),Vector2(605,660),Vector2(592,674),Vector2(591,682),Vector2(598,690),Vector2(589,697),Vector2(577,696),Vector2(567,688),Vector2(568,680),Vector2(578,664)],
	[Vector2(782,630),Vector2(797,638),Vector2(793,654),Vector2(784,666),Vector2(789,673),Vector2(783,681),Vector2(772,681),Vector2(761,674),Vector2(760,668),Vector2(768,660),Vector2(773,646)]]

static func paint(canvas: CanvasItem, points: Array, anchor: Vector2, scale_value: float, source_points: Array = []) -> void:
	var vertices := PackedVector2Array()
	var uv := PackedVector2Array()
	for i in points.size():
		vertices.append((points[i]-anchor)*scale_value)
		uv.append((points[i] if source_points.is_empty() else source_points[i])/ATLAS.get_size())
	canvas.draw_polygon(vertices,PackedColorArray([Color.WHITE]),uv,ATLAS)

static func draw_pose(canvas: CanvasItem, region: Rect2, scale_value: float) -> void:
	var key := clampi(floori(region.get_center().x/180.0)-1,0,3)
	var feet := Vector2(region.get_center().x,region.end.y)
	if not FAR_ARMS[key].is_empty():
		var far_shoulder := Vector2(104,646) if key==0 else Vector2(64,643)
		paint(canvas,FAR_ARMS[key],FAR_ROOTS[key]+SOURCE_FEET-far_shoulder,scale_value)
	paint(canvas,LOWER[key],feet,scale_value)
	var waist: Rect2 = WAISTS[key]
	var sides: Vector2 = WAIST_BOTTOMS[key]
	var source: Array[Vector2] = [waist.position,Vector2(waist.end.x,waist.position.y),Vector2(sides.y,waist.end.y),Vector2(sides.x,waist.end.y)]
	var belt: Array[Vector2] = [Vector2(waist.position.x,WAIST_Y),Vector2(waist.end.x,WAIST_Y),source[2],source[3]]
	paint(canvas,belt,feet,scale_value,source)
	var cloth: Array[Vector2] = []
	for point in SHIRT:
		cloth.append(Vector2(259+(point.x-61)*27.0/50.0,641+(point.y-643)*33.0/36.0))
	paint(canvas,SHIRT,SOURCE_FEET,scale_value,cloth)
	paint(canvas,BACK,SOURCE_FEET,scale_value)
	paint(canvas,FRONT,SOURCE_FEET,scale_value)
	# Rigidly attach each original arm at the same shoulder. No limb is stretched.
	paint(canvas,NEAR_ARMS[key],ARM_ROOTS[key]+SOURCE_FEET-SHOULDER,scale_value)
	paint(canvas,UPPER,SOURCE_FEET,scale_value)
