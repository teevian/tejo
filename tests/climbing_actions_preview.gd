extends SceneTree
## Capture production actions against the real rock, at synchronized phases.
var scene: Node2D

func _initialize() -> void:
	call_deferred("run")

func place(kind: int, shelf: int, x: float) -> void:
	var p = scene.people[kind]
	p.traversal.clear()
	p.grounded = true
	p.shelf = shelf
	p.anchor = ""
	p.velocity = Vector2.ZERO
	p.hanging = false
	p.gesture_time = 0
	p.landing_time = 0
	p.position = Vector2(x,scene.surface_y(scene.platforms[shelf],x,p))
	p.view_offset = Vector2.ZERO
	p.choreography_offset = Vector2.ZERO
	scene.space.sync_people()

func capture(label: String, index: int) -> void:
	scene.camera.position = (scene.people[0].position+scene.people[1].position)*0.5-Vector2(0,105)
	scene.camera.zoom = Vector2.ONE*1.4
	scene.wall.update_view()
	scene.perspective.update_view()
	scene.scenery.queue_redraw()
	for person in scene.people: person.queue_redraw()
	await process_frame
	await process_frame
	RenderingServer.force_draw()
	root.get_texture().get_image().save_png("/tmp/tejo-climb-work/scene/"+label+"-%02d.png"%index)

func run() -> void:
	if DisplayServer.get_name()=="headless":
		push_error("Action preview requires graphics")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute("/tmp/tejo-climb-work/scene")
	scene = load("res://scenes/rock_climbing.tscn").instantiate()
	root.add_child(scene)
	while not scene._initialization_complete: await process_frame
	scene.set_process(false)
	scene.set_physics_process(false)
	for label in ["boost","carry","help","rope","chimney","push"]:
		scene.restart()
		scene.set_process(false)
		scene.set_physics_process(false)
		if label=="help":
			place(0,1,596)
			place(1,0,552)
			scene.interact()
		elif label=="rope":
			place(0,13,820)
			place(1,12,552)
			scene.interact()
			scene._select_person(1)
			scene.attempt_climb(1)
		elif label=="push":
			place(0,2,291)
			place(1,2,240)
			Input.action_press("walk_right")
		else:
			var shelf := 3 if label=="carry" else (9 if label=="chimney" else 0)
			var direction := -1 if shelf>0 else 1
			place(0,shelf,568 if direction<0 else 552)
			place(1,shelf,604 if direction<0 else 516)
			scene.people[0].face = direction
			scene.interact()
		if label!="push" and not scene.people.any(func(person): return person.traversing()):
			push_error("Preview did not start the real action: "+label)
			quit(1)
			return
		for index in 8:
			for tick in 6: scene._physics_process(1.0/60.0)
			await capture(label,index)
		Input.action_release("walk_right")
	print("PASS: real leg-up, carry, helping hand, rope ascent/haul, chimney and push previews")
	quit(0)
