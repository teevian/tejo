extends SceneTree
const ItemArt = preload("res://scripts/item_art.gd")
var scene: Node2D
var output_dir := "res://output/interactions"
var sand_only := false

func _initialize() -> void:
	sand_only = "--sand-only" in OS.get_cmdline_user_args()
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--output-dir="):
			output_dir = argument.trim_prefix("--output-dir=")
	call_deferred("run")

func frames(count: int) -> void:
	for i in count:
		await physics_frame

func capture(label: String) -> void:
	for i in 2:
		await process_frame
	RenderingServer.force_draw()
	root.get_texture().get_image().save_png(output_dir+"/"+label+".png")

func place(a: Vector2,b: Vector2) -> void:
	for person in scene.people:
		person.in_dialogue = false
		person.stand_up(true)
		person.cancel_sand_drawing()
		person._finish_phone()
		person.collecting_time = 0
		person.velocity = Vector2.ZERO
		person.moving = false
		person.path.clear()
		person.queued_jump.clear()
	scene.people[0].position = a
	scene.people[1].position = b

func run() -> void:
	if DisplayServer.get_name()=="headless":
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_dir))
	scene = load("res://scenes/garden.tscn").instantiate()
	root.add_child(scene)
	while not scene._initialization_complete: await process_frame
	if sand_only:
		await preview_sand()
		return
	for item in [0,1,4]:
		scene.people[0].inventory.try_add(ItemArt.ITEMS[item])
	for item in [2,0,3]:
		scene.people[1].inventory.try_add(ItemArt.ITEMS[item])
	place(Vector2(915,2970),Vector2(835,3000))
	scene.camera.position = scene._camera_target()
	await frames(15)
	await capture("inventories-and-pickup")
	place(Vector2(770,2920),Vector2(850,2890))
	scene._select_person(1)
	scene.camera.position = scene._camera_target()
	await frames(720)
	await capture("te-drawing-in-sand")
	scene._select_person(0)
	var benches: Array = scene.world.interactions.targets.filter(func(t):return t.kind=="bench")
	benches.sort_custom(func(a,b):return a.position.distance_to(Vector2(1030,2860))<b.position.distance_to(Vector2(1030,2860)))
	var bench: Dictionary = benches[0]
	place(bench.position+Vector2(0,75),bench.position+Vector2(-100,95))
	scene._interact()
	scene.camera.position = scene._camera_target()
	await frames(200)
	await capture("sitting-on-bench")
	var x: float = scene.world.river_x(3900)
	place(Vector2(x-110,3900),Vector2(x-190,3910))
	for target in scene.world.interactions.targets:
		if target.kind=="pickup" and target.position.distance_to(scene.people[0].position)<150:
			target.node.hide()
	scene.people[0].facing = Vector2.RIGHT
	scene.people[0].visual_facing = Vector2.RIGHT
	scene.camera.position = scene._camera_target()
	scene._interact()
	scene.set_process(false)
	await frames(20)
	await capture("jumping-narrow-river")
	quit()

func preview_sand() -> void:
	var spot := Vector2.ZERO
	for y in range(2900,3300,40):
		for x in range(650,1150,40):
			var candidate := Vector2(x,y)
			if scene.world.is_walkable(candidate,46) and scene.world.is_walkable(candidate+Vector2(0,-36),32) and scene.world.is_walkable(candidate+Vector2(30,6),28) and scene.world.is_walkable(candidate+Vector2(104,0),14):
				spot = candidate
				break
		if spot!=Vector2.ZERO: break
	if spot==Vector2.ZERO:
		push_error("No clear ground for the drawing preview")
		quit(1)
		return
	scene._select_person(1)
	place(spot,spot+Vector2(104,0))
	# Clear only the review view; collision checks and the actual idle action stay active.
	for prop in scene.world.props: prop.hide()
	for plant in scene.world.low_foliage: plant.hide()
	for prop in scene.world.scenery_props: prop.hide()
	scene.hud.hide()
	scene.inventory_panel.hide()
	scene.camera.position = spot+Vector2(52,-60)
	scene.camera.zoom = Vector2(2.2,2.2)
	scene.set_process(false)
	await frames(720)
	if scene.people[0].sand_state!=scene.people[0].SandState.DRAWING:
		push_error("Te did not enter the real ground-drawing idle action")
		quit(1)
		return
	for person in scene.people:
		person.set_physics_process(false)
		person.selected_blend = 0.0
		person.queue_redraw()
	scene.people[1].controlled = false
	for frame in 4:
		scene.people[0].sand_time = frame*0.4+0.01
		scene.people[0].body.queue_redraw()
		await capture("te-drawing-%d"%frame)
	print("PASS: real idle ground drawing captured in the garden")
	quit()
