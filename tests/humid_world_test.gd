extends SceneTree
var scene: Node2D
var failed := false
func _initialize() -> void:
	call_deferred("run")
func check(value: bool, message: String) -> void:
	if not value:
		failed = true
		push_error(message)
func frames(count: int) -> void:
	for i in count:
		await physics_frame
func run() -> void:
	scene = load("res://scenes/garden.tscn").instantiate()
	root.add_child(scene)
	await frames(3)
	check(scene.world.WORLD_SIZE.x>=4800 and scene.world.WORLD_SIZE.y>=5400,"World must preserve the complete humid extension")
	for landmark in scene.world.landmarks:
		check(not scene.world.find_path(Vector2(850,2890),landmark.position).is_empty(),"No route to "+str(landmark.id))
	var te = scene.people[0]
	var jo = scene.people[1]
	te.position = Vector2(2560,4420)
	jo.position = Vector2(2450,4420)
	Input.action_press("walk_right")
	await frames(210)
	Input.action_release("walk_right")
	await frames(210)
	check(te.position.x>3250,"Leader crosses new sloped boardwalk")
	check(jo.position.x>3100,"Companion crosses new sloped boardwalk")
	check(not scene.world.in_water(jo.position),"Follower stays on bridge or bank")
	# An unbridged part of the ravine must physically stop movement.
	te.position = Vector2(2600,4800)
	jo.position = Vector2(2470,4800)
	Input.action_press("walk_right")
	await frames(150)
	Input.action_release("walk_right")
	await frames(20)
	check(te.position.x<scene.world.river_x(4800)-65,"Ravine bank collision must agree with painting")
	te.position = Vector2(1200,4200)
	jo.position = Vector2(1100,4210)
	scene._talk()
	check(scene.dialogue.active_topic.id=="ivy_hollow_humid","New area gets its own contextual conversation")
	scene.dialogue.cancel()
	scene.exploration_map.record_positions()
	check(scene.exploration_map.discovered.has("ivy_hollow"),"Expanded landmarks can be discovered")
	for person in scene.people:
		check(person.modulate.a==1.0 and person.body.modulate.a==1.0,"Depth effects never fade characters")
	if not failed:
		print("PASS: expansion connectivity, new sloped crossing and companion, ravine collision, local conversation, discovery and opaque characters")
	quit(1 if failed else 0)
