class_name JoPhoneArt
extends RefCounted

const Appearance = preload("res://scripts/jo_art.gd")
const ATLAS: Texture2D = preload("res://assets/characters/jo/jo-phone-poses.png")
# Four pocket-to-phone poses, followed by four quiet reading/scrolling poses.
const FRAMES: Array[Rect2] = [
	Rect2(61, 30, 202, 567), Rect2(355, 36, 228, 562),
	Rect2(693, 38, 200, 560), Rect2(1009, 39, 200, 559),
	Rect2(63, 656, 207, 557), Rect2(378, 657, 207, 556),
	Rect2(689, 657, 206, 556), Rect2(1005, 657, 204, 557),
]
const FOOT_CENTER: Array[float] = [166.5, 486.0, 795.0, 1112.5, 168.0, 483.0, 795.5, 1112.0]

static func draw_pose(canvas: CanvasItem, frame: int) -> void:
	var region := FRAMES[frame]
	# Fixed scale lets the head lower toward the phone without stretching the legs.
	var size_value := region.size * (Appearance.HEIGHT / FRAMES[0].size.y)
	# An arm reaching into a pocket changes the silhouette width, not the foot position.
	var left := (region.position.x - FOOT_CENTER[frame]) * (Appearance.HEIGHT / FRAMES[0].size.y)
	canvas.draw_texture_rect_region(ATLAS, Rect2(Vector2(left, -size_value.y), size_value), region)
