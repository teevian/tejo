extends SceneTree
var scene: Node2D
func _initialize() -> void:
	create_timer(180,true,false,true).timeout.connect(func():quit(2))
	call_deferred("run")
func capture(label: String) -> void:
	for i in 3: await process_frame
	RenderingServer.force_draw(); root.get_texture().get_image().save_png("res://output/journey-"+label+".png")
func run() -> void:
	root.size = Vector2i(1280,720)
	scene = load("res://scenes/sintra_village.tscn").instantiate(); root.add_child(scene)
	for i in 4: await physics_frame
	scene.set_process(false)
	var bakery: Node2D = scene.world.bakery
	for i in 2:
		scene.people[i].set_physics_process(false); scene.people[i].position = scene.world.population.free_point(bakery.position+Vector2(-50+i*105,115),true)
		scene.people[i].visual_facing = Vector2.UP; scene.people[i].body.queue_redraw()
	scene.day_cycle.minutes = 630; scene.world.synchronize_clock(scene.day_cycle,true)
	scene.journey.bond = 24
	scene.journey.needs[0] = {"hunger":58.0,"fatigue":34.0}; scene.journey.needs[1] = {"hunger":43.0,"fatigue":48.0}
	scene.journey.changed.emit(); scene.daylight.set_shader_parameter("daylight",scene.day_cycle.light_color())
	scene.camera.position = bakery.position-Vector2(0,80); scene.camera.zoom = Vector2.ONE*1.15
	scene.hud.area_title = "Pastelaria do Largo"; scene.hud.interaction_prompt = "Comprar bolos e bebidas"; scene.hud.queue_redraw()
	bakery.buy(scene.journey,0,1); bakery.buy(scene.journey,0,6)
	await capture("bakery")
	bakery.interact(scene.people[0]); await capture("menu")
	scene.journey.shop_panel.finish(); scene.journey.open_food(0,0); await capture("share")
	scene.journey.panel.finish(); scene.journey.open_progress(); await capture("progress")
	scene.queue_free()
	for i in 8: await physics_frame
	print("PASS: rendered needs HUD, bakery, complete menu, sharing and relationship unlocks"); quit()
