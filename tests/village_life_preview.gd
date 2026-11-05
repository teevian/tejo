extends SceneTree
var scene: Node2D
func _initialize() -> void: call_deferred("run")
func capture(label: String, at: Vector2, minutes: float, zoom := .95) -> void:
	scene.day_cycle.minutes = minutes
	scene.world.synchronize_clock(scene.day_cycle,true)
	scene.daylight.set_shader_parameter("daylight",scene.day_cycle.light_color())
	var preferred := at+Vector2(-90,130)
	scene.people[0].position = scene.world.population.free_point(preferred,true)
	scene.people[1].position = scene.world.population.free_point(scene.people[0].position+Vector2(-100,25),true)
	for person in scene.people:
		person.visual_facing = Vector2.UP
		person.body.queue_redraw()
	scene.camera.position = at
	scene.camera.zoom = Vector2.ONE*zoom
	scene.hud.area_title = scene.world.area_at(at)
	scene.hud.interaction_prompt = ""
	scene.hud.queue_redraw()
	await process_frame
	await process_frame
	RenderingServer.force_draw()
	root.get_texture().get_image().save_png("res://output/village-life-"+label+".png")
func run() -> void:
	create_timer(70).timeout.connect(func(): quit(2))
	scene = load("res://scenes/sintra_village.tscn").instantiate()
	root.add_child(scene)
	for i in 4: await physics_frame
	scene.set_process(false)
	for player in scene.people: player.process_mode = Node.PROCESS_MODE_DISABLED
	scene.world.interactions.highlight({})
	await capture("tourists",Vector2(9560,2560),690,.9)
	await capture("scouts",Vector2(8880,3180),690,1)
	await capture("nannarella",Vector2(10700,2370),690,1)
	scene.day_cycle.minutes = 960
	scene.world.synchronize_clock(scene.day_cycle,true)
	var shopper: Node2D = scene.world.street_life.by_id.mariana_montras
	await capture("windows",shopper.position+Vector2(0,-80),960,1)
	await capture("family",Vector2(9800,2430),1050,.9)
	await capture("concert",Vector2(6770,4910),1155,.9)
	await capture("day",Vector2(9900,5650),690,.85)
	await capture("night",Vector2(9900,5650),1290,.85)
	scene.queue_free()
	for i in 3: await physics_frame
	quit()
