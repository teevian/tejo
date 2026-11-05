extends SceneTree
const FootballArt = preload("res://scripts/football_art.gd")
var scene: Node2D
var world: Node2D
var life: Node2D
var failed := false
func _initialize() -> void:
	create_timer(300,true,false,true).timeout.connect(func(): push_error("Festival test timed out"); quit(2))
	call_deferred("run")
func check(ok: bool,message: String) -> void:
	if not ok: failed = true; push_error(message)
func at_time(minute: float) -> void:
	scene.day_cycle.minutes = minute
	world.synchronize_clock(scene.day_cycle,true)
func tick(seconds: float, advance := true) -> void:
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
	life = world.festival_life
	for player in scene.people:
		player.set_physics_process(false)
		player.cancel_sand_drawing(false)
		player.position = Vector2(1500,14000)
	check(life.residents.size()==50 and world.social_life.actors.size()==145+world.passers.residents.size(),"Exactly fifty new persistent people join the previous forty-five")
	var ids: Dictionary = {}
	var tourists := 0
	for actor in life.residents:
		check(not ids.has(actor.entry.id),"Each additional person has a unique identity")
		ids[actor.entry.id] = true
		check(not actor.entry.purpose.is_empty() and actor.schedule.size()>=7 and actor.motion.personality.lines.size()>=2,"Individual purpose, day and voice: "+actor.entry.id)
		if actor.entry.tourist: tourists += 1
		for block in actor.schedule:
			check(world.is_walkable(block.destination,12),"Daily appointment uses real reachable paving: "+actor.entry.id+" "+block.at)
			check(not world.find_path(world.menu_spawn,block.destination).is_empty(),"Daily appointment remains connected: "+actor.entry.id+" "+block.at)
			if block.mode=="inside": check(life.routines.doors.has(block.destination),"Meals and sleep use an actual door: "+actor.entry.id)
	check(tourists>=20,"Many more tourists are distributed through the city")
	check(life.vehicles.size()==3 and life.dogs.size()==1 and life.event_props.size()==8,"Two tuk-tuks, horse/cart, leashed dog and eight activity installations exist")
	at_time(680)
	var covered := 0
	for plaza in world.plazas:
		if plaza.id=="palace_arcade": continue
		var nearby: Array = world.social_life.actors.filter(func(a): return a.available() and a.position.distance_to(plaza.rect.get_center())<1100)
		if nearby.size()>0: covered += 1
	check(covered>=11,"People occupy the remote squares as well as the central town: "+str(covered))
	var player: CharacterBody2D = scene.people[0]
	var before: int = player.inventory.items.size()
	check(life.interact_event("fruit",player).contains("Dona Ana"),"The fruit vendor actually serves fruit")
	check(player.inventory.items.size()==before+1 and player.inventory.items[-1].type=="festival_fruit","Bought fruit goes into the real inventory")
	life.interact_event("sweets",player)
	check(player.inventory.items[-1].type=="festival_sweets","The sweet trailer serves a real pastry")
	while player.inventory.can_add({"porte":1}): player.inventory.try_add({"type":"festival_fruit","name":"Teste","porte":1})
	var sold: int = life.sales.get("fruit0",0)
	life.interact_event("fruit",player)
	check(life.sales.get("fruit0",0)==sold,"Full inventory prevents a false fruit sale")
	player.inventory.items.clear()
	at_time(1160)
	check(not life.cinema_open(),"Cinema is advertised before the film starts")
	at_time(1180)
	check(life.cinema_open(),"First scheduled film session is actually playing")
	var audience: Array = life.residents.filter(func(a): return a.entry.role=="cinema" and a.available() and a.state=="activity" and a.appointment.place=="cinema")
	check(audience.size()==10,"Ten actual people reach their seats at the outdoor cinema")
	await tick(2,false)
	check(audience.all(func(a): return a.frame<2 and a.motion.phase=="watch"),"Seated filmgoers use their authored sitting/reaction poses")
	world.hide()
	check(not life.movie_layer.visible,"Cinema projection cannot leak into the forest when the village is hidden")
	world.show()
	check(life.movie_layer.visible,"Projection resumes with the actual village")
	at_time(1200)
	check(not life.cinema_open(),"There is a real interval between advertised sessions")
	at_time(1235)
	check(life.cinema_open(),"The next scheduled cinema session starts")
	# Road vehicles travel on wide routes; the talkative driver actually sees us.
	at_time(680)
	var to: CharacterBody2D = life.vehicles[0]
	player.controlled = true
	player.moving = true
	player.position = world.interactions.find_drop_position(to.position+Vector2(0,190))
	var conversations: int = to.conversation_count
	await tick(2,false)
	check(to.conversation_count>conversations and to.wait>0,"Tó sees us walking, stops nearby and starts a conversation")
	check(to.driver.social_line.length()>0,"The driver's automatic conversation is visible without a modal interruption")
	player.moving = false
	player.position = Vector2(1500,14000)
	var positions: Dictionary = {}
	var distances: Array = life.vehicles.map(func(v): return v.distance_travelled)
	for actor in world.social_life.actors: positions[actor.entry.id] = actor.position
	for i in 240:
		scene.day_cycle.advance(.25)
		world.step_environment(.25,scene.day_cycle)
		await physics_frame
		for actor in world.social_life.actors:
			check(actor.position.distance_to(positions[actor.entry.id])<100,"No additional person or driver teleports during normal life: "+actor.entry.id)
			positions[actor.entry.id] = actor.position
			if actor.available(): check(world.is_walkable(actor.position,9),"All residents remain on public floor: "+actor.entry.id)
		for vehicle in life.vehicles:
			if vehicle.boarded: check(world.is_walkable(vehicle.position,vehicle.margin-2),"Vehicle keeps its whole ground footprint out of buildings")
	check(life.vehicles.any(func(v): return v.distance_travelled>400),"Tours involve real driving, not stationary scenery")
	check(life.dogs[0].travelled>50 and world.is_walkable(life.dogs[0].position,8),"Bolacha actually follows her owner over reachable paving")
	# Player championship score comes only from physical contacts in the existing game.
	at_time(1050)
	scene._select_person(1)
	var jo: CharacterBody2D = scene.people[1]
	jo.position = world.population.free_point(life.event_props.score.position+Vector2(160,95))
	jo.stand_up(true)
	jo.cancel_sand_drawing(false)
	jo.football_action = ""
	life.interact_event("score",jo)
	check(life.ball.juggling.active() and life.round_owner==jo,"Jo can enter the actual championship")
	for i in 60: life.ball.step_ball(1.0/120)
	for touch in 9:
		var point: Vector2 = FootballArt.contact("foot",touch%3)
		life.ball.position = jo.position+Vector2(point.x,0)
		life.ball.juggling.height = -point.y
		life.ball.juggling.vertical_speed = 0
		life.ball.ball_velocity = Vector2.ZERO
		life.ball.juggling.request_touch()
		for i in 48: life.ball.step_ball(1.0/120)
	life.ball.juggling.height = 2
	life.ball.juggling.vertical_speed = -100
	for i in 12: life.ball.step_ball(1.0/120)
	world.step_environment(.01,scene.day_cycle)
	var result: Array = life.ranking.filter(func(row): return row.name=="Jo")
	check(not result.is_empty() and result[0].score==9,"Leaderboard records nine real contacts, not key presses")
	check(life.pending_medals.has(1),"A qualifying real round earns a prize")
	life.interact_event("score",jo)
	check(jo.inventory.items.any(func(item): return item.type=="festival_medal"),"The earned medal can be collected in the real bag")
	await tick(60,false)
	check(life.ranking.any(func(row): return row.name in ["Hugo","Salma","Bento"] and row.score>0),"NPC competitors take turns and complete visible attempts")
	at_time(180)
	check(life.residents.all(func(a): return a.state=="inside" and not a.available()),"All fifty people still go indoors to sleep")
	check(life.vehicles.all(func(v): return not v.visible and not v.boarded) and not life.dogs[0].visible,"Tours and dog walks end overnight")
	# Regression: a legal paving junction rejected the route's generous smoothing
	# margin and could strand the cobbler on his way home for the whole night.
	var cobbler: CharacterBody2D = life.by_id.zeca_sapateiro
	cobbler.position = Vector2(10162.93,11027.08)
	cobbler._outside()
	cobbler.anchor = cobbler.appointment.destination
	cobbler._begin_walk(cobbler.anchor,"commuting")
	for i in 120:
		var from: Vector2 = cobbler.position
		cobbler.step(.25,scene.day_cycle)
		await physics_frame
		check(cobbler.position.distance_to(from)<40,"Recovering at a paving junction still uses real, bounded steps")
		if cobbler.state=="inside": break
	check(cobbler.state=="inside","The cobbler passes the formerly blocking junction and reaches home")
	print("New residents: ",life.residents.size(),"; tourists: ",tourists,"; inhabited plazas: ",covered,"; leaderboard: ",life.ranking)
	scene.queue_free()
	for i in 4: await physics_frame
	if not failed: print("PASS: fifty lives, wider coverage, shopping, seated scheduled cinema, actual tours/driver conversations, dog walking, real championship contacts/prizes and overnight rest")
	quit(1 if failed else 0)
