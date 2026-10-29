class_name JoArt
extends RefCounted

const ATLAS: Texture2D = preload("res://assets/characters/jo/jo-sprites-v6.png")
const FACE_PORTRAIT: Texture2D = preload("res://assets/characters/jo/jo-portrait.png")
const HEIGHT := 182.0
const PIXEL_SCALE := HEIGHT / 420.0
# Each complete pose includes its own painted head in that pose's original angle.
const FRAMES: Array[Rect2] = [
	Rect2(83, 32, 166, 420), Rect2(397, 33, 166, 419),
	Rect2(710, 32, 166, 420), Rect2(1023, 32, 166, 420),
	Rect2(27, 488, 299, 400), Rect2(373, 489, 221, 395),
	Rect2(696, 488, 213, 400), Rect2(959, 488, 292, 399),
	Rect2(37, 904, 226, 345), Rect2(395, 907, 175, 342),
	Rect2(633, 903, 286, 315), Rect2(955, 922, 295, 326),
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
	var destination := Rect2(Vector2(-size_value.x * 0.5, -size_value.y), size_value)
	canvas.draw_texture_rect_region(ATLAS, destination, region)

static func draw_portrait(canvas: CanvasItem, center: Vector2) -> void:
	canvas.draw_circle(center, 25.0, Color("d5ceaf"))
	canvas.draw_texture_rect(FACE_PORTRAIT, Rect2(center + Vector2(-25, -26), Vector2(50, 50)), false)
