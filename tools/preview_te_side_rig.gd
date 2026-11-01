extends SceneTree
const Rig = preload("res://scripts/te_side_rig.gd")
class Board extends Node2D:
	func _ready() -> void:
		var ink := ShaderMaterial.new()
		ink.shader = preload("res://shaders/opaque_cutout.gdshader")
		material = ink
	func _draw() -> void:
		for side in 2:
			for frame in 8:
				draw_set_transform(Vector2(frame*220+110,side*310+280),0,Vector2(-.5 if side else .5,.5))
				Rig.draw_pose(self,frame/8.0*Rig.STRIDE,480)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var view := SubViewport.new()
	view.size = Vector2i(1760,620)
	view.transparent_bg = true
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(view)
	view.add_child(Board.new())
	for i in 3: await process_frame
	RenderingServer.force_draw()
	view.get_texture().get_image().save_png("res://output/te-propostas-rpg/te-side-rig-v19-board.png")
	quit()
