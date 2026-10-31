extends SceneTree
var scene: Node2D
var eco: Node2D
var failed := false
class ErrorLog:
	extends Logger
	var errors: Array[String] = []
	func _log_error(_function: String, file: String, line: int, code: String, _rationale: String, _editor_notify: bool, _error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
		errors.append("%s:%d %s"%[file,line,code])
func _initialize() -> void:
	call_deferred("run")
func check(value: bool, message: String) -> void:
	if not value:
		failed = true
		push_error(message)
func simulate(seconds: float) -> void:
	for i in ceili(seconds/0.05): eco.step(0.05)
func animal(species: String):
	for a in eco.animals:
		if a.species==species: return a
	return null
func run() -> void:
	var log := ErrorLog.new()
	OS.add_logger(log)
	scene = load("res://scenes/garden.tscn").instantiate()
	root.add_child(scene)
	scene.set_process(false)
	eco = scene.world.wildlife
	for person in scene.people:
		person.set_physics_process(false)
		person.position = Vector2(50,50)
	var population: int = eco.animals.size()
	check(eco.colonies.size()==7 and eco.firefly_patches.size()==20,"Persistent communities across the expanded forest")
	for a in eco.animals:
		if a.species in ["bat","owl","firefly","snake"]:
			check(a.state=="shelter" and not a.art.visible,"Night residents are sheltered during the day")
	for sample in [[18*60,0.0],[20*60,1.0],[23*60,1.0],[0,1.0],[6*60,0.0],[12*60,0.0]]:
		scene.day_cycle.minutes = sample[0]
		check(is_equal_approx(eco.nocturnal_activity(),sample[1]),"Daily activity at "+str(sample[0]))
	scene.day_cycle.minutes = 19.5*60
	check(eco.nocturnal_activity()>0 and eco.nocturnal_activity()<1,"Gradual dusk activity")
	scene.day_cycle.minutes = 5.5*60
	check(eco.nocturnal_activity()>0 and eco.nocturnal_activity()<1,"Gradual dawn activity")
	scene.day_cycle.minutes = 23*60
	simulate(0.4)
	var owl = animal("owl")
	var bat = animal("bat")
	var firefly = animal("firefly")
	check(owl.state=="watch" and firefly.state=="glimmer","Owls and insects wake at night")
	var owls := 0
	var snakes := 0
	for resident in eco.animals:
		if resident.species=="owl": owls += 1
		if resident.species=="snake": snakes += 1
	check(owls==14 and snakes==8,"A modest increase in owls and a sparse river snake population")
	var fixed_point: Vector2 = firefly.anchor
	var frequencies: Dictionary = {}
	for patch in eco.firefly_patches:
		for light in patch.members: frequencies[light.pulse_rate] = true
	check(frequencies.size()>20,"Ground lights use individual pulse frequencies")
	simulate(3)
	check(firefly.position==fixed_point and firefly.altitude==0 and firefly.velocity==Vector2.ZERO,"Fireflies are stationary points on the ground")
	eco.release_colony(eco.colonies[0])
	for member in eco.colonies[0].members:
		check(member.state=="emerge","Colony departs together with staggered wingbeats")
	check(eco.events.bat_groups>0,"Group departures are recorded")
	simulate(1.3)
	check(bat.state in ["cruise","hunt","evade"],"Bats leave their actual hollow by flight")
	# The character walks behind the owl: the head can reach 180 degrees, feet never move.
	owl.set_state("watch",60)
	owl.head_yaw = 0
	var perched_at: Vector2 = owl.position
	var perched_height: float = owl.altitude
	var body_facing: Vector2 = owl.facing
	scene.people[0].position = owl.position+Vector2(0,-400)
	for i in 65: owl.step(0.05)
	check(absf(absf(owl.head_yaw)-PI)<0.01,"Owl follows a person behind it through 180 degrees")
	check(owl.position==perched_at and owl.altitude==perched_height and owl.facing==body_facing,"Owl body and feet stay fixed on the branch")
	scene.people[0].position = owl.position+Vector2(400,0)
	for i in 65: owl.step(0.05)
	check(absf(owl.head_yaw+PI/2)<0.01,"Head follows the moving character independently")
	owl.phase = 0
	owl.head_yaw = -0.1
	owl.eye_open = 1
	owl.glint_cooldown = 0
	scene.people[0].position = owl.position+Vector2(-180,300)
	owl._owl_move(0.2)
	check(owl.eye_glint>0.9 and eco.events.owl_glints>0,"Head turns briefly catch the light in the owl's eyes")
	owl._owl_eyes(0.5)
	check(owl.eye_glint==0 and owl.glint_cooldown>0,"Eye reflections fade quickly and cannot flash continuously")
	scene.people[0].position = Vector2(50,50)
	var destination: Dictionary = eco.next_owl_tree(owl,owl.position+Vector2(400,0))
	check(not destination.is_empty(),"An unoccupied neighboring tree is available")
	if not destination.is_empty():
		owl.owl_flight(destination)
		var previous: Vector2 = owl.position
		for i in 220: owl.step(0.05)
		check(owl.position.distance_to(previous)>100 and owl.state=="watch","Owl flies to another tree and lands")
		check(owl.position==destination.foot+Vector2(destination.owl_perch.x,0) and is_equal_approx(owl.altitude,-destination.owl_perch.y+42),"Owl lands at the branch's actual world position")
	# Controlled encounters use residents, without removing prey from the population.
	for resident in eco.animals:
		if resident.species=="owl": resident.set_state("shelter")
	var flying_insect = animal("butterfly")
	flying_insect.position = firefly.anchor
	flying_insect.altitude = 22
	flying_insect.set_state("flutter")
	bat.position = flying_insect.position+Vector2(65,0)
	bat.altitude = flying_insect.altitude+12
	bat.outing_time = 20
	bat.cooldown = 0
	bat.set_state("cruise")
	bat._bat_think()
	check(bat.state=="hunt" and bat.quarry!=null,"Bats pursue flying insects, leaving the fixed ground lights in place")
	var insect = bat.quarry
	if insect!=null:
		bat.position = insect.position+Vector2(12,0)
		bat._bat_think()
		check(insect.state=="evade","Insects scatter and dim during a bat's approach")
	owl.position = bat.position+Vector2(60,0)
	owl.altitude = bat.altitude
	owl.set_state("watch",30)
	bat.cooldown = 0
	bat._bat_think()
	check(bat.state=="evade" and eco.events.aerial_escapes>0,"Bats evade an owl instead of passing through it")
	bat.set_state("cruise")
	owl.timer = 0
	owl.cooldown = 0
	owl._owl_think()
	check(owl.state=="swoop" and eco.events.owl_hunts>0,"Owls join the food web with short hunting flights")
	owl.set_state("shelter")
	var frog = animal("frog")
	frog.position = frog.pond.bank
	frog.cooldown = 0
	frog.set_state("bank",10)
	var original_anchor: Vector2 = firefly.anchor
	firefly.anchor = frog.position+Vector2(25,0)
	firefly.position = firefly.anchor
	firefly.altitude = 0
	firefly.cooldown = 0
	firefly.set_state("glimmer")
	for a in eco.animals:
		if a.species=="fox": a.position = Vector2(50,50)
	frog._frog_think()
	check(frog.state=="snap" and firefly.cooldown>0,"Ground insects dim when disturbed without flying away")
	firefly._firefly_move(0.3)
	check(firefly.position==firefly.anchor and firefly.altitude==0,"Even a startled ground light remains fixed")
	firefly.anchor = original_anchor
	firefly.position = original_anchor
	var snake = animal("snake")
	frog.pond = snake.pond
	frog.position = snake.anchor
	frog.set_state("bank",5)
	snake.position = snake.anchor
	for i in 32:
		var at: Vector2 = snake.anchor+Vector2.from_angle(i*TAU/32)*85
		if scene.world.is_walkable(at,8) and scene.world.can_walk_line(at,frog.position):
			snake.position = at
			break
	snake.cooldown = 0
	snake.set_state("coil")
	snake._snake_think()
	check(snake.state=="stalk" and snake.quarry!=null,"River snakes stalk exposed frogs along reachable banks")
	if snake.quarry!=null:
		var hunted_frog = snake.quarry
		hunted_frog._frog_think()
		check(hunted_frog.state=="hop" and hunted_frog.jump_next=="submerged","Frogs dive away from a stalking snake")
	scene.people[0].position = snake.position+Vector2(30,0)
	snake._snake_think()
	check(snake.state in ["retreat","shelter"],"Snakes retreat or hide when a person approaches")
	scene.people[0].position = Vector2(50,50)
	var bird = animal("bird")
	owl.position = bird.position+Vector2(70,0)
	owl.altitude = bird.altitude
	owl.set_state("watch",5)
	bird.set_state("roost",5)
	bird.cooldown = 0
	bird._bird_think()
	check(bird.state=="fly","Roosting birds give way to a nearby owl and alarm their flock")
	# Several whole-world sorties exercise coexistence, separation and bounded habitats.
	simulate(100)
	check(eco.animals.size()==population,"Encounters preserve the resident population")
	check(eco.events.bat_groups>=7,"Colonies periodically emerge around the world")
	for a in eco.animals:
		check(a.position.is_finite() and is_finite(a.altitude),"Stable coordinates for every resident")
		if a.species=="firefly": check(a.position==a.anchor and a.altitude==0,"Ground lights never drift or gain height")
		if a.species=="snake":
			check(not scene.world.in_water(a.position) and scene.world.is_walkable(a.position,4),"Snakes respect water and solid obstacles")
			check(a.position.distance_to(a.anchor)<=270,"Snakes remain in their river-bank territory")
	scene.day_cycle.minutes = 6*60
	simulate(22)
	for a in eco.animals:
		if a.species in ["bat","owl","firefly","snake"]:
			check(a.state=="shelter" and not a.art.visible,"Dawn returns nocturnal animals to shelter: "+a.species+" "+a.state)
	scene.day_cycle.minutes = 23*60
	simulate(1)
	var before_toggle: float = eco.elapsed
	scene._toggle_debug_time()
	for a in eco.animals:
		if a.species in ["bat","owl","firefly","snake"]:
			check(a.state=="shelter","Debug day immediately shelters every nocturnal species")
	scene._toggle_debug_time()
	check(eco.elapsed==before_toggle and eco.animals.size()==population,"Debug toggles preserve the ecosystem and simulation time")
	for a in eco.animals:
		if a.species=="snake": check(a.state=="coil","Debug night immediately restores river snakes")
		if a.species=="firefly": check(a.position==a.anchor and a.altitude==0 and a.glow>0,"Debug night restores the same fixed ground lights")
	var elapsed: float = eco.elapsed
	var yaw: float = owl.head_yaw
	var glow: float = firefly.glow
	scene._toggle_pause()
	scene._process(1)
	check(eco.elapsed==elapsed and owl.head_yaw==yaw and firefly.glow==glow,"Pause freezes movement, head tracking and light pulses")
	scene._toggle_pause()
	scene._toggle_map()
	scene._process(1)
	check(eco.elapsed==elapsed,"Map freezes the nocturnal ecosystem")
	scene._toggle_map()
	scene._process(0.1)
	check(eco.elapsed>elapsed,"The shared clock resumes every species")
	OS.remove_logger(log)
	check(log.errors.is_empty(),"Runtime errors: "+str(log.errors))
	print("Nocturnal events: ",eco.events)
	if not failed: print("PASS: dusk/dawn, fixed ground lights and individual pulses, brief owl reflections, river snake encounters and navigation, debug day/night, stable population, pause/map")
	quit(1 if failed else 0)
