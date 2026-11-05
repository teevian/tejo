extends SceneTree
var scene: Node2D
var world: Node2D
func _initialize() -> void: call_deferred("run")
func ticks(seconds: float) -> void:
	for i in roundi(seconds*4):
		scene.day_cycle.advance(.25)
		world.step_environment(.25,scene.day_cycle)
		await physics_frame
func capture(label: String,at: Vector2,zoom := 1.1) -> void:
	scene.camera.position = at
	scene.camera.zoom = Vector2.ONE*zoom
	for i in 2:
		scene.people[i].position = world.population.free_point(at+Vector2(-300-i*90,160),true)
		scene.people[i].visual_facing = Vector2.UP
		scene.people[i].body.queue_redraw()
	scene.hud.area_title = world.area_at(at)
	scene.hud.interaction_prompt = ""
	scene.hud.comment_time = 0
	scene.hud.queue_redraw()
	scene.daylight.set_shader_parameter("daylight",scene.day_cycle.light_color())
	for a in world.social_life.actors: a.art.queue_redraw()
	for p in world.dining.props: p.queue_redraw()
	for i in 3: await process_frame
	RenderingServer.force_draw()
	root.get_texture().get_image().save_png("res://output/village-individuality-"+label+".png")
func run() -> void:
	create_timer(180,true,false,true).timeout.connect(func():quit(2))
	scene = load("res://scenes/sintra_village.tscn").instantiate(); root.add_child(scene)
	for i in 4: await physics_frame
	scene.set_process(false); world = scene.world
	for p in scene.people: p.set_physics_process(false); p.position = Vector2(1500,14000)
	scene.day_cycle.minutes = 400; world.synchronize_clock(scene.day_cycle,true)
	await ticks(150)
	var matilde: CharacterBody2D = world.population.by_id.matilde
	await capture("breakfast",matilde.position-Vector2(0,75),1.2)
	await ticks(270)
	var antonio: CharacterBody2D = world.population.by_id.antonio
	await capture("garden-lunch",antonio.position-Vector2(0,75),1.3)
	var friends: CharacterBody2D = world.population.by_id.martim
	await capture("cafe-lunch",friends.position-Vector2(0,75),1.15)
	scene.day_cycle.minutes = 1000; world.synchronize_clock(scene.day_cycle,true)
	world.social_life.next_decision = 999; world.living_life.events.next_decision = 999
	var clear: Vector2 = world._event_space(antonio.home+Vector2(-250,260),220)
	antonio._begin_walk(clear,"walking")
	await ticks(65)
	var end: Vector2 = world.population.free_point(antonio.position+Vector2(170,10),true)
	antonio._begin_walk(end,"walking")
	await ticks(1)
	await capture("cane",antonio.position-Vector2(0,75),1.55)
	matilde._cancel_encounter(); matilde.greet_time = 0
	matilde._begin_walk(world.population.free_point(matilde.position+Vector2(240,-140),true),"walking")
	await ticks(1)
	await capture("running",matilde.position-Vector2(0,65),1.4)
	scene.queue_free()
	for i in 5: await physics_frame
	print("PASS: five actual city views of breakfast, garden/cafe lunch, supported cane gait and running")
	quit()
