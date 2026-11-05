extends SceneTree
var scene: Node2D
var failed := false
func _initialize() -> void:
	create_timer(120).timeout.connect(func(): push_error("Population test timed out"); quit(2))
	call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok: failed = true; push_error(message)
func frames(count: int) -> void:
	for i in count: await physics_frame
func run() -> void:
	scene = load("res://scenes/sintra_village.tscn").instantiate()
	root.add_child(scene)
	await frames(3)
	if not scene._initialization_complete: check(false,"Shared village controller initializes"); quit(1); return
	var world: Node2D = scene.world
	var population: Node2D = world.population
	scene.day_cycle.minutes = 690
	population.synchronize(scene.day_cycle,true)
	check(population.residents.size()==35,"Thirty original residents plus five distinct friends")
	check(world.people.size()==2 and scene.people.size()==2,"Residents never replace or join Te and Jo's controllable pair")
	var ids: Dictionary = {}
	var slots: Dictionary = {}
	var children := 0
	var elders := 0
	var cameos := 0
	var friends: Dictionary = {}
	var references := {"gil":[1],"tiago":[2],"alexandre":[3,6],"martim":[4],"afonso":[5]}
	var bounds := Rect2(population.residents[0].position,Vector2.ZERO)
	for actor in population.residents:
		check(not ids.has(actor.entry.id),"Unique resident identity: "+actor.entry.id)
		ids[actor.entry.id] = true
		var slot := str(actor.entry.atlas)+":"+str(actor.entry.column)
		check(not slots.has(slot),"Each person uses a different painted character")
		slots[slot] = true
		if actor.entry.age<13: children += 1
		if actor.entry.age>=65: elders += 1
		if actor.entry.public_figure: cameos += 1
		if actor.entry.has("friend_of"):
			friends[actor.entry.id] = actor
			check(actor.entry.friend_of==["te","jo"],"Each new friend knows both protagonists")
			check(PackedInt32Array(actor.entry.reference_images)==PackedInt32Array(references.get(actor.entry.id,[])),"User's portrait/name mapping, including Alexandre's two references")
		check(actor.home!=Vector2.INF and world.is_walkable(actor.home,14),"Safe public home for "+actor.entry.id)
		check(not world.find_path(world.menu_spawn,actor.home).is_empty(),"Reachable resident: "+actor.entry.id)
		check(actor.get_parent()==world.actors,"People share the village's foot-depth ordering")
		if actor.appointment.stroll: check(actor.stroll.size()>1,"A real clear local stroll for "+actor.entry.id)
		bounds = bounds.expand(actor.home)
	check(children==3 and elders>=5 and cameos==4,"Cast includes children, older people, four public cameos and varied adults")
	check(friends.size()==5 and friends.keys().all(func(id): return references.has(id)),"Exactly Gil, Tiago, Alexandre, Martim and Afonso; no duplicate Alexandre")
	check(bounds.size.x>15000 and bounds.size.y>11000,"Residents are distributed across the expanded city")
	check(world.interactions.targets.filter(func(t): return t.kind=="resident").size()==35,"Each resident and friend has an individual greeting target")
	scene.set_process(false)
	for player in scene.people: player.process_mode = Node.PROCESS_MODE_DISABLED
	var seen: Dictionary = {}
	for tick in 2400:
		population.step(1.0/60.0,scene.day_cycle)
		await physics_frame
		for actor in population.residents:
			if not seen.has(actor.entry.id): seen[actor.entry.id] = {}
			seen[actor.entry.id][actor.frame] = true
			if tick%60==0: check(world.is_walkable(actor.position,12),"Resident stays on public floor: "+actor.entry.id)
	for actor in population.residents:
		check(seen[actor.entry.id].has(0) and seen[actor.entry.id].has(1),"Two genuine activity poses animate for "+actor.entry.id)
		if actor.stroll.size()>1:
			check(actor.travelled>60 and seen[actor.entry.id].has(2) and seen[actor.entry.id].has(3),"Locomotion advances along the street with animated steps: "+actor.entry.id)
	var harry: CharacterBody2D = population.residents[0]
	var greeting_point := harry.position+Vector2(0,62)
	if not world.is_walkable(greeting_point,14): greeting_point = harry.position+Vector2(62,0)
	scene.people[0].position = greeting_point
	scene.people[1].position = greeting_point+Vector2(-100,0)
	var target: Dictionary = world.interactions.nearest(scene.people[0])
	check(target.get("kind","")=="resident" and target.node==harry,"Approaching Harry Kane selects his greeting")
	var response: String = world.interactions.interact(scene.people[0])
	check(response.contains("Harry Kane") and harry.greet_time>0,"Greeting identifies the cameo and briefly pauses his activity")
	check(world.interactions.discoveries.get("met_harry_kane",false),"Meeting a resident persists as a local discovery")
	for actor in friends.values():
		var approached := false
		for angle in 16:
			var point: Vector2 = actor.position+Vector2.from_angle(angle*TAU/16)*55
			if not world.is_walkable(point,14): continue
			scene.people[0].position = point
			scene.people[0].facing = point.direction_to(actor.position)
			scene.people[1].position = world.menu_spawn
			var nearby: Dictionary = world.interactions.nearest(scene.people[0])
			if nearby.get("kind","")!="resident" or nearby.node!=actor: continue
			check(world.interactions.prompt(scene.people[0],nearby).begins_with("Cumprimentar "+actor.entry.name+" · "),"Named greeting and current activity for "+actor.entry.id)
			var reply: String = world.interactions.interact(scene.people[0])
			check(reply.contains(actor.entry.name) and reply.contains("Te") and reply.contains("Jo") and actor.greet_time>0,"Friend recognises both Te and Jo: "+actor.entry.id)
			check(world.interactions.discoveries.get("met_"+actor.entry.id,false),"Meeting the friend is remembered: "+actor.entry.id)
			approached = true
			break
		check(approached,"A playable approach can greet "+actor.entry.id)
	for player in scene.people: player.process_mode = Node.PROCESS_MODE_INHERIT
	scene.set_process(true)
	scene._toggle_map()
	var elapsed: float = population.elapsed
	await frames(12)
	check(population.elapsed==elapsed,"Map freezes the entire background population")
	scene._toggle_map()
	scene._toggle_pause()
	await frames(12)
	check(population.elapsed==elapsed,"Pause freezes activities and local walks")
	scene._toggle_pause()
	check(scene._travel_region("forest",true),"Leave the town after meeting a resident")
	elapsed = population.elapsed
	var last_position: Vector2 = harry.position
	await frames(20)
	check(population.elapsed==elapsed and harry.position==last_position,"Inactive city residents stay frozen")
	check(scene._travel_region("village",true),"Return to the retained town")
	check(scene.world.population==population and population.residents.size()==35 and harry.greetings==1,"Revisits preserve all thirty-five identities, activity state and greeting memory without duplicates")
	for actor in friends.values():
		check(is_instance_valid(actor) and actor.greetings==1 and world.interactions.discoveries.get("met_"+actor.entry.id,false),"Revisits retain the same friend and their meeting: "+actor.entry.id)
	scene.queue_free()
	await frames(3)
	if not failed: print("PASS: 35 unique painted people, five reference-matched friends without duplicate Alexandre, reachable activities, local motion, individual greetings and persistent revisits")
	quit(1 if failed else 0)
