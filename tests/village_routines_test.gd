extends SceneTree
## A complete accelerated day still uses real streets and the production state machine.
var scene: Node2D
var failed := false
var issues: Dictionary = {}
func _initialize() -> void:
	create_timer(160).timeout.connect(func(): push_error("Daily routines test timed out"); quit(2))
	call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok and not issues.has(message):
		issues[message] = true
		failed = true
		push_error(message)
func frames(count: int) -> void:
	for i in count: await physics_frame
func run() -> void:
	scene = load("res://scenes/sintra_village.tscn").instantiate()
	root.add_child(scene)
	await frames(3)
	scene.set_process(false)
	for player in scene.people:
		player.process_mode = Node.PROCESS_MODE_DISABLED
		player.position = Vector2(100,100)
	var world: Node2D = scene.world
	var population: Node2D = world.population
	if population.residents.size()!=35 or population.by_id.is_empty():
		check(false,"Population initializes before simulating routines")
		quit(1)
		return
	var visits: Dictionary = {}
	for actor in population.residents:
		visits[actor.entry.id] = {}
		check(actor.schedule.size()>=8,"Each person has a complete individual day: "+actor.entry.id)
		check(actor.schedule[0].at=="00:00","Schedule covers midnight: "+actor.entry.id)
		var last := -1.0
		for i in actor.schedule.size():
			var block: Dictionary = actor.schedule[i]
			check(block.minute>last,"Strictly ordered hours: "+actor.entry.id)
			last = block.minute
			check(world.is_walkable(block.destination,14),"Safe appointment: "+actor.entry.id+" "+block.at)
			if block.mode=="inside": check(population.routines.doors.has(block.destination),"Meals and sleep use an actual building entrance: "+actor.entry.id+" "+block.at)
			var previous: Dictionary = actor.schedule[posmod(i-1,actor.schedule.size())]
			var path: PackedVector2Array = world.find_path(previous.destination,block.destination)
			check(not path.is_empty(),"Connected consecutive appointments: "+actor.entry.id+" "+block.at)
			var next: Dictionary = actor.schedule[(i+1)%actor.schedule.size()]
			var window: float = fposmod(float(next.minute)-float(block.minute),1440)
			var cost: float = population.routines.path_length(path)/float(actor.profile.commute_speed)
			if next.place!=block.place:
				check(cost+15<window,"Enough travel and activity time: "+actor.entry.id+" "+block.at+" travel="+str(roundi(cost))+" window="+str(window))
		if actor.entry.age<13:
			check(actor.profile.has("guardian"),"Children have an adult companion: "+actor.entry.id)
			var adult: CharacterBody2D = population.by_id[actor.profile.guardian]
			check(adult.profile.residence==actor.profile.residence,"Child and adult return to the same home: "+actor.entry.id)
			for i in actor.schedule.size():
				var block: Dictionary = actor.schedule[i]
				if block.place=="residence" and actor.schedule[posmod(i-1,actor.schedule.size())].place=="residence": continue
				check(adult.schedule.any(func(other): return other.at==block.at and other.place==block.place),"Child's departures match the adult: "+actor.entry.id+" "+block.at)
	scene.day_cycle.day = 1
	scene.day_cycle.minutes = 0
	scene.day_cycle.minutes_per_second = 1
	population.synchronize(scene.day_cycle,true)
	check(population.residents.all(func(actor): return not actor.available() and actor.state=="inside"),"At midnight people sleep inside, including the late musician")
	var walked_before := 0.0
	for actor in population.residents: walked_before += actor.travelled
	# 27 game hours at one game minute per simulated second; quarter-second motion.
	for tick in 6480:
		var before: Dictionary = {}
		for actor in population.residents: before[actor.entry.id] = actor.position
		scene.day_cycle.advance(.25)
		population.step(.25,scene.day_cycle)
		await physics_frame
		for actor in population.residents:
			check(actor.position.distance_to(before[actor.entry.id])<120,"Appointments never teleport active people: "+actor.entry.id)
			if actor.state in ["activity","inside","meal"]: visits[actor.entry.id][actor.routine_index] = true
			if tick%40==0:
				check(world.is_walkable(actor.position,12),"Routine journeys stay on public floor: "+actor.entry.id)
				check(actor.routine_index==population.routines.index_at(actor,scene.day_cycle.minutes),"Appointment follows shared clock: "+actor.entry.id)
				if not actor.visible: check(not actor.available(),"Indoor people cannot be greeted through walls: "+actor.entry.id)
				if actor.entry.age<13 and actor.state=="commuting":
					var adult: CharacterBody2D = population.by_id[actor.profile.guardian]
					check(not adult.visible or actor.position.distance_to(adult.position)<600,"Child stays with the accompanying adult on journeys: "+actor.entry.id)
	for actor in population.residents:
		for i in actor.schedule.size():
			var block: Dictionary = actor.schedule[i]
			# A late walk home can continue across midnight into the same sleep block.
			if i==actor.schedule.size()-1 and block.place==actor.schedule[0].place and visits[actor.entry.id].has(0): continue
			check(visits[actor.entry.id].has(i),"Actually reaches every appointment: "+actor.entry.id+" "+block.at+" final="+actor.state+" "+str(actor.position)+" goal="+str(actor.anchor))
	check(population.residents.all(func(actor): return actor.state=="inside" and not actor.visible),"After the full day, everyone has actually returned indoors by 03:00")
	var walked_after := 0.0
	for actor in population.residents: walked_after += actor.travelled
	check(walked_after-walked_before>150000,"Daily location changes involve substantial real walking")
	# A late visit and a return after hours in the forest use the current shared time.
	scene.day_cycle.minutes = 690
	population.synchronize(scene.day_cycle,true)
	var gil: CharacterBody2D = population.by_id.gil
	var identity: int = gil.get_instance_id()
	gil.greet()
	check(gil.available(),"The friend is outside in the late morning")
	for i in 2: scene.people[i].position = world.menu_spawn+Vector2(i*100,0)
	check(scene._travel_region("forest",true),"Leave the village")
	scene.day_cycle.minutes = 180
	scene.day_cycle.day += 1
	check(scene._travel_region("village",true),"Return after the night has passed")
	check(gil.get_instance_id()==identity and gil.greetings==1,"Clock catch-up preserves identity and meeting history")
	check(not gil.visible and gil.state=="inside","Returning at 03:00 cannot restore yesterday's daytime activity")
	var near: Dictionary = world.interactions.nearest(scene.people[0])
	check(near.get("kind","")!="resident","Sleeping residents do not offer greetings")
	scene.queue_free()
	await frames(3)
	if not failed: print("PASS: 35 individual days, actual doors/meals/sleep, reachable timed appointments, full-day walking without teleports, child escorts, midnight and return-time catch-up")
	quit(1 if failed else 0)
