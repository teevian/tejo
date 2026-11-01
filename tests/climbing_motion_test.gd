extends SceneTree
var scene: Node2D
var failed := false
var preview := false
var max_rope := 0.0

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

func frames(count: int) -> void:
	for i in count:
		await physics_frame
		if scene.people.size()==2:
			max_rope = maxf(max_rope,scene.rope_separation())

func press(key: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = key
	event.pressed = true
	root.push_input(event)
	event = event.duplicate()
	event.pressed = false
	root.push_input(event)

func place(index: int, shelf: int, x: float, anchor := "") -> void:
	var person = scene.people[index]
	person.traversal.clear()
	person.grounded = true
	person.shelf = shelf
	person.position = Vector2(x,scene.surface_y(scene.platforms[shelf],x,person))
	scene.space.sync_people()
	person.velocity = Vector2.ZERO
	person.ground_slope = float(scene.platforms[shelf].get("slope",0))
	person.anchor = anchor
	person.jump_buffer = 0
	person.hanging = false

func capture(label: String) -> void:
	if not preview: return
	scene.camera.position = scene.camera_target()
	scene.wall.update_view()
	await process_frame
	await process_frame
	RenderingServer.force_draw()
	root.get_texture().get_image().save_png("res://output/climbing-"+label+".png")

func run() -> void:
	var errors := ErrorLog.new()
	OS.add_logger(errors)
	scene = load("res://scenes/rock_climbing.tscn").instantiate()
	root.add_child(scene)
	await frames(4)
	await capture("rock-wall")
	check(scene.summit_reveal==0,"The valley must stay hidden before the summit")
	# Air control no longer locks the companion, and a late press is buffered.
	press(KEY_UP)
	check(scene.any_busy(),"Buffered input must be considered pending movement before the next physics frame")
	press(KEY_T)
	check(scene.dialogue_lines.is_empty(),"A conversation must not hide an unconsumed jump and trigger it later")
	await frames(10)
	check(not scene.people[0].grounded,"Cima must launch a jump immediately")
	press(KEY_TAB)
	check(scene.selected==1,"Character switching must remain responsive during the other's jump")
	Input.action_press("walk_right")
	var friend_x: float = scene.people[1].position.x
	await frames(8)
	Input.action_release("walk_right")
	check(scene.people[1].position.x>friend_x+10,"One airborne person must not freeze the other")
	scene.restart()
	press(KEY_UP)
	for i in 50:
		await frames(1)
		if scene.people[0].velocity.y>0 and scene.people[0].position.y>scene.Route.START_Y-28: break
	press(KEY_UP)
	await frames(10)
	check(not scene.people[0].grounded and scene.people[0].velocity.y<0,"A press just before landing must become the next jump")
	# Slope collision follows the painted angle; steep inclines also slide downhill.
	scene.restart()
	place(0,8,350)
	place(1,8,250,"test")
	var initial: Vector2 = scene.people[0].position
	await frames(36)
	var person = scene.people[0]
	check(person.position.x<initial.x-8,"A steep rock must exert downhill slip")
	check(absf(person.position.y-scene.surface_y(scene.platforms[8],person.position.x,person))<0.1,"Feet must follow the actual incline at their persistent depth")
	Input.action_press("walk_right")
	await frames(36)
	Input.action_release("walk_right")
	check(person.position.x>initial.x+60 and person.position.y<initial.y-5,"Walking across an uneven incline must gain elevation overall")
	await capture("inclined-rock")
	# Real countdowns pause with the game and conversations, then remove support.
	scene.restart()
	place(0,5,920)
	place(1,4,500,"test")
	await frames(10)
	var timer: float = scene.platforms[5].timer
	press(KEY_T)
	await frames(60)
	check(scene.platforms[5].timer==timer,"Reading a conversation must not consume a fragile ledge's countdown")
	press(KEY_ESCAPE)
	press(KEY_ESCAPE)
	await frames(60)
	check(paused and scene.platforms[5].timer==timer,"Pause must freeze crumbling rocks")
	press(KEY_ESCAPE)
	for i in 160:
		await frames(1)
		if not scene.platforms[5].enabled: break
	check(not scene.platforms[5].enabled and not scene.people[0].grounded,"A timed rock must lose collision and drop its occupant")
	var falling_y: float = scene.people[0].position.y
	await frames(14)
	check(scene.people[0].position.y>falling_y+10 and scene.platforms[5].fall>0,"Both player and rock must visibly fall")
	await capture("crumbling-rock")
	await frames(340)
	check(scene.platforms[5].enabled and scene.platforms[5].timer<0,"A failed timed crossing must become retryable")
	# A belayer on solid granite arrests a fall, without an ever-growing rope.
	scene.restart()
	place(0,1,1000)
	place(1,1,600,"test")
	Input.action_press("walk_right")
	await frames(43)
	Input.action_release("walk_right")
	await frames(110)
	person = scene.people[0]
	check(not person.grounded and person.hanging,"The finite rope must catch a climber who falls past an edge")
	check(person.position.distance_to(scene.people[1].position)<=scene.Route.ROPE_LENGTH+0.1,"A caught fall must remain within the rope length")
	var feet_y: float = (person.position.y-scene.camera.position.y)*scene.camera.zoom.y+360
	check(feet_y<705,"The camera must keep the hanging climber visible, including below the starting ledge")
	var points: PackedVector2Array = scene.rope_points()
	var drawn := 0.0
	for i in points.size()-1: drawn += points[i].distance_to(points[i+1])
	check(drawn<=scene.Route.ROPE_LENGTH+0.1,"The visible rope must obey the same maximum length")
	await capture("rope-catch")
	press(KEY_UP)
	await frames(70)
	check(person.grounded and person.shelf==1,"Cima must recover a climber hanging on the rope")
	scene.restart()
	place(0,2,300)
	place(1,2,400,"test")
	press(KEY_DOWN)
	await frames(50)
	check(scene.people[0].grounded and scene.people[0].shelf==0,"Baixo must descend from a ledge even away from an authored climb link")
	# If neither climber has an anchor, a shared fall returns to a safe belay.
	scene.restart()
	scene.checkpoint = 1
	place(0,1,1130)
	place(1,1,1200)
	await frames(75)
	check(scene.recoveries==1 and scene.people[0].shelf==1 and scene.people[1].shelf==1,"A shared fall must recover both at the last safe support")
	# Walking pushes a block and carries a companion standing on it.
	scene.restart()
	var stone: Dictionary = scene.boulders[0]
	place(0,2,280)
	place(1,20,355,"test")
	var block_x: float = stone.x
	var rider_x: float = scene.people[1].position.x
	Input.action_press("walk_right")
	await frames(45)
	Input.action_release("walk_right")
	check(stone.x>block_x+35,"Walking into a loose stone must push it")
	check(absf((scene.people[1].position.x-rider_x)-(float(stone.x)-block_x))<0.2,"A pushed stone must carry the person standing on it")
	await capture("pushing-together")
	check(max_rope<=scene.Route.ROPE_LENGTH+0.5,"No tested frame may stretch the rope indefinitely; maximum "+str(max_rope))
	scene.restart()
	check(scene.platforms[5].enabled and scene.platforms[5].timer<0 and scene.boulders[0].x==scene.boulders[0].start_x,"Restart must reset hazards and movable stones")
	OS.remove_logger(errors)
	check(errors.errors.is_empty(),"Motion runtime errors: "+str(errors.errors))
	scene.queue_free()
	await process_frame
	if not failed: print("PASS: jump/air control, independent movement, buffered input, real slopes, timed collapse, fall arrest, finite drawn rope, recovery and pushable support")
	quit(1 if failed else 0)
