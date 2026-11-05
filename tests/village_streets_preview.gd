extends SceneTree
var scene: Node2D
func _initialize() -> void: call_deferred("run")
func capture(label: String, at: Vector2, zoom: float) -> void:
	var preferred := at+Vector2(0,100)
	scene.people[0].position = scene.world.population.free_point(preferred,true)
	scene.people[1].position = scene.world.population.free_point(scene.people[0].position+Vector2(-100,20),true)
	for player in scene.people:
		player.visual_facing = Vector2.DOWN
		player.body.queue_redraw()
	scene.camera.position = at
	scene.camera.zoom = Vector2.ONE*zoom
	scene.hud.area_title = scene.world.area_at(at)
	scene.hud.interaction_prompt = ""
	scene.hud.queue_redraw()
	await process_frame
	await process_frame
	RenderingServer.force_draw()
	root.get_texture().get_image().save_png("res://output/village-streets-"+label+".png")
func run() -> void:
	scene = load("res://scenes/sintra_village.tscn").instantiate()
	root.add_child(scene)
	for i in 4: await physics_frame
	scene.set_process(false)
	for player in scene.people: player.process_mode = Node.PROCESS_MODE_DISABLED
	scene.day_cycle.minutes = 690
	scene.world.population.synchronize(scene.day_cycle,true)
	scene.daylight.set_shader_parameter("daylight",scene.day_cycle.light_color())
	scene.world.interactions.highlight({})
	await capture("padarias",Vector2(9800,5700),.9)
	await capture("junction",Vector2(9000,6720),.8)
	await capture("backlots",Vector2(15130,12120),.65)
	await capture("townscape",Vector2(11600,9000),.28)
	await capture("market",Vector2(11850,7950),.85)
	scene.queue_free()
	for i in 3: await physics_frame
	quit()
