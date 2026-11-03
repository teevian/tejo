class_name JoPhoneArt
extends RefCounted

const Appearance = preload("res://scripts/jo_art.gd")
const ATLAS: Texture2D = preload("res://assets/characters/jo/jo-phone-poses.png")
const CELL := Vector2(400,640)
const FOOT_ANCHOR := Vector2(200,600)
const SOURCE_HEIGHT := 516.0
# Jo's reference profile, with a moderate extra downward nod while reading.
# Four pocket poses followed by four quiet scrolling poses.
# All cutouts share one scale and a fixed foot anchor, including the reverse gesture.
const FRAMES: Array[Rect2] = [
	Rect2(0,0,400,640),Rect2(400,0,400,640),
	Rect2(800,0,400,640),Rect2(1200,0,400,640),
	Rect2(0,640,400,640),Rect2(400,640,400,640),
	Rect2(800,640,400,640),Rect2(1200,640,400,640),
]

static func draw_pose(canvas: CanvasItem, frame: int, height: float = Appearance.HEIGHT) -> void:
	var factor := height/SOURCE_HEIGHT
	canvas.draw_texture_rect_region(ATLAS,Rect2(-FOOT_ANCHOR*factor,CELL*factor),FRAMES[clampi(frame,0,7)])
