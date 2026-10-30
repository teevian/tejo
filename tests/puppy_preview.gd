## Run with a graphics window. Stages are reached using normal gameplay actions.
extends SceneTree
var scene: Node2D
var pup: Node2D
func _initialize() -> void: call_deferred("run")
func place(te: Vector2, jo: Vector2) -> void:
	for i in 2:
		var person = scene.people[i]
		person.position = te if i==0 else jo
		person.velocity = Vector2.ZERO
		pup.previous_people[i] = person.position
func tick(seconds: float) -> void:
	for i in ceili(seconds/.05): pup.step(.05)
func until_state(value: String, limit := 35.0) -> void:
	for i in ceili(limit/.05):
		if pup.state==value: return
		pup.step(.05)
func capture(label: String) -> void:
	scene.camera.position = (scene.people[0].position+pup.position)*.5-Vector2(0,75)
	pup.queue_redraw()
	pup.body.queue_redraw()
	for person in scene.people: person.body.queue_redraw()
	await process_frame
	await process_frame
	RenderingServer.force_draw()
	root.get_texture().get_image().save_png("res://output/puppy-"+label+".png")
func run() -> void:
	scene = load("res://scenes/garden.tscn").instantiate()
	root.add_child(scene)
	scene.set_process(false)
	pup = scene.world.puppy
	for person in scene.people:
		person.set_physics_process(false)
		person.in_dialogue = true
	var home: Vector2 = pup.home
	place(home+Vector2(-260,110),home+Vector2(-160,180))
	tick(1)
	await capture("guard")
	for meal in 2:
		scene.people[0].inventory.try_add(pup.Art.FOOD)
		pup.interact(scene.people[0])
		await capture("offering-"+str(meal+1))
		var at: Vector2 = pup.food.position
		place(at+Vector2(-230,250),at+Vector2(230,250))
		until_state("eat")
		await capture("eating-"+str(meal+1))
		tick(5)
		place(pup.position+Vector2(-230,160),pup.position+Vector2(-110,280))
	# Two independent sniffing encounters, with enough time to retreat in between.
	for greeting in 2:
		place(pup.position+Vector2(-230,120),pup.position+Vector2(-130,280))
		until_state("sniff")
		await capture("sniff-"+str(greeting+1))
		tick(5)
		if greeting==0:
			tick(8)
	pup.interact(scene.people[0])
	await capture("pet")
	tick(3.5)
	await capture("friend")
	place(pup.position+Vector2(-170,80),pup.position+Vector2(-62,0))
	pup.interact(scene.people[1])
	await capture("jo-pet")
	tick(3.5)
	# Separate fixture for the initial defensive nip; never changes the real session.
	pup.friendly = false
	pup.trust = .1
	pup.bite_cooldown = 0
	pup.position = home
	pup._set_state("guard")
	place(home+Vector2(-95,20),home+Vector2(125,30))
	scene.people[0].velocity = Vector2(235,0)
	pup.step(.05)
	scene.people[0].velocity = Vector2.ZERO
	until_state("nip",3)
	await capture("jo-nip")
	quit()
