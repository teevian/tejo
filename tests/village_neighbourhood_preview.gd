extends SceneTree
var scene: Node2D
var world: Node2D
func _initialize() -> void:
	create_timer(300,true,false,true).timeout.connect(func():quit(2))
	call_deferred("run")
func ticks(seconds: float) -> void:
	for i in roundi(seconds*4):
		scene.day_cycle.advance(.25); world.step_environment(.25,scene.day_cycle); await physics_frame
func at(minute: float) -> void:
	scene.day_cycle.minutes = minute; world.synchronize_clock(scene.day_cycle,true)
func capture(label: String,position: Vector2,zoom := 1.25) -> void:
	scene.camera.position = position-Vector2(0,60); scene.camera.zoom = Vector2.ONE*zoom
	for p in scene.people:
		p.position = world.population.free_point(position+Vector2(-240,170),true)
		p.visual_facing = Vector2.UP; p.body.queue_redraw()
	scene.hud.area_title = world.area_at(position); scene.hud.interaction_prompt = ""; scene.hud.comment_time = 0; scene.hud.queue_redraw()
	scene.daylight.set_shader_parameter("daylight",scene.day_cycle.light_color())
	for a in world.social_life.actors: a.art.queue_redraw()
	for p in world.neighbourhood.objects.values(): p.queue_redraw()
	for i in 3: await process_frame
	RenderingServer.force_draw()
	root.get_texture().get_image().save_png("res://output/village-neighbours-"+label+".png")
func run() -> void:
	root.size = Vector2i(1280,720)
	scene = load("res://scenes/sintra_village.tscn").instantiate(); root.add_child(scene)
	for i in 5: await physics_frame
	scene.set_process(false); world = scene.world
	for p in scene.people: p.set_physics_process(false); p.position = Vector2(1500,14000)
	at(600); await ticks(50)
	await capture("pigeon",world.neighbourhood.places.pigeon)
	await capture("queue",world.neighbourhood.places.queue)
	await capture("scouts",world.neighbourhood.places.raffle)
	await capture("papers",world.neighbourhood.places.papers)
	at(700); await ticks(55)
	await capture("picnic",world.neighbourhood.places.picnic,1.4)
	at(1010); await ticks(40)
	await capture("foosball",world.neighbourhood.places.foosball,1.4)
	var window: Node2D = world.neighbourhood.by_id.odete_janela.window_node
	if is_instance_valid(window): await capture("window",window.building.position-Vector2(0,130),1.45)
	var streets: Array = world.neighbourhood.presence.samples.duplicate()
	streets.sort_custom(func(a,b):return a.distance_squared_to(Vector2(14800,10500))<b.distance_squared_to(Vector2(14800,10500)))
	await capture("street",streets[0],1.05)
	scene.queue_free()
	for i in 10: await physics_frame
	print("PASS: eight actual rendered neighbourhood scenes")
	quit()
