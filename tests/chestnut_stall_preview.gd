extends SceneTree
var scene: Node2D
func _initialize() -> void:
	create_timer(180,true,false,true).timeout.connect(func():quit(2))
	call_deferred("run")
func capture(label: String) -> void:
	for i in 3: await process_frame
	RenderingServer.force_draw(); root.get_texture().get_image().save_png("res://output/chestnuts-"+label+".png")
func run() -> void:
	root.size = Vector2i(1280,720)
	scene = load("res://scenes/sintra_village.tscn").instantiate(); root.add_child(scene)
	for i in 4: await physics_frame
	scene.set_process(false)
	var stall: Node2D = scene.world.chestnuts
	for i in 2:
		scene.people[i].set_physics_process(false); scene.people[i].position = scene.world.population.free_point(stall.position+Vector2(-50+i*105,110),true)
		scene.people[i].visual_facing = Vector2.UP; scene.people[i].body.queue_redraw()
	scene.day_cycle.minutes = 960; scene.world.synchronize_clock(scene.day_cycle,true)
	scene.daylight.set_shader_parameter("daylight",scene.day_cycle.light_color())
	scene.camera.position = stall.position-Vector2(0,80); scene.camera.zoom = Vector2.ONE*1.35
	scene.hud.area_title = "Castanhas do Parque"; scene.hud.interaction_prompt = stall.interaction_prompt(); scene.hud.queue_redraw()
	stall.buy(scene.journey,0,false); stall.buy(scene.journey,1,true)
	await capture("park")
	stall.interact(scene.people[0]); await capture("menu"); scene.journey.panel.finish()
	scene.day_cycle.minutes = 1320; stall.step(0,scene.day_cycle)
	scene.daylight.set_shader_parameter("daylight",scene.day_cycle.light_color()); scene.hud.queue_redraw()
	scene.hud.interaction_prompt = "Castanhas do Parque · fechado até às 10:00"
	await capture("closed")
	scene.queue_free()
	for i in 8: await physics_frame
	print("PASS: rendered chestnut stall, both inventory icons, butter menu and closed cart"); quit()
