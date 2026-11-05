extends SceneTree
var scene: Node2D
var world: Node2D
var social: Node2D
func _initialize() -> void: call_deferred("run")
func at_time(minutes: float) -> void:
	scene.day_cycle.minutes = minutes
	world.synchronize_clock(scene.day_cycle,true)
	social.cooldowns.clear()
	social.next_decision = 1000
	scene.daylight.set_shader_parameter("daylight",scene.day_cycle.light_color())
func pose_people() -> void:
	for actor in social.actors:
		actor.motion.step(actor,.001,0)
		actor.art.queue_redraw()
		actor.queue_redraw()
	social.queue_redraw()
func capture(label: String, focus: Vector2, zoom := 1.15) -> void:
	scene.people[0].position = world.population.free_point(focus+Vector2(-240,120),true)
	scene.people[1].position = world.population.free_point(focus+Vector2(-330,155),true)
	for person in scene.people:
		person.visual_facing = Vector2.UP
		person.body.queue_redraw()
	scene.camera.position = focus+Vector2(0,-90)
	scene.camera.zoom = Vector2.ONE*zoom
	scene.hud.area_title = world.area_at(focus)
	scene.hud.interaction_prompt = ""
	scene.hud.queue_redraw()
	pose_people()
	await process_frame
	await process_frame
	RenderingServer.force_draw()
	root.get_texture().get_image().save_png("res://output/village-social-"+label+".png")
func arrange(actor: CharacterBody2D, at: Vector2) -> void:
	actor._outside()
	actor.position = world.population.free_point(at,true)
	actor.state = "activity"
	actor.route.clear()
	actor.greet_time = 0
func turn(event: Dictionary, count: int) -> void:
	for i in count:
		event.remaining = 0
		social._advance(event,.01)
func run() -> void:
	create_timer(80).timeout.connect(func(): quit(2))
	scene = load("res://scenes/sintra_village.tscn").instantiate()
	root.add_child(scene)
	for i in 4: await physics_frame
	scene.set_process(false)
	for player in scene.people: player.process_mode = Node.PROCESS_MODE_DISABLED
	world = scene.world
	social = world.social_life
	world.interactions.highlight({})
	at_time(960)
	var vendor: CharacterBody2D = social.by_id.enzo_gelados
	var gil: CharacterBody2D = social.by_id.gil
	arrange(gil,social._meeting_spot(gil,vendor))
	if social._start("gelato",[gil,vendor],vendor.position,false):
		turn(social.encounters[-1],3)
		await capture("gelato",vendor.position+Vector2(-30,0))
	at_time(1080)
	var tiago: CharacterBody2D = social.by_id.tiago
	var alexandre: CharacterBody2D = social.by_id.alexandre
	arrange(gil,tiago.position+Vector2(-145,25))
	arrange(alexandre,tiago.position+Vector2(-50,80))
	if social._start("chat",[gil,tiago,alexandre],tiago.position,false):
		turn(social.encounters[-1],2)
		await capture("friends",tiago.position+Vector2(-20,20))
	at_time(1050)
	var mother: CharacterBody2D = social.by_id.leonor
	var father: CharacterBody2D = social.by_id.daniel_familia
	var child: CharacterBody2D = social.by_id.matilde
	if social._start("family_photo",[mother,father,child],mother.position,false):
		turn(social.encounters[-1],3)
		await capture("family",mother.position.lerp(child.position,.5),1.25)
	at_time(690)
	var scout: CharacterBody2D = social.by_id.ines_escuteira
	arrange(gil,scout.position+Vector2(-125,75))
	if social._start("raffle",[gil,scout],scout.position,false):
		turn(social.encounters[-1],1)
		await capture("raffles",scout.position+Vector2(0,40))
	at_time(1110)
	var guitar: CharacterBody2D = social.by_id.farid
	var violin: CharacterBody2D = social.by_id.clara_violinista
	var audience: Array = []
	for i in 5:
		var friend: CharacterBody2D = social.by_id[["gil","tiago","alexandre","martim","afonso"][i]]
		arrange(friend,Vector2(7000+(i-2)*95,5230+(i%2)*72))
		audience.append(friend)
	if social._start("applause",audience,guitar.position,false):
		turn(social.encounters[-1],1)
		guitar.social_pose = "thanks"
		violin.social_pose = "thanks"
		await capture("concert",Vector2(6990,5140),.95)
	scene.queue_free()
	for i in 3: await physics_frame
	quit()
