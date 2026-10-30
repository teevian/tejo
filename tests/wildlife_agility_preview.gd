## Real-world rendering of the behaviors in a disposable deterministic scene.
extends SceneTree
var scene: Node2D
func _initialize() -> void:
	call_deferred("run")
func capture(label: String) -> void:
	for a in scene.world.wildlife.animals:
		a.art.queue_redraw()
	scene.camera.force_update_scroll()
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://output/fox-"+label+".png")
func run() -> void:
	root.size = Vector2i(1280,720)
	scene = load("res://scenes/garden.tscn").instantiate()
	root.add_child(scene)
	scene.set_process(false)
	for p in scene.people: p.set_physics_process(false)
	var eco = scene.world.wildlife
	var fox
	var squirrel
	for a in eco.animals:
		if a.species=="fox" and fox==null: fox = a
		if a.species=="squirrel":
			a.set_state("hidden",1000)
			a.art.hide()
			if squirrel==null: squirrel = a
	fox.thirst = 0
	fox.cooldown = 999
	fox.ground_speed = 0
	var point: Dictionary = {}
	for center in [Vector2(850,2820),Vector2(1650,1850),Vector2(2500,1600),Vector2(4020,2930)]:
		scene.people[0].position = center+Vector2(0,70)
		scene.people[1].position = center+Vector2(-80,80)
		scene.camera.position = center
		scene.camera.force_update_scroll()
		await process_frame
		await process_frame
		fox.position = eco.land_point(center+Vector2(450,50),80)
		point = eco.observation_point(fox,scene.people[0])
		if not point.is_empty(): break
	if point.is_empty():
		push_error("No visible observation point found for preview")
		quit(1)
		return
	print("Observation point: ",point.position," camera: ",scene.camera.position)
	if not point.is_empty():
		fox.position = point.position
		fox.watched_person = scene.people[0]
		fox.set_state("watch",5)
		fox._fox_think()
		await capture("watching-at-edge")
		fox.flee_from(scene.people[0])
		fox.step(0.14)
		await capture("turning-bound")
	# A clear close-up makes the characteristic running and startle poses reviewable.
	for p in scene.people: p.position = Vector2(50,50)
	fox.position = Vector2(850,2820)
	fox.facing = Vector2(1,-1).normalized()
	fox.velocity = fox.facing*530
	fox.set_state("flee",5)
	fox.velocity = fox.facing*530
	fox.gait_distance = 30
	fox.art.position = Vector2(0,-6)
	squirrel.position = fox.position+Vector2(150,-70)
	squirrel.facing = Vector2(1,-1).normalized()
	squirrel.set_state("startled",0.24)
	squirrel.art.show()
	squirrel.art.position = Vector2(0,-16)
	scene.camera.position = fox.position+Vector2(70,-100)
	scene.camera.zoom = Vector2.ONE*1.5
	await capture("running-and-startle")
	quit()
