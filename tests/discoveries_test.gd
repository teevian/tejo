extends SceneTree
var failed := false
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		push_error(message)
func run() -> void:
	var scene = load("res://scenes/garden.tscn").instantiate()
	root.add_child(scene)
	scene.set_process(false)
	for person in scene.people: person.set_physics_process(false)
	var world = scene.world
	check(world.scenery_props.size()>=16,"Authored discoveries scattered between monuments")
	for site in world.Discoveries.landmarks():
		check(world.is_walkable(site.position,23),"Clear approach: "+site.id)
		check(not world.find_path(Vector2(850,2890),site.position).is_empty(),"Connected discovery: "+site.id)
		scene.people[0].position = site.position
		scene.exploration_map.record_positions()
		check(scene.exploration_map.discovered.has(site.id),"Discovery appears on explored map: "+site.id)
		scene._talk()
		check(scene.dialogue.active_topic.id==site.id+"_discovery","Conversation fits the new place")
		scene.dialogue.cancel()
	var ball: Node2D
	var signs := 0
	var distinct_plants := 0
	for object in world.scenery_props:
		if object.kind==0:
			signs += 1
			check(object.labels.size()==2,"Old signs have two actual directions")
		if object.kind in [1,2]: distinct_plants += 1
		if object.kind==3: ball = object
	check(signs==6 and distinct_plants>=4,"Signs and unusual plants break up repetitive regions")
	var start: Vector2 = ball.position
	scene.people[0].position = start-Vector2(50,0)
	scene.people[0].facing = Vector2.RIGHT
	scene._interact()
	for i in 50: world.Discoveries.step(world,.02)
	check(ball.position.x>start.x+60,"Old football can be kicked and rolls")
	check(world.is_walkable(ball.position,17),"Rolling ball remains on accessible ground")
	var time: Vector2 = ball.position
	scene._toggle_map()
	scene._process(3)
	check(ball.position==time,"Exploration map suspends ball physics")
	scene._toggle_map()
	var art = preload("res://scripts/puppy_art.gd")
	var pup = world.puppy
	pup.friendly = false
	pup.state = "guard"
	pup.trust = 0
	var angry: Dictionary = art.sprite_spec(pup)
	pup.trust = .35
	var wary: Dictionary = art.sprite_spec(pup)
	pup.trust = .80
	var trusted: Dictionary = art.sprite_spec(pup)
	check(angry.texture!=wary.texture and wary.texture!=trusted.texture,"Face changes with trust while action stays identical")
	pup.trust = .1
	check(art.expression(pup)=="angry","Setbacks return the face to a defensive expression")
	pup.friendly = true
	check(art.expression(pup)=="trusted","Established friendship keeps original cute face")
	if not failed: print("PASS: distinct reachable encounters, signs, unusual plants, local conversations, kickable ball and modal pause, trust-dependent facial art")
	quit(1 if failed else 0)
