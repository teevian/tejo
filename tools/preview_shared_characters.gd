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
	var version := "v14" if "--motion-v14" in OS.get_cmdline_user_args() else "v13" if "--motion-v13" in OS.get_cmdline_user_args() else "v12" if "--motion-v12" in OS.get_cmdline_user_args() else "v11"
	var motion := "--motion-v14" in OS.get_cmdline_user_args() or "--motion-v13" in OS.get_cmdline_user_args() or "--motion-v12" in OS.get_cmdline_user_args() or "--motion-v11" in OS.get_cmdline_user_args()
	await capture("res://output/character-motion-%s-scene.png"%version if motion else ("res://output/character-neck-v10-scene.png" if "--neck-v10" in OS.get_cmdline_user_args() else "res://output/characters-shared-rig-front.png"))
	for phase in 4:
		pose(Vector2.RIGHT,true,float(phase)/4.0)
		await capture("/tmp/tejo-shared-game-%02d.png"%phase)
	if "--all-directions" in OS.get_cmdline_user_args():
		var directory := "/tmp/tejo-motion-%s"%version if motion else "/tmp/tejo-neck-game"
		var phases := 8 if motion else 4
		DirAccess.make_dir_recursive_absolute(directory)
		var directions := [Vector2.DOWN,Vector2(1,1).normalized(),Vector2.RIGHT,Vector2(1,-1).normalized(),Vector2.UP,Vector2(-1,-1).normalized(),Vector2.LEFT,Vector2(-1,1).normalized()]
		for direction in (1 if "--south-only" in OS.get_cmdline_user_args() else directions.size()):
			for phase in phases:
				pose(directions[direction],true,float(phase)/phases)
				await capture(directory+"/d%d-p%d.png"%[direction,phase])
	quit()
