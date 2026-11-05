extends SceneTree
var scene: Node2D
var failed := false
func _initialize() -> void:
	var audit_seed := 20261104
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--seed="): audit_seed = int(argument.trim_prefix("--seed="))
	seed(audit_seed)
	create_timer(300,true,false,true).timeout.connect(func(): push_error("Full additional day timed out"); quit(2))
	call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok: failed = true; push_error(message)
func run() -> void:
	scene = load("res://scenes/sintra_village.tscn").instantiate()
	root.add_child(scene)
	for i in 3: await physics_frame
	scene.set_process(false)
	for person in scene.people: person.set_physics_process(false); person.position = Vector2(1500,14000)
	var world: Node2D = scene.world
	var life: Node2D = world.festival_life
	scene.day_cycle.minutes = 480
	world.synchronize_clock(scene.day_cycle,true)
	var previous: Dictionary = {}
	var visits: Dictionary = {}
	var cinema_arrivals: Dictionary = {}
	var sleep: Dictionary = {}
	for actor in life.residents: previous[actor.entry.id] = actor.position; visits[actor.entry.id] = {}
	var max_dog_gap := 0.0
	for i in 4800:
		scene.day_cycle.advance(.25)
		world.step_environment(.25,scene.day_cycle)
		await physics_frame
		for actor in life.residents:
			if actor.position.distance_to(previous[actor.entry.id])>=100: print("JUMP ",actor.entry.id," minute=",scene.day_cycle.minutes," from=",previous[actor.entry.id]," to=",actor.position," state=",actor.state)
			check(actor.position.distance_to(previous[actor.entry.id])<100,"Normal daily boundaries never teleport additional people: "+actor.entry.id)
			previous[actor.entry.id] = actor.position
			if actor.state in ["activity","inside","riding"]: visits[actor.entry.id][actor.appointment.place] = true
			if actor.entry.role=="cinema" and actor.appointment.place=="cinema" and actor.state=="activity" and scene.day_cycle.minutes>=1170 and scene.day_cycle.minutes<1200: cinema_arrivals[actor.entry.id] = true
			if actor.state=="inside" and scene.day_cycle.day==2: sleep[actor.entry.id] = true
			if actor.available(): check(world.is_walkable(actor.position,8),"Daily extra resident stays on public floor: "+actor.entry.id)
		var dog: CharacterBody2D = life.dogs[0]
		if dog.visible: max_dog_gap = maxf(max_dog_gap,dog.position.distance_to(dog.walker.position))
	for actor in life.residents:
		check(visits[actor.entry.id].size()>=3,"Additional resident reaches work/leisure/meals over a real day: "+actor.entry.id+" "+str(visits[actor.entry.id]))
	check(cinema_arrivals.size()==10,"All ten filmgoers arrive by walking in time for the first session")
	check(sleep.size()==50,"All fifty additional people reach an interior overnight")
	for actor in life.residents:
		if not sleep.has(actor.entry.id): print("Awake: ",actor.entry.id," state=",actor.state," at=",actor.position," anchor=",actor.anchor," route=",actor.route.size()," distance=",actor.position.distance_to(actor.anchor)," busy=",actor.event_busy)
	check(max_dog_gap<400,"Walker waits instead of leaving her dog behind: "+str(max_dog_gap))
	check(life.vehicles.all(func(v): return v.distance_travelled>1000),"Every tourist vehicle completes real journeys over a day")
	check(life.exploratory_walks>=5,"Curious visitors independently walk towards quieter streets")
	print("Full day: cinema arrivals ",cinema_arrivals.size(),"; sleepers ",sleep.size(),"; longest leash gap ",max_dog_gap,"; vehicle distances ",life.vehicles.map(func(v):return roundi(v.distance_travelled)))
	for vehicle in life.vehicles: print(vehicle.kind," at ",vehicle.position," path=",vehicle.path.size()," wait=",vehicle.wait," yielded=",vehicle.yielded)
	scene.queue_free()
	for i in 4: await physics_frame
	if not failed: print("PASS: complete real day of fifty lives, staggered work/meals/sleep, timely cinema, dog tether and all tourist vehicles")
	quit(1 if failed else 0)
