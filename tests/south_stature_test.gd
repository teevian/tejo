extends SceneTree
const Person=preload("res://scripts/open_world_person.gd")
const Art=preload("res://scripts/open_world_art.gd")
var failed=false
func _initialize():
	call_deferred("run")
func run():
	if DisplayServer.get_name()=="headless":
		push_error("Graphics required")
		quit(1)
		return
	var view=SubViewport.new()
	view.size=Vector2i(840,400)
	view.transparent_bg=true
	view.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(view)
	var people=[]
	for col in 3:
		var p=Person.new()
		p.kind=1 if col==2 else 0
		p.facing=Vector2.DOWN
		p.visual_facing=Vector2.DOWN
		p.moving=col>0
		p.velocity=Vector2.DOWN*235 if col>0 else Vector2.ZERO
		p.position=Vector2(140+col*280,350)
		p.scale=Vector2.ONE*1.8
		view.add_child(p)
		p.set_physics_process(false)
		people.append(p)
	for frame in 4:
		for p in people:
			p.walked=(frame+.1)*Art.STRIDE/4
			p.body.queue_redraw()
		for i in 3: await process_frame
		RenderingServer.force_draw()
		var image=view.get_texture().get_image()
		var tops=[]
		for col in 2:
			var top=400
			for y in 350:
				for x in range(col*280,(col+1)*280):
					if image.get_pixel(x,y).a>.8: top=mini(top,y)
			tops.append(top)
		if absi(tops[0]-tops[1])>3:
			failed=true
			push_error("Te changes stature from idle to south step %d: %s"%[frame,tops])
		image.save_png("res://output/south-arms/motor-%d.png"%frame)
	if not failed: print("PASS: actual Te idle and all south steps match crown-to-ground stature within 3 rendered pixels")
	quit(1 if failed else 0)
