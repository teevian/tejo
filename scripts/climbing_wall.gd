extends Node2D
const PANORAMA: Texture2D = preload("res://assets/climbing/sintra-panorama.png")
var scene: Node2D
var face: ColorRect
var paint: ShaderMaterial

func _ready() -> void:
	z_index = -20
	face = ColorRect.new()
	face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	face.size = Vector2(1282,722)
	paint = ShaderMaterial.new()
	paint.shader = preload("res://shaders/climbing_wall.gdshader")
	paint.set_shader_parameter("escarpment",preload("res://assets/climbing/sintra-escarpment.png"))
	face.material = paint
	add_child(face)

func update_view() -> void:
	var visible_size: Vector2 = scene.get_viewport_rect().size/scene.camera.zoom
	face.position = scene.camera.position-visible_size*0.5-Vector2.ONE
	face.size = visible_size+Vector2(2,2)
	paint.set_shader_parameter("summit_reveal",scene.summit_reveal)
	paint.set_shader_parameter("view_origin",face.position)
	paint.set_shader_parameter("view_size",face.size)
	paint.set_shader_parameter("camera_y",scene.camera.position.y)
	paint.set_shader_parameter("yaw",scene.space.angle)
	queue_redraw()

func _draw() -> void:
	if not is_instance_valid(scene.camera) or scene.summit_reveal<=0: return
	var origin: Vector2 = scene.camera.position-Vector2(640,360)
	draw_texture_rect(PANORAMA,Rect2(origin+Vector2(-140,-70),Vector2(1580,1053)),false)
