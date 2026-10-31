extends StaticBody2D
## Visual height and the occupied ground are separate, in the same foot-sorted actor.
## Both physics and navigation use the authored ground polygons, never the canopy.
var surface: Polygon2D
var footprints: Array[PackedVector2Array] = []
var scenery_kind := "masonry"
var ground_bounds := Rect2()
var screen_bounds := Rect2()
var cutout_mask: Texture2D
var mask_world_rect := Rect2()
static var occlusion_images: Dictionary = {}

func configure(texture_value: Texture2D, source_points: PackedVector2Array, contact: Vector2, origin: Vector2, pixel_scale: Vector2) -> void:
	var world_points := PackedVector2Array()
	for point in source_points:
		world_points.append(origin+point*pixel_scale)
	configure_mapped(texture_value,source_points,world_points,origin+contact*pixel_scale)

func configure_mapped(texture_value: Texture2D, source_points: PackedVector2Array, world_points: PackedVector2Array, contact: Vector2) -> void:
	position = contact
	screen_bounds = Rect2(world_points[0],Vector2.ZERO)
	for point in world_points: screen_bounds = screen_bounds.expand(point)
	surface = Polygon2D.new()
	var local_points := PackedVector2Array()
	for point in world_points:
		local_points.append(point-contact)
	surface.polygon = local_points
	surface.uv = source_points
	surface.texture = texture_value
	surface.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(surface)

func add_footprint(world_points: PackedVector2Array) -> void:
	var bounds := Rect2(world_points[0],Vector2.ZERO)
	for point in world_points: bounds = bounds.expand(point)
	ground_bounds = bounds if footprints.is_empty() else ground_bounds.merge(bounds)
	var local_points := PackedVector2Array()
	for point in world_points:
		local_points.append(point-position)
	var collider := CollisionPolygon2D.new()
	collider.polygon = local_points
	add_child(collider)
	footprints.append(world_points)
	collision_layer = 1
	collision_mask = 2

func configure_cutout_mask(texture: Texture2D, rect: Rect2) -> void:
	cutout_mask = texture
	mask_world_rect = rect

static func _image(texture: Texture2D) -> Image:
	var key := texture.get_instance_id()
	if not occlusion_images.has(key):
		var source := texture.get_image()
		if source.is_compressed(): source.decompress()
		occlusion_images[key] = source
	return occlusion_images[key]

func covers_point(point: Vector2) -> bool:
	if not screen_bounds.has_point(point) or not Geometry2D.is_point_in_polygon(surface.to_local(point),surface.polygon): return false
	if cutout_mask==null: return true
	var uv := (point-mask_world_rect.position)/mask_world_rect.size
	var mask_image := _image(cutout_mask)
	var mask := mask_image.get_pixelv(Vector2i(uv*Vector2(mask_image.get_size())).clamp(Vector2i.ZERO,mask_image.get_size()-Vector2i.ONE))
	var paint_image := _image(surface.texture)
	var paint := paint_image.get_pixelv(Vector2i(uv*Vector2(paint_image.get_size())).clamp(Vector2i.ZERO,paint_image.get_size()-Vector2i.ONE))
	var green := paint.g-maxf(paint.r*.92,paint.b*.80)
	var chroma := maxf(paint.r,maxf(paint.g,paint.b))-minf(paint.r,minf(paint.g,paint.b))
	var leaf := smoothstep(-.006,.018,green)*smoothstep(.035,.085,chroma)
	return maxf(mask.r,mask.g*leaf)*mask.a>.12
