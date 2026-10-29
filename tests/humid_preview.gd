extends SceneTree
var scene: Node2D
func _initialize() -> void:
	call_deferred("run")
func capture(label: String) -> void:
	for i in 5:
		await process_frame
	RenderingServer.force_draw()
	root.get_texture().get_image().save_png("res://output/"+label+".png")
func run() -> void:
	for file in ["sintra-high-branch.png","sintra-humid-trees.png"]:
		var im := Image.load_from_file("res://assets/world/"+file)
		print(file," alpha corner: ",im.get_pixel(0,im.get_height()-1).a)
	scene = load("res://scenes/garden.tscn").instantiate()
	root.add_child(scene)
	scene.set_process(false)
	for person in scene.people:
		person.in_dialogue = true
	for shot in [[Vector2(850,2890),"sintra-humid-entrance"],[Vector2(1300,4180),"sintra-ivy-hollow"],[Vector2(2900,4470),"sintra-ravine"],[Vector2(4110,4150),"sintra-moss-steps"]]:
		for i in 2:
			scene.people[i].position = shot[0]+Vector2(i*100,i*30)
			scene.people[i].facing = Vector2.DOWN if i==0 else Vector2.RIGHT
		scene.camera.position = scene._camera_target()
		scene.hud.area_title = scene.world.area_at(shot[0])
		scene.hud.queue_redraw()
		await capture(shot[1])
	for x in 40:
		for y in 45:
			scene.exploration_map.explored[Vector2i(x,y)] = true
	for place in scene.world.landmarks:
		scene.exploration_map.discovered[place.id] = true
	scene._toggle_map()
	await capture("sintra-expanded-overview")
	quit()
