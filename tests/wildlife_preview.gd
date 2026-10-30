## Run with graphics. Normal simulation plus separate close-up behavior captures.
extends SceneTree
var scene: Node2D
func _initialize() -> void:
	call_deferred("run")
func capture(label: String) -> void:
	for a in scene.world.wildlife.animals:
		a.art.queue_redraw()
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://output/wildlife-"+label+".png")
func run() -> void:
	root.size = Vector2i(1280,720)
	scene = load("res://scenes/garden.tscn").instantiate()
	root.add_child(scene)
	for i in 90:
		await process_frame
	await capture("clearing")
	scene.set_process(false)
	for person in scene.people:
		person.set_physics_process(false)
		person.position = Vector2(50,50)
	var eco = scene.world.wildlife
	var fox
	var squirrel
	var frog
	for a in eco.animals:
		if a.species=="fox" and fox==null: fox = a
		if a.species=="squirrel" and squirrel==null: squirrel = a
		if a.species=="frog" and frog==null: frog = a
	var at: Vector2 = eco.land_point(Vector2(850,2820),80)
	fox.position = at
	fox.set_state("watch",4)
	fox.facing = Vector2.RIGHT
	squirrel.position = at+Vector2(110,-5)
	squirrel.set_state("forage",4)
	scene.camera.position = at+Vector2(30,-90)
	scene.camera.zoom = Vector2.ONE*1.7
	await capture("mammals")
	fox.position = frog.pond.bank+Vector2(0,70)
	fox.set_state("drink",7)
	fox.facing = Vector2.RIGHT
	frog.position = frog.pond.leaf
	frog.set_state("leaf",5)
	frog.step(0)
	scene.camera.position = frog.pond.bank+Vector2(40,-30)
	await capture("river")
	# Cover every animated drawing branch in the renderer.
	for state in ["fly","forage","perch","climb","descend","sleep","drink","pounce","hop","snap","nectar","flutter","rest"]:
		for a in eco.animals:
			a.set_state(state,2)
			a.art.queue_redraw()
		await process_frame
		await process_frame
	quit()
