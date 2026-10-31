extends SceneTree
const Art = preload("res://scripts/open_world_art.gd")
class Sheet:
	extends Node2D
	func _ready() -> void:
		var ink := ShaderMaterial.new()
		ink.shader = preload("res://shaders/opaque_cutout.gdshader")
		material = ink
	func _draw() -> void:
		for row in 4:
			var kind := row/2
			var direction := Vector2.RIGHT if row%2==0 else Vector2.LEFT
			for frame in 9:
				Art.draw_pose(self,kind,direction,frame>0,float(maxi(0,frame-1))*Art.STRIDE/8.0,Vector2(80+frame*150,210+row*215))
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1350,880)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	RenderingServer.set_default_clear_color(Color("647269"))
	viewport.add_child(Sheet.new())
	for i in 5:
		await process_frame
	RenderingServer.force_draw()
	viewport.get_texture().get_image().save_png("res://output/te-walk-consistent-side.png")
	quit()
