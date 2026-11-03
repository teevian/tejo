extends "res://tests/football_test.gd"

func run() -> void:
	scene = load("res://scenes/garden.tscn").instantiate()
	root.add_child(scene)
	while not scene._initialization_complete: await process_frame
	scene.set_process(false)
	for p in scene.people: p.set_physics_process(false)
	jo = scene.people[1]
	var te: CharacterBody2D = scene.people[0]
	for object in scene.world.scenery_props:
		if object.kind==3: ball = object
	home = ball.position
	ball.juggling.rng.seed = 3792
	var directions := {}
	var shot_sides := {}
	for round_index in 8:
		reset()
		te.position = home-Vector2(20,0)
		scene._select_person(0)
		space()
		check(te.is_juggling() and te.football_action=="lift","Te must use his own foot lift on the real ball")
		step(0.6)
		var previous: Vector2 = ball.ball_velocity.normalized()
		for contact in 2:
			var point := Art.contact("foot",contact,1,0)
			ball.position = te.position+Vector2(point.x,0)
			ball.juggling.height = -point.y
			ball.juggling.vertical_speed = 0
			ball.ball_velocity = Vector2.ZERO
			space()
			check(te.football_action=="foot","Te's contact must use his own football art")
			step(0.1)
			check(ball.juggling.count==contact+1,"Te must produce one touch per timed Space")
			var direction: Vector2 = ball.ball_velocity.normalized()
			check(direction.dot(previous)<=0.51,"Every Te flick must change direction by at least sixty degrees")
			directions[roundi(direction.angle()*100)] = true
			previous = direction
			if contact==1:
				check(absf(ball.ball_velocity.x)>600 and absf(direction.y)<0.38,"Te's final touch must fire sideways much faster than walking")
				check(ball.juggling.vertical_speed<175,"The escaping ball must use a low trajectory, not another high juggle")
				shot_sides[signf(direction.x)] = true
			step(0.3)
		check(not te.is_juggling() and ball.juggling.last_count==2,"Te must release the ball after exactly two touches")
		check(ball.ball_velocity.length()>60 and ball.juggling.height>0,"Te's second touch must send the airborne ball away")
		space()
		step(0.1)
		check(not te.is_juggling() and ball.juggling.count==2,"A third press in the same flight must not add another touch")
	check(shot_sides.size()==2,"The random escaping shots must use both left and right")
	check(directions.size()>12,"Different rounds must produce varied random angles, not two fixed directions")
	# Prove a whole round works with normal flight, arrows and timed presses.
	reset()
	te.position = home-Vector2(20,0)
	scene._select_person(0)
	te.set_physics_process(true)
	drive_ball = true
	space()
	for frame in 600:
		if not te.is_juggling(): break
		var point := Art.contact("foot",mini(ball.juggling.count,1),1,0)
		var offset: Vector2 = ball.position-Vector2(point.x,0)-te.position
		for axis in ["walk_left","walk_right","walk_up","walk_down"]: Input.action_release(axis)
		if absf(offset.x)>4: Input.action_press("walk_right" if offset.x>0 else "walk_left")
		if absf(offset.y)>4: Input.action_press("walk_down" if offset.y>0 else "walk_up")
		if ball.juggling.vertical_speed<0 and absf(ball.juggling.height+point.y)<15 and ball.juggling.cooldown<=0 and ball.juggling.pending.is_empty(): space()
		await frames(1)
	for axis in ["walk_left","walk_right","walk_up","walk_down"]: Input.action_release(axis)
	check(ball.juggling.last_count==2,"Arrows and timed Space must sustain Te's complete two-touch round without teleporting the ball")
	drive_ball = false
	# On clear ground the shot must travel several character heights in under a second.
	ball.position = home
	ball.juggling.height = 40
	ball.juggling.last_direction = Vector2.UP
	ball.juggling._te_shot()
	var launch: Vector2 = ball.position
	step(0.75)
	check(absf(ball.position.x-launch.x)>400,"Te's shot must visibly escape far across the real clearing")
	scene.queue_free()
	await process_frame
	if not failed: print("PASS: Te lifts with Space, two timed touches, three own drawings, random changing angles, no third touch, and a natural round using arrows")
	quit(1 if failed else 0)
