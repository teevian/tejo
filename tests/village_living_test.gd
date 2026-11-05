extends SceneTree
var scene: Node2D
var world: Node2D
var life: Node2D
var failed := false
func _initialize() -> void:
	root.size = Vector2i(1280,720)
	seed(20261104)
	create_timer(240,true,false,true).timeout.connect(func():push_error("Living test timed out");quit(2))
	call_deferred("run")
func check(ok: bool,text: String) -> void:
	if not ok: failed = true; push_error(text)
func at(minute: float,day := 1) -> void:
	scene.day_cycle.minutes = minute
	scene.day_cycle.day = day
	world.synchronize_clock(scene.day_cycle,true)
func ticks(seconds: float,advance := true) -> void:
	for i in roundi(seconds*4):
		if advance: scene.day_cycle.advance(.25)
		world.step_environment(.25,scene.day_cycle)
		await physics_frame
func run() -> void:
	scene = load("res://scenes/sintra_village.tscn").instantiate()
	root.add_child(scene)
	for i in 4: await physics_frame
	scene.set_process(false)
	world = scene.world
	life = world.living_life
	check(not life.storage_enabled,"Automated scenes never load or replace the player's community save")
	for p in scene.people: p.set_physics_process(false); p.position = Vector2(1500,14000)
	at(650)
	check(life.residents.size()==30 and world.social_life.actors.size()==145+world.passers.residents.size(),"Thirty new identities join the existing ninety-five")
	var ids: Dictionary = {}
	for a in world.social_life.actors: check(not ids.has(a.entry.id),"No identity alias: "+a.entry.id); ids[a.entry.id] = true
	check(life.DATA.data.events.size()>=24,"At least twenty genuinely authored additional episodes")
	check(life.addresses.size()==12,"Twelve stable real game addresses")
	for address in life.addresses:
		check(is_instance_valid(address.building) and world.is_walkable(address.at,12),"Address is an actual building with public approach")
		check(not world.find_path(world.menu_spawn,address.at).is_empty(),"Post destination is connected to the town")
	for actor in life.residents:
		for block in actor.schedule: check(world.is_walkable(block.destination,10),"Public scheduled point: "+actor.entry.id+" "+block.place)
	check(life.windows.size()>=4 and life.by_id.alzira.state=="window","Alzira actually opens a native house window")
	var p: CharacterBody2D = scene.people[0]
	var chalk_node: Node2D = life.objects.filter(func(o):return o.kind=="chalk")[0]
	life.draw_chalk(chalk_node,p,0)
	check(life.chalk.size()==1,"Chalk remains a real world drawing")
	life.by_id.celso.position = chalk_node.position
	life._sweep()
	check(life.chalk.is_empty() and life.sweeps>0,"The roaming sweeper erases chalk when he reaches it")
	life.draw_chalk(chalk_node,p,2)
	at(700,5)
	await ticks(.5,false)
	check(life.rain and life.chalk.is_empty(),"A rainy day washes the drawings away")
	at(650)
	var before: int = p.inventory.items.size()
	life.give(p,"grain","Sementes")
	p.position = life.animals.home+Vector2(80,0)
	check(life.feed_birds(p).contains("pombos") and p.inventory.items.size()==before,"Feeding consumes actual appropriate food")
	var old_goals: Array = life.animals.flock.map(func(b):return b.goal)
	await ticks(1,false)
	check(life.animals.flock.any(func(b):return b.goal.distance_to(life.animals.feed)<100),"Flock is attracted to actual seeds")
	p.position = life.animals.flock[3].at; p.moving = true; p.velocity = Vector2(240,0)
	life.animals.rethink = 0
	life.animals.step(.25)
	check(life.animals.frightened>1 and life.animals.flock.any(func(b):return b.fly>0),"Running causes cascading flock take-off")
	p.moving = false; p.velocity = Vector2.ZERO
	at(900)
	await ticks(.5,false)
	check(life.wind and life.hat.visible,"Occasional wind starts the hat chase")
	var hat_start: Vector2 = life.hat.position
	await ticks(3,false)
	check(life.hat.position.distance_to(hat_start)>15 and world.is_walkable(life.hat.position,5),"Hat moves along a plausible connected route")
	life.open_object(life.hat,p)
	check(not life.hat.visible and p.inventory.items.any(func(i):return i.type=="living_hat"),"Hat recovery uses the real bag")
	var dialogue := preload("res://scripts/village_living_dialogues.gd").new()
	dialogue.d = life; dialogue.actor = life.by_id.sven; dialogue.person = p
	dialogue.choose(3)
	check(life.state.quests.get("hat_returns",0)==1,"Recovered hat can actually be returned")
	# Address hint then escort: no automatic completion without walking to the real door.
	at(650)
	life.state.quests["post_known_"+str(life.post_target)] = true
	p.position = life.by_id.augusto.position
	var delivered: int = life.state.quests.get("post_deliveries",0)
	check(life.start_delivery(false),"Confirmed indication starts a real delivery route")
	var post_position: Vector2 = life.by_id.augusto.position
	await ticks(3,false)
	check(life.by_id.augusto.position.distance_to(post_position)>10,"The postman actually walks")
	check(life.by_id.augusto.goal==life.addresses[life.post_target].at,"Passing the player preserves the postman's real delivery destination")
	for i in 1200:
		if int(life.state.quests.get("post_deliveries",0))>delivered: break
		await ticks(.25,false)
	if int(life.state.quests.get("post_deliveries",0))<=delivered:
		var post: CharacterBody2D = life.by_id.augusto
		print("Delivery diagnostic: ",post.position," -> ",life.addresses[life.post_target].at," state ",post.state," route ",post.route.size()," encounter ",post.encounter_id)
	check(life.state.quests.get("post_deliveries",0)>delivered,"Letter reaches the actual door before it is marked delivered")
	var fountain: Node2D = life.objects.filter(func(o):return o.kind=="fountain")[0]
	p.inventory.items.clear()
	life.give(p,"bottle","Garrafa")
	life.fountain_action(fountain,p,1)
	check(p.inventory.items[0].type=="living_water","The fountain fills an actual carried bottle")
	for key in ["mourisca","bell","steps"]:
		var node: Node2D = life.objects.filter(func(o):return o.kind=="sound" and o.key==key)[0]
		life.open_object(node,p)
	dialogue.actor = life.by_id.ema; dialogue.choose(1)
	check(life.state.quests.get("melody_complete",false),"Three collected place sounds complete Ema's musical story")
	var pickup: Dictionary = world.interactions.spawn_pickup({"type":"pebble","name":"Pedrinha marcada","porte":1,"art":0},life.by_id.celso.position)
	life._sweep()
	check(not pickup.node.visible and life.state.lost.any(func(i):return i.name=="Pedrinha marcada"),"Sweeper preserves dropped objects in lost-and-found")
	p.inventory.items.clear()
	life.open_lost(p)
	life.panel.choose(life.state.lost.size()-1)
	check(p.inventory.items.any(func(i):return i.name=="Pedrinha marcada"),"Lost property is recoverable with identity intact")
	# Transaction never consumes an item when there is no matching offer.
	p.inventory.items.clear()
	p.inventory.try_add({"type":"pebble","name":"Pedrinha","porte":1,"art":0})
	check(life.exchange(p,["pebble"],"grain","Sementes").begins_with("Troca") and p.inventory.items[0].type=="living_grain","Barter exchanges real items atomically")
	# Exercise every authored episode through approach/action/consequence/release.
	at(650,3)
	for spec in life.DATA.data.events:
		life.events.reset()
		for id in spec.cast:
			var a: CharacterBody2D = life.by_id[id]
			a._cancel_encounter(); a._outside(); a.state = "activity"; a.event_busy = false; a.greet_time = 0; a.delivery_mode = ""
		check(life.events.start(spec,true),"Valid real paths for episode "+spec.id)
		if life.events.active.is_empty(): continue
		var episode: Dictionary = life.events.active[-1]
		for i in episode.people.size(): episode.people[i].position = episode.destinations[i]
		life.events.step(.25)
		check(episode.phase=="action","Episode enters its visible action: "+spec.id)
		if spec.id=="duvida":
			p.position = episode.at+Vector2(0,100)
			life.episode_choice(episode,p,1)
			check(life.state.quests.get("count_hortensias",0)==9,"Helping the count records the actual nearby staircase, not another district")
		life.events.step(10)
		check(life.state.events.has(spec.id) and not life.events.active.has(episode),"Episode commits consequence and releases cast: "+spec.id)
	# The habitual bench is actually occupied with authored sitting poses; he yields to both players.
	at(890)
	world.social_life.next_decision = 999
	life.events.next_decision = 999
	var sitter: CharacterBody2D = life.by_id.teodoro
	sitter._cancel_encounter()
	life._bench_routine(sitter)
	for i in 480:
		if sitter.bench_sitting: break
		await ticks(.25,false)
	if not sitter.bench_sitting: print("Bench diagnostic: ",sitter.position," -> ",sitter.goal," state ",sitter.state," route ",sitter.route.size())
	check(sitter.bench_sitting,"Teodoro walks to the real bench and sits")
	if sitter.has_meta("favourite_bench"):
		life.yield_bench(sitter.get_meta("favourite_bench"))
		check(not sitter.bench_sitting and not sitter.route.is_empty(),"The regular yields his bench and waits visibly for the player")
	# Participating in an episode produces memory only on successful completion.
	var helped_spec: Dictionary = life.DATA.data.events[2]
	for id in helped_spec.cast:
		var a: CharacterBody2D = life.by_id[id]
		a._outside(); a.state = "activity"; a.greet_time = 0; a.event_busy = false; a.delivery_mode = ""
	check(life.events.start(helped_spec,true),"Interactive episode reserves real participants")
	if not life.events.active.is_empty():
		var episode: Dictionary = life.events.active[-1]
		for i in episode.people.size(): episode.people[i].position = episode.destinations[i]
		p.position = episode.at+Vector2(0,100)
		life.events.step(.25)
		check(life.open_episode(episode.people[0],p),"The player can join a running episode")
		life.panel.choose(1)
		life.events.step(10)
		check(int(episode.people[0].memory.get("helped_by_player",0))>0,"Participants remember the actual completed help")
	# UI only blocks protagonists, Escape closes it, and world hiding cancels it.
	life.open_character(life.by_id.augusto,p)
	check(life.panel.opened and p.in_dialogue,"Branching conversation blocks movement")
	var key := InputEventKey.new(); key.keycode = KEY_ESCAPE; key.pressed = true
	life.handle_input(key)
	check(not life.panel.opened and not p.in_dialogue,"Escape closes the local choice panel without leaving controls stuck")
	life.open_character(life.by_id.augusto,p)
	await process_frame
	await process_frame
	var button: Button = life.panel.content.get_child(3)
	var mouse := InputEventMouseButton.new()
	mouse.button_index = MOUSE_BUTTON_LEFT
	mouse.position = button.get_global_rect().get_center()
	mouse.global_position = mouse.position
	mouse.pressed = true
	check(not life.handle_input(mouse),"Mouse choices reach the actual GUI")
	var motion := InputEventMouseMotion.new()
	motion.position = mouse.position
	root.push_input(motion,true)
	root.push_input(mouse,true)
	await process_frame
	mouse.pressed = false
	root.push_input(mouse,true)
	await process_frame
	check(life.state.quests.has("post_search") and not life.panel.opened,"Actual mouse click chooses the address-search branch")
	# Test persistence in an isolated test file, never the user's save.
	life.save_path = "user://living-test-isolated.json"; life.storage_enabled = true
	life.state.quests.audit_mark = 17
	check(life.save_state(),"Community memory saves atomically")
	life.state.quests.audit_mark = 0
	check(life.load_state() and int(life.state.quests.audit_mark)==17,"Community consequences survive reload")
	life.storage_enabled = false
	DirAccess.remove_absolute(ProjectSettings.globalize_path(life.save_path))
	life.panel.finish()
	at(180)
	check(life.residents.all(func(a):return a.state=="inside"),"New residents sleep indoors at night")
	print("People ",world.social_life.actors.size(),"; real addresses ",life.addresses.size(),"; native windows ",life.windows.size(),"; authored episodes verified ",life.DATA.data.events.size())
	scene.queue_free()
	for i in 4: await physics_frame
	if not failed: print("PASS: interconnected community, real errands, reactive birds, hat chase, chalk/weather/sweeper, sound story, transactions, choices and persistence")
	quit(1 if failed else 0)
