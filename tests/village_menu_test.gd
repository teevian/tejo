extends SceneTree
var failed := false
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		push_error(message)
func frames(n: int) -> void:
	for i in n: await physics_frame
func run() -> void:
	var scene: Node2D = load("res://scenes/garden.tscn").instantiate()
	root.add_child(scene)
	await frames(3)
	scene._select_person(1)
	var start: Vector2 = scene.people[0].position
	scene._toggle_pause()
	check(scene.village_button.visible and scene.village_button.text=="Explorar a Vila de Sintra","Escape menu offers the village")
	if DisplayServer.get_name()!="headless":
		await process_frame
		RenderingServer.force_draw()
		root.get_texture().get_image().save_png("res://output/village-escape-menu.png")
	scene.village_button.pressed.emit()
	await frames(3)
	check(scene.region_id=="village" and not paused and not scene.hud.paused,"Village opens with play resumed")
	check(scene.people[0].position.distance_to(scene.world.menu_spawn)<30 and scene.selected==1,"First menu visit arrives at the palace with selection preserved")
	scene._toggle_pause()
	var return_point: Vector2 = scene.region_states["forest"].positions[0]
	scene.village_button.pressed.emit()
	check(scene.region_id=="forest" and not paused and scene.people[0].position.distance_to(return_point)<1 and return_point.distance_to(start)<=100,"Return restores a safe position at the forest departure point")
	await frames(3)
	scene.queue_free()
	await frames(2)
	if not failed: print("PASS: Escape menu, first palace arrival, playable state, selection and return to departure point")
	quit(1 if failed else 0)
