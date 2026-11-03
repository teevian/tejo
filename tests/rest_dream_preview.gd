extends SceneTree
var scene: Node2D
var prefix := "dream"

func _initialize() -> void:
	call_deferred("run")
	create_timer(90,true,false,true).timeout.connect(func(): quit(1))

func capture(path: String) -> Image:
	await process_frame
	await process_frame
	RenderingServer.force_draw()
	var picture := root.get_texture().get_image()
	if not path.is_empty(): picture.save_png(path)
	return picture

func run() -> void:
	if DisplayServer.get_name()=="headless":
		quit(1)
		return
	scene = load("res://scenes/garden.tscn").instantiate()
	root.add_child(scene)
	while not scene._initialization_complete: await process_frame
	if "--second-track" in OS.get_cmdline_user_args():
		scene.rest_dream.set_track(1)
		prefix = "dream2"
	scene.set_process(false)
	scene.rest_dream.set_process(false)
	for p in scene.people: p.set_physics_process(false)
	scene._toggle_pause()
	await capture("res://output/"+prefix+"-sleep-menu.png")
	scene._toggle_pause()
	# The real forest and the approved resting drawings; only the review clock is advanced.
	var spot := Vector2.ZERO
	for y in range(3030,3331,30):
		for x in range(10530,10951,30):
			var at := Vector2(x,y)
			if scene._ground_rest_clear(at) and scene._ground_rest_clear(at+Vector2(132,0)):
				spot = at
				break
		if spot!=Vector2.ZERO: break
	if spot==Vector2.ZERO:
		push_error("No clear resting spot for dream review")
		quit(1)
		return
	for p in scene.people:
		p.position = spot+Vector2(p.kind*132,0)
		p.begin_ground_sitting(p.position)
		p._physics_process(0.02)
		p._advance_rest_transition(p.RestArt.SIT_SECONDS)
		p.begin_lying()
		p._advance_rest_transition(p.RestArt.LIE_SECONDS)
		p.close_rest_eyes()
	scene.camera.position = spot+Vector2(66,-60)
	scene.camera.zoom = Vector2(2.0,2.0)
	scene.day_cycle.minutes = 12*60
	scene.daylight.set_shader_parameter("daylight",scene.day_cycle.light_color())
	scene.hud.hide()
	scene.inventory_panel.hide()
	var dream = scene.rest_dream
	dream.layer.hide()
	var before := await capture("res://output/"+prefix+"-normal.png")
	for at in [8.0,38.0,88.0]:
		dream.layer.show()
		dream.apply_visuals(at,at,1.0)
		await capture("res://output/"+prefix+"-%02d.png"%int(at))
	# Hold time and composition fixed: only the measured beat impulse may change.
	dream.material.set_shader_parameter("beat",1.0)
	var on_beat := await capture("")
	dream.material.set_shader_parameter("beat",0.0)
	var between_beats := await capture("")
	var changed := 0
	for y in range(0,720,4):
		for x in range(0,1280,4):
			if on_beat.get_pixel(x,y)!=between_beats.get_pixel(x,y): changed += 1
	if changed<1000:
		push_error("Musical beat must visibly animate the actual shader")
		quit(1)
		return
	scene.hud.show()
	scene.inventory_panel.show()
	dream.layer.hide()
	var ordinary_ui := await capture("")
	dream.layer.show()
	dream.apply_visuals(88,88,1)
	var dreamy_ui := await capture("")
	# Exclude the rounded panel's transparent corners, which show the world below.
	if ordinary_ui.get_region(Rect2i(776,45,210,80)).get_data()!=dreamy_ui.get_region(Rect2i(776,45,210,80)).get_data():
		push_error("The dream must not recolour or distort the clock and HUD")
		quit(1)
		return
	scene.hud.hide()
	scene.inventory_panel.hide()
	# Verify the actual audio mixer silently, before it reaches the master output.
	var master_muted := AudioServer.is_bus_mute(0)
	AudioServer.set_bus_mute(0,true)
	AudioServer.add_bus()
	var bus := AudioServer.bus_count-1
	AudioServer.set_bus_name(bus,"DreamVerification")
	AudioServer.set_bus_send(bus,"Master")
	dream.player.bus = "DreamVerification"
	dream.player.volume_db = -10
	dream.player.play(40)
	var audible := false
	for i in 45:
		await process_frame
		if AudioServer.get_bus_peak_volume_left_db(bus,0)>-50: audible = true
	dream.player.stop()
	dream.player.bus = "Master"
	AudioServer.remove_bus(bus)
	AudioServer.set_bus_mute(0,master_muted)
	if not audible:
		push_error("The supplied music must produce real audio in the mixer")
		quit(1)
		return
	if "--animate" in OS.get_cmdline_user_args():
		DirAccess.make_dir_recursive_absolute("/tmp/tejo-"+prefix+"-motion")
		for frame in 48:
			var at := 85.0+float(frame)/8.0
			dream.apply_visuals(at,at,1)
			await capture("/tmp/tejo-"+prefix+"-motion/%03d.png"%frame)
	dream.stop_immediately()
	var after := await capture("res://output/"+prefix+"-restored.png")
	var change := 0.0
	for y in range(0,720,8):
		for x in range(0,1280,8):
			var a := before.get_pixel(x,y)
			var b := after.get_pixel(x,y)
			change += absf(a.r-b.r)+absf(a.g-b.g)+absf(a.b-b.b)
	print("PASS: Dormir menu, progressive dream, visible beat response, unchanged HUD and real decoded audio; reset mean colour difference ",change/(160*90*3))
	quit(0 if change/(160*90*3)<0.02 else 1)
