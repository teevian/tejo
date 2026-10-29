extends SceneTree
var scene: Node2D
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var texture: Texture2D = load("res://assets/world/sintra-high-branch-complete.png")
	var im := texture.get_image()
	var max_edge_alpha := 0.0
	for x in im.get_width():
		for y in [0,1,im.get_height()-2,im.get_height()-1]:
			max_edge_alpha = maxf(max_edge_alpha,im.get_pixel(x,y).a)
	for y in im.get_height():
		for x in [0,1,im.get_width()-2,im.get_width()-1]:
			max_edge_alpha = maxf(max_edge_alpha,im.get_pixel(x,y).a)
	if max_edge_alpha>=0.02:
		push_error("Foreground paint reaches the canvas edge: "+str(max_edge_alpha))
		quit(1)
		return
	print("PASS: all four sprite borders fully clear under the production alpha threshold")
	scene = load("res://scenes/garden.tscn").instantiate()
	root.add_child(scene)
	scene.set_process(false)
	for person in scene.people:
		person.in_dialogue = true
	var points := [Vector2(1050,1400),Vector2(1700,2050),Vector2(1300,4180)]
	for index in points.size():
		for i in 2:
			scene.people[i].position = points[index]+Vector2(i*100,25*i)
			scene.people[i].facing = Vector2.UP
		scene.camera.position = scene._camera_target()
		for frame in 5:
			await process_frame
		RenderingServer.force_draw()
		root.get_texture().get_image().save_png("res://output/branch-complete-"+str(index)+".png")
	quit()
