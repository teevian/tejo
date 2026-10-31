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
	for i in ceili(seconds/0.05):
		eco.step(0.05)
func animal(species: String):
	for a in eco.animals:
		if a.species==species:
			return a
	return null
func run() -> void:
	var log := ErrorLog.new()
	OS.add_logger(log)
	scene = load("res://scenes/garden.tscn").instantiate()
	root.add_child(scene)
	scene.set_process(false)
	eco = scene.world.wildlife
	var count: int = eco.animals.size()
	check(count>320 and count<400,"Bounded day and night populations across the whole forest")
	for species in ["bird","squirrel","fox","frog","butterfly","bat","owl","firefly","snake"]:
		check(animal(species)!=null,"Missing species: "+species)
	for person in scene.people:
		person.set_physics_process(false)
		person.position = Vector2(50,50)
	# Test actual predator/prey reaction near a reachable refuge.
	var squirrel = animal("squirrel")
	var fox = animal("fox")
	var foot: Vector2 = squirrel.home.foot
	squirrel.position = foot
	squirrel.set_state("forage",5)
	fox.position = foot+Vector2(0,85)
	for i in 32:
		var candidate := foot+Vector2.from_angle(i*TAU/32)*85
		if scene.world.can_walk_line(candidate,foot):
			fox.position = candidate
			break
	fox.hunger = 1
	fox.thirst = 0
	fox.cooldown = 0
	fox.set_state("listen",0)
	fox._fox_think()
	check(fox.state=="bound" and fox.run_next=="chase","Fox immediately bounds into a chase when it sees a squirrel")
	squirrel._squirrel_think()
	check(squirrel.state=="startled","Squirrel startles before fleeing predator")
	simulate(3)
	check(squirrel.state=="hidden","Squirrel climbs and enters actual tree hollow")
	check(not squirrel.art.visible,"Hidden squirrel is no longer drawn")
	check(fox.quarry!=squirrel or fox.state!="chase","Fox gives up inaccessible prey")
	# Thirst sends fox to a reachable bank, never into the river.
	var pond: Dictionary = eco.nearest_pond(fox.position)
	fox.position = pond.bank
	fox.thirst = 1
	fox.set_state("listen",0)
	fox._fox_think()
	fox._fox_think()
	check(fox.state=="drink","Thirsty fox drinks at river bank")
	check(not scene.world.in_water(fox.position),"Fox remains on dry bank")
	var initial_thirst: float = fox.thirst
	for i in 5:
		fox._fox_think()
	check(fox.thirst<initial_thirst,"Drinking reduces thirst")
	# A nearby person triggers water refuge, then the frog resurfaces once safe.
	var frog = animal("frog")
	frog.position = frog.pond.bank
	frog.set_state("bank",5)
	scene.people[0].position = frog.position+Vector2(40,0)
	frog._frog_think()
	check(frog.state=="hop" and frog.jump_next=="submerged","Frog dives when approached")
	for i in 15:
		frog.step(0.05)
	check(frog.state=="submerged" and scene.world.in_water(frog.position),"Frog hides in real water")
	scene.people[0].position = Vector2(50,50)
	frog.timer = 0
	frog._frog_think()
	check(frog.state=="surface","Frog emerges when threat leaves")
	frog.timer = 0
	frog._frog_think()
	for i in 12:
		frog.step(0.05)
	check(frog.state=="leaf","Frog lands on floating leaf")
	# Flock alarm, individual flight and insect startle.
	var bird = animal("bird")
	scene.people[0].position = bird.position
	bird.cooldown = 0
	bird.set_state("perch",5)
	bird._bird_think()
	check(bird.state=="fly","Bird takes off when approached")
	for other in eco.animals:
		if other.species=="bird" and other.flock==bird.flock:
			check(other.state=="fly","Whole flock responds to alarm")
	var butterfly = animal("butterfly")
	scene.people[0].position = butterfly.position
	butterfly.cooldown = 0
	butterfly._butterfly_think()
	check(butterfly.state=="evade","Butterfly veers away from person")
	scene.people[0].position = Vector2(50,50)
	# Night settles diurnal species; dawn wakes them.
	scene.day_cycle.minutes = 1380
	bird.set_state("perch",5)
	bird._bird_think()
	butterfly.cooldown = 0
	butterfly.set_state("nectar",0)
	butterfly._butterfly_think()
	check(bird.state=="roost" and butterfly.state=="rest","Diurnal animals rest at night")
	scene.day_cycle.minutes = 480
	bird._bird_think()
	butterfly._butterfly_think()
	check(bird.state=="perch" and butterfly.state=="flutter","Diurnal animals wake in morning")
	# Simulate organic behavior and validate ground locomotion, no population leak.
	simulate(120)
	check(eco.animals.size()==count,"Population remains stable")
	for a in eco.animals:
		check(a.position.is_finite(),"Animal position must stay finite")
		if a.species in ["fox","squirrel"]:
			check(not scene.world.in_water(a.position),"Ground mammal must never walk into water")
	var elapsed: float = eco.elapsed
	scene._toggle_pause()
	scene._process(1)
	check(eco.elapsed==elapsed,"Pause freezes the ecosystem")
	scene._toggle_pause()
	scene._toggle_map()
	scene._process(1)
	check(eco.elapsed==elapsed,"Map freezes the ecosystem")
	scene._toggle_map()
	scene._process(0.1)
	check(eco.elapsed>elapsed,"Ecosystem resumes with the shared clock")
	OS.remove_logger(log)
	check(log.errors.is_empty(),"Runtime errors: "+str(log.errors))
	print("Wildlife events: ",eco.events)
	if not failed:
		print("PASS: habitats, pursuit/refuge, thirst, frog water/leaf cycle, flock alarm, insect response, daily rhythm, population and pause")
	quit(1 if failed else 0)
