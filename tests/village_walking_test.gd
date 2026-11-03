extends SceneTree
var scene: Node2D
var failed := false
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		push_error(message)
func frames(n: int) -> void:
	for i in n: await physics_frame
func release() -> void:
	for action in ["walk_left","walk_right","walk_up","walk_down"]: Input.action_release(action)
func walk_to(goal: Vector2, label: String) -> bool:
	var leader: CharacterBody2D = scene.people[scene.selected]
	var path: PackedVector2Array = scene.world.find_path(leader.position,goal)
	check(not path.is_empty(),"A route exists to "+label)
	if path.is_empty(): return false
	var last := leader.position
	var stalled := 0
	for tick in 16000:
		while not path.is_empty() and leader.position.distance_to(path[0])<10: path.remove_at(0)
		if path.is_empty(): break
		var direction := leader.position.direction_to(path[0])
		for binding in [["walk_left",maxf(0,-direction.x)],["walk_right",maxf(0,direction.x)],["walk_up",maxf(0,-direction.y)],["walk_down",maxf(0,direction.y)]]:
			if binding[1]>.01: Input.action_press(binding[0],binding[1])
			else: Input.action_release(binding[0])
		await physics_frame
		if leader.position.distance_to(last)<.1: stalled += 1
		else: stalled = 0
		last = leader.position
		if stalled>90:
			check(false,"Physical route stalled near "+label+" at "+str(leader.position)+" towards "+str(path[0]))
			release()
			return false
	release()
	await frames(90)
	check(leader.position.distance_to(goal)<90,"Leader reaches "+label)
	var friend: CharacterBody2D = scene.people[1-scene.selected]
	check(friend.position.distance_to(leader.position)<260,"Companion follows through "+label+" gap="+str(friend.position.distance_to(leader.position)))
	return true
func run() -> void:
	scene = load("res://scenes/sintra_village.tscn").instantiate()
	root.add_child(scene)
	await frames(3)
	for person in scene.people: person.idle_delay = 10000
	var places: Dictionary = {}
	for place in scene.world.landmarks: places[place.id] = place.position
	for id in ["village_piriquita","village_ferraria","village_ferreira","village_sassetti","forest_access"]:
		if not await walk_to(places[id],id): break
	scene._select_person(1)
	for id in ["village_pipa","village_martinho","village_lawrence","village_valencas","village_mourisca","village_liberdade","village_market","village_western_court","village_tiles","village_residential","village_gardens","village_byron","village_palace"]:
		if not await walk_to(places[id],id): break
	# The palace loggia has three real openings, not a painted solid rectangle.
	for i in 3:
		var approach: Vector2 = scene.world._point(scene.world.LAYOUT.data.arcade_approaches[i])
		var opening: Vector2 = scene.world._point(scene.world.LAYOUT.data.arcade_openings[i])
		if not await walk_to(approach,"palace arcade approach"): break
		if not await walk_to(opening,"palace arcade opening"): break
		if not await walk_to(approach,"palace arcade return"): break
	var bench: Dictionary = scene.world.interactions.targets.filter(func(t): return t.kind=="bench")[0]
	await walk_to(bench.position+Vector2(0,75),"palace bench")
	scene._interact()
	await frames(240)
	check(scene.people.all(func(p): return p.seated),"Both people actually sit on the village bench")
	scene._interact()
	await frames(10)
	# Validate every authored two-seat bench with the same routes used to sit.
	for target in scene.world.interactions.targets:
		if target.kind!="bench": continue
		for kind in 2:
			var seat: Vector2 = target.node.seat_position(kind)
			check(scene.world.is_walkable(seat,14) and not scene.world.find_path(scene.people[kind].position,seat).is_empty(),"Both places on bench "+target.id+" are accessible")
	release()
	scene.queue_free()
	await frames(2)
	if not failed: print("PASS: real input traversal Palace–Padarias–Ferraria–Sassetti, return with Jo via Pipa/Church/Lawrence/Valenças/Duche/Park, companion and all bench seats")
	quit(1 if failed else 0)
