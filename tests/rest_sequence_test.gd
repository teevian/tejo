extends SceneTree
## Exercise barriers, independent deadlines and the whole waking exchange in actual actors.
const Sequence = preload("res://scripts/rest_sequence.gd")
var failed := false
var scene: Node2D

func _initialize() -> void:
	call_deferred("run")
	create_timer(360,true,false,true).timeout.connect(func(): push_error("Rest sequence timed out"); quit(1))

func check(value: bool, message: String) -> void:
	if not value:
		failed = true
		push_error(message)

func frames(count: int, coordinate := false) -> void:
	for i in count:
		if coordinate: scene._update_ground_rest(1.0/60)
		await physics_frame

func run() -> void:
	var sample = Sequence.new()
	var durations := {}
	for seed_value in 200:
		sample.rng.seed = seed_value
		sample.reset()
		check(sample.companion_delay>=7 and sample.companion_delay<=10,"Companion wait must be sampled within 7–10 seconds")
		check(sample.seat_delay>=10 and sample.seat_delay<=15,"There must be exactly one shared 10–15 second seated deadline")
		durations[snappedf(sample.seat_delay,0.1)] = true
		sample._timed_stage("seated",15,20)
		check(sample.waits.all(func(t): return t>=15 and t<=20),"Both semi-recline timers must be sampled within 15–20 seconds")
		check(sample.waits[0]!=sample.waits[1],"Characters must receive independent deadlines")
		sample._timed_stage("reclined",5,15)
		check(sample.waits.all(func(t): return t>=5 and t<=15),"Both flat-lying timers must be sampled within 5–15 seconds")
	check(durations.size()>25,"Separate quiet waits must vary")
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
	check(spot!=Vector2.ZERO,"The real world must have safe resting places")
	for selected in 2:
		for p in scene.people:
			p.stand_up(true)
			p._finish_phone()
			p.position = spot+Vector2(p.kind*90,0)
			p.velocity = Vector2.ZERO
			p.moving = false
		scene._select_person(selected)
		scene._reset_rest_wait()
		var leader = scene.people[selected]
		var other = scene.people[1-selected]
		var seq = scene.rest_sequence
		seq.companion_delay = 7.5
		seq.seat_delay = 11.0
		await frames(440,true)
		check(other.phone_state==other.PhoneState.NONE and other.sand_state==other.SandState.NONE and other.rest_target!="sand","Neither companion animation may start before its sampled idle deadline")
		await frames(120,true)
		check(seq.stage=="companion","The shared timer starts on the actual companion animation")
		check((other.kind==1 and other.phone_state==other.PhoneState.READING) or (other.kind==0 and other.sand_state==other.SandState.DRAWING),"The unselected character must perform its own phone/drawing animation")
		check(not leader.ground_rest,"The selected character must stay standing during the companion animation")
		seq.elapsed = seq.seat_delay-0.1
		scene._update_ground_rest(0.05)
		check(not leader.ground_rest,"The common sitting deadline must not fire early")
		scene._update_ground_rest(0.06)
		check(scene.people.all(func(p): return p.ground_rest),"The common deadline must prepare both ground-rest locations")
		var sit_start := [-1,-1]
		for frame in 300:
			scene._update_ground_rest(1.0/60)
			for i in 2:
				if scene.people[i].rest_target=="ground" and sit_start[i]<0: sit_start[i] = frame
			await physics_frame
			if seq.stage=="seated": break
		check(sit_start[0]>=0 and sit_start[0]==sit_start[1],"Both actors must START sitting on exactly the same frame, including Te's drawing and Jo's phone stow")
		check(seq.stage=="seated" and scene.people.all(func(p): return p.ground_pose==0 and p.ground_seated),"The seated timers start only after both sit transitions complete")
		seq.waits.assign([15.0,20.0])
		scene._update_ground_rest(15.01)
		check(scene.people[0].rest_transition=="recline" and scene.people[1].rest_transition.is_empty(),"The first independent deadline must recline only its own actor")
		await frames(60)
		scene._update_ground_rest(0.01)
		check(seq.stage=="seated" and scene.people[0].ground_pose==4,"The first arrival must wait for the second actor without starting the next timer")
		var remaining: float = seq.waits[1]
		scene._toggle_pause()
		scene._update_ground_rest(50)
		await frames(10)
		check(seq.waits[1]==remaining,"Pause must freeze individual deadlines")
		scene._toggle_pause()
		scene._toggle_map()
		scene._update_ground_rest(50)
		await frames(10)
		check(seq.waits[1]==remaining,"The map must freeze individual deadlines")
		scene._toggle_map()
		scene._update_ground_rest(remaining+0.01)
		check(seq.stage=="seated","Starting the second transition is insufficient to cross the barrier")
		await frames(60)
		scene._update_ground_rest(0)
		check(seq.stage=="reclined" and scene.people.all(func(p): return p.ground_pose==4 and not p.is_sleeping()),"Only BOTH semi-reclined arrivals start the 5–15 second timers; eyes remain open")
		seq.waits.assign([5.0,15.0])
		scene._update_ground_rest(5.01)
		await frames(55)
		scene._update_ground_rest(0)
		check(seq.stage=="reclined" and scene.people[0].ground_pose==1 and scene.people[1].ground_pose==4,"The first flat-lying actor must wait with open eyes for its partner")
		check(not scene.rest_dream.eligible(),"Awake rest must not start the sleep dream")
		scene._update_ground_rest(10)
		await frames(55)
		scene._update_ground_rest(0)
		check(seq.stage=="lying" and seq.waits.all(func(t): return t>=5 and t<=10) and seq.waits[0]!=seq.waits[1],"Independent 5–10 second eye-closing clocks begin only after BOTH lie flat")
		seq.waits.assign([5.0,8.0])
		scene._update_ground_rest(4.99)
		check(scene.people.all(func(p): return not p.is_sleeping()),"Eyes must remain open throughout the full five seconds")
		scene._update_ground_rest(0.02)
		check(scene.people[0].is_sleeping() and not scene.people[1].is_sleeping() and seq.stage=="lying","Each actor closes eyes at its own deadline")
		check(not scene.rest_dream.eligible(),"One sleeping character must not start the shared dream")
		scene._update_ground_rest(3.0)
		check(seq.stage=="sleep" and scene.people.all(func(p): return p.is_sleeping()),"The final sleep state must wait for both independent deadlines")
		scene._select_person(1-selected)
		check(scene.people.all(func(p): return p.is_sleeping()),"Selection alone must preserve sleep")
		scene._select_person(selected)
		var starts := [leader.position,other.position]
		Input.action_press("walk_right")
		await frames(3,true)
		Input.action_release("walk_right")
		check(leader.wake_leader and not leader.is_sleeping() and other.is_sleeping(),"A brief move must wake ONLY the selected character first")
		var stretch_seen := false
		var call_seen := false
		var other_awake := false
		var rises := [-1,-1]
		for frame in 420:
			stretch_seen = stretch_seen or leader.rest_transition=="stretch"
			call_seen = call_seen or leader.rest_transition=="call"
			if not call_seen: check(other.is_sleeping(),"The partner must keep sleeping until called")
			other_awake = other_awake or not other.is_sleeping()
			for i in 2:
				if scene.people[i].rest_target=="standing" and rises[i]<0: rises[i] = frame
			if frame<300: check(leader.position==starts[0] and other.position==starts[1],"The waking exchange must not slide either actor")
			await frames(1,true)
			if scene.people.all(func(p): return not p.ground_rest and p.rest_transition.is_empty()): break
		check(stretch_seen and call_seen and other_awake,"A brief move must complete stretch, call, partner wake and both rises even after key release")
		check(rises[0]>=0 and rises[0]==rises[1],"Both actors must start their final rise together")
		check(scene.people.all(func(p): return not p.ground_rest and p.rest_transition.is_empty()),"The full waking exchange must complete")
	# Interrupt every posture and a partially completed descent with either actor.
	for selected in 2:
		for posture in ["seated","semi","flat","recline","lie","roll"]:
			for p in scene.people:
				p.stand_up(true)
				p.position = spot+Vector2(p.kind*132,0)
				p.ground_rest = true
				p.ground_seated = true
				p.seat_id = "ground_rest"
				p.velocity = Vector2.ZERO
				p.moving = false
			scene._select_person(selected)
			var leader = scene.people[selected]
			for p in scene.people:
				match posture:
					"semi": p.ground_pose = 4
					"flat": p.ground_pose = 1
					"recline": p.begin_reclining()
					"lie": p.ground_pose = 4; p.begin_lying()
					"roll": p.ground_pose = 1; p.eyes_closed = true; p.begin_ground_roll(2)
			if posture in ["recline","lie","roll"]: await frames(12)
			Input.action_press("walk_right")
			await frames(3)
			Input.action_release("walk_right")
			check(leader.wake_leader,"The selected actor must lead a wake from "+posture)
			if posture=="semi":
				var held: float = leader.rest_time
				scene._toggle_map()
				await frames(12)
				check(leader.rest_time==held,"The map must freeze the waking animation too")
				scene._toggle_map()
			await frames(420)
			check(scene.people.all(func(p): return not p.ground_rest and p.rest_transition.is_empty()),"A brief move from "+posture+" must finish the whole wake exchange")
	# The explicit menu still bypasses the long waits, preserving natural transitions.
	scene._request_sleep()
	for i in 600:
		await frames(1,true)
		if scene.people.all(func(p): return p.is_sleeping()): break
	check(scene.people.all(func(p): return p.is_sleeping()),"Dormir must still reach sleep through all authored transitions")
	# One complete uninterrupted wait uses the real sampled clocks at every stage.
	for p in scene.people:
		p.stand_up(true)
		p.position = spot+Vector2(p.kind*90,0)
		p._finish_phone()
		p.velocity = Vector2.ZERO
		p.moving = false
	scene._select_person(1)
	scene._reset_rest_wait()
	scene.sleep_requested = false
	var visited := {}
	for frame in 6000:
		visited[scene.rest_sequence.stage] = true
		await frames(1,true)
		if scene.rest_sequence.stage=="sleep": break
	check(scene.people.all(func(p): return p.is_sleeping()),"A natural uninterrupted wait must reach sleep without injecting any deadline or menu request")
	for stage in ["idle","companion","approach","seating","seated","reclined","lying"]:
		check(visited.has(stage),"The natural wait must visit stage "+stage)
	scene.queue_free()
	await process_frame
	if not failed: print("PASS: random intervals, both companion identities, exact simultaneous sitting, independent recline/lie deadlines, both-arrival barriers, independent eye-closing deadlines, freeze, selection, selected-first wake/stretch/call, simultaneous rise and Dormir")
	quit(1 if failed else 0)
