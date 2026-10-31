extends SceneTree
## Offline snapshot of the incoming 10593d9 body/gait. The runtime will use
## complete baked sprites; these original multipart painters stay reference-only.
const Reference = preload("res://tools/pulled_walk_reference.gd")
const SIZE := Vector2i(200,280)
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
		var frame := 0 if key==0 else 1+(key-1)*2
		var region := Reference.pose_region(0,row,frame)
		draw_set_transform(Vector2(100,260))
		if key==0:
			draw_texture_rect_region(Reference.ATLASES[0],Rect2(-Vector2(region.size.x*.5,region.size.y),region.size),region)
		elif row==0:
			Reference.TeFrontGait.draw_pose(self,region,1.0)
		elif row==4:
			Reference.TeNorthGait.draw_pose(self,region,1.0)
		elif row==2:
			Reference.TeSideGait.draw_pose(self,region,1.0)
		else:
			Reference.TeDiagonalGait.draw_pose(self,row,region,1.0)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	if DisplayServer.get_name()=="headless":
		push_error("Baking the incoming gait requires the graphics renderer")
		quit(1)
		return
	var view := SubViewport.new()
	view.size = SIZE*FACTOR
	view.transparent_bg = true
	view.world_2d = World2D.new()
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(view)
	var pose := Pose.new()
	pose.scale = Vector2.ONE*FACTOR
	view.add_child(pose)
	var atlas := Image.create(1000*FACTOR,1400*FACTOR,false,Image.FORMAT_RGBA8)
	for row in 5:
		for key in 5:
			pose.row = row
			pose.key = key
			pose.queue_redraw()
			for i in 3:
				await process_frame
			RenderingServer.force_draw()
			var pixels := view.get_texture().get_image()
			atlas.blit_rect(pixels,Rect2i(Vector2i.ZERO,SIZE*FACTOR),Vector2i(key*200,row*280)*FACTOR)
	atlas.save_png("res://assets/characters/open_world/sources/te-pulled-10593d9.png")
	print("Baked all 25 incoming Te poses at their original anatomy, foot anchors and four-key cadence")
	quit()
