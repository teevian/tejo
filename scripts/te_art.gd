class_name TeArt
extends RefCounted

const ATLAS: Texture2D = preload("res://assets/characters/te/te-sprites.png")
const FACE_PORTRAIT: Texture2D = preload("res://assets/characters/te/te-portrait.png")
const HEIGHT := 184.0
const PIXEL_SCALE := HEIGHT / 424.0
# Every complete pose has Te's own painted head, turned with the body.
const FRAMES: Array[Rect2] = [
	Rect2(79, 19, 157, 424), Rect2(386, 18, 161, 425),
	Rect2(699, 20, 161, 423), Rect2(1010, 20, 162, 423),
	Rect2(29, 461, 292, 390), Rect2(368, 454, 239, 398),
	Rect2(687, 459, 216, 395), Rect2(960, 456, 283, 395),
	Rect2(44, 866, 243, 363), Rect2(407, 865, 199, 366),
	Rect2(654, 869, 278, 311), Rect2(959, 890, 287, 339),
]

# Only the second atlas row forms the walk cycle. Frames 8–9 are
# crouched running poses and introduce a visible height drop when walking.
const WALK_FRAMES: Array[int] = [4, 5, 6, 7]

static func frame_for(on_floor: bool, moving: bool, vertical_speed: float, step: float, clock: float) -> int:
	if not on_floor:
		return 10 if vertical_speed < 0.0 else 11
	if moving:
		return WALK_FRAMES[int(step * 0.6) % WALK_FRAMES.size()]
	return int(clock * 2.0) % 4

static func draw_pose(canvas: CanvasItem, frame: int) -> void:
	var region := FRAMES[frame]
	# One uniform scale for the whole atlas: bending a knee must not enlarge the body.
	var size_value := region.size * PIXEL_SCALE
	canvas.draw_texture_rect_region(ATLAS, Rect2(Vector2(-size_value.x * 0.5, -size_value.y), size_value), region)

static func draw_portrait(canvas: CanvasItem, center: Vector2) -> void:
	canvas.draw_circle(center, 25.0, Color("c6c6b6"))
	canvas.draw_texture_rect(FACE_PORTRAIT, Rect2(center + Vector2(-25, -26), Vector2(50, 50)), false)
