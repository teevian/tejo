extends SceneTree
var scene: Node2D
var failed := false
func _initialize() -> void:
	create_timer(160).timeout.connect(func(): push_error("Street life test timed out"); quit(2))
	call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok: failed = true; push_error(message)
func at_time(minutes: float) -> void:
	scene.day_cycle.minutes = minutes
	scene.world.synchronize_clock(scene.day_cycle,true)
func run() -> void:
	scene = load("res://scenes/sintra_village.tscn").instantiate()
	root.add_child(scene)
	for i in 3: await physics_frame
	scene.set_process(false)
	for p in scene.people: p.process_mode = Node.PROCESS_MODE_DISABLED
	var world: Node2D = scene.world
	var life: Node2D = world.street_life
	check(life.residents.size()==10 and world.population.residents.size()==35,"Ten distinct new people join the existing 35")
	for actor in life.residents:
		for block in actor.schedule:
			check(world.is_walkable(block.destination,14),"New activity uses reachable public floor: "+actor.entry.id+" "+block.at)
			check(not world.find_path(world.menu_spawn,block.destination).is_empty(),"Connected activity: "+actor.entry.id+" "+block.at)
			if block.mode=="inside": check(life.routines.doors.has(block.destination),"New meals and sleep use real doors: "+actor.entry.id+" "+block.at)
	at_time(690)
	check(life.residents.filter(func(a): return a.entry.role=="scout" and a.available()).size()==3,"Two scouts and their adult leader run the raffle table together")
	for id in ["oliver_turista","helena_turista","mariana_montras"]:
		check(life.by_id[id].position.distance_to(world.population.by_id.teresa.position)<350,"Visitors form a group around the actual guide: "+id)
	var player: CharacterBody2D = scene.people[0]
	var scout: CharacterBody2D = life.by_id.ines_escuteira
	player.position = scout.position+Vector2(0,22)
	var before: int = player.inventory.items.size()
	var message: String = world.interactions.interact(player)
	check(player.inventory.items.size()==before+1 and player.inventory.items[-1].type=="raffle_ticket","Space interaction buys and stores a real raffle ticket: "+message)
	world.interactions.interact(player)
	check(player.inventory.items.size()==before+1,"Repeated greetings do not duplicate the same daily ticket")
	var vendor: CharacterBody2D = life.by_id.enzo_gelados
	player.position = vendor.position+Vector2(0,18)
	message = world.interactions.interact(player)
	check(player.inventory.items.size()==before+2 and player.inventory.items[-1].type=="gelato","Space interaction buys a Nannarella cone: "+message)
	for i in 3: player.inventory.try_add({"type":"gelato","name":"Teste","porte":1,"flavor":0})
	var sold: int = life.gelato_sales.get(player.kind,0)
	life.interact_role("gelato",player)
	check(life.gelato_sales.get(player.kind,0)==sold,"A full bag does not record an unsuccessful sale")
	var lamps: int = world.lighting.lamps.size()
	check(lamps>=80,"Street lamps are spread throughout the town")
	check(world.lighting.lamp_strength==0 and world.lighting.lit_windows==0,"Daytime lights are off")
	at_time(1290)
	check(world.lighting.lamp_strength>.95 and world.lighting.lit_windows>100,"Evening lamps and many individual windows light up")
	var early: int = world.lighting.lit_windows
	at_time(159)
	check(world.lighting.lit_windows<early,"Most households turn their windows off after bedtime")
	check(not life.is_open("icecream") and not life.is_open("raffles") and not life.is_open("concert"),"Businesses and concert close overnight")
	at_time(1155)
	check(life.is_open("concert") and life.concert.active,"Evening concert has scheduled audible music")
	check(life.by_id.clara_violinista.available() and world.population.by_id.farid.available(),"Both real musicians are outside for the duet")
	check(life.by_id.clara_violinista.position.distance_to(world.population.by_id.farid.position)<500,"The guitar and violin share the same performance area")
	life.interact_role("musician",player)
	check(life.applause==1,"Players can applaud the performers")
	at_time(960)
	check(life.by_id.mariana_montras.appointment.place=="window_crafts","Window shopper changes to a real craft shop during the afternoon")
	at_time(1050)
	var family: CharacterBody2D = life.by_id.daniel_familia
	check(family.position.distance_to(world.population.by_id.leonor.position)<350,"The father walks with the existing mother and child")
	# Simulate a real guided departure: the followers must walk and stay on paving.
	at_time(810)
	var distance := 0.0
	var positions: Dictionary = {}
	for actor in life.residents: positions[actor.entry.id] = actor.position
	for tick in 240:
		scene.day_cycle.advance(.25)
		world.step_environment(.25,scene.day_cycle)
		await physics_frame
		for actor in life.residents:
			var gap: float = actor.position.distance_to(positions[actor.entry.id])
			check(gap<90,"Street groups move without teleporting")
			check(world.is_walkable(actor.position,10),"New people never walk through buildings: "+actor.entry.id)
			distance += gap
			positions[actor.entry.id] = actor.position
	check(distance>3000,"The new activities involve actual journeys")
	at_time(1155)
	scene._toggle_map()
	var minute: float = scene.day_cycle.minutes
	var frozen: Vector2 = life.by_id.oliver_turista.position
	for i in 5: await physics_frame
	check(scene.day_cycle.minutes==minute and life.by_id.oliver_turista.position==frozen,"Map freezes event participants and shared time")
	scene._toggle_map()
	world.hide()
	check(not world.lighting.emission_layer.visible and life.concert.player.stream_paused,"Hidden village cannot leak lights or concert sound into the forest")
	world.show()
	at_time(180)
	check(life.residents.all(func(a): return a.state=="inside" and not a.available()),"All additional participants sleep indoors at 03:00")
	print("Street lamps: ",lamps," · Evening windows: ",early)
	scene.queue_free()
	for i in 3: await physics_frame
	if not failed: print("PASS: guided tourists, family, shop windows, scouts/tickets, Nannarella/inventory, police, live duet, shared hours, lights and suspension")
	quit(1 if failed else 0)
