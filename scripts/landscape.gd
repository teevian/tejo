extends Sprite2D

const STAGE_SIZE := Vector2(1280, 720)

func _ready() -> void:
	# Keep the painted trail aligned with the existing y=554 walking surface.
	centered = false
	if texture:
		scale = STAGE_SIZE / texture.get_size()
