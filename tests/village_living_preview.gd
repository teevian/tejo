extends SceneTree
var scene: Node2D
var world: Node2D
var life: Node2D
func _initialize() -> void: call_deferred("run")
func capture(label: String,at: Vector2,zoom := 1.0) -> void:
	scene.camera.position = at
	scene.camera.zoom = Vector2.ONE*zoom
	scene.people[0].position = world.population.free_point(at+Vector2(-210,145),true)
	scene.people[1].position = world.population.free_point(at+Vector2(-300,170),true)
	for p in scene.people:
		p.visual_facing = Vector2.UP
		p.body.queue_redraw()
	world.interactions.highlight({})
	scene.hud.interaction_prompt = world.interactions.prompt(scene.people[0],world.interactions.nearest(scene.people[0]))
	scene.hud.area_title = world.area_at(at)
	scene.hud.queue_redraw()
	world.social_life.queue_redraw()
	for a in world.social_life.actors: a.art.queue_redraw()
	for w in life.windows: w.queue_redraw()
	life.animals.queue_redraw()
	for i in 3: await process_frame
	RenderingServer.force_draw()
	root.get_texture().get_image().save_png("res://output/village-living-"+label+".png")
func at(minute: float,day := 1) -> void:
	scene.day_cycle.minutes = minute; scene.day_cycle.day = day
	world.synchronize_clock(scene.day_cycle,true)
	scene.daylight.set_shader_parameter("daylight",scene.day_cycle.light_color())
func run() -> void:
	create_timer(120,true,false,true).timeout.connect(func():quit(2))
	scene = load("res://scenes/sintra_village.tscn").instantiate(); root.add_child(scene)
	for i in 4: await physics_frame
	scene.set_process(false)
	world = scene.world; life = world.living_life
	for p in scene.people: p.set_physics_process(false); p.position = Vector2(1500,14000)
	at(650)
	var window: Node2D = life.by_id.alzira.window_node
	await capture("window",window.building.position+window.pane.get_center()+Vector2(0,50),1.2)
	scene.people[0].position = life.by_id.augusto.position+Vector2(-120,70)
	scene.people[1].position = scene.people[0].position+Vector2(-80,20)
	life.open_character(life.by_id.augusto,scene.people[0])
	await capture("postman",life.by_id.augusto.position-Vector2(0,50),1.05)
	life.panel.finish()
	var chalk_node: Node2D = life.objects.filter(func(o):return o.kind=="chalk" and o.position.distance_to(life.animals.home)<800)[0]
	life.draw_chalk(chalk_node,scene.people[0],0)
	life.draw_chalk(chalk_node,scene.people[1],2)
	life.by_id.celso.position = life.routines.clear_destination(chalk_node.position+Vector2(110,0),[])
	life.by_id.celso.frame = 1
	life.animals.feed_at(life.animals.home+Vector2(40,0))
	for i in 8: life.animals.step(.25)
	await capture("pigeons",life.animals.home-Vector2(0,30),1.1)
	await capture("chalk",chalk_node.position,1.05)
	at(900)
	for i in 8: life._step_hat(.25)
	await capture("hat",life.hat.position,1.1)
	at(552)
	await capture("rivals",life.rival_park-Vector2(-100,45),1.0)
	at(1065,3)
	life.open_character(life.by_id.plutonio,scene.people[0])
	await capture("cameo",life.by_id.plutonio.position-Vector2(0,50),1.1)
	life.panel.finish()
	at(890)
	world.social_life.next_decision = 999
	life.events.next_decision = 999
	life._bench_routine(life.by_id.teodoro)
	for i in 120:
		world.step_environment(.25,scene.day_cycle)
		await physics_frame
	await capture("bench",life.by_id.teodoro.position-Vector2(0,70),1.2)
	var fountain: Node2D = life.objects.filter(func(o):return o.kind=="fountain")[0]
	fountain.state = 90
	await capture("fountain",fountain.position-Vector2(0,70),1.1)
	scene.queue_free()
	for i in 4: await physics_frame
	print("PASS: nine living-world rendered previews")
	quit()
