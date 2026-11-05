extends SceneTree
var scene: Node2D
var failed := false
func _initialize() -> void:
	seed(240601)
	create_timer(300,true,false,true).timeout.connect(func():push_error("Community day timed out");quit(2))
	call_deferred("run")
func check(ok: bool,text: String) -> void:
	if not ok: failed = true; push_error(text)
func run() -> void:
	scene = load("res://scenes/sintra_village.tscn").instantiate(); root.add_child(scene)
	for i in 4: await physics_frame
	scene.set_process(false)
	for p in scene.people: p.set_physics_process(false); p.position = Vector2(1500,14000)
	var world: Node2D = scene.world
	var life: Node2D = world.living_life
	scene.day_cycle.minutes = 480; world.synchronize_clock(scene.day_cycle,true)
	var previous: Dictionary = {}
	var visits: Dictionary = {}
	for a in world.social_life.actors: previous[a.entry.id] = a.position
	for a in life.residents: visits[a.entry.id] = {}
	var sleeping: Dictionary = {}
	var covered: Dictionary = {}
	var cost := 0
	var max_cost := 0
	var moving := 0
	for i in 4800:
		scene.day_cycle.advance(.25)
		var start := Time.get_ticks_usec()
		world.step_environment(.25,scene.day_cycle)
		var took := Time.get_ticks_usec()-start
		cost += took
		max_cost = maxi(max_cost,took)
		await physics_frame
		for a in world.social_life.actors:
			var distance: float = a.position.distance_to(previous[a.entry.id])
			check(distance<100,"No ordinary teleport: "+a.entry.id+" "+str(distance)+" at "+str(scene.day_cycle.minutes))
			previous[a.entry.id] = a.position
			if a.available(): check(world.is_walkable(a.position,7),"Resident stays on paving: "+a.entry.id)
		for a in life.residents:
			if a.state in ["activity","inside","window"]: visits[a.entry.id][a.appointment.place] = true
			if a.state=="inside" and scene.day_cycle.day==2: sleeping[a.entry.id] = true
			if a.travelled>300: moving += 1
		if i%120==0 and scene.day_cycle.minutes<1200:
			for plaza in world.plazas:
				if world.social_life.actors.any(func(a):return a.visible and a.position.distance_to(plaza.rect.get_center())<1000): covered[plaza.id] = true
	check(sleeping.size()==30,"All thirty new people reach an interior at night: "+str(sleeping.size()))
	for a in life.residents:
		if not sleeping.has(a.entry.id): print("Awake ",a.entry.id," state=",a.state," position=",a.position," anchor=",a.anchor," route=",a.route.size())
		if a.entry.role!="cameo": check(visits[a.entry.id].size()>=3,"Work/leisure, meals and sleep reached: "+a.entry.id+" "+str(visits[a.entry.id]))
	check(life.events.history.size()>=4,"Several coherent episodes complete autonomously: "+str(life.events.history))
	check(covered.size()>=12,"Activity covers peripheral plazas: "+str(covered.size()))
	check(life.rivalry>0,"The rival tuk-tuk guides meet and argue without player initiation")
	print("Day audit: population ",world.social_life.actors.size(),"; squares ",covered.size(),"; new sleepers ",sleeping.size(),"; completed episodes ",life.events.history.size(),"; rivalries ",life.rivalry,"; mean simulation ms ",float(cost)/4800/1000,"; max ",float(max_cost)/1000)
	scene.queue_free()
	for i in 5: await physics_frame
	if not failed: print("PASS: complete community day, autonomous episodes, 125 continuous lives, sleeping, distribution and rival guides")
	quit(1 if failed else 0)
