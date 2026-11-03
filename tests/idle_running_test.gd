extends SceneTree
## Real character physics: double taps, exact idle boundaries and reversible rest.
var failed := false
var scene: Node2D

func _initialize() -> void:
	call_deferred("run")
	create_timer(100,true,false,true).timeout.connect(func():
		push_error("Idle/running verification timed out")
		quit(1))

func check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		push_error(message)

func frames(count: int) -> void:
	for i in count: await physics_frame

func release_directions() -> void:
	for action in ["walk_left","walk_right","walk_up","walk_down"]: Input.action_release(action)

func set_direction(direction: Vector2) -> void:
	if direction.x!=0: Input.action_press("walk_right" if direction.x>0 else "walk_left")
	if direction.y!=0: Input.action_press("walk_down" if direction.y>0 else "walk_up")

func reset_people(spot: Vector2) -> void:
	release_directions()
	for p in scene.people:
		p.stand_up(true)
		p.cancel_sand_drawing(false)
		p._finish_phone()
		p.velocity = Vector2.ZERO
		p.moving = false
		p.position = spot+Vector2(p.kind*90,0)
		p.facing = Vector2.DOWN
		p.visual_facing = Vector2.DOWN
	scene.ground_idle_time = 0
	scene.rest_retry_time = 0

func run() -> void:
	var floor_scene = load("res://scenes/walking_test.tscn").instantiate()
	root.add_child(floor_scene)
	await frames(4)
	check(not InputMap.has_action("sprint"),"Shift/B must no longer have a separate sprint binding")
	for kind in 2:
		floor_scene._select_person(kind)
		var person = floor_scene.people[kind]
		# A held first press, including all repeated key events, stays a walk.
		set_direction(Vector2.RIGHT)
		await frames(24)
		check(not person.run_input.running and person.velocity.length()<250,"Holding a single direction must never activate running")
		check(not person.is_running(),"A normal walk must keep the approved walking drawings")
		release_directions()
		await frames(12)
		for direction in [Vector2.RIGHT,Vector2.LEFT,Vector2.UP,Vector2.DOWN,Vector2(1,1),Vector2(-1,1),Vector2(1,-1),Vector2(-1,-1)]:
			person.run_input.reset()
			set_direction(direction)
			await frames(12)
			release_directions()
			await frames(2)
			set_direction(direction)
			await frames(12)
			check(person.run_input.running and person.velocity.length()>315,"Two quick taps must run in all eight directions for character "+str(kind))
			check(person.is_running() and person.run_distance>0,"A real double tap must advance the dedicated running sprites")
			check(person.velocity.normalized().dot(direction.normalized())>0.98,"Running must retain the requested diagonal/axis")
			release_directions()
			await frames(12)
			check(not person.run_input.running,"Release must end the run")
			check(not person.is_running() and person.run_distance==0,"Release must restore walking/idle and reset the running cycle")
		# Start once, then turn through axes, diagonals and reversals without another tap.
		person.run_input.reset()
		set_direction(Vector2.RIGHT)
		await frames(4)
		release_directions()
		await frames(2)
		set_direction(Vector2.RIGHT)
		await frames(16)
		for direction in [Vector2.DOWN,Vector2(1,1),Vector2(-1,-1),Vector2.LEFT,Vector2.UP,Vector2(1,-1),Vector2(-1,1),Vector2.RIGHT]:
			release_directions()
			set_direction(direction)
			for frame in 36:
				await frames(1)
				check(person.run_input.running,"Changing direction must preserve running for character "+str(kind))
			check(person.is_running() and person.velocity.length()>315,"A turn must retain running speed and sprites without another double tap")
			check(person.velocity.normalized().dot(direction.normalized())>0.98,"Running must follow the new direction")
		release_directions()
		await frames(12)
		check(not person.run_input.running and not person.is_running(),"Releasing movement after turning must still stop running")
		person.run_input.reset()
		set_direction(Vector2.RIGHT)
		await frames(4)
		release_directions()
		await frames(20)
		set_direction(Vector2.RIGHT)
		await frames(12)
		check(not person.run_input.running,"Two slow taps must stay a walk")
		release_directions()
		await frames(12)
		# A stale first tap cannot survive a pause or a change of character.
		set_direction(Vector2.LEFT)
		await frames(2)
		release_directions()
		floor_scene._toggle_pause()
		await frames(4)
		floor_scene._toggle_pause()
		set_direction(Vector2.LEFT)
		await frames(12)
		check(not person.run_input.running,"Pause must invalidate a pending double tap")
		release_directions()
		await frames(12)
	# The companion uses the same running art while closing a large gap.
	floor_scene._select_person(0)
	var leader = floor_scene.people[0]
	var follower = floor_scene.people[1]
	leader.position = Vector2(2400,1800)
	follower.position = Vector2(2000,1800)
	leader.velocity = Vector2.ZERO
	follower.velocity = Vector2.ZERO
	follower.partner = leader
	await frames(20)
	check(follower.is_running() and follower.run_distance>0,"The companion must use running drawings while catching up")
	await frames(70)
	check(not follower.is_running(),"The companion must stop its running animation after catching up")
	floor_scene.queue_free()
	await frames(3)
	scene = load("res://scenes/garden.tscn").instantiate()
	root.add_child(scene)
	while not scene._initialization_complete: await process_frame
	scene.set_process(false)
	var spot := Vector2.ZERO
	for y in range(2900,3300,40):
		for x in range(650,1150,40):
			var at := Vector2(x,y)
			if scene._ground_rest_clear(at) and scene._ground_rest_clear(at+Vector2(132,0)) and scene.world.can_walk_line(at,at+Vector2(132,0)):
				spot = at
				break
		if spot!=Vector2.ZERO: break
	check(spot!=Vector2.ZERO,"A safe pair of ground-rest locations must exist")
	reset_people(spot)
	scene._select_person(0)
	var te = scene.people[0]
	var jo = scene.people[1]
	te.idle_delay = 9.5
	jo.idle_delay = 9.5
	await frames(540)
	check(jo.phone_state==jo.PhoneState.NONE,"The phone must wait its full sampled deadline")
	await frames(50)
	check(jo.phone_state==jo.PhoneState.TAKING_OUT,"The sampled deadline must start the authored pocket gesture")
	await frames(60)
	check(jo.phone_state==jo.PhoneState.READING and te.sand_state==te.SandState.NONE,"Only the unselected character may perform the idle gesture")
	set_direction(Vector2.RIGHT)
	await frames(4)
	check(jo.phone_state==jo.PhoneState.PUTTING_AWAY,"Player movement must stow the companion's phone")
	release_directions()
	reset_people(spot)
	scene._select_person(1)
	te.idle_delay = 9.5
	await frames(540)
	check(te.sand_state==te.SandState.NONE,"Te must also wait his full sampled deadline")
	await frames(50)
	check(te.rest_target=="sand" and te.rest_transition=="sit","Te must visibly lower himself into the drawing posture")
	await frames(60)
	check(te.sand_state==te.SandState.DRAWING and jo.phone_state==jo.PhoneState.NONE,"Idle Te draws while selected Jo remains standing")
	set_direction(Vector2.RIGHT)
	await frames(4)
	check(te.rest_target=="standing","The drawing pose must stand up through a reverse transition")
	release_directions()
	scene.queue_free()
	await frames(3)
	if not failed: print("PASS: both characters run by double tap in eight directions; sampled companion idle, phone stow and reversible drawing. Full paired rest is covered by rest_sequence_test.gd")
	quit(1 if failed else 0)
