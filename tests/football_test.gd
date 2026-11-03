extends SceneTree
const Art = preload("res://scripts/football_art.gd")
var failed := false
var scene: Node2D
var ball: Node2D
var jo: CharacterBody2D
var home := Vector2.ZERO
var drive_ball := false

func _initialize() -> void:
	call_deferred("run")
	physics_frame.connect(func():
		if drive_ball and is_instance_valid(ball): ball.step_ball(1.0/60.0))
	create_timer(90,true,false,true).timeout.connect(func(): quit(1))

func check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		push_error(message)

func frames(count: int) -> void:
	for i in count: await physics_frame

func step(seconds: float) -> void:
	for i in roundi(seconds*120): ball.step_ball(1.0/120.0)

func space(echo := false) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = KEY_SPACE
	event.pressed = true
	event.echo = echo
	scene._input(event)

func reset() -> void:
	ball.juggling.stop()
	ball.juggling.height = 0
	ball.juggling.vertical_speed = 0
	ball.ball_velocity = Vector2.ZERO
	ball.position = home
	ball.ball_accumulator = 0
	for p in scene.people:
		p.stand_up(true)
		p.cancel_sand_drawing(false)
		p._finish_phone()
		p.football_action = ""
		p.velocity = Vector2.ZERO
		p.moving = false
	jo.position = home-Vector2(20,0)
	scene.people[0].position = jo.position+Vector2(-135,35)
	scene._select_person(1)

func run() -> void:
	scene = load("res://scenes/garden.tscn").instantiate()
	root.add_child(scene)
	while not scene._initialization_complete: await process_frame
	scene.set_process(false)
	for p in scene.people: p.set_physics_process(false)
	jo = scene.people[1]
	for object in scene.world.scenery_props:
		if object.kind==3: ball = object
	check(is_instance_valid(ball),"Use the existing football in the real clearing")
	home = ball.position
	reset()
	space()
	check(jo.is_juggling() and jo.football_action=="lift" and ball.juggling.lifting,"Space on the existing ball must start Jo's foot lift")
	step(0.15)
	check(ball.juggling.height<10,"The lift begins by rolling the ball on the ground")
	step(0.20)
	check(not ball.juggling.lifting and ball.juggling.height>20 and ball.juggling.vertical_speed>0,"The toe flick must release a rising ball")
	step(0.3)
	var rising: float = ball.juggling.height
	step(0.6)
	check(ball.juggling.vertical_speed<0 and ball.juggling.height!=rising,"The football must rise, reach an apex and fall under gravity")
	# All nine real contact drawings must be reachable through Space and ball geometry.
	for action in ["foot","knee","head"]:
		for variant in 3:
			var point: Vector2 = Art.contact(action,variant)
			ball.position = jo.position+Vector2(point.x,0)
			ball.juggling.height = -point.y
			ball.juggling.vertical_speed = 0
			ball.ball_velocity = Vector2.ZERO
			var before: int = ball.juggling.count
			space()
			check(jo.football_action==action,"Ball height must choose the correct foot, knee or forehead action")
			check(jo.football_variant==variant,"Each authored contact variation must be usable")
			for repeat in 5: space()
			space(true)
			step(0.09)
			check(ball.juggling.count==before+1,"One timed press must produce one touch; spam and key repeat must not add touches")
			check(ball.juggling.vertical_speed>0 and ball.ball_velocity.length()>1,"A contact must produce a new rising arc and some lateral drift")
			check(ball.juggling.last_contact==action,"The actual collision must match the displayed contact type")
			step(0.30)
	check(ball.juggling.count==9,"Foot, knee and forehead variations form a continuous nine-touch round")
	var count: int = ball.juggling.count
	ball.position = jo.position
	ball.juggling.height = 300
	ball.juggling.vertical_speed = 0
	space()
	step(0.15)
	check(ball.juggling.count==count and ball.juggling.vertical_speed<0,"An early press must miss instead of automatically waiting for the ball")
	step(0.2)
	ball.position = jo.position+Vector2(24,100)
	ball.juggling.height = 235
	ball.juggling.vertical_speed = 0
	space()
	step(0.1)
	check(ball.juggling.count==count,"A ball at the wrong ground depth must miss even if its projected image overlaps the head")
	ball.juggling.height = 3
	ball.juggling.vertical_speed = -100
	step(0.1)
	check(not jo.is_juggling() and ball.juggling.last_count==9 and ball.juggling.best>=9,"A ground impact must end the round and preserve its score")
	# Te now lifts the ball too; Jo's arrows remain ordinary real movement.
	reset()
	scene._select_person(0)
	scene.people[0].position = home-Vector2(50,0)
	scene.people[0].facing = Vector2.RIGHT
	space()
	step(0.35)
	check(scene.people[0].is_juggling() and ball.juggling.height>20,"Te must also lift the football with Space")
	reset()
	space()
	step(0.6)
	jo.football_action = ""
	ball.position = jo.position
	ball.juggling.height = 250
	ball.juggling.vertical_speed = 0
	ball.ball_velocity = Vector2.ZERO
	jo.set_physics_process(true)
	drive_ball = true
	var from: Vector2 = jo.position
	Input.action_press("walk_right")
	await frames(25)
	Input.action_release("walk_right")
	check(jo.position.x>from.x+30 and jo.is_juggling(),"Arrows must move Jo freely to recover the drifting football")
	check(ball.juggling.count==0,"Movement alone must never juggle automatically")
	scene._update_ground_rest(80)
	check(scene.ground_idle_time==0 and not jo.ground_rest,"The idle rest system must not interrupt football")
	scene.people[0]._update_sand_drawing(15,Vector2.ZERO)
	check(scene.people[0].sand_state==scene.people[0].SandState.NONE,"Te must not draw in the sand during Jo's round")
	jo.play_football("head",0,0.34,1)
	await frames(2)
	scene._toggle_pause()
	var held := Vector3(ball.position.x,ball.position.y,ball.juggling.height)
	var animation_time: float = jo.football_time
	await frames(10)
	check(Vector3(ball.position.x,ball.position.y,ball.juggling.height)==held and jo.football_time==animation_time,"Pause must freeze the football and the drawn action")
	scene._toggle_pause()
	scene._toggle_map()
	held = Vector3(ball.position.x,ball.position.y,ball.juggling.height)
	await frames(10)
	check(Vector3(ball.position.x,ball.position.y,ball.juggling.height)==held and jo.football_time==animation_time,"The map must also freeze the football and its animation")
	scene._toggle_map()
	scene._select_person(0)
	check(not ball.juggling.active(),"Changing character must release Jo's round without teleporting the ball")
	# A real uninterrupted flight: only arrows and Space, with no ball repositioning.
	reset()
	space()
	var wanted := ["foot","knee","head","foot","knee","head"]
	var used := {}
	for frame in 1000:
		if not jo.is_juggling() or ball.juggling.count>=wanted.size(): break
		var action: String = wanted[ball.juggling.count]
		var point := Art.contact(action,0)
		var goal: Vector2 = ball.position-Vector2(point.x,0)
		var offset := goal-jo.position
		for axis in ["walk_left","walk_right","walk_up","walk_down"]: Input.action_release(axis)
		if absf(offset.x)>4: Input.action_press("walk_right" if offset.x>0 else "walk_left")
		if absf(offset.y)>4: Input.action_press("walk_down" if offset.y>0 else "walk_up")
		if ball.juggling.vertical_speed<0 and absf(ball.juggling.height+point.y)<15 and ball.juggling.cooldown<=0 and ball.juggling.pending.is_empty():
			space()
		var before: int = ball.juggling.count
		await frames(1)
		if ball.juggling.count>before: used[ball.juggling.last_contact] = true
	for axis in ["walk_left","walk_right","walk_up","walk_down"]: Input.action_release(axis)
	check(ball.juggling.count==6 and used.size()==3,"Normal arrows and timed Space must sustain six natural arcs with all three body contacts")
	drive_ball = false
	scene.queue_free()
	await process_frame
	if not failed: print("PASS: real clearing interaction, both foot lifts, gravity, all nine Jo contacts, six natural arcs, timing misses, no repeat/spam, lateral flight, arrows, scores, idle priority and modal freeze")
	quit(1 if failed else 0)
