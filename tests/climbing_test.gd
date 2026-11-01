extends SceneTree
## Real input drives a complete climb; no character is teleported through puzzles.
var scene: Node2D
var failed := false
var preview := false

class ErrorLog:
	extends Logger
	var errors: Array[String] = []
	func _log_error(_function: String, file: String, line: int, code: String, _rationale: String, _editor_notify: bool, _error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
		errors.append("%s:%d %s"%[file,line,code])

func _initialize() -> void:
	preview = "--preview" in OS.get_cmdline_user_args()
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failed = true
		push_error(message)
		if is_instance_valid(scene):
			for person in scene.people: print("STATE ",person.kind," shelf ",person.shelf," point ",scene.space.world_point(person)," anchor ",person.anchor," grounded ",person.grounded)
			print("VIEW ",scene.space.view," NOTE ",scene.hud.note)
		quit(1)

func frames(count: int) -> void:
	for i in count: await physics_frame

func press(key: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = key
	event.pressed = true
	root.push_input(event)
	event = event.duplicate()
	event.pressed = false
	root.push_input(event)

func settle() -> void:
	for i in 240:
		await physics_frame
		if not scene.any_busy(): break
	check(not scene.any_busy(),"Traversal must finish within four seconds")
	await frames(4)

func walk_to(x: float) -> void:
	var person = scene.people[scene.selected]
	var direction := signf(x-person.position.x)
	if is_zero_approx(direction): return
	var action := "walk_right" if direction>0 else "walk_left"
	Input.action_press(action)
	for i in 360:
		await physics_frame
		if absf(person.position.x-x)<5 or (person.position.x-x)*direction>=0: break
	Input.action_release(action)
	await frames(3)
	if "--trace" in OS.get_cmdline_user_args(): print("WALK ",person.kind," to ",x," got ",person.position," shelf ",person.shelf," world ",scene.space.world_point(person)," rope ",scene.rope_separation())

func to_edge(direction: int) -> void:
	var person = scene.people[scene.selected]
	await walk_to(scene.edge_x(person,direction))
	# Hold at the rock: it must never silently become an automatic climb.
	var action := "walk_right" if direction>0 else "walk_left"
	Input.action_press(action)
	await frames(8)
	Input.action_release(action)
	await frames(2)

func climb_solo(target: int) -> void:
	var person = scene.people[scene.selected]
	var edge: Dictionary = scene.edge_for(person)
	check(not edge.is_empty(),"Missing ascending link on shelf "+str(person.shelf))
	if edge.is_empty(): return
	await to_edge(int(edge.dir))
	press(KEY_UP)
	await settle()
	check(person.shelf==target,"Cima must reach shelf %d, got %d"%[target,person.shelf])
	if "--trace" in OS.get_cmdline_user_args(): print("CLIMB ",target," world ",scene.space.world_point(person)," partner ",scene.space.world_point(scene.people[1-person.kind])," partner shelf ",scene.people[1-person.kind].shelf," timer ",scene.platforms[person.shelf].get("timer",0))

func capture(label: String) -> void:
	if not preview: return
	if label=="summit": await frames(90)
	scene.camera.position = scene.camera_target()
	await frames(4)
	await process_frame
	RenderingServer.force_draw()
	root.get_texture().get_image().save_png("res://output/climbing-"+label+".png")

func run() -> void:
	var errors := ErrorLog.new()
	scene = load("res://scenes/rock_climbing.tscn").instantiate()
	OS.add_logger(errors)
	root.add_child(scene)
	await frames(4)
	check(scene.platforms.size()==39,"The climbing route must include both flanks, two tunnels and lateral galleries")
	var atlas := preload("res://assets/climbing/granite-atlas.png").get_image()
	check(atlas.get_pixel(0,0).a<0.01 and atlas.get_pixel(720,510).a<0.01,"Granite atlas must have real transparent gaps")
	await capture("trailhead")
	press(KEY_T)
	check(not scene.dialogue_lines.is_empty(),"T must start a contextual puzzle conversation")
	var start: Vector2 = scene.people[0].position
	Input.action_press("walk_right")
	await frames(10)
	Input.action_release("walk_right")
	check(scene.people[0].position==start,"Conversation must suspend movement")
	press(KEY_ESCAPE)
	check(scene.dialogue_lines.is_empty() and not paused,"Esc closes the conversation before pausing")
	# Cima away from the face is a responsive jump, with horizontal air control.
	var takeoff: Vector2 = scene.people[0].position
	press(KEY_UP)
	Input.action_press("walk_right")
	await frames(10)
	Input.action_release("walk_right")
	check(scene.people[0].position.y<takeoff.y-40 and scene.people[0].position.x>takeoff.x+10,"Cima must jump and retain air control")
	await settle()
	check(scene.people[0].grounded and scene.people[0].shelf==0,"A free jump must land back on the rock")
	# First high wall: held arrows never bypass the required boost and pull.
	await to_edge(1)
	press(KEY_RIGHT)
	await frames(12)
	check(scene.people[0].shelf==0,"A high rock cannot be climbed alone")
	press(KEY_SPACE)
	await frames(24)
	await capture("boost-action")
	await settle()
	check(scene.people[0].shelf==1 and scene.people[1].shelf==0,"Giving a foot only raises the first climber")
	# A fixed rope stops the upper climber walking indefinitely away.
	Input.action_press("walk_right")
	await frames(170)
	Input.action_release("walk_right")
	check(scene.rope_separation()<=scene.Route.ROPE_LENGTH+0.1,"The rope must physically limit separation")
	var rope: PackedVector2Array = scene.rope_points()
	var rope_length := 0.0
	for i in rope.size()-1: rope_length += rope[i].distance_to(rope[i+1])
	check(rope_length<=scene.Route.ROPE_LENGTH+0.2,"The drawn rope must not stretch beyond its physical limit")
	await walk_to(596)
	await capture("helping-hand")
	press(KEY_SPACE)
	await settle()
	check(scene.people[1].shelf==1,"The upper climber must pull the lower one")
	await climb_solo(2)
	# Climb over the loose block, then push it back towards the high wall.
	await walk_to(430)
	press(KEY_UP)
	await settle()
	check(scene.people[scene.selected].shelf==20,"Cima must climb a loose stone from either side")
	await walk_to(260)
	await settle()
	check(scene.people[scene.selected].shelf==2,"Walking off the block must land on the ledge below")
	Input.action_press("walk_right")
	for i in 180:
		await physics_frame
		if scene.flags.get("push_step",false): break
	Input.action_release("walk_right")
	await frames(4)
	check(scene.flags.get("push_step",false),"Walking against the block must push it to the wall")
	await capture("pushable-stone")
	press(KEY_UP)
	await settle()
	check(scene.people[scene.selected].shelf==20,"The pushed block must remain a real foothold; got "+str(scene.people[scene.selected].shelf)+" at "+str(scene.people[scene.selected].position))
	await climb_solo(3)
	# Undercut face: a pull cannot replace the new stepping stone.
	await to_edge(-1)
	press(KEY_SPACE)
	await settle()
	check(scene.people[0].shelf==4 and scene.people[1].shelf==3,"Rock puzzle needs the two characters on different levels")
	press(KEY_SPACE)
	await settle()
	check(scene.flags.get("rock_step",false) and scene.platforms[18].enabled,"The loose rock must create a real support")
	check(scene.people[1].shelf==3,"Dropping the rock must not teleport the waiting climber")
	await capture("stepping-stone")
	press(KEY_TAB)
	await climb_solo(18)
	await climb_solo(4)
	await climb_solo(22)
	await climb_solo(23)
	await walk_to(990)
	await capture("dolmen-entrance")
	press(KEY_UP)
	await frames(65)
	check(scene.people.all(func(person): return person.traversing() and person.pose=="tunnel"),"Both partners must physically enter the sheltered tunnel")
	await capture("inside-dolmen")
	await settle()
	check(scene.people.all(func(person): return person.shelf==24),"The dolmen must lead to the far flank")
	press(KEY_E)
	await settle()
	await capture("perspective-passage")
	await climb_solo(5)
	await climb_solo(6)
	press(KEY_Q)
	await settle()
	# Balance: one stays put while the other uses and locks the raised slab.
	await walk_to(260)
	press(KEY_SPACE)
	check(scene.people[scene.selected].anchor=="balance","Space on the left end must hold the slab")
	var anchor_person: int = scene.selected
	var anchor_position: Vector2 = scene.people[anchor_person].position
	press(KEY_TAB)
	await climb_solo(19)
	check(scene.people[anchor_person].position==anchor_position,"The supporting partner must stay on the counterweight")
	await capture("counterweight")
	# Releasing early is recoverable; it cannot leave somebody on invisible ground.
	press(KEY_TAB)
	press(KEY_SPACE)
	check(not scene.people[1-anchor_person].grounded,"Releasing the slab must drop its occupant naturally")
	await settle()
	check(not scene.platforms[19].enabled and scene.people[1-anchor_person].shelf==6,"Releasing an unsecured slab safely returns its climber")
	press(KEY_SPACE)
	press(KEY_TAB)
	await climb_solo(19)
	await climb_solo(7)
	await walk_to(740)
	press(KEY_SPACE)
	check(scene.flags.get("balance_locked",false),"A wedge must lock the slab before the supporter can leave")
	press(KEY_TAB)
	await climb_solo(19)
	await climb_solo(7)
	await climb_solo(8)
	await climb_solo(9)
	# Both have to be at the chimney, then rise together.
	await to_edge(-1)
	press(KEY_SPACE)
	await settle()
	check(scene.people[0].shelf==10 and scene.people[1].shelf==10,"Back-to-back climbing must carry both up the chimney")
	await capture("chimney")
	# The lower climber waits at the outer end of the safe terrace. The scout
	# explores a lateral route alone, then lowers the rope instead of retracing it.
	await walk_to(590)
	press(KEY_TAB)
	await walk_to(590)
	press(KEY_TAB)
	await climb_solo(26)
	await walk_to(900)
	press(KEY_E)
	await settle()
	await climb_solo(11)
	await climb_solo(27)
	await climb_solo(28)
	check(scene.people[1-scene.selected].shelf==10,"The scout route must leave the partner on the safe lower terrace")
	press(KEY_SPACE)
	check(scene.people[scene.selected].anchor=="belay","The scout must explicitly hold the rope on solid rock")
	await capture("scout-belay")
	press(KEY_TAB)
	press(KEY_UP)
	await frames(50)
	check(scene.people[scene.selected].pose=="rope" and scene.people[scene.selected].traversing(),"The waiting partner must visibly climb the rope")
	await capture("climbing-partner-rope")
	await settle()
	check(scene.people.all(func(person): return person.shelf==28) and scene.flags.get("scout_reunited",false),"Both climbers must reunite before continuing")
	await climb_solo(12)
	press(KEY_Q)
	await settle()
	await to_edge(1)
	press(KEY_SPACE)
	await settle()
	await walk_to(820)
	press(KEY_SPACE)
	check(scene.rope_ready(),"The upper climber must hold the rope at the granite horn")
	press(KEY_TAB)
	await to_edge(1)
	press(KEY_UP)
	await frames(25)
	check(scene.any_busy(),"Rope climb should have visible duration")
	var mid_rope: Vector2 = scene.people[scene.selected].position
	press(KEY_ESCAPE)
	await frames(25)
	check(paused and scene.people[scene.selected].position==mid_rope,"Pause must freeze a climb in progress")
	press(KEY_SPACE)
	check(scene.people[scene.selected].position==mid_rope,"Space must not act while paused")
	await capture("pause")
	press(KEY_ESCAPE)
	await settle()
	check(scene.people[0].shelf==13 and scene.people[1].shelf==13 and scene.flags.get("rope_secured",false),"Belay must get both climbers to the rope station")
	await capture("rope-station")
	await climb_solo(14)
	await climb_solo(30)
	await walk_to(435)
	press(KEY_E)
	await settle()
	await walk_to(1080)
	await capture("fern-tunnel")
	press(KEY_UP)
	await settle()
	check(scene.people.all(func(person): return person.shelf==31),"The second tunnel must cross the mountain in real depth")
	check(not scene.platforms[29].enabled,"The far-side bridge must remain unsafe until braced")
	Input.action_press("walk_right")
	for i in 240:
		await frames(1)
		if scene.flags.get("bridge_braced",false): break
	Input.action_release("walk_right")
	await frames(3)
	check(scene.flags.get("bridge_braced",false),"Pushing in the side projection must move the key stone along Z and brace the bridge")
	await capture("depth-key-stone")
	press(KEY_UP)
	await settle()
	check(scene.people[scene.selected].shelf==33,"The bracing stone must also be a physical step")
	await climb_solo(29)
	await climb_solo(15)
	press(KEY_Q)
	await settle()
	await to_edge(-1)
	press(KEY_SPACE)
	await settle()
	press(KEY_SPACE)
	await settle()
	await climb_solo(17)
	check(scene.completed and scene.checkpoint==17,"The summit requires both Te and Jo")
	await capture("summit")
	# Descending stays possible, and a fresh attempt starts without stale supports.
	press(KEY_DOWN)
	await settle()
	check(scene.people[scene.selected].shelf==16,"Down must descend a previously climbed face")
	scene.restart()
	check(not scene.completed and scene.flags.is_empty() and not scene.platforms[18].enabled and not scene.platforms[19].enabled,"Restart must reset every puzzle")
	check(scene.people[0].shelf==0 and scene.people[1].shelf==0,"Restart must return both to the trailhead")
	check(scene.hud.arrival_time==0,"Restart must clear the previous summit celebration")
	OS.remove_logger(errors)
	check(errors.errors.is_empty(),"Climbing runtime errors: "+str(errors.errors))
	scene.queue_free()
	await frames(2)
	if not failed: print("PASS: complete keyboard-driven cooperative climb, rock step, counterweight recovery, chimney, belay, summit, conversations, pause and restart")
	quit(1 if failed else 0)
