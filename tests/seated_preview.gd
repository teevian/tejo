## Captures the three bench postures and both ground-rest poses.
extends SceneTree
var output_dir := "res://output/seated-review"

func _initialize() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--output-dir="):
			output_dir = argument.trim_prefix("--output-dir=")
	call_deferred("run")

func run() -> void:
	if DisplayServer.get_name()=="headless":
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_dir))
	var scene = load("res://scenes/garden.tscn").instantiate()
	root.add_child(scene)
	while not scene._initialization_complete:
		await process_frame
	var benches: Array = scene.world.interactions.targets.filter(func(t):return t.kind=="bench")
	benches.sort_custom(func(a,b):return a.position.distance_to(Vector2(1030,2860))<b.position.distance_to(Vector2(1030,2860)))
	var bench: Dictionary = benches[0]
	# Clear only the review view so foliage cannot hide the artwork.
	for prop in scene.world.props:
		if prop!=bench.node: prop.hide()
	for plant in scene.world.low_foliage: plant.hide()
	for prop in scene.world.scenery_props: prop.hide()
	for person in scene.people:
		person.stand_up()
		person._finish_phone()
		person.cancel_sand_drawing()
		person.position = bench.node.seat_position(person.kind)
		person.seat_id = bench.id
		person.seat_slot = person.kind
		person.seated = true
		person.set_physics_process(false)
	scene.set_process(false)
	scene.hud.hide()
	scene.inventory_panel.hide()
	scene.camera.position = bench.position+Vector2(0,-45)
	scene.camera.zoom = Vector2(2.2,2.2)
	for pose in 5:
		bench.node.visible = pose<3
		if pose>=3:
			for person in scene.people:
				person.seated = false
				person.ground_seated = true
				person.ground_pose = pose-3
		scene.seated_posture_time = pose*30.0
		scene.seated_pair_id = bench.id
		scene._advance_seated_posture(0.0)
		for person in scene.people:
			person.selected_blend = 0.0
			person.controlled = false
			person.body.queue_redraw()
			person.queue_redraw()
		for frame in 3:
			await process_frame
		RenderingServer.force_draw()
		root.get_texture().get_image().save_png(output_dir+"/posture-%d.png"%pose)
	quit()
