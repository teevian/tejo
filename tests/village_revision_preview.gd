extends SceneTree
var scene: Node2D
func _initialize() -> void: call_deferred("run")
func frames(count: int) -> void:
	for i in count: await physics_frame
func capture(name: String, at: Vector2, minutes: float, zoom := 1.0) -> void:
	scene.day_cycle.minutes = minutes
	scene.world.population.synchronize(scene.day_cycle,true)
	scene.daylight.set_shader_parameter("daylight",scene.day_cycle.light_color())
	scene.camera.position = at
	scene.camera.zoom = Vector2.ONE*zoom
	scene.hud.area_title = scene.world.area_at(scene.people[0].position)
	scene.hud.interaction_prompt = ""
	scene.hud.queue_redraw()
	scene.world.interactions.highlight({})
	for player in scene.people: player.body.queue_redraw()
	await process_frame
	await process_frame
	RenderingServer.force_draw()
	root.get_texture().get_image().save_png("res://output/village-revised-"+name+".png")
func run() -> void:
	scene = load("res://scenes/sintra_village.tscn").instantiate()
	root.add_child(scene)
	await frames(4)
	scene.set_process(false)
	for player in scene.people: player.process_mode = Node.PROCESS_MODE_DISABLED
	for spec in scene.world.TERRACES.data.terraces:
		var platform: Rect2 = scene.world._rect(spec.platform)
		var stairs: Rect2 = scene.world.stair_rect(spec)
		scene.people[0].position = stairs.get_center()
		scene.people[1].position = Vector2(stairs.get_center().x-20,stairs.end.y+55)
		for player in scene.people:
			player.visual_facing = Vector2.UP
			player.facing = Vector2.UP
		await capture("stairs-"+str(spec.id),platform.get_center()+Vector2(0,140),690,1.1)
	for direction in ["left","right"]:
		var candidates: Array = scene.world.buildings.filter(func(b): return b.has_meta("side_facing") and b.get_meta("side_facing")==direction and b.label=="Café")
		candidates.sort_custom(func(a,b): return a.position.distance_to(Vector2(10000,5600))<b.position.distance_to(Vector2(10000,5600)))
		var building: Node2D = candidates[0]
		scene.people[0].position = scene.world.population.free_point(building.entry_position+Vector2(0,80),true)
		scene.people[1].position = scene.world.population.free_point(scene.people[0].position+Vector2(-110,25),true)
		for player in scene.people: player.visual_facing = Vector2.DOWN
		await capture("side-"+direction,building.position+Vector2(0,-150),690,.85)
	scene.people[0].position = Vector2(9570,3490)
	scene.people[1].position = Vector2(9460,3510)
	await capture("friends-evening",Vector2(9620,3300),1110,1.0)
	await capture("square-night",Vector2(9620,3300),1410,1.0)
	scene.queue_free()
	await frames(3)
	quit()
