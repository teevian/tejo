extends SceneTree
const Art = preload("res://scripts/open_world_art.gd")
class Sheet:
	extends Node2D
	func _ready() -> void:
		var ink := ShaderMaterial.new()
		ink.shader = preload("res://shaders/opaque_cutout.gdshader")
		material = ink
	func _draw() -> void:
		var directions := [Vector2.DOWN,Vector2(1,1),Vector2.RIGHT,Vector2(1,-1),Vector2.UP]
		for row in 5:
			for frame in 9:
				Art.draw_pose(self,1,directions[row],frame>0,float(maxi(0,frame-1))*Art.STRIDE/8.0,Vector2(85+frame*150,245+row*225))
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1370,1160)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	RenderingServer.set_default_clear_color(Color("647269"))
	viewport.add_child(Sheet.new())
	for i in 5:
		await process_frame
	RenderingServer.force_draw()
	viewport.get_texture().get_image().save_png("res://output/jo-movement-v5-preview.png")
	quit()
