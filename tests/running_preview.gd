extends SceneTree
const Person = preload("res://scripts/open_world_person.gd")
const Run = preload("res://scripts/running_art.gd")
const DIRECTIONS := [Vector2.DOWN,Vector2(1,1),Vector2.RIGHT,Vector2(1,-1),Vector2.UP,Vector2(-1,-1),Vector2.LEFT,Vector2(-1,1)]
var people: Array = []

func _initialize() -> void: call_deferred("run")

func run() -> void:
	if DisplayServer.get_name()=="headless":
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute("/tmp/tejo-running-work/preview")
	var view := SubViewport.new()
	view.size = Vector2i(1200,560)
	view.disable_3d = true
	view.world_2d = World2D.new()
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(view)
	var background := ColorRect.new()
	background.color = Color("a7b29d")
	background.size = view.size
	view.add_child(background)
	for kind in 2:
		for direction in 8:
			var person := Person.new()
			person.kind = kind
			person.facing = DIRECTIONS[direction].normalized()
			person.visual_facing = person.facing
			person.position = Vector2(75+direction*150,270+kind*265)
			person.scale = Vector2(1.32,1.32)
			view.add_child(person)
			person.set_physics_process(false)
			people.append(person)
			var label := Label.new()
			label.position = Vector2(direction*150,12+kind*265)
			label.size.x = 150
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			label.text = ("Te · " if kind==0 else "Jo · ")+["S","SE","E","NE","N","NO","O","SO"][direction]
			label.add_theme_font_size_override("font_size",16)
			label.add_theme_color_override("font_color",Color("283d33"))
			view.add_child(label)
	for i in 3: await process_frame
	for frame in 48:
		for person in people:
			person.moving = true
			person.running = true
			person.velocity = person.facing*340
			person.run_distance = frame*340.0/24.0
			person.body.queue_redraw()
		await process_frame
		RenderingServer.force_draw()
		view.get_texture().get_image().save_png("/tmp/tejo-running-work/preview/%03d.png"%frame)
	print("PASS: eight-direction running preview captured from the actual game bodies")
	quit()
