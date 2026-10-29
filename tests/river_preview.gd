extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var scene = load("res://scenes/garden.tscn").instantiate()
	root.add_child(scene)
	scene.set_process(false)
	for person in scene.people:
		person.in_dialogue = true
	scene.people[0].position = Vector2(2850,1550)
	scene.people[1].position = Vector2(2760,1580)
	scene.camera.position = Vector2(3050,1430)
	var river = scene.world.get_node("LivingRiver")
	river.set_process(false)
	for index in 2:
		river.water_material.set_shader_parameter("flow_time",float(index)*1.3)
		for frame in 4:
			await process_frame
		RenderingServer.force_draw()
		root.get_texture().get_image().save_png("res://output/river-flow-"+str(index)+".png")
	quit()
