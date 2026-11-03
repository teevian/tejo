extends SceneTree
var scene: Node2D
func _initialize() -> void: call_deferred("run")
func frames(count: int) -> void:
	for i in count: await physics_frame
func capture(label: String) -> void:
	await process_frame
	await process_frame
	RenderingServer.force_draw()
	root.get_texture().get_image().save_png("res://output/village-"+label+".png")
func run() -> void:
	scene = load("res://scenes/sintra_village.tscn").instantiate()
	root.add_child(scene)
	await frames(3)
	for p in scene.people: p.in_dialogue = true
	scene.day_cycle.minutes = 720
	for entry in [["village_palace","palace"],["village_piriquita","padarias"],["village_ferraria","ferraria"],["village_ferreira","ferreira"],["village_sassetti","sassetti"],["village_mourisca","mourisca"],["village_valencas","valencas"],["village_lawrence","lawrence"],["village_republic","republic"],["village_market","market"],["village_tiles","tiles"],["village_residential","residential"],["village_byron","byron"]]:
		var place: Dictionary = scene.world.landmarks.filter(func(p): return p.id==entry[0])[0]
		scene.people[0].position = place.position
		scene.people[1].position = place.position+Vector2(-100,20)
		scene.camera.position = scene._camera_target()
		await frames(3)
		await capture(entry[1])
	# A wider disposable review view shows both chimneys and their scale to Te/Jo.
	scene.people[0].position = scene.world.menu_spawn
	scene.people[1].position = scene.world.menu_spawn+Vector2(-100,20)
	scene.set_process(false)
	scene.camera.zoom = Vector2(.34,.34)
	scene.camera.position = scene.world.buildings[0].position-Vector2(0,650)
	scene.hud.get_parent().hide()
	await capture("palace-overview")
	scene.hud.get_parent().show()
	scene.set_process(true)
	scene.camera.zoom = Vector2.ONE
	scene.camera.position = scene._camera_target()
	scene.day_cycle.minutes = 1380
	await frames(3)
	await capture("night")
	scene._toggle_map()
	for x in ceili(scene.world.WORLD_SIZE.x/120):
		for y in ceili(scene.world.WORLD_SIZE.y/120): scene.exploration_map.explored[Vector2i(x,y)] = true
	for place in scene.world.landmarks: scene.exploration_map.discovered[place.id] = true
	scene.exploration_map.queue_redraw()
	await capture("map")
	quit()
