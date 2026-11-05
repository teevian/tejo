extends SceneTree
var scene: Node2D
var world: Node2D
var life: Node2D
func _initialize() -> void: call_deferred("run")
func at_time(minute: float) -> void:
	scene.day_cycle.minutes = minute
	world.synchronize_clock(scene.day_cycle,true)
	scene.daylight.set_shader_parameter("daylight",scene.day_cycle.light_color())
func capture(label: String, focus: Vector2, zoom := 1.0) -> void:
	scene.camera.position = focus
	scene.camera.zoom = Vector2.ONE*zoom
	scene.people[0].position = world.population.free_point(focus+Vector2(-230,100),true)
	scene.people[1].position = world.population.free_point(focus+Vector2(-320,135),true)
	if label=="cinema":
		scene.people[0].position = world.population.free_point(life.event_props.cinema.position+Vector2(-580,90),true)
		scene.people[1].position = world.population.free_point(life.event_props.cinema.position+Vector2(-660,120),true)
	for player in scene.people:
		player.visual_facing = Vector2.UP
		player.body.queue_redraw()
	scene.hud.area_title = world.area_at(focus)
	scene.hud.interaction_prompt = ""
	scene.hud.queue_redraw()
	for actor in world.social_life.actors:
		if actor.entry.get("role","")=="cinema" and actor.appointment.get("place","")=="cinema": actor.step(.01,scene.day_cycle)
		else: actor.motion.step(actor,.01,0)
		actor.art.queue_redraw()
	world.social_life.queue_redraw()
	life._refresh_displays()
	await process_frame
	await process_frame
	RenderingServer.force_draw()
	root.get_texture().get_image().save_png("res://output/village-festival-"+label+".png")
func run() -> void:
	create_timer(150,true,false,true).timeout.connect(func(): quit(2))
	scene = load("res://scenes/sintra_village.tscn").instantiate()
	root.add_child(scene)
	for i in 4: await physics_frame
	scene.set_process(false)
	for player in scene.people: player.set_physics_process(false)
	world = scene.world
	life = world.festival_life
	world.interactions.highlight({})
	at_time(1182)
	await capture("cinema",life.event_props.cinema.position+Vector2(-200,-90),.95)
	at_time(680)
	await capture("fruit",life.event_props.fruit.position+Vector2(40,-65),1.1)
	await capture("sweets",life.event_props.sweets.position+Vector2(45,-65),1.1)
	var green: CharacterBody2D = life.vehicles[0]
	green.interact(null)
	await capture("tuktuk",green.position+Vector2(20,-55),1.1)
	await capture("carriage",life.vehicles[2].position+Vector2(0,-55),1.1)
	await capture("dog",life.by_id.bea_cao.position+Vector2(30,-45),1.1)
	await capture("tourists",life.by_id.mateo_turista.position+Vector2(0,-50),1.0)
	at_time(1050)
	for i in 180:
		world.step_environment(.25,scene.day_cycle)
		await physics_frame
	await capture("championship",life.event_props.score.position+Vector2(50,-60),.95)
	at_time(680)
	world.social_life._say(life.by_id.basilio_guarda_chuva,"Perdi o guarda-chuva. Este? Ah, este é o que eu procurava!","speak")
	await capture("umbrella",life.by_id.basilio_guarda_chuva.position+Vector2(0,-60),1.1)
	scene.queue_free()
	for i in 4: await physics_frame
	quit()
