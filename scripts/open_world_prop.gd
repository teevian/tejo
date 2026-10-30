extends StaticBody2D
## Opaque scenery sorts at its ground contact point. Leaf gaps remain real cutouts.
var sprite: Sprite2D
var half_width := 60.0
var height := 240.0
var seat_offsets: Array[Vector2] = []

func seat_position(index: int) -> Vector2:
	return position+seat_offsets[index]
