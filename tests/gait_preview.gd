extends SceneTree
const Art = preload("res://scripts/open_world_art.gd")
class Sheet:
	extends Node2D
	var direction := Vector2.RIGHT
	func _ready() -> void:
		var ink := ShaderMaterial.new()
		ink.shader = preload("res://shaders/opaque_cutout.gdshader")
		material = ink
	func _draw() -> void:
		for kind in 2:
			for frame in 8:
				draw_set_transform(Vector2(80+frame*160,270+kind*260))
				Art.draw_pose(self,kind,direction,true,float(frame)*Art.STRIDE/8.0)
			draw_set_transform(Vector2.ZERO)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	RenderingServer.set_default_clear_color(Color("56665c"))
	var sheet := Sheet.new()
	root.add_child(sheet)
	for entry in [[Vector2.RIGHT,"side"],[Vector2.DOWN,"front"],[Vector2(1,-1).normalized(),"diagonal"]]:
		sheet.direction=entry[0]
		sheet.queue_redraw()
		for i in 4:
			await process_frame
		RenderingServer.force_draw()
		root.get_texture().get_image().save_png("res://output/gait-"+entry[1]+".png")
	quit()
