extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func capture(label: String) -> void:
	await process_frame
	await process_frame
	RenderingServer.force_draw()
	root.get_texture().get_image().save_png("res://output/heritage-"+label+".png")
func run() -> void:
	var scene = load("res://scenes/garden.tscn").instantiate()
	root.add_child(scene)
	for i in 3:
		await physics_frame
	scene.set_process(false)
	for person in scene.people:
		person.in_dialogue = true
	scene.day_cycle.minutes = 720
	scene.hud.queue_redraw()
	scene.daylight.set_shader_parameter("daylight",scene.day_cycle.light_color())
	# Wider framing only in this disposable art-review scene.
	scene.camera.zoom = Vector2.ONE
	for place in scene.world.Heritage.landmarks():
		scene.people[0].position = place.position
		scene.people[1].position = place.position+Vector2(95,25)
		scene.camera.position = scene._camera_target()
		scene.camera.reset_smoothing()
		for i in 6:
			await physics_frame
		await capture(place.id)
		var i: int = scene.world.Heritage.IDS.find(place.id)
		scene.camera.zoom = Vector2.ONE*.72
		scene.camera.position = scene.world.Heritage.ORIGINS[i]+scene.world.Heritage.site_size(i)*Vector2(.5,.40)
		var half_view: Vector2 = Vector2(1280,720)/scene.camera.zoom*.5
		scene.camera.position = scene.camera.position.clamp(half_view,scene.world.WORLD_SIZE-half_view)
		await capture(place.id+"-wide")
		scene.camera.zoom = Vector2.ONE
	scene._toggle_map()
	for x in ceili(scene.world.WORLD_SIZE.x/120.0):
		for y in ceili(scene.world.WORLD_SIZE.y/120.0):
			scene.exploration_map.explored[Vector2i(x,y)] = true
	for place in scene.world.landmarks:
		scene.exploration_map.discovered[place.id] = true
	scene.exploration_map.queue_redraw()
	await capture("overview")
	quit()
