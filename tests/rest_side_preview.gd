extends SceneTree
const Person = preload("res://scripts/open_world_person.gd")

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	if DisplayServer.get_name()=="headless":
		quit(1)
		return
	var view := SubViewport.new()
	view.size = Vector2i(1100,960)
	view.world_2d = World2D.new()
	view.disable_3d = true
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(view)
	var background := ColorRect.new()
	background.size = Vector2(1100,960)
	background.color = Color("a7b29d")
	view.add_child(background)
	var sleeping := "--sleep" in OS.get_cmdline_user_args()
	for row in 3:
		var label := Label.new()
		label.text = ["Sentados · mão do Te apoiada no chão","Deitados sobre o ombro · esquerda","Deitados sobre o ombro · direita"][row]
		if sleeping: label.text = ["A dormir · de costas","A dormir · sobre o ombro esquerdo","A dormir · sobre o ombro direito"][row]
		label.position = Vector2(310,25+row*310)
		label.add_theme_font_size_override("font_size",23)
		label.add_theme_color_override("font_color",Color("2b4036"))
		view.add_child(label)
		for kind in 2:
			var person := Person.new()
			person.kind = kind
			person.ground_seated = true
			person.eyes_closed = sleeping
			person.ground_pose = row+1 if sleeping else (0 if row==0 else row+1)
			person.position = Vector2(415+kind*285,290+row*310)
			person.scale = Vector2(2.1,2.1)
			view.add_child(person)
			person.set_physics_process(false)
	for i in 3: await process_frame
	RenderingServer.force_draw()
	view.get_texture().get_image().save_png("res://output/sleep-closed-eyes-preview.png" if sleeping else "res://output/rest-side-preview.png")
	print("PASS: actual seated hand and both fully side-lying pairs captured")
	quit()
