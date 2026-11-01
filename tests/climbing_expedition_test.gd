extends SceneTree
## Spatial puzzle regressions: wide side faces, continuous tunnels, scout belay
## and a stone pushed in depth. The complete route is also keyboard-tested.
var scene: Node2D
var failed := false
var preview := false
var maximum_rope := 0.0

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
		quit(1)

func frames(count: int) -> void:
	for i in count:
		await physics_frame
		maximum_rope = maxf(maximum_rope,scene.rope_separation())

func press(key: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = key
	event.pressed = true
	root.push_input(event)
	event = event.duplicate()
	event.pressed = false
	root.push_input(event)

func place(index: int, shelf: int, x: float, z: float) -> void:
	var person = scene.people[index]
	person.traversal.clear()
	person.grounded = true
	person.shelf = shelf
	person.anchor = ""
	person.velocity = Vector2.ZERO
	person.jump_buffer = 0
	person.hanging = false
	var box: Dictionary = scene.space.boxes[shelf]
	scene.space.set_world(person,Vector3(x,scene.space.surface_world(box,x,z),z))

func turn(direction: int) -> void:
	check(scene.rotate_world(direction),"Idle players must be able to discover the next face")
	await frames(42)
	check(not scene.space.rotating,"Quarter turns must finish smoothly")

func capture(label: String) -> void:
	if not preview: return
	scene.camera.position = scene.camera_target()
	scene.perspective.update_view()
	scene.hud.note_time = 0
	await process_frame
	await process_frame
	RenderingServer.force_draw()
	root.get_texture().get_image().save_png("res://output/climbing-expedition-"+label+".png")

func run() -> void:
	var errors := ErrorLog.new()
	OS.add_logger(errors)
	scene = load("res://scenes/rock_climbing.tscn").instantiate()
	root.add_child(scene)
	await frames(6)
	check(scene.platforms.size()==39,"The mountain must have 39 physical ledges and loose stones")
	for face in 4:
		for id in [0,1,4,5,6,7,10,12,13,14,15,16,17,22,23,24,26,27,28,29,30,31,34,35,36,37,38]:
			var box: Dictionary = scene.space.boxes[id]
			var low := INF
			var high := -INF
			for point in scene.space.corners(box):
				var x: float = scene.space.project(point,face*PI*0.5).x
				low = minf(low,x); high = maxf(high,x)
			check(high-low>=279,"Every face needs broad traversable shelves instead of a thin vertical column: %d/%d"%[id,face])
	check(not scene.platform_visible(34),"The opposite-flank garden must be concealed from the first view")
	var initial: Vector3 = scene.space.world_point(scene.people[0])
	await capture("front")
	await turn(1)
	check(scene.platform_visible(34) and not scene.platform_visible(36),"Turning must reveal a new horizontal garden on the corresponding flank")
	check(scene.space.world_point(scene.people[0]).is_equal_approx(initial),"Exploration turns cannot teleport actors")
	await capture("side")
	await turn(1)
	check(scene.platform_visible(34) and scene.platform_visible(36),"The rear view must uncover both flanking terraces")
	await capture("rear")
	await turn(1)
	await capture("other-side")
	await turn(1)
	# The dolmen is a continuous sheltered crossing, not a shelf teleport.
	place(0,23,990,120)
	place(1,22,900,120)
	press(KEY_UP)
	await frames(2)
	check(not scene.people[0].traversing(),"A long tunnel must wait for both partners to keep the rope inside")
	place(1,23,930,120)
	press(KEY_UP)
	await frames(60)
	check(scene.people.all(func(person): return person.traversing() and person.pose=="tunnel"),"Both actors must walk through the rock passage")
	check(scene.space.world_point(scene.people[0]).distance_to(Vector3(990,3420,120))>70,"Tunnel travel must move through real depth")
	check(not scene.rotate_world(1),"A capstone crossing must finish before another camera turn")
	await capture("dolmen-inside")
	press(KEY_ESCAPE)
	var stopped: Vector3 = scene.space.world_point(scene.people[0])
	await frames(20)
	check(scene.space.world_point(scene.people[0]).is_equal_approx(stopped),"Pause must freeze world-space passage travel")
	press(KEY_ESCAPE)
	await frames(155)
	check(scene.people.all(func(person): return person.grounded and person.shelf==24),"Both must emerge on the far terrace")
	check(scene.checkpoint==24,"A tunnel exit must be a recoverable checkpoint even with a non-sequential shelf id")
	await capture("dolmen-exit")
	press(KEY_DOWN)
	await frames(190)
	check(scene.people.all(func(person): return person.grounded and person.shelf==23),"Down at the exit must retrace the continuous tunnel in reverse")
	# The scout cannot continue alone; the second climber uses the held rope.
	scene.restart()
	place(0,28,650,100)
	place(1,10,590,100)
	scene.checkpoint = 10
	await turn(1)
	check(scene.near_edge(scene.people[0],scene.edge_for(scene.people[0])),"The reunion gate must be tested at an otherwise reachable lip")
	check(not scene.attempt_climb(),"The scout must bring the partner up before leaving the lookout")
	press(KEY_SPACE)
	check(scene.people[0].anchor=="belay","The upper person must keep a deliberate stationary belay")
	press(KEY_TAB)
	press(KEY_UP)
	await frames(50)
	check(scene.people[1].traversing() and scene.people[1].pose=="rope" and scene.people[0].anchor=="belay","Only the lower climber moves while using the rope")
	await capture("rope-ascent")
	await frames(95)
	check(scene.people.all(func(person): return person.shelf==28 and person.grounded),"The rope must get the waiting partner onto actual granite")
	check(scene.flags.get("scout_reunited",false) and scene.checkpoint==28,"Reunion unlocks the onward route and updates the checkpoint by height")
	# Releasing an active belay cannot leave an unsupported scripted ascent.
	scene.restart()
	place(0,28,650,100)
	place(1,10,590,100)
	scene.checkpoint = 10
	press(KEY_SPACE)
	press(KEY_TAB)
	press(KEY_UP)
	await frames(35)
	press(KEY_TAB)
	press(KEY_SPACE)
	check(not scene.people[1].traversing() and not scene.people[1].grounded and scene.people[1].hanging,"Releasing the belay must interrupt the ascent and leave a physical rope catch")
	# The bridge key moves along Z only when seen from the side.
	scene.restart()
	place(0,31,450,-620)
	place(1,31,510,-620)
	await turn(1)
	var stone: Dictionary = scene.boulders[2]
	await capture("unbraced-slab")
	check(scene.perspective.meshes[29].visible and not scene.platforms[29].enabled,"The loose slab must already be visible before its support stone is pushed into place")
	var before: Vector3 = stone.world
	Input.action_press("walk_right")
	for i in 240:
		await frames(1)
		if scene.flags.get("bridge_braced",false): break
	Input.action_release("walk_right")
	check(scene.flags.get("bridge_braced",false) and scene.platforms[29].enabled,"Walking into the depth stone must brace the unsafe stone bridge")
	check(absf(stone.world.x-before.x)<0.1 and stone.world.z>before.z+150,"The key stone must genuinely move in Z, not reset on a turn")
	await frames(48)
	check(absf(scene.perspective.meshes[29].rotation.x)<0.02,"The existing tilted slab must visibly settle onto its new stone support")
	await capture("bridge-key")
	var braced: Vector3 = stone.world
	await turn(1)
	check(stone.world.is_equal_approx(braced) and scene.platforms[29].enabled,"Both the stone and its braced bridge must survive rotation")
	check(maximum_rope<=scene.Route.ROPE_LENGTH+0.5,"No new tunnel or belay may stretch the finite rope")
	scene.restart()
	check(not scene.platforms[29].enabled and not scene.flags.get("bridge_braced",false),"Restart must reset the spatial bridge puzzle")
	OS.remove_logger(errors)
	check(errors.errors.is_empty(),"Expedition runtime errors: "+str(errors.errors))
	scene.queue_free()
	await process_frame
	if not failed: print("PASS: wide shelves in all four views, hidden flank gardens, continuous paired tunnels, passage pause, scout/rope reunion, real Z-axis key stone and persistent bridge")
	quit(1 if failed else 0)
