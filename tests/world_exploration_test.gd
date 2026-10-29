extends SceneTree
var scene: Node2D
var failed := false
func _initialize() -> void:
	call_deferred("run_checks")
func check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		push_error(message)
func frames(count: int) -> void:
	for i in count:
		await physics_frame
func capture(file_name: String) -> void:
	if DisplayServer.get_name() == "headless" or not "--capture-world" in OS.get_cmdline_user_args():
		return
	await process_frame
	await process_frame
	RenderingServer.force_draw()
	check(root.get_texture().get_image().save_png("res://output/" + file_name + ".png") == OK, "Could not capture map")
func run_checks() -> void:
	scene = load("res://scenes/side_trail.tscn").instantiate()
	root.add_child(scene)
	await frames(60)
	check(is_equal_approx(scene.camera.position.x, 640), "Opening view should keep its original framing")
	Input.action_press("walk_right")
	await frames(190)
	Input.action_release("walk_right")
	await frames(70)
	check(scene.people[0].position.x > 1280, "Characters must walk beyond the old screen edge")
	check(scene.camera.position.x > 1000, "Camera must reveal the continuation")
	await capture("map-transition-preview")
	Input.action_press("walk_right")
	await frames(230)
	Input.action_release("walk_right")
	await frames(70)
	check(scene.people[1].position.x > 2000, "The companion must follow into new scenery")
	check("old_fountain" in scene.dialogue_context().near, "The painted fountain should have a nearby conversation")
	await capture("map-fountain-preview")
	scene._talk()
	check(scene.dialogue.active_topic.id == "fountain_sintra", "New scenery must select its own dialogue")
	scene.dialogue.cancel()
	Input.action_press("walk_right")
	await frames(215)
	Input.action_release("walk_right")
	await frames(70)
	await capture("map-clearing-preview")
	check(scene.hud.area_title == "Clareira do sobreiro", "The location label should follow exploration")
	Input.action_press("walk_right")
	await frames(150)
	Input.action_release("walk_right")
	await frames(150)
	check(is_equal_approx(scene.people[0].position.x, scene.WORLD_WIDTH - 85), "The new right boundary should contain the leader")
	check(scene.people[0].is_on_floor() and scene.people[1].is_on_floor(), "Ground must span the entire map")
	check(scene.camera.position.x <= scene.WORLD_WIDTH - 640, "Camera must never reveal empty space beyond the map")
	var before_pause: Vector2 = scene.camera.position
	scene._toggle_pause()
	await frames(30)
	check(scene.camera.position == before_pause, "Pause must freeze camera movement")
	scene._toggle_pause()
	# Return with Jo selected: camera and companion must work in both directions.
	scene._select_person(1)
	Input.action_press("walk_left")
	await frames(740)
	Input.action_release("walk_left")
	await frames(150)
	check(is_equal_approx(scene.people[1].position.x, 85), "Jo must be able to return to the start")
	check(scene.people[0].position.x < 210, "Te should follow Jo back through the extended map")
	check(absf(scene.camera.position.x - 640) < 1, "Camera must settle back at the original left boundary")
	if not failed:
		print("PASS: continuous exploration beyond old edge, follower, camera, new context/dialogue, map boundaries, floor, pause and return with Jo.")
	quit(1 if failed else 0)
