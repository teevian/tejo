extends Node2D
## Reuses exact pixels from the terrain painting as an opaque depth-sorted surface.
## The ground copy stays underneath; only the solid masonry outline goes above actors.
var surface: Polygon2D

func configure(texture_value: Texture2D, source_points: PackedVector2Array, contact: Vector2, origin: Vector2, pixel_scale: Vector2) -> void:
	position = origin + contact * pixel_scale
	surface = Polygon2D.new()
	var local_points := PackedVector2Array()
	for point in source_points:
		local_points.append((point-contact)*pixel_scale)
	surface.polygon = local_points
	surface.uv = source_points
	surface.texture = texture_value
	surface.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(surface)
