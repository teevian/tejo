extends SceneTree
## Projection changes topology; persistent X/Y/Z and the belay remain physical.
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

func place(index: int, shelf: int, x: float, z := 0.0) -> void:
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

func finish_turn() -> void:
	for i in 100:
		await physics_frame
		if not scene.space.rotating: break
	check(not scene.space.rotating,"Every quarter turn must finish")

func capture(label: String) -> void:
	scene.perspective.update_view()
	var world: Vector3 = scene.space.actors[0]
	var rendered: Vector2 = scene.perspective.camera_3d.unproject_position(Vector3(world.x,-world.y,world.z))
	var projected: Vector2 = (scene.space.project(world)-scene.camera.position)*scene.camera.zoom+Vector2(640,360)
	check(rendered.distance_to(projected)<0.1,"The 3D camera must agree with the playable 2D projection at every angle")
	if not preview: return
	scene.camera.position = scene.camera_target()
	scene.perspective.update_view()
	scene.hud.note_time = 0
	await process_frame
	await process_frame
	RenderingServer.force_draw()
	root.get_texture().get_image().save_png("res://output/climbing-"+label+".png")

func climb(target: int) -> void:
	var edge: Dictionary = scene.edge_for(scene.people[scene.selected])
	if not edge.is_empty(): press(KEY_RIGHT if edge.dir>0 else KEY_LEFT)
	press(KEY_UP)
	await frames(35)
	check(scene.people[scene.selected].grounded and scene.people[scene.selected].shelf==target,"The scout must use the projected passage to shelf "+str(target))

func run() -> void:
	var errors := ErrorLog.new()
	OS.add_logger(errors)
	scene = load("res://scenes/rock_climbing.tscn").instantiate()
	root.add_child(scene)
	await frames(4)
	place(0,26,900,-180)
	place(1,10,600,-180)
	scene.checkpoint = 10
	scene.space.move_boulder(scene.boulders[0],35)
	scene.flags["orientation_sentinel"] = true
	var a: Vector3 = scene.space.actors[0]
	var b: Vector3 = scene.space.actors[1]
	var stone: Vector3 = scene.boulders[0].world
	var rope: float = scene.rope_separation()
	var edge: Dictionary = scene.edge_for(scene.people[0])
	check(not scene.near_edge(scene.people[0],edge),"The scout's separated ledge must be impossible to mantle from the front")
	await capture("perspective-front")
	press(KEY_E)
	await frames(14)
	check(scene.space.rotating and scene.space.angle>0.15 and scene.space.angle<PI/2,"The camera must orbit smoothly through intermediate 3D angles")
	check(scene.space.actors[0].is_equal_approx(a) and scene.space.actors[1].is_equal_approx(b),"An orbit must not change either world position")
	press(KEY_UP)
	press(KEY_TAB)
	press(KEY_T)
	check(scene.people[0].jump_buffer==0 and scene.selected==0 and scene.dialogue_lines.is_empty(),"Movement, swaps and conversations must not interrupt a turn")
	press(KEY_ESCAPE)
	var angle: float = scene.space.angle
	await frames(15)
	check(paused and scene.space.angle==angle,"Pause must freeze an orbit halfway through")
	press(KEY_ESCAPE)
	await capture("perspective-orbit")
	await finish_turn()
	check(scene.space.view==1 and scene.near_edge(scene.people[0],scene.edge_for(scene.people[0])),"A quarter turn must align the first separated ledges")
	check(absf(scene.rope_separation()-rope)<0.01,"Turning cannot change the physical rope distance")
	await capture("perspective-side")
	for i in 3:
		press(KEY_E)
		await finish_turn()
		if i==0: await capture("perspective-back")
		if i==1: await capture("perspective-left")
	check(scene.space.view==0 and scene.space.actors[0].is_equal_approx(a) and scene.space.actors[1].is_equal_approx(b),"Four turns must restore the exact initial view and preserve depth")
	check(scene.boulders[0].world.is_equal_approx(stone),"Turning must never reset a pushed stone")
	check(scene.flags.get("orientation_sentinel",false),"Turning must preserve solved puzzle state")
	press(KEY_T)
	press(KEY_E)
	check(not scene.space.rotating,"Dialogue must suspend rotation")
	press(KEY_ESCAPE)
	press(KEY_E)
	await finish_turn()
	press(KEY_UP)
	check(not scene.rotate_world(1),"Rotation must wait for a pending mantle or jump")
	await frames(2)
	check(not scene.rotate_world(1),"Rotation must wait for an actual mantle to finish")
	await frames(35)
	check(scene.people[0].shelf==11 and scene.people[1].shelf==10,"The hidden-depth passage must carry only the scout")
	var timer: float = scene.platforms[11].timer
	press(KEY_Q)
	await frames(18)
	check(scene.platforms[11].timer==timer,"Fragile ledges must freeze during the orbit")
	await finish_turn()
	check(not scene.near_edge(scene.people[0],scene.edge_for(scene.people[0])),"Returning to the front must separate the route again")
	press(KEY_E)
	await finish_turn()
	# Move to the next lip in the widened side view before mantling.
	var person = scene.people[0]
	person.position.x = scene.edge_x(person,int(scene.edge_for(person).dir))
	scene.space.sync_people()
	await climb(27)
	person.position.x = scene.edge_x(person,int(scene.edge_for(person).dir))
	scene.space.sync_people()
	await climb(28)
	press(KEY_Q)
	await finish_turn()
	check(scene.space.view==0 and scene.people[0].shelf==28 and scene.people[1].shelf==10,"The scout and waiting partner must keep their separate physical supports after turning back")
	# An airborne turn freezes the jump, then resumes its momentum.
	scene.restart()
	press(KEY_UP)
	await frames(8)
	var velocity: Vector2 = scene.people[0].velocity
	check(scene.rotate_world(1),"Airborne turns must remain responsive")
	var airborne: Vector3 = scene.space.actors[0]
	await frames(15)
	check(scene.space.actors[0].is_equal_approx(airborne) and scene.people[0].velocity==velocity,"The orbit must conserve airborne position and velocity")
	await finish_turn()
	await frames(50)
	check(scene.people[0].grounded and scene.people[0].shelf==0,"The jump must resume and land normally after turning")
	# Nearly coincident screen positions still consume the full rope in depth.
	scene.restart()
	place(1,1,800,100)
	# Keep 4 units of slack despite the irregular terrain's varying elevation.
	var lower := 250.0
	var upper := 320.0
	for i in 28:
		var x := (lower+upper)*0.5
		place(0,0,x,100)
		if scene.rope_separation()>556: lower = x
		else: upper = x
	place(0,0,(lower+upper)*0.5,100)
	press(KEY_E)
	await finish_turn()
	check(absf(scene.people[0].position.x-scene.people[1].position.x)<0.01 and scene.rope_separation()>550,"Hidden depth must remain part of the rope length")
	check(not scene.rope_allows(scene.people[1],scene.people[1].position+Vector2(80,0)),"A side view cannot bypass the finite 3D rope")
	scene.restart()
	check(scene.space.view==0 and scene.space.turns==0 and not scene.space.rotating,"Restart must reset orientation and every pending turn")
	OS.remove_logger(errors)
	check(errors.errors.is_empty(),"Perspective runtime errors: "+str(errors.errors))
	scene.queue_free()
	await frames(2)
	if not failed: print("PASS: four persistent 3D views, smooth reversible orbit, lateral scout passage, paused hazards, action guards and true 3D rope")
	quit(1 if failed else 0)
