extends SceneTree
var scene: Node2D
var failed := false
var te: CharacterBody2D
var jo: CharacterBody2D
func _initialize() -> void:
	call_deferred("run_checks")
func check(condition: bool, message: String) -> void:
	if not condition:
		failed = true
		push_error(message)
func frames(n: int) -> void:
	for i in n:
		await physics_frame
func place(a: Vector2,b: Vector2) -> void:
	te.position = a
	jo.position = b
	for person in scene.people:
		person.velocity = Vector2.ZERO
		person.path.clear()
		person.route_time = 0
		person._finish_phone()
func run_checks() -> void:
	scene = load("res://scenes/garden.tscn").instantiate()
	root.add_child(scene)
	te = scene.people[0]
	jo = scene.people[1]
	await frames(30)
	check(scene.world.props.size() > 150,"The world needs an actual forest, not just a backdrop")
	check(scene.world.WORLD_SIZE.x > 4000 and scene.world.WORLD_SIZE.y > 3000,"Map must extend in both axes")
	check(scene.world.actors.y_sort_enabled,"Trees and characters must share depth sorting")
	var start := te.position
	Input.action_press("walk_up")
	await frames(25)
	Input.action_release("walk_up")
	await frames(12)
	check(te.position.y < start.y-60,"W must walk north, not jump")
	check(te.facing.y < -0.9,"North movement must show the back-facing sprites")
	start = te.position
	Input.action_press("walk_down")
	await frames(25)
	Input.action_release("walk_down")
	await frames(12)
	check(te.position.y > start.y+60,"S must walk south")
	check(te.facing.y > 0.9,"South movement must face the viewer")
	# Digital diagonals are normalized, so they cannot move faster.
	Input.action_press("walk_up")
	Input.action_press("walk_right")
	await frames(12)
	check(te.velocity.length() <= 235.1,"Diagonal movement must not gain extra speed")
	Input.action_release("walk_up")
	Input.action_release("walk_right")
	await frames(20)
	# All places remain connected through the forest and across the real bridges.
	for landmark in scene.world.landmarks:
		check(not scene.world.find_path(Vector2(850,2890),landmark.position).is_empty(),"Unreachable landmark: "+str(landmark.id))
	print("Checking stream and both bridges...")
	place(Vector2(2600,1700),Vector2(2480,1700))
	Input.action_press("walk_right")
	await frames(160)
	Input.action_release("walk_right")
	await frames(20)
	check(te.position.x < scene.world.river_x(te.position.y)-120,"River must physically stop a character outside bridges")
	for bridge in scene.world.BRIDGES:
		place(Vector2(bridge.x-320,bridge.y),Vector2(bridge.x-430,bridge.y))
		Input.action_press("walk_right")
		await frames(175)
		Input.action_release("walk_right")
		await frames(160)
		check(te.position.x > bridge.x+250,"Both bridge decks must be physically traversable")
		check(jo.position.x > bridge.x+100,"The companion must cross each bridge too")
	# Companion plans a detour when leader is on opposite shore, away from a bridge.
	place(Vector2(3500,1680),Vector2(2650,1670))
	await frames(900)
	check(te.position.distance_to(jo.position) < 125,"Follower must route around the river via a bridge")
	check(not scene.world.in_water(jo.position),"Follower may never walk through the river")
	print("Checking doorway and solid foreground depth...")
	place(scene.world.ARCH_CENTER+Vector2(0,150),scene.world.ARCH_CENTER+Vector2(-80,190))
	Input.action_press("walk_up")
	await frames(85)
	Input.action_release("walk_up")
	await frames(20)
	check(te.position.y < scene.world.ARCH_CENTER.y-100,"Characters must physically pass underneath the chapel arch")
	check(is_equal_approx(te.modulate.a,1.0) and is_equal_approx(te.body.modulate.a,1.0),"Crossing masonry must keep the character opaque")
	check(scene.hud.avatars[0].active and not scene.hud.avatars[1].active,"Only the selected avatar is outlined")
	print("Checking free exploration, map, phone and conversation...")
	# A physically colliding trunk has a tiny ground footprint, not its whole canopy.
	var prop = scene.world.props.filter(func(item):return int(item.get_meta("kind"))<2)[0]
	check(not scene.world.is_walkable(prop.position),"Tree trunk must collide")
	check(prop.half_width > 50,"Tree canopy must extend beyond trunk collision")
	place(prop.position+Vector2(0,-120),prop.position+Vector2(80,-120))
	for person in scene.people:
		person.in_dialogue = true
	await frames(45)
	check(is_equal_approx(prop.sprite.modulate.a,1.0),"Canopies must remain opaque when characters pass behind them")
	for person in scene.people:
		check(is_equal_approx(person.modulate.a,1.0) and is_equal_approx(person.body.modulate.a,1.0),"Characters must never fade")
	check(not scene.world.masonry.is_empty(),"Ruins need solid foreground masonry over the doorway")
	check(scene.world.low_foliage.size()>50,"Walk-through foliage must provide real gaps around opaque characters")
	for person in scene.people:
		person.in_dialogue = false
	place(Vector2(850,2890),Vector2(770,2920))
	await frames(500)
	check(jo.phone_state == jo.PhoneState.READING,"Jo's seven-second phone idle should work in the open world")
	Input.action_press("walk_up")
	await frames(2)
	Input.action_release("walk_up")
	check(jo.phone_state == jo.PhoneState.PUTTING_AWAY,"A northward move must also cancel Jo's phone")
	await frames(30)
	scene._talk()
	check(scene.dialogue.is_active(),"T must still start context conversations")
	check(jo.phone_state == jo.PhoneState.NONE,"Conversations must put the phone away")
	start = te.position
	Input.action_press("walk_right")
	await frames(30)
	Input.action_release("walk_right")
	check(te.position == start,"Movement is blocked during conversation")
	scene.dialogue.cancel()
	place(Vector2(2870,920),Vector2(2770,940))
	scene._talk()
	check(scene.dialogue.active_topic.id == "bridge_te","Te should retain the bridge-specific conversation")
	while scene.dialogue.is_active():
		scene.dialogue.advance()
	check(scene.dialogue.flags.get("bridge_inspected",false),"Correct completed dialogue must record its puzzle flag")
	var seen_before: int = scene.exploration_map.explored.size()
	place(Vector2(4030,2920),Vector2(3930,2950))
	await frames(30)
	check(scene.exploration_map.explored.size() > seen_before,"New exploration must reveal new map cells")
	check(scene.exploration_map.discovered.has("cork_oak"),"Visiting a landmark must discover it")
	scene._toggle_map()
	check(scene.exploration_map.visible and te.in_dialogue,"Map opens and safely holds movement")
	scene._toggle_map()
	check(not te.in_dialogue,"Closing the map restores movement")
	scene._select_person(1)
	check(jo.controlled and not te.controlled,"Both characters must remain selectable")
	place(Vector2(4030,2920),Vector2(3930,2950))
	var camera_before: Vector2 = scene.camera.position
	scene._toggle_pause()
	await frames(40)
	check(scene.camera.position == camera_before,"Pause freezes camera")
	scene._toggle_pause()
	await frames(150)
	check(scene.camera.position.x > 3500 and scene.camera.position.y > 2500,"Camera must follow both axes")
	if not failed:
		print("PASS: eight-way movement, sprites, diagonal speed, forest collisions, connected landmarks, river, both bridges, companion detours, opaque canopy/character depth and arch passage, phone, contextual dialogue, discovery, map, selection and pause.")
	quit(1 if failed else 0)
