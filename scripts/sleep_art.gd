extends RefCounted
const Scale = preload("res://scripts/world_scale.gd")
const POSES := [preload("res://assets/characters/interactions/te-sleep-poses.png"),preload("res://assets/characters/interactions/jo-sleep-poses.png")]
const ROLLS := [preload("res://assets/characters/interactions/te-sleep-roll.png"),preload("res://assets/characters/interactions/jo-sleep-roll.png")]

static func draw(canvas: CanvasItem, kind: int, pose: int) -> void:
	var factor: float = Scale.PERSON_HEIGHTS[kind]/438.0
	canvas.draw_texture_rect_region(POSES[kind],Rect2(Vector2(-320,-520)*factor,Vector2(640,560)*factor),Rect2(clampi(pose-1,0,2)*640,0,640,560))
