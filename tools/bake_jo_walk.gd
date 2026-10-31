extends SceneTree
## Preserve Jo's approved complete body poses before replacing facial identity.
const Reference = preload("res://tools/pulled_walk_reference.gd")
const FACTOR := 4
class Pose:
	extends Node2D
	var row := 0
	var key := 0
	func _ready() -> void:
		var ink := ShaderMaterial.new()
		ink.shader = preload("res://shaders/opaque_cutout.gdshader")
		material = ink
	func _draw() -> void:
		var region := Reference.pose_region(1,row,0 if key==0 else 1+(key-1)*2)
		draw_texture_rect_region(Reference.ATLASES[1],Rect2(Vector2(100,260)-Vector2(region.size.x/2,region.size.y),region.size),region)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	if DisplayServer.get_name()=="headless":
		push_error("Jo body capture requires the graphics renderer")
		quit(1)
		return
	var view := SubViewport.new()
	view.size = Vector2i(800,1120)
	view.transparent_bg = true
	view.world_2d = World2D.new()
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(view)
	var pose := Pose.new()
	pose.scale = Vector2.ONE*FACTOR
	view.add_child(pose)
	var atlas := Image.create(4000,5600,false,Image.FORMAT_RGBA8)
	for row in 5:
		for key in 5:
			pose.row = row
			pose.key = key
			pose.queue_redraw()
			for i in 3:
				await process_frame
			RenderingServer.force_draw()
			atlas.blit_rect(view.get_texture().get_image(),Rect2i(0,0,800,1120),Vector2i(key*800,row*1120))
	atlas.save_png("res://assets/characters/open_world/sources/jo-body-v8.png")
	print("Captured Jo's 25 approved complete bodies without changing poses, scale or foot anchors")
	quit()
