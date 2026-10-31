extends SceneTree
var scene: Node2D
func _initialize() -> void: call_deferred("run")
func capture(name_value: String) -> void:
	for i in 3: await process_frame
	RenderingServer.force_draw()
	root.get_texture().get_image().save_png("res://output/"+name_value+".png")
func run() -> void:
	scene = load("res://scenes/garden.tscn").instantiate()
	root.add_child(scene)
	for i in 3: await physics_frame
	scene.set_process(false)
	scene.world.wildlife.process_mode = Node.PROCESS_MODE_DISABLED
	for person in scene.people: person.set_physics_process(false)
	scene.people[0].position = Vector2(10670,3150)
	scene.people[1].position = Vector2(10770,3170)
	scene.camera.position = Vector2(10730,3040)
	scene._select_person(1)
	scene.dialogue.visits["football_clearing_discovery"] = 1
	scene._talk()
	for i in 4: scene._talk()
	await capture("banter-football-conversation")
	scene.dialogue.cancel()
	scene._select_person(0)
	scene.people[0].facing = Vector2.RIGHT
	scene._interact()
	await capture("banter-visible-world-comment")
	quit()
