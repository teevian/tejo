extends SceneTree
const ItemArt = preload("res://scripts/item_art.gd")
var scene: Node2D
var output_dir := "res://output/interactions"

func _initialize() -> void:
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
		person.stand_up()
		person.cancel_shoulder()
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
	await frames(540)
	await capture("te-hand-on-shoulder")
	scene._select_person(0)
	var bench: Dictionary = scene.world.interactions.targets.filter(func(t):return t.kind=="bench" and t.position.distance_to(Vector2(1030,2860))<10)[0]
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
