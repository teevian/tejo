extends SceneTree
var failed := false
var scene: Node2D
var pup: Node2D
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		push_error(message)
func tick(seconds: float) -> void:
	for i in ceili(seconds/.05): pup.step(.05)
func wait_for(condition: Callable, seconds: float) -> bool:
	for i in ceili(seconds/.05):
		if condition.call(): return true
		pup.step(.05)
	return condition.call()
func place(te: Vector2, jo: Vector2) -> void:
	scene.people[0].position = te
	scene.people[1].position = jo
	for person in scene.people:
		person.velocity = Vector2.ZERO
		pup.previous_people[person.kind] = person.position
func run() -> void:
	scene = load("res://scenes/garden.tscn").instantiate()
	root.add_child(scene)
	scene.set_process(false)
	pup = scene.world.puppy
	for person in scene.people: person.set_physics_process(false)
	var te = scene.people[0]
	var jo = scene.people[1]
	var start: Vector2 = pup.home
	place(start+Vector2(0,290),start+Vector2(130,330))
	tick(1)
	check(pup.state=="bark" and not pup.friendly,"Initially guards and barks")
	pup.interact(te)
	check(pup.pets==0 and pup.food.is_empty(),"Cannot bypass food by spamming interaction")
	te.inventory.try_add(pup.Art.FOOD)
	var count: int = te.inventory.items.size()
	scene.world.interactions.drop(te,count-1)
	check(not pup.food.is_empty() and te.inventory.items.size()==count-1,"Real inventory food is placed on ground")
	var meal_point: Vector2 = pup.food.position
	tick(5)
	check(pup.meals==0,"Does not eat while either person crowds the food")
	place(meal_point+Vector2(-250,240),meal_point+Vector2(250,240))
	wait_for(func(): return pup.meals==1,30)
	check(pup.meals==1 and pup.food.is_empty(),"Approaches and eats when both leave space and wait")
	check(not pup.friendly and pup.trust<.4,"One meal cannot tame puppy")
	# A second offering is another inventory action, with time and distance between meals.
	te.inventory.try_add(pup.Art.FOOD)
	pup.interact(te)
	check(not pup.food.is_empty(),"Accepts a second ground offering")
	var at: Vector2 = pup.food.get("position",start)
	place(at+Vector2(-230,250),at+Vector2(230,250))
	wait_for(func(): return pup.meals==2,35)
	check(pup.meals==2,"Second meal is earned with another calm encounter")
	check(not pup.friendly,"Food alone cannot unlock friendship")
	# Let him approach a still visitor; never move the visitor toward him.
	place(start+Vector2(0,260),start+Vector2(145,310))
	var before: Vector2 = te.position
	wait_for(func(): return pup.sniffs>=1,40)
	check(te.position==before and pup.sniffs>=1,"Puppy voluntarily approaches and completes first sniff")
	check(not pup.friendly,"First sniff still needs another encounter")
	# Reposition visitors only between encounters, at a safe distance.
	wait_for(func(): return pup.state=="guard",15)
	place(start+Vector2(0,260),start+Vector2(150,310))
	wait_for(func(): return pup.state=="invite",40)
	check(pup.sniffs>=2 and pup.state=="invite","Repeated calm encounter leads to invitation to touch")
	pup.interact(te)
	check(pup.state=="pet","Space accepts puppy's own invitation")
	tick(3.5)
	check(pup.friendly and pup.meals>=2 and pup.sniffs>=2 and pup.pets>=1,"Full trust requires meals, self-led sniffing and accepted petting")
	# A fresh nervous encounter: Te's approach always sends the nip toward Jo.
	pup.friendly = false
	pup.trust = .1
	pup.bite_cooldown = 0
	pup.position = start
	pup._set_state("guard")
	place(start+Vector2(-95,20),start+Vector2(125,30))
	te.velocity = Vector2(235,0)
	pup.step(.05)
	check(pup.state=="chase_jo" and pup.attack_target==jo,"Te rushing triggers pursuit of Jo, never Te")
	te.velocity = Vector2.ZERO
	tick(1.4)
	check(pup.last_bitten_kind==1 and te.puppy_recoil_time==0,"Only Jo gets the boot nip/recoil")
	pup.bite_cooldown = 0
	pup._set_state("guard")
	pup.position = start
	place(start+Vector2(-95,0),start+Vector2(1600,0))
	te.velocity = Vector2(235,0)
	pup.step(.05)
	check(pup.state!="chase_jo" and pup.attack_target==jo,"If Jo is outside territory, puppy retreats instead of biting Te")
	te.velocity = Vector2.ZERO
	# Integration suspension: pause and exploration map freeze trust and behavior.
	scene._toggle_map()
	var time: float = pup.elapsed
	scene._process(10)
	check(pup.elapsed==time,"Map suspends puppy progression")
	scene._toggle_map()
	scene._toggle_pause()
	scene._process(10)
	check(pup.elapsed==time,"Pause suspends puppy progression")
	scene._toggle_pause()
	if not failed: print("PASS: food inventory, distance and waiting, voluntary sniffing, consent to pet, gradual trust, Jo-only chase/nip, territory and pause/map")
	quit(1 if failed else 0)
