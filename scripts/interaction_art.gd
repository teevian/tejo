extends RefCounted
const WorldScale = preload("res://scripts/world_scale.gd")
const ATLAS: Texture2D = preload("res://assets/characters/interactions/interaction-poses.png")
const REST_SEQUENCE_ATLASES := [preload("res://assets/characters/interactions/te-rest-sequence.png"),preload("res://assets/characters/interactions/jo-rest-sequence.png")]
const REST_SIDE_ATLASES := [preload("res://assets/characters/interactions/te-rest-side.png"),preload("res://assets/characters/interactions/jo-rest-side.png")]
const REST_LOOK_ATLASES := [preload("res://assets/characters/interactions/te-rest-look.png"),preload("res://assets/characters/interactions/jo-rest-look.png")]
const SAND_REGIONS := [Rect2(20,6,258,294),Rect2(278,6,258,294),Rect2(20,300,258,294),Rect2(278,300,258,294)]
const SAND_RECT := Rect2(-51.6,-110.4,103.2,117.6)
const SAND_SEQUENCE := [0,1,2,3,2,1]
const SAND_FRAME_SECONDS := 0.4
const PICKUP := Rect2(1100,96,356,407)
const SCALE := WorldScale.PERSON_HEIGHTS[0]/588.0
const SEATED_POSE_SECONDS := 30.0
const SEATED_POSE_COUNT := 3
const GROUND_POSE_COUNT := 5
# Every posture has two independent silhouettes with space between the characters.
const SEATED_REGIONS := [
	[Rect2(331,630,362,540), Rect2(1374,630,324,540)],
	[Rect2(205,1230,613,540), Rect2(1348,1230,375,540)],
	[Rect2(348,1830,327,540), Rect2(1245,1830,582,540)],
]
const SEATED_RECTS := [
	[Rect2(-45.250,-135.000,90.500,135.000), Rect2(-39.600,-132.000,79.200,132.000)],
	[Rect2(-71.300,-137.000,122.600,108.000), Rect2(-32.833,-132.000,91.667,132.000)],
	[Rect2(-53.875,-135.000,81.750,135.000), Rect2(-43.889,-137.000,107.778,100.000)],
]
const SEATED_HEAD_X := [[0.0,-7.0],[-36.0,14.0],[-7.0,37.0]]
const GROUND_REGIONS := [
	[Rect2(311,2430,401,540), Rect2(1330,2430,411,540)],
	[Rect2(380,3030,263,540), Rect2(1420,3030,231,540)],
]
const GROUND_RECTS := [
	[Rect2(-40.843,-110.000,81.685,110.000), Rect2(-41.100,-108.000,82.200,108.000)],
	[Rect2(-62,-110,124,110), Rect2(-46,-108,92,108)],
	[Rect2(-100,-110,155,110), Rect2(-62,-90,124,90)],
	[Rect2(-100,-110,155,110), Rect2(-62,-90,124,90)],
	[Rect2(-70,-125,140,125), Rect2(-65,-125,130,125)],
]

static func seated_rect(kind: int, pose: int = 0) -> Rect2:
	return SEATED_RECTS[posmod(pose,SEATED_POSE_COUNT)][kind]

static func draw_sand(canvas: CanvasItem, time: float) -> void:
	var frame: int = SAND_SEQUENCE[posmod(int(time/SAND_FRAME_SECONDS),SAND_SEQUENCE.size())]
	canvas.draw_texture_rect_region(ATLAS,SAND_RECT,SAND_REGIONS[frame])

static func draw_seated(canvas: CanvasItem, kind: int, pose: int = 0) -> void:
	pose = posmod(pose,SEATED_POSE_COUNT)
	canvas.draw_texture_rect_region(ATLAS,seated_rect(kind,pose),SEATED_REGIONS[pose][kind])

static func draw_ground(canvas: CanvasItem, kind: int, pose: int = 0, gaze_key: int = 2, sleeping := false) -> void:
	pose = posmod(pose,GROUND_POSE_COUNT)
	if pose==4:
		var factor: float = WorldScale.PERSON_HEIGHTS[kind]/438.0
		# Jo briefly holds the left profile on the final key of a leftward glance.
		var key: int = [0,0,2,3,4][clampi(gaze_key,0,4)] if kind==1 else clampi(gaze_key,0,4)
		canvas.draw_texture_rect_region(REST_SEQUENCE_ATLASES[kind],Rect2(Vector2(-240,-520)*factor,Vector2(480,560)*factor),Rect2(key*480,0,480,560))
		return
	if pose>=1:
		if sleeping: preload("res://scripts/sleep_art.gd").draw(canvas,kind,pose)
		elif pose>=2:
			var factor: float = WorldScale.PERSON_HEIGHTS[kind]/438.0
			canvas.draw_texture_rect_region(REST_SIDE_ATLASES[kind],Rect2(Vector2(-320,-520)*factor,Vector2(640,560)*factor),Rect2(1920,(pose-2)*560,640,560))
		else: draw_look(canvas,kind,1,gaze_key)
		return
	draw_look(canvas,kind,0,gaze_key)

static func draw_look(canvas: CanvasItem, kind: int, pose: int, gaze_key: int) -> void:
	# Every gaze key keeps the approved body, hands and shared phone fixed.
	var scale_value: float = WorldScale.PERSON_HEIGHTS[kind]/438.0
	canvas.draw_texture_rect_region(REST_LOOK_ATLASES[kind],Rect2(Vector2(-240,-520)*scale_value,Vector2(480,560)*scale_value),Rect2(clampi(gaze_key,0,4)*480,pose*560,480,560))

static func draw_pickup(canvas: CanvasItem) -> void:
	canvas.draw_texture_rect_region(ATLAS,Rect2(Vector2(-PICKUP.size.x*0.5,-PICKUP.size.y)*SCALE,PICKUP.size*SCALE),PICKUP)
