extends SceneTree
var scene: Node2D
var world: Node2D
func _initialize() -> void:
	create_timer(180,true,false,true).timeout.connect(func():quit(2))
	call_deferred("run")
func capture(label: String) -> void:
	scene.daylight.set_shader_parameter("daylight",scene.day_cycle.light_color())
	scene.hud.area_title = "Lord Byron · conversa e dança"; scene.hud.interaction_prompt = ""; scene.hud.comment_time = 0; scene.hud.queue_redraw()
	for i in 3: await process_frame
	RenderingServer.force_draw()
	root.get_texture().get_image().save_png("res://output/village-nightlife-"+label+".png")
func run() -> void:
	root.size = Vector2i(1280,720)
	scene = load("res://scenes/sintra_village.tscn").instantiate(); root.add_child(scene)
	for i in 5: await physics_frame
	scene.set_process(false); world = scene.world
	for p in scene.people:
		p.set_physics_process(false); p.position = world.population.free_point(world.nightlife.center+Vector2(-270,370),true)
		p.visual_facing = Vector2.UP; p.body.queue_redraw()
	scene.camera.position = world.nightlife.center+Vector2(0,-15); scene.camera.zoom = Vector2.ONE*.95
	scene.day_cycle.minutes = 1350; world.synchronize_clock(scene.day_cycle,true)
	for i in 260:
		scene.day_cycle.advance(.25); world.step_environment(.25,scene.day_cycle); await physics_frame
		var dancers: Array = world.nightlife.patrons.filter(func(a):return a.get_meta("nightlife_mode","")=="dance")
		if i>100 and dancers.size()>=2 and not world.nightlife.talks.is_empty(): break
	await capture("open")
	scene.day_cycle.minutes = 30; world.synchronize_clock(scene.day_cycle,true)
	for i in 120:
		world.step_environment(.25,scene.day_cycle); await physics_frame
	await capture("midnight")
	scene.day_cycle.minutes = 720; world.synchronize_clock(scene.day_cycle,true)
	world.step_environment(.25,scene.day_cycle); await physics_frame
	await capture("day")
	scene.queue_free()
	for i in 10: await physics_frame
	print("PASS: rendered night, after-midnight and daytime bar")
	quit()
