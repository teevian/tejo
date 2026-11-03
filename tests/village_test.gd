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
func run() -> void:
	scene = load("res://scenes/sintra_village.tscn").instantiate()
	root.add_child(scene)
	await frames(3)
	check(scene._initialization_complete,"Village must initialize through the common exploration controller")
	if not scene._initialization_complete: quit(1); return
	var world: Node2D = scene.world
	var earth: Vector2 = world._point(world.LAYOUT.data.earth_test)
	var stone: Vector2 = world._point(world.LAYOUT.data.stone_test)
	check(world.WORLD_SIZE.x*world.WORLD_SIZE.y==6400*5600*10,"Expanded region has exactly ten times the previous area")
	check(world.buildings.size()>=500 and world.routes.size()>=70,"Dense housing and connected neighbourhoods populate the expanded area")
	check(world.puppy==null and world.wildlife==null,"Local forest encounters must not be instantiated in the town")
	print("Buildings: ",world.buildings.size()," Routes: ",world.routes.size())
	for place in world.landmarks:
		var path: PackedVector2Array = world.find_path(scene.people[0].position,place.position)
		check(not path.is_empty(),"Reachable place: "+place.id)
		check(world.is_walkable(place.position,14),"Clear approach: "+place.id+" "+str(place.position))
	for route in world.routes:
		for at in route.points:
			check(not world.find_path(world.menu_spawn,at).is_empty(),"Connected public junction: "+route.id+" "+str(at))
	check(not world.allows_ground_rest(stone),"Sand drawing must not start on calçada")
	check(world.allows_ground_rest(earth),"A garden must offer earth for sand drawing")
	for building in world.buildings:
		for polygon in building.footprints:
			var at := Vector2.ZERO
			for point in polygon: at += point
			at /= polygon.size()
			check(not world.is_walkable(at,0),"Building base blocks navigation: "+building.name)
			var query := PhysicsPointQueryParameters2D.new()
			query.position = at
			query.collision_mask = 1
			check(not world.get_world_2d().direct_space_state.intersect_point(query).is_empty(),"Building base exists in physics: "+building.name)
	# Exercise the actual waiting decision, rather than only its surface predicate.
	scene._select_person(1)
	for person in scene.people:
		person.velocity = Vector2.ZERO
		person.moving = false
	scene.people[0].position = earth
	scene.people[1].position = earth+Vector2(130,0)
	scene.people[0].sand_idle_time = 100
	scene.people[0]._update_sand_drawing(1,Vector2.ZERO)
	check(scene.people[0].sand_state==scene.Person.SandState.APPROACHING,"Te can approach earth to draw in the garden")
	scene.people[0].cancel_sand_drawing(false)
	scene.people[0].position = stone
	scene.people[1].position = stone+Vector2(120,0)
	scene.people[0].sand_idle_time = 100
	scene.people[0]._update_sand_drawing(1,Vector2.ZERO)
	check(scene.people[0].sand_state==scene.Person.SandState.NONE,"Te never starts sand drawing on urban paving")
	scene._select_person(0)
	# Effects only commit at the last line, just like forest conversations.
	scene.people[0].position = world.menu_spawn
	scene._talk()
	check(scene.dialogue.is_active() and scene.dialogue.active_topic.id=="village_chimneys","Palace has a local conversation")
	while scene.dialogue.is_active(): scene._talk()
	check(scene.dialogue.flags.get("village_palace_seen",false),"Completed local conversation applies its effect")
	var market: Dictionary = world.landmarks.filter(func(p): return p.id=="village_market")[0]
	scene.people[0].position = market.position
	scene.people[1].position = market.position+Vector2(-100,20)
	scene._talk()
	check(scene.dialogue.is_active() and scene.dialogue.active_topic.id=="village_market_detail","The new market has its own local conversation")
	while scene.dialogue.is_active(): scene._talk()
	check(scene.dialogue.flags.get("village_market_talk",false),"Market conversation commits its local memory")
	scene._toggle_map()
	var minutes: float = scene.day_cycle.minutes
	await frames(6)
	check(scene.day_cycle.minutes==minutes,"Map suspends shared time")
	scene._toggle_map()
	scene._toggle_pause()
	await frames(6)
	check(scene.day_cycle.minutes==minutes,"Pause suspends shared time")
	scene._toggle_pause()
	scene.queue_free()
	await frames(2)
	if not failed: print("PASS: urban approaches, physical building bases, garden surfaces, local dialogue, map and pause")
	quit(1 if failed else 0)
