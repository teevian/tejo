extends RefCounted
const WorldScale = preload("res://scripts/world_scale.gd")
const ATLAS: Texture2D = preload("res://assets/characters/open_world/interaction-poses-v2.png")
const SHOULDER := Rect2(210,25,516,588)
const SEATED: Array[Rect2] = [Rect2(867,98,290,513),Rect2(259,634,282,496)]
const PICKUP := Rect2(840,710,356,407)
const SCALE := WorldScale.PERSON_HEIGHTS[0]/588.0

static func draw_shoulder(canvas: CanvasItem, side: float) -> void:
	# The anchor is between the feet, not the centre of the outstretched arm.
	canvas.draw_set_transform(Vector2.ZERO,0,Vector2(side,1))
	canvas.draw_texture_rect_region(ATLAS,Rect2(Vector2(-155,-588)*SCALE,SHOULDER.size*SCALE),SHOULDER)
	canvas.draw_set_transform(Vector2.ZERO)

static func draw_seated(canvas: CanvasItem, kind: int) -> void:
	var region := SEATED[kind]
	canvas.draw_texture_rect_region(ATLAS,Rect2(Vector2(-region.size.x*0.5,-region.size.y)*SCALE,region.size*SCALE),region)

static func draw_pickup(canvas: CanvasItem) -> void:
	canvas.draw_texture_rect_region(ATLAS,Rect2(Vector2(-PICKUP.size.x*0.5,-PICKUP.size.y)*SCALE,PICKUP.size*SCALE),PICKUP)
