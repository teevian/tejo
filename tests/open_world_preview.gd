## Run with a graphics window; captures are isolated to this disposable scene.
extends SceneTree
var scene: Node2D
func _initialize() -> void:
	call_deferred("run")
func frames(n: int) -> void:
	for i in n:
		await physics_frame
func capture(file: String) -> void:
	await process_frame
	await process_frame
	RenderingServer.force_draw()
	root.get_texture().get_image().save_png("res://output/"+file+".png")
func run() -> void:
	scene = load("res://scenes/garden.tscn").instantiate()
	root.add_child(scene)
	await frames(60)
	await capture("open-world-trailhead")
	for person in scene.people:
		person.in_dialogue = true
	for entry in [[Vector2(3070,920),"open-world-wooden-bridge"],[Vector2(2930,2280),"open-world-stone-bridge"],[Vector2(4170,1460),"open-world-ruins"]]:
		scene.people[0].position = entry[0]
		scene.people[1].position = entry[0]+Vector2(-105,25)
		scene.people[0].facing = Vector2.RIGHT
		scene.people[1].facing = Vector2.UP
		scene.camera.position = scene._camera_target()
		await frames(40)
		await capture(entry[1])
	# Show normal discovery behavior first.
	scene._toggle_map()
	await capture("open-world-exploration-map")
	# A separate fully revealed art/QA overview, never written to saved game progress.
	for x in 40:
		for y in 30:
			scene.exploration_map.explored[Vector2i(x,y)] = true
	for place in scene.world.landmarks:
		scene.exploration_map.discovered[place.id] = true
	scene.exploration_map.queue_redraw()
	await capture("open-world-overview")
	quit()
