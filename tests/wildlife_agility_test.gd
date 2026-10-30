extends SceneTree
const Art = preload("res://scripts/wildlife_art.gd")
var failed := false
var scene: Node2D
var eco: Node2D
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
func get_animal(species: String):
	for a in eco.animals:
		if a.species==species: return a
	return null
func tick(a: Node2D, seconds: float) -> void:
	for i in ceili(seconds/0.01):
		eco.elapsed += 0.01
		a.step(0.01)
func run() -> void:
	var log := ErrorLog.new()
	OS.add_logger(log)
	root.size = Vector2i(1280,720)
	scene = load("res://scenes/garden.tscn").instantiate()
	root.add_child(scene)
	scene.set_process(false)
	eco = scene.world.wildlife
	for person in scene.people:
		person.set_physics_process(false)
		person.position = Vector2(50,50)
	for a in eco.animals:
		if a.species=="squirrel": a.set_state("hidden",1000)
	var fox = get_animal("fox")
	fox.thirst = 0
	fox.curiosity_cooldown = 999
	fox.set_state("listen",10)
	fox.ground_speed = 0
	fox.position = Vector2(850,2890)
	check(scene.world.is_walkable(fox.position,12),"Fixture starts in walkable clearing")
	scene.people[0].position = fox.position+Vector2(90,0)
	var start_distance: float = fox.position.distance_to(scene.people[0].position)
	fox._fox_think()
	check(fox.state=="bound" and fox.run_next=="flee","Stationary fox launches with a turning bound")
	tick(fox,0.12)
	check(fox.altitude>12,"Launch visibly leaves the ground")
	tick(fox,0.5)
	check(fox.state=="flee" and fox.velocity.length()>450,"Fox reaches a genuinely fast escape speed")
	check(fox.position.distance_to(scene.people[0].position)>start_distance+120,"Escape increases distance from the person")
	var bounds: int = eco.events.fox_bounds
	tick(fox,0.3)
	check(eco.events.fox_bounds==bounds,"Continuous flight does not repeatedly restart the bound")
	check(not scene.world.in_water(fox.position),"Fast flight respects land")
	# A normal walking transition never uses the sprint-start jump.
	scene.people[0].position = Vector2(50,50)
	fox.set_state("wander",3)
	fox.ground_speed = 0
	fox.go_land(eco.land_point(fox.position,150))
	fox.think_in = 10
	tick(fox,0.15)
	check(fox.altitude==0 and eco.events.fox_bounds==bounds,"Walking does not produce a launch jump")
	# Watch a real person from a reachable, visible corner, with no teleport.
	var observation: Dictionary = {}
	for center in [Vector2(850,2820),Vector2(1650,1850),Vector2(2500,1600),Vector2(4020,2930)]:
		scene.people[0].position = center+Vector2(0,70)
		scene.camera.position = center
		scene.camera.force_update_scroll()
		fox.position = eco.land_point(center+Vector2(450,50),80)
		observation = eco.observation_point(fox,scene.people[0])
		if not observation.is_empty(): break
	check(not observation.is_empty(),"Forest has a reachable observation point at the view edge")
	if not observation.is_empty():
		fox.position = observation.position
		fox.curiosity_cooldown = 0
		fox.panic_time = 0
		fox.think_in = 0
		fox.ground_speed = 0
		fox.set_state("listen",0)
		fox._fox_think()
		check(fox.state=="approach_watch","Fox approaches a peripheral watch point")
		fox._fox_think()
		check(fox.state=="watch" and eco.at_view_edge(fox.position),"Curious fox watches from inside the edge of the view")
		check(eco.visible_watch_point(fox.position),"Watching fox has a visible head/torso, not just an on-screen ground point")
		fox._fox_think()
		check(fox.facing.dot(fox.position.direction_to(scene.people[0].position))>0.99,"Watching fox faces the person")
		fox.timer = 0
		fox._fox_think()
		check(fox.state=="bound" and fox.run_next=="flee","Sighting is brief: fox bounds away after watching")
		check(fox.curiosity_cooldown>=24,"Fox does not immediately return for another sighting")
	# Visible prey overrides other quiet activity, even without hunger.
	for person in scene.people: person.position = Vector2(50,50)
	var squirrel = get_animal("squirrel")
	squirrel.position = squirrel.home.foot
	squirrel.set_state("forage",5)
	fox.position = squirrel.position+Vector2(0,85)
	for i in 32:
		var at: Vector2 = squirrel.position+Vector2.from_angle(i*TAU/32)*85
		if scene.world.can_walk_line(at,squirrel.position):
			fox.position = at
			break
	fox.hunger = 0
	fox.cooldown = 0
	fox.ground_speed = 0
	fox.set_state("listen",20)
	fox._fox_think()
	check(fox.quarry==squirrel and fox.state=="bound" and fox.run_next=="chase","Seeing a squirrel triggers an immediate chase regardless of hunger")
	squirrel._squirrel_think()
	check(squirrel.state=="startled","Squirrel has a distinct startle state")
	tick(squirrel,0.12)
	check(squirrel.altitude>10 and squirrel.art.pose_frame()==3,"Squirrel makes a visible startled hop with its own sprite")
	tick(squirrel,0.15)
	check(squirrel.state=="flee","Startled hop finishes in an escape")
	# All 8 facings select genuine front/back/diagonal source regions.
	for species in ["fox","squirrel","bird","frog","butterfly"]:
		var a = get_animal(species)
		a.set_state("wander",10)
		a.velocity = Vector2.ZERO
		var regions: Array = []
		for d in 8:
			a.facing = Vector2.from_angle(-PI/2+d*PI/4)
			var spec: Dictionary = a.art.sprite_spec()
			check(spec.direction==d,"Direction mapping: "+species+str(d))
			check(Rect2(Vector2.ZERO,spec.texture.get_size()).encloses(spec.region),"Sprite lies within atlas")
			if d<=4: regions.append(spec.region)
			else: check(spec.flip,"Western directions mirror their matching eastern view")
		check(regions[0]!=regions[2] and regions[4]!=regions[2] and regions[1]!=regions[3],"Front/back/diagonals use distinct anatomy: "+species)
	OS.remove_logger(log)
	check(log.errors.is_empty(),"Runtime errors: "+str(log.errors))
	if not failed: print("PASS: sprint speed, launch hop, safe flight, no walking hop, peripheral curiosity, rarity cooldown, immediate pursuit, squirrel startle and eight-way art")
	quit(1 if failed else 0)
