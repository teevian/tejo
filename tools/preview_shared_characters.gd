extends SceneTree
const Art = preload("res://scripts/open_world_art.gd")
var scene: Node2D

func _initialize() -> void:
	call_deferred("run")

func capture(filename: String) -> void:
	for i in 3:
		await process_frame
	RenderingServer.force_draw()
	root.get_texture().get_image().save_png(filename)

func pose(direction: Vector2, moving: bool, phase: float) -> void:
	for person in scene.people:
		person.facing = direction
		person.visual_facing = direction
		person.moving = moving
		person.walked = phase*Art.STRIDE
		person.body.queue_redraw()

func run() -> void:
	if DisplayServer.get_name()=="headless":
		quit(1)
		return
	scene = load("res://scenes/garden.tscn").instantiate()
	root.add_child(scene)
	scene.set_process(false)
	scene.hud.hide()
	scene.inventory_panel.hide()
	for kind in 2:
		var person = scene.people[kind]
		person.set_physics_process(false)
		person.set_process(false)
		person.position = Vector2(740+kind*110,2890)
		person.controlled = false
		person.selected_blend = 0.0
		person.velocity = Vector2.ZERO
		person.path.clear()
		person._finish_phone()
		person.queue_redraw()
	scene.camera.position = Vector2(795,2820)
	scene.camera.zoom = Vector2(2,2)
	scene.camera.reset_smoothing()
	pose(Vector2.DOWN,false,0)
	await capture("res://output/characters-shared-rig-front.png")
	for phase in 4:
		pose(Vector2.RIGHT,true,float(phase)/4.0)
		await capture("/tmp/tejo-shared-game-%02d.png"%phase)
	if "--all-directions" in OS.get_cmdline_user_args():
		DirAccess.make_dir_recursive_absolute("/tmp/tejo-neck-game")
		var directions := [Vector2.DOWN,Vector2(1,1).normalized(),Vector2.RIGHT,Vector2(1,-1).normalized(),Vector2.UP,Vector2(-1,-1).normalized(),Vector2.LEFT,Vector2(-1,1).normalized()]
		for direction in directions.size():
			for phase in 4:
				pose(directions[direction],true,float(phase)/4.0)
				await capture("/tmp/tejo-neck-game/d%d-p%d.png"%[direction,phase])
	quit()
