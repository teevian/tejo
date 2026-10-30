extends SceneTree
var scene: Node2D
func _initialize() -> void: call_deferred("run")
func capture(label: String) -> void:
	await process_frame
	await process_frame
	RenderingServer.force_draw()
	root.get_texture().get_image().save_png("res://output/discoveries-"+label+".png")
func run() -> void:
	scene = load("res://scenes/garden.tscn").instantiate()
	root.add_child(scene)
	scene.set_process(false)
	for person in scene.people:
		person.set_physics_process(false)
		person.in_dialogue = true
	scene.day_cycle.minutes = 660
	scene.hud.queue_redraw()
	scene.daylight.set_shader_parameter("daylight",scene.day_cycle.light_color())
	for entry in [[Vector2(10720,3150),"football-clearing"],[Vector2(6800,6200),"rest-clearing"],[Vector2(5010,2190),"signpost"],[Vector2(5530,3700),"white-flowers"],[Vector2(11030,5140),"silver-leaves"],[Vector2(8650,4720),"hollow-log"],[Vector2(8910,3880),"old-gate"],[Vector2(6000,6750),"insect-hotel"]]:
		scene.people[0].position = entry[0]+Vector2(-80,95)
		scene.people[1].position = entry[0]+Vector2(40,130)
		scene.camera.position = entry[0]-Vector2(0,75)
		await capture(entry[1])
	var puppy = scene.world.puppy
	puppy.position = puppy.home
	puppy.state = "guard"
	puppy.facing = Vector2.DOWN
	puppy.velocity = Vector2.ZERO
	puppy.friendly = false
	scene.people[0].position = puppy.position+Vector2(-150,140)
	scene.people[1].position = puppy.position+Vector2(-40,180)
	scene.camera.position = puppy.position-Vector2(0,75)
	for entry in [[0.0,"angry"],[.36,"wary"],[.85,"trusted"]]:
		puppy.trust = entry[0]
		puppy.body.queue_redraw()
		await capture("puppy-"+entry[1])
	scene._toggle_map()
	for x in ceili(scene.world.WORLD_SIZE.x/120.0):
		for y in ceili(scene.world.WORLD_SIZE.y/120.0):
			scene.exploration_map.explored[Vector2i(x,y)] = true
	for place in scene.world.landmarks: scene.exploration_map.discovered[place.id] = true
	scene.exploration_map.queue_redraw()
	await capture("overview")
	quit()
