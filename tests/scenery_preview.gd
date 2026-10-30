extends SceneTree
var scene: Node2D
func _initialize() -> void: call_deferred("run")
func capture(label: String, te_at: Vector2, jo_at: Vector2, camera_at: Vector2) -> void:
	for i in 2:
		scene.people[i].position = te_at if i==0 else jo_at
		scene.people[i].velocity = Vector2.ZERO
		scene.people[i].in_dialogue = true
		scene.people[i].facing = Vector2.DOWN
		scene.people[i].visual_facing = Vector2.DOWN
		scene.people[i].body.queue_redraw()
	scene.camera.position = camera_at
	scene.hud.area_title = scene.world.area_at(te_at)
	scene.hud.queue_redraw()
	for i in 4: await process_frame
	RenderingServer.force_draw()
	root.get_texture().get_image().save_png("res://output/"+label+".png")
func run() -> void:
	scene = load("res://scenes/garden.tscn").instantiate()
	root.add_child(scene)
	for i in 3: await physics_frame
	scene.set_process(false)
	scene.world.wildlife.process_mode = Node.PROCESS_MODE_DISABLED
	await capture("scenery-rock-behind",scene.world.Heritage.point(0,Vector2(.30,.41)),Vector2(840,890),Vector2(640,550))
	await capture("scenery-rock-front",scene.world.Heritage.point(0,Vector2(.30,.62)),Vector2(840,890),Vector2(640,550))
	await capture("scenery-tree-depth",scene.world.Heritage.point(1,Vector2(.325,.46)),scene.world.Heritage.point(1,Vector2(.51,.68)),Vector2(5540,1150))
	await capture("scenery-tree-open-branches",scene.world.Heritage.point(1,Vector2(.875,.35)),scene.world.Heritage.point(1,Vector2(.56,.57)),scene.world.Heritage.point(1,Vector2(.84,.38)))
	await capture("scenery-porch-depth",scene.world.Heritage.point(3,Vector2(.80,.52)),scene.world.Heritage.point(3,Vector2(.62,.72)),Vector2(7600,4020))
	await capture("scenery-arch-depth",scene.world.ARCH_CENTER-Vector2(0,90),scene.world.ARCH_CENTER+Vector2(120,160),scene.world.ARCH_CENTER-Vector2(0,50))
	quit()
