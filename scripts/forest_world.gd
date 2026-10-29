extends Node2D
## World-space scenery. Landmarks stay aligned with interaction points.
const WORLD_WIDTH := 3520.0
const CONTINUATION = preload("res://assets/backgrounds/sintra-continuation.png")
const NEAR_FOLIAGE = preload("res://assets/foreground/sintra-foreground.png")
var near_layer: Node2D

func _ready() -> void:
	var painting := Sprite2D.new()
	painting.name = "ForestContinuation"
	painting.texture = CONTINUATION
	painting.centered = false
	painting.position = Vector2(1120, -44)
	painting.scale = Vector2(2400, 800) / CONTINUATION.get_size()
	painting.z_index = -9
	painting.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	# Overlap the original painting; feather only the joining edge, not landmarks.
	var blend := Shader.new()
	blend.code = "shader_type canvas_item; void fragment() { vec4 ink = texture(TEXTURE, UV); ink.a *= smoothstep(0.0, 0.066667, UV.x); COLOR = ink; }"
	var material_value := ShaderMaterial.new()
	material_value.shader = blend
	painting.material = material_value
	add_child(painting)
	near_layer = Node2D.new()
	near_layer.name = "NearFoliage"
	near_layer.z_index = 22
	add_child(near_layer)
	# Low plants frame the path without covering faces or the walkable trail.
	for item in [[180, 622, 0, 0.43], [1020, 636, 2, 0.48], [1450, 621, 0, 0.48], [2060, 640, 2, 0.43], [2610, 626, 0, 0.51], [3350, 624, 2, 0.50]]:
		_add_cutout(Vector2(item[0], item[1]), int(item[2]), float(item[3]))
	# Canopy silhouettes pass slightly faster than the landscape.
	_add_cutout(Vector2(1340, -95), 3, 0.61)
	_add_cutout(Vector2(2830, -125), 3, 0.76)

func _add_cutout(at: Vector2, cell: int, zoom: float) -> void:
	var regions: Array[Rect2] = [Rect2(0, 310, 575, 414), Rect2(590, 0, 465, 724), Rect2(1080, 320, 595, 404), Rect2(1660, 0, 512, 460)]
	var sprite := Sprite2D.new()
	sprite.texture = NEAR_FOLIAGE
	sprite.region_enabled = true
	sprite.region_rect = regions[cell]
	sprite.region_filter_clip_enabled = true
	sprite.centered = false
	sprite.position = at
	sprite.scale = Vector2.ONE * zoom
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	near_layer.add_child(sprite)

func update_parallax(camera_x: float) -> void:
	near_layer.position.x = -(camera_x - 640.0) * 0.08
