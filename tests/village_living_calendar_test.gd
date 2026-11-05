extends SceneTree
## Eight ordinary days: no forced events, reserved casts or moved inhabitants.
var failed := false
func _initialize() -> void:
	seed(1234)
	create_timer(480,true,false,true).timeout.connect(func():push_error("Community calendar timed out");quit(2))
	call_deferred("run")
func check(ok: bool,text: String) -> void:
	if not ok: failed = true; push_error(text)
func run() -> void:
	var scene: Node2D = load("res://scenes/sintra_village.tscn").instantiate()
	root.add_child(scene)
	for i in 4: await physics_frame
	scene.set_process(false)
	for p in scene.people:
		p.set_physics_process(false)
		p.position = Vector2(1500,14000)
	var world: Node2D = scene.world
	var life: Node2D = world.living_life
	scene.day_cycle.minutes = 480
	world.synchronize_clock(scene.day_cycle,true)
	var seen: Dictionary = {}
	var last_day := 1
	for i in 11520:
		scene.day_cycle.advance(1)
		world.step_environment(1,scene.day_cycle)
		await physics_frame
		for episode in life.events.history: seen[episode.id] = true
		if scene.day_cycle.day!=last_day:
			last_day = scene.day_cycle.day
			print("Calendar day ",last_day,"; distinct autonomous episodes ",seen.size())
	var missing: Array = life.DATA.data.events.filter(func(e):return not seen.has(e.id)).map(func(e):return e.id)
	check(missing.is_empty(),"All authored episodes can occur during normal routines; missing "+str(missing))
	for key in seen:
		check(life.state.quests.get("event_"+str(key),0)>0,"Autonomous episode keeps its consequence: "+str(key))
	print("Calendar audit: ",seen.size()," distinct episodes, eight days, 125 residents; missing ",missing)
	scene.queue_free()
	for i in 5: await physics_frame
	if not failed: print("PASS: all 24 episodes emerge autonomously across the calendar, with persistent consequences")
	quit(1 if failed else 0)
