extends SceneTree
const Person = preload("res://scripts/open_world_person.gd")
const Prop = preload("res://scripts/discovery_prop.gd")
const Art = preload("res://scripts/football_art.gd")
const Floor = preload("res://tests/football_preview.gd").Floor
const OUTPUT := "/tmp/tejo-football-work/motion"

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	if DisplayServer.get_name()=="headless":
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	var kind := 0 if "--te" in OS.get_cmdline_user_args() else 1
	var output_dir := OUTPUT+"-te" if kind==0 else OUTPUT
	DirAccess.make_dir_recursive_absolute(output_dir)
	var view := SubViewport.new()
	view.size = Vector2i(1000,740)
	view.world_2d = World2D.new()
	view.disable_3d = true
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(view)
	var bg := ColorRect.new()
	bg.size = Vector2(1000,740)
	bg.color = Color("a7b29d")
	view.add_child(bg)
	var floor_node := Floor.new()
	floor_node.scale = Vector2(1.8,1.8)
	floor_node.opaque_paint = ShaderMaterial.new()
	floor_node.opaque_paint.shader = preload("res://shaders/opaque_cutout.gdshader")
	view.add_child(floor_node)
	var jo := Person.new()
	jo.kind = kind
	jo.controlled = true
	jo.world = floor_node
	jo.position = Vector2(310,350)
	floor_node.add_child(jo)
	jo.set_physics_process(false)
	var te := Person.new()
	te.kind = 1-kind
	te.world = floor_node
	te.position = jo.position+Vector2(-135,35)
	te.facing = Vector2.RIGHT
	te.visual_facing = Vector2.RIGHT
	floor_node.add_child(te)
	te.set_physics_process(false)
	var ball := Prop.new()
	ball.kind = 3
	ball.paint_height = 31
	ball.world = floor_node
	ball.position = jo.position+Vector2(20,0)
	floor_node.add_child(ball)
	var label := Label.new()
	label.position = Vector2(330,30)
	label.add_theme_font_size_override("font_size",24)
	label.add_theme_color_override("font_color",Color("2b4036"))
	view.add_child(label)
	for axis in ["walk_left","walk_right","walk_up","walk_down"]:
		if not InputMap.has_action(axis): InputMap.add_action(axis)
	ball.juggling.start(jo)
	var wanted := ["foot","foot"] if kind==0 else ["foot","knee","head","foot","knee","head"]
	var captured := 0
	for frame in 960:
		if not jo.is_juggling() or ball.juggling.count>=wanted.size(): break
		var action: String = wanted[ball.juggling.count]
		var point := Art.contact(action,mini(ball.juggling.count,1) if kind==0 else 0,1,kind)
		var offset: Vector2 = ball.position-Vector2(point.x,0)-jo.position
		for axis in ["walk_left","walk_right","walk_up","walk_down"]: Input.action_release(axis)
		if absf(offset.x)>4: Input.action_press("walk_right" if offset.x>0 else "walk_left")
		if absf(offset.y)>4: Input.action_press("walk_down" if offset.y>0 else "walk_up")
		if ball.juggling.vertical_speed<0 and absf(ball.juggling.height+point.y)<15 and ball.juggling.cooldown<=0 and ball.juggling.pending.is_empty():
			ball.juggling.request_touch()
		label.text = "Levantar com o pé" if ball.juggling.lifting else "Setas + Espaço · dar toques"
		await physics_frame
		jo._physics_process(1.0/60.0)
		ball.step_ball(1.0/60.0)
		te.facing = te.position.direction_to(jo.position)
		te.visual_facing = te.facing
		te.body.queue_redraw()
		if frame%3==0:
			await process_frame
			RenderingServer.force_draw()
			view.get_texture().get_image().save_png(output_dir+"/%03d.png"%captured)
			captured += 1
	for axis in ["walk_left","walk_right","walk_up","walk_down"]: Input.action_release(axis)
	if kind==0 and ball.juggling.count==2:
		label.text = "Segundo toque · a bola dispara!"
		for frame in 75:
			await physics_frame
			jo._physics_process(1.0/60.0)
			ball.step_ball(1.0/60.0)
			if frame%3==0:
				await process_frame
				RenderingServer.force_draw()
				view.get_texture().get_image().save_png(output_dir+"/%03d.png"%captured)
				captured += 1
	print("PASS: continuous football preview, %d touches, %d captured frames"%[ball.juggling.count,captured])
	quit(0 if ball.juggling.count==wanted.size() else 1)
