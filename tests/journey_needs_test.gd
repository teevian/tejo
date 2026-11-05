extends SceneTree
const Catalog = preload("res://scripts/bakery_catalog.gd")
var scene: Node2D
var j: Node2D
var failed := false
func _initialize() -> void:
	create_timer(240,true,false,true).timeout.connect(func():push_error("Journey test timeout");quit(2))
	call_deferred("run")
func check(ok: bool,text: String) -> void:
	if not ok: failed = true; push_error(text)
func close(a: float,b: float) -> bool: return absf(a-b)<.001
func pair(at: Vector2) -> void:
	for i in 2:
		scene.people[i].stand_up(true); scene.people[i].moving = false; scene.people[i].running = false
		scene.people[i].position = scene.world.population.free_point(at+Vector2(i*105,0),true)
func run() -> void:
	scene = load("res://scenes/sintra_village.tscn").instantiate(); root.add_child(scene)
	for i in 4: await physics_frame
	scene.set_process(false); j = scene.journey
	for p in scene.people: p.set_physics_process(false)
	var world: Node2D = scene.world; var bakery: Node2D = world.bakery
	check(not j.storage_enabled and not world.living_life.storage_enabled,"Tests never read or write the player's saves")
	check(Catalog.PRODUCTS.size()==8 and Catalog.PRODUCTS.filter(func(p):return p.type=="bakery_peach_tea").size()==1,"Eight distinct products, peach iced tea appears once")
	check(not world.is_walkable(bakery.position-Vector2(0,20),1),"Bakery display is a real baked-in obstacle")
	for need in j.needs: need.hunger = 20.0; need.fatigue = 50.0
	for p in scene.people: p.moving = false; p.running = false
	j.step_needs(120,scene.people)
	check(close(j.needs[0].hunger,29) and close(j.needs[1].fatigue,55.4),"Individual hunger and fatigue increase with elapsed game minutes")
	for need in j.needs: need.fatigue = 50.0
	var te: CharacterBody2D = scene.people[0]; var jo: CharacterBody2D = scene.people[1]
	te.ground_seated = true; te.ground_rest = true; te.ground_pose = 1; te.eyes_closed = true; te.rest_target = ""
	jo.seated = true; jo.seating = false
	j.step_needs(60,scene.people)
	check(close(50-j.needs[0].fatigue,(50-j.needs[1].fatigue)*4),"Real sleeping state recovers exactly four times the actual bench state")
	check(close(j.needs[0].fatigue,30.8) and close(j.needs[1].fatigue,45.2),"Recovery uses sleep x1 and bench x0.25 without simultaneous fatigue accrual")
	te.stand_up(true); jo.stand_up(true)
	var before: Dictionary = j.needs[0].duplicate()
	paused = true; j.step(60); paused = false
	check(j.needs[0]==before,"Pause freezes hunger, fatigue and relationship time")
	scene.exploration_map.show(); j.step(60); scene.exploration_map.hide()
	check(j.needs[0]==before,"The map does not quietly accumulate needs")
	pair(bakery.position+Vector2(0,100)); scene.day_cycle.minutes = 600
	j.coins = 10000
	for k in Catalog.PRODUCTS.size():
		te.inventory.items.clear()
		var wallet: int = j.coins
		var reply: String = bakery.buy(j,0,k)
		check(te.inventory.items.size()==1 and te.inventory.items[0].type==Catalog.PRODUCTS[k].type,"Actual bakery purchase delivers the selected product: "+reply)
		check(j.coins==wallet-int(Catalog.PRODUCTS[k].price),"Purchase debits exact integer-cent price")
	te.inventory.items.clear(); j.coins = 0
	bakery.buy(j,0,0); check(j.coins==0 and te.inventory.items.is_empty(),"Insufficient funds never give a free cake")
	j.coins = 2400
	for i in 5: te.inventory.try_add({"type":"pebble","name":"Pedrinha","porte":1,"art":0})
	bakery.buy(j,0,0); check(j.coins==2400 and te.inventory.items.size()==5,"Full bag never charges the wallet")
	te.inventory.items.clear(); scene.day_cycle.minutes = 1290
	bakery.buy(j,0,0); check(j.coins==2400 and te.inventory.items.is_empty(),"Closing at 21:30 is checked again at the purchase transaction")
	scene.day_cycle.minutes = 600; te.position += Vector2(1700,0)
	bakery.buy(j,0,0); check(j.coins==2400 and te.inventory.items.is_empty(),"Cannot buy remotely through an old menu")
	pair(bakery.position+Vector2(0,100)); bakery.buy(j,0,3)
	j.needs[0].hunger = 60; j.needs[1].hunger = 80
	j.consume(0,0,0)
	check(close(j.needs[0].hunger,42) and close(j.needs[1].hunger,80) and te.inventory.items.is_empty(),"Eating consumes one item and satisfies only the eater")
	bakery.buy(j,0,1); var count: int = te.inventory.items.size(); jo.position += Vector2(1500,0)
	j.consume(0,0,2); check(te.inventory.items.size()==count,"A distant companion cannot share or consume the carried portion")
	pair(bakery.position+Vector2(0,100)); j.bond = 0; j.awarded.clear(); j.daily.clear()
	j.needs[0].hunger = 60; j.needs[1].hunger = 80; j.consume(0,0,2)
	check(close(j.needs[0].hunger,44) and close(j.needs[1].hunger,64) and te.inventory.items.is_empty() and j.bond==2,"Sharing divides a single cake into two halves and gains bonding")
	bakery.buy(j,0,2); j.consume(0,0,1)
	check(close(j.needs[0].hunger,44) and close(j.needs[1].hunger,32),"Giving a product feeds the named companion only")
	bakery.buy(j,0,7); var tired: float = j.needs[0].fatigue; j.consume(0,0,0)
	check(j.needs[0].fatigue==tired and j.needs[0].hunger==44,"Water does not invent food calories or replace actual rest")
	bakery.buy(j,0,0); scene.inventory_panel.refresh(); scene.inventory_panel.entries[0].pressed.emit()
	check(j.panel.opened and te.inventory.items.size()==1,"Clicking food opens the real eat/give/share panel instead of dropping it")
	j.panel.choose(2); check(te.inventory.items.is_empty(),"The actual inventory choice consumes the shared product once")
	j.bond = 0; j.awarded.clear(); j.daily.clear(); j.earned_today.clear(); j.coins = 1000
	check(j.record_activity("football","round",2,te.position,75),"A real shared activity grants progress")
	check(not j.record_activity("football","round",2,te.position,75) and j.bond==2 and j.coins==1075,"Repeating the same completion does not duplicate points or money")
	jo.position += Vector2(1000,0)
	check(not j.record_activity("football","remote_round",2,te.position,75),"The companion must actually be nearby for a shared activity")
	pair(world.neighbourhood.places.foosball+Vector2(0,150)); j.bond = 0; j.awarded.clear(); j.daily.clear(); j.coins = 1000
	for i in 3:
		world.neighbourhood.dialogues._match_panel(te)
		var defence: int = world.neighbourhood.episodes.player_match.defence
		world.living_life.panel.choose((defence+1)%3)
	check(j.bond==6 and j.coins==1200,"Completing the actual three-goal foosball game earns shared progress and the real prize")
	j.bond = 39; world.living_life.panel.finish()
	world.living_life.begin_beat(world.living_life.by_id.plutonio,te)
	check(not world.living_life.panel.opened,"Roda de ritmo is genuinely locked before bonding 40")
	j.bond = 40; world.living_life.begin_beat(world.living_life.by_id.plutonio,te)
	check(world.living_life.panel.opened,"Roda de ritmo unlocks at the stated relationship threshold"); world.living_life.panel.finish()
	var director: RefCounted = scene.dialogue
	check(not director.matches({"min_bond":60,"lines":[{}]},{"bond":59}) and director.matches({"min_bond":60,"lines":[{}]},{"bond":60}),"Special conversations enforce their actual relationship requirement")
	var old: float = j.bond
	director.topics = [{"id":"journey_cancel","lines":[{"speaker":0,"text":"Uma conversa."}]}]
	director.start(scene.dialogue_context()); director.cancel(); check(j.bond==old,"Cancelled conversations do not award completion progress")
	director.start(scene.dialogue_context()); director.advance(); check(j.bond==old+2,"Completing the actual dialogue awards bonding")
	# Listening requires time together at an actual active source, not a menu click.
	scene.day_cycle.minutes = 1360; world.nightlife.synchronize(scene.day_cycle)
	pair(world.nightlife.center+Vector2(0,200)); world.nightlife.step(0,scene.day_cycle)
	j.listening.clear(); j.daily.clear(); j.awarded.clear()
	j.step(44.8)
	var music_key := str(scene.day_cycle.day)+":music"
	check(float(j.daily.get(music_key,0))==0,"A brief stop at the bar is not a completed music moment")
	j.step(.3); check(float(j.daily.get(music_key,0))==3,"Forty-five seconds together listening to the actual night bar grants bonding")
	j.step(90); check(float(j.daily.get(music_key,0))==3,"Leaving a music loop running cannot repeatedly grant its reward")
	scene.day_cycle.minutes = 1175; world.festival_life.synchronize(scene.day_cycle,true)
	pair(world.festival_life.event_props.cinema.position+Vector2(-180,150)); j.listening.clear()
	j.step(14.8)
	var movie_key := str(scene.day_cycle.day)+":cinema"
	check(float(j.daily.get(movie_key,0))==0,"Cinema requires a real joint viewing interval")
	j.step(.3); check(float(j.daily.get(movie_key,0))==4,"Fifteen seconds together within the real 24-second screening grants its single daily reward")
	world.living_life.audio.stop(); world.living_life.audio.stream = null
	# Round-trip the real JSON writer, complete inventory and common clock in a unique temporary file.
	j.bond = 63; j.coins = 1755; j.needs[0].hunger = 37; te.inventory.items.clear(); te.inventory.try_add(Catalog.item(4))
	scene.day_cycle.day = 4; scene.day_cycle.minutes = 1182
	j.storage_enabled = true; j.save_path = "/tmp/tejo-journey-test-"+str(OS.get_process_id())+".json"
	check(j.save_state(),"Atomic journey save writes successfully")
	j.bond = 0; j.coins = 0; te.inventory.items.clear(); j.needs[0].hunger = 100
	check(j.load_state(),"Saved journey loads")
	check(j.bond==63 and j.coins==1755 and j.needs[0].hunger==37 and te.inventory.items.size()==1 and scene.day_cycle.day==4 and scene.day_cycle.minutes==1182,"Reload preserves bonding, each need, wallet, food bag and exact common clock")
	world.living_life.loaded_items_pending = true; world.living_life.storage_enabled = true; world.living_life.state.bags = {"Te":[Catalog.item(4)]}
	world.living_life._restore_bags(); world.living_life.storage_enabled = false
	check(te.inventory.items.size()==1,"Legacy community restore cannot duplicate or replace the complete saved bags")
	check(not j.restore({"version":1,"needs":[]}),"Malformed save does not overwrite live progress")
	DirAccess.remove_absolute(j.save_path); j.storage_enabled = false
	# Explicit sleep can use clear paving; ambient idle still keeps out of busy streets.
	world.manual_street_rest = true
	var sleeping_spot := Vector2.INF
	for plaza in world.plazas:
		if plaza.get("surface","")=="earth": continue
		var at: Vector2 = plaza.rect.get_center()
		for dx in [-150.0,0.0,150.0]:
			var candidate := at+Vector2(dx,0)
			if scene._ground_rest_clear(candidate) and scene._ground_rest_clear(candidate+Vector2(132,0)): sleeping_spot = candidate; break
		if sleeping_spot!=Vector2.INF: break
	check(sleeping_spot!=Vector2.INF,"At least one actual paved square has space for two sleeping bodies")
	if sleeping_spot!=Vector2.INF:
		for i in 2: scene.people[i].stand_up(true); scene.people[i].position = sleeping_spot+Vector2(i*132,0)
		world.manual_street_rest = false; scene._request_sleep()
		check(te.ground_rest and jo.ground_rest and world.manual_street_rest,"The real Sleep action reserves both places on the street without teleporting")
		for p in scene.people: p.stand_up(true)
		scene.sleep_requested = false; scene._update_ground_rest(0)
		check(not world.manual_street_rest,"Manual street sleep permission clears after getting up")
		j.daily.clear(); j.awarded.clear(); j.meters_together = 0
		j.last_positions.assign([te.position,jo.position]); j.step(120)
		var walk_key := str(scene.day_cycle.day)+":walk"
		check(float(j.daily.get(walk_key,0))==0,"Merely standing together cannot farm walking progress")
		for leg in 16:
			for step in 8:
				for p in scene.people: p.moving = true; p.move_and_collide(Vector2(10 if leg%2==0 else -10,0))
				j.step(.1)
		check(float(j.daily.get(walk_key,0))>0,"Real collision-checked displacement by both people accumulates shared walking progress")
		for p in scene.people: p.moving = false
	te.inventory.items.clear(); te.inventory.try_add({"type":"festival_fruit","name":"Maçã da Dona Ana","porte":1})
	j.needs[0].hunger = 50; j.consume(0,0,0)
	check(j.needs[0].hunger==32,"Existing street fruit, sweets and ice creams also participate in the food system")
	for need in j.needs: need.hunger = 99; need.fatigue = 99
	j.step_needs(10000,scene.people); check(j.needs.all(func(n):return n.hunger==100 and n.fatigue==100),"Need bars remain bounded at 100")
	print("JOURNEY AUDIT: 8 products, independent needs, exact 4:1 recovery, physical purchases, eat/give/share, real minigame completion, relationship gates, no duplicate rewards, full save round-trip")
	scene.queue_free()
	for i in 8: await physics_frame
	if not failed: print("PASS: shared journey, bakery transactions, needs, progression, controls and persistence")
	quit(1 if failed else 0)
