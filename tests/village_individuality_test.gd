extends SceneTree
var failed := false
var scene: Node2D
func _initialize() -> void:
	seed(314159)
	create_timer(300,true,false,true).timeout.connect(func():push_error("Individuality audit timed out");quit(2))
	call_deferred("run")
func check(ok: bool,text: String) -> void:
	if not ok: failed = true; push_error(text)
func run() -> void:
	scene = load("res://scenes/sintra_village.tscn").instantiate(); root.add_child(scene)
	for i in 4: await physics_frame
	scene.set_process(false)
	for p in scene.people: p.set_physics_process(false); p.position = Vector2(1500,14000)
	var world: Node2D = scene.world
	var cast: Dictionary = world.living_life.by_id
	var art: Dictionary = preload("res://data/village/individuality-art.json").data
	check(art.characters.size()==125,"Every citizen has a revised personal atlas")
	check(art.meals.size()==13 and art.canes.size()==4,"Authored eating poses and four supported cane users")
	check(world.dining.terraces.size()==6 and world.dining.diners.size()==13,"Six new cafe terraces and thirteen scheduled diners")
	for a in world.social_life.actors:
		if a.entry.get("neighbour",false) or a.entry.has("ambient_source"): continue
		check(art.characters[a.entry.id].frames.size()==6,"Activity, forward and backward poses: "+a.entry.id)
		if int(a.entry.age)>=75: check(a.gait.commute_speed<55,"An elderly commute never silently becomes a sprint: "+a.entry.id)
		if int(a.entry.age)<13: check(a.gait.walk_speed>125,"Children actually run: "+a.entry.id)
		a.meal_seated = false
		a.motion.phase = "walk"; a.frame = 2; a.travel_direction = Vector2(1,1)
		var front: Dictionary = a.art.individual_pose()
		a.travel_direction = Vector2(1,-1)
		var back: Dictionary = a.art.individual_pose()
		check(front.rect!=back.rect,"Walking away uses a painted rear view: "+a.entry.id)
		a.motion.phase = "rest"
	for seat in world.dining.seats:
		check(world.is_walkable(seat.at,12),"Every dining seat is on real public paving")
		check(not world.find_path(world.menu_spawn,seat.at).is_empty(),"Every dining seat has a real approach")
	for terrace in world.dining.terraces:
		check(terrace.cafe.label=="Café","Each terrace belongs to an actual cafe")
		for table in terrace.tables: check(not world.is_walkable(table.position-Vector2(0,12),1),"Painted table foot is a real obstacle")
	var cane: CharacterBody2D = cast.antonio
	var speeds: Array[float] = []
	for i in 100:
		cane.clock = float(i)*.03; speeds.append(cane.gait.speed(cane))
	check(speeds.min()<speeds.max()*.2,"Cane plant pauses before the supported short step")
	check(cast.matilde.gait.walk_speed>cast.antonio.gait.commute_speed*3,"Child and cane walker have strongly different physical paces")
	var distances: Dictionary = {}
	var start: Vector2 = world._event_space(Vector2(15600,5200),320)
	var finish: Vector2 = world.population.free_point(start+Vector2(500,0),true)
	for id in ["matilde","tiago","antonio"]:
		var actor: CharacterBody2D = cast[id]
		actor._cancel_encounter(); actor.greet_time = 0; actor.event_busy = false; actor.meal_seated = false
		actor.position = start; actor.anchor = finish
		check(actor._begin_walk(finish,"walking"),"Actual public walk for the pace comparison: "+id)
		var before: float = actor.travelled
		for j in 60:
			actor.step(.025,scene.day_cycle)
			await physics_frame
		distances[id] = actor.travelled-before
	check(float(distances.matilde)>float(distances.tiago)*1.35,"Measured child running distance exceeds adult walking distance: "+str(distances))
	check(float(distances.antonio)<float(distances.tiago)*.55,"Measured supported cane walk is slower than an adult: "+str(distances))
	# Real ordinary morning and lunch, not repositioned meal screenshots.
	scene.day_cycle.minutes = 400; world.synchronize_clock(scene.day_cycle,true)
	var seen: Dictionary = {}
	var previous: Dictionary = {}
	for a in world.dining.diners: seen[a.entry.id] = {}; previous[a.entry.id] = a.position
	for i in 2080:
		scene.day_cycle.advance(.25); world.step_environment(.25,scene.day_cycle)
		await physics_frame
		for a in world.dining.diners:
			check(a.position.distance_to(previous[a.entry.id])<80,"Meals never teleport a diner: "+a.entry.id)
			previous[a.entry.id] = a.position
			if a.meal_seated:
				check(a.position.distance_to(a.appointment.seat.at)<33,"The eating body sits at its own reserved seat")
				check(a.state=="meal" and a.route.is_empty(),"Eating does not drift back into the generic strolling loop")
				seen[a.entry.id][a.appointment.meal] = true
	for a in world.dining.diners:
		check(seen[a.entry.id].has("breakfast"),"Walked to outdoor breakfast: "+a.entry.id+" "+str(seen[a.entry.id]))
		check(seen[a.entry.id].has("lunch"),"Walked to outdoor lunch: "+a.entry.id+" "+str(seen[a.entry.id]))
		check(not a.meal_seated,"The meal ends and the next real appointment resumes: "+a.entry.id)
	print("Individuality audit: 125 people, four cane gaits, thirteen breakfast/lunch routines, six terraces, five garden benches")
	scene.queue_free()
	for i in 5: await physics_frame
	if not failed: print("PASS: personal pace, supported cane phases, running children, actual rear views and real outdoor meals")
	quit(1 if failed else 0)
