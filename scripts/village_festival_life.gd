extends "res://scripts/village_population.gd"
## Fifty additional persistent lives, local activities, real shopping and competition.
const DATA = preload("res://data/village/festival-life.json")
const Actor = preload("res://scripts/village_festival_actor.gd")
var event_props: Dictionary = {}
var vehicles: Array[CharacterBody2D] = []
var dogs: Array[CharacterBody2D] = []
var minute := 0.0
var day := 1
var sales: Dictionary = {}
var ranking: Array[Dictionary] = []
var ball: Node2D
var round_owner: CharacterBody2D
var npc_round: CharacterBody2D
var npc_touches := 0
var npc_target := 0
var npc_clock := 0.0
var next_match := 8.0
var match_index := 0
var pending_medals: Dictionary = {}
var trader_clock := 5.0
var notices: Array[String] = []
var coverage: Dictionary = {}
var traffic_grids: Dictionary = {}
var movie_layer: CanvasLayer
var explore_clock := 9.0
var explorer_cooldowns: Dictionary = {}
var exploratory_walks := 0

func _ready() -> void:
	name = "FiftyNewLivesAndActivities"
	routines.population = self
	by_id.merge(world.population.by_id)
	by_id.merge(world.street_life.by_id)
	for i in DATA.data.people.size():
		var e: Dictionary = DATA.data.people[i]
		var actor := Actor.new()
		actor.population = self
		actor.entry = e
		actor.ordinal = i+50
		actor.name = e.id
		actor.home = free_point(Vector2(e.home[0],e.home[1]),true)
		actor.position = actor.home
		actor.anchor = actor.home
		actor.profile = {"residence":"hotel" if e.tourist else "local","commute_speed":110 if e.age>=65 else 135}
		if e.has("guardian"): actor.profile.guardian = e.guardian
		world.actors.add_child(actor)
		residents.append(actor)
		by_id[e.id] = actor
		world.interactions.targets.append({"id":"festival_person_"+e.id,"kind":"resident","label":e.name,"position":actor.position,"reach":155.0,"radius":12.0,"node":actor})
	for object in world.festival_props:
		object.director = self
		event_props[object.kind] = object
		world.interactions.targets.append({"id":"festival_event_"+object.kind,"kind":"street_scene","label":object.kind,"position":object.position+Vector2(0,35),"reach":155.0,"radius":0.0,"node":object})
	for actor in residents:
		for authored in actor.entry.plan:
			var block: Dictionary = authored.duplicate(true)
			block.minute = routines.minute(block.at)
			block.destination = destination_for(actor,block.place)
			block.location = "casa" if block.place=="home" else ("Café" if block.place=="meal" else DATA.data.places[block.place].name)
			actor.schedule.append(block)
		if actor.profile.has("guardian"): by_id[actor.profile.guardian].dependants.append(actor)
		actor.prepare_stroll()
	for actor in residents:
		if actor.entry.has("vehicle"):
			var vehicle := preload("res://scripts/village_tour_vehicle.gd").new()
			vehicle.director = self
			vehicle.driver = actor
			vehicle.kind = actor.entry.vehicle
			vehicle.position = actor.home
			world.actors.add_child(vehicle)
			vehicles.append(vehicle)
			actor.ride = vehicle
			for block in actor.schedule:
				if block.mode!="inside": block.destination = vehicle.position
			world.interactions.targets.append({"id":"tour_vehicle_"+actor.entry.id,"kind":"street_scene","label":"Visita turística","position":vehicle.position,"reach":210.0,"radius":55.0,"node":vehicle})
		if actor.entry.has("dog"):
			var dog := preload("res://scripts/village_walking_dog.gd").new()
			dog.director = self
			dog.walker = actor
			world.actors.add_child(dog)
			dogs.append(dog)
			actor.companion_dog = dog
			world.interactions.targets.append({"id":"bolacha_walk","kind":"street_scene","label":"Bolacha","position":dog.position,"reach":100.0,"radius":12.0,"node":dog})
	ball = preload("res://scripts/discovery_prop.gd").new()
	ball.world = world
	ball.kind = 3
	ball.label = "Bola do campeonato de toques"
	ball.paint_height = 31
	ball.position = routines.clear_destination(event_props.score.position+Vector2(160,75),[])
	world.actors.add_child(ball)
	world.interactions.targets.append({"id":"festival_football","kind":"football","label":ball.label,"position":ball.position,"reach":110.0,"radius":0.0,"node":ball})
	movie_layer = CanvasLayer.new()
	movie_layer.layer = 4
	add_child(movie_layer)
	var projection := preload("res://scripts/village_movie_overlay.gd").new()
	projection.director = self
	movie_layer.add_child(projection)
	world.visibility_changed.connect(_projection_visibility)
	_projection_visibility()

func destination_for(actor: CharacterBody2D, place: String) -> Vector2:
	var key: String = actor.entry.id+":"+place
	if routines.appointments.has(key): return routines.appointments[key]
	var preferred: Vector2 = actor.home
	if place in ["home","meal"]:
		var shared: String = actor.profile.get("guardian",actor.entry.id)
		var home_actor: CharacterBody2D = by_id[shared]
		preferred = routines.doorway(home_actor.home+Vector2(220,0),place=="home","Café" if place=="meal" else "")
	else:
		var source: Array = DATA.data.places[place].at
		preferred = Vector2(source[0],source[1])
		var event: String = {"football":"score"}.get(place,place)
		if event_props.has(event):
			preferred = event_props[event].position+Vector2(120,40)
			if place=="cinema":
				var seat: int = actor.ordinal-60
				preferred = event_props.cinema.position+Vector2(-525+(posmod(seat,5))*84,-100+floori(seat/5.0)*120) if actor.entry.role=="cinema" else event_props.cinema.position+Vector2(80,40)
			elif place=="football": preferred += Vector2((int(actor.entry.column)-2)*90,100+actor.ordinal%2*85)
		else: preferred += Vector2((int(actor.entry.column)-2)*84,actor.ordinal%3*45)
		var occupied: Array = routines.reservations.get(place,[])
		preferred = routines.clear_destination(preferred,occupied)
		occupied.append(preferred)
		routines.reservations[place] = occupied
	routines.appointments[key] = preferred
	return preferred

func cinema_open() -> bool: return minute>=1170 and minute<1320 and fposmod(minute-1170,60)<24
func tournament_open() -> bool: return minute>=960 and minute<1170
func is_open(kind: String) -> bool:
	if kind=="cinema": return cinema_open()
	if kind=="score": return tournament_open()
	return minute>=540 and minute<1170 and not (minute>=750 and minute<840)

func synchronize(cycle: RefCounted, force := false) -> void:
	minute = cycle.minutes
	day = cycle.day
	if is_instance_valid(ball):
		ball.juggling.stop()
		ball.juggling.height = 0
		ball.juggling.vertical_speed = 0
		ball.ball_velocity = Vector2.ZERO
		ball.position = routines.clear_destination(event_props.score.position+Vector2(160,75),[])
	_clear_npc_match()
	round_owner = null
	super.synchronize(cycle,force)
	for vehicle in vehicles: vehicle.synchronize(cycle)
	for dog in dogs: dog.synchronize()
	_refresh_displays()

func step(delta: float, cycle: RefCounted) -> void:
	minute = cycle.minutes
	day = cycle.day
	super.step(delta,cycle)
	# Population already owns elapsed; keep one shared pause-aware timer.
	for vehicle in vehicles: vehicle.step(delta,cycle)
	for dog in dogs: dog.step(delta)
	ball.step_ball(delta)
	if ball.juggling.active() and round_owner==null and tournament_open():
		_clear_npc_match()
		round_owner = ball.juggling.owner
	elif round_owner!=null and not ball.juggling.active():
		_record(round_owner.name,ball.juggling.last_count,round_owner.kind)
		round_owner = null
	if tournament_open() and round_owner==null: _npc_match(delta)
	elif not tournament_open(): _clear_npc_match()
	trader_clock -= delta
	if trader_clock<=0:
		trader_clock = 8+float(match_index%5)
		_trade_between_people()
		_small_happening()
	explore_clock -= delta
	if explore_clock<=0:
		explore_clock = 16
		_explore_quiet_street()
	_refresh_displays()

func _refresh_displays() -> void:
	_projection_visibility()
	for child in movie_layer.get_children(): child.queue_redraw()
	for object in event_props.values():
		for child in object.get_children():
			if child is Node2D: child.queue_redraw()

func _projection_visibility() -> void:
	if is_instance_valid(movie_layer): movie_layer.visible = world.is_visible_in_tree() and cinema_open()

func _record(person: String, score: int, player_kind := -1) -> void:
	var found := false
	for row in ranking:
		if row.name==person:
			row.score = maxi(row.score,score)
			found = true
	if not found: ranking.append({"name":person,"score":score})
	ranking.sort_custom(func(a,b): return a.score>b.score)
	if player_kind>=0:
		var prize: String = "Prémio de Estilo" if player_kind==0 and score>=2 else ("Medalha de Toques" if score>=8 else "")
		if not prize.is_empty() and not sales.has("prize_"+str(player_kind)): pending_medals[player_kind] = prize
		for person_node in world.people:
			if person_node.kind==player_kind:
				for id in ["rafa_toques","lia_comentadora"]:
					var host: CharacterBody2D = by_id[id]
					world.social_life._say(host,person+": "+str(score)+" toques! "+("Grande tentativa!" if score<8 else "Novo candidato ao pódio!"),"speak")

func _clear_npc_match() -> void:
	if is_instance_valid(npc_round): npc_round.event_busy = false; npc_round.social_pose = ""
	npc_round = null
	npc_touches = 0
	npc_clock = 0

func _npc_match(delta: float) -> void:
	if npc_round==null:
		next_match -= delta
		if next_match>0: return
		var id: String = ["hugo_toques","salma_toques","bento_toques"][match_index%3]
		var athlete: CharacterBody2D = by_id[id]
		if not athlete.available() or athlete.state!="activity" or athlete.encounter_id>=0 or athlete.position.distance_to(event_props.score.position)>600: next_match = 3; return
		npc_round = athlete
		athlete.event_busy = true
		npc_target = [5,11,7,8,14,9][match_index%6]
		match_index += 1
		npc_clock = 0
		npc_touches = 0
		world.social_life._say(by_id.lia_comentadora,athlete.entry.name+" vai tentar o seu recorde!","speak")
	else:
		if not npc_round.available() or npc_round.appointment.place!="football": _clear_npc_match(); return
		npc_clock += delta
		npc_round.frame = 1 if fposmod(npc_clock,1.1)<.36 else 0
		npc_round.motion.extra = -1
		npc_round.art.queue_redraw()
		if npc_clock>=1.1:
			npc_clock -= 1.1
			npc_touches += 1
			if npc_touches>=npc_target:
				_record(npc_round.entry.name,npc_touches)
				world.social_life._say(by_id.filipe_arbitro,str(npc_touches)+" toques, resultado confirmado!","speak")
				_clear_npc_match()
				next_match = 12

func interact_event(kind: String, player: CharacterBody2D) -> String:
	if kind=="cinema": return "Cinema nas Hortênsias: O elétrico e a lua, uma curta original. Sessões às 19h30, 20h30 e 21h30; entrada livre. Os lugares estão à esquerda do ecrã."
	if kind=="score":
		if player==null: return "Campeonato de toques, das 16h às 19h30. Contamos os contactos reais com a bola."
		if pending_medals.has(player.kind):
			var title: String = pending_medals[player.kind]
			if not player.inventory.try_add({"type":"festival_medal","name":title,"porte":1}): return "O teu prémio está guardado. Liberta um espaço na bolsa para o receber."
			pending_medals.erase(player.kind)
			sales["prize_"+str(player.kind)] = true
			return player.name+" recebeu: "+title+"!"
		if not tournament_open(): return "O campeonato começa às 16h e termina às 19h30. Podes treinar junto à bola."
		if ball.juggling.active() or ball.juggling.height>10: return "Espera que a bola termine esta tentativa."
		var point: Vector2 = world.interactions.find_drop_position(player.position+Vector2(35,0),player.position)
		if point==Vector2.INF: return "Avança para o espaço livre ao lado do quadro, para começares a tentativa."
		ball.position = point
		ball.ball_velocity = Vector2.ZERO
		_clear_npc_match()
		if not ball.juggling.start(player): return "Aproxima-te da bola no chão."
		round_owner = player
		return "Valem os toques reais: Setas para acompanhar, Espaço no momento certo. O Te concorre também ao Prémio de Estilo pelos seus dois toques e remate inesperado!"
	if kind in ["fruit","sweets","flowers"]:
		var host_id: String = {"fruit":"ana_fruta","sweets":"quim_doces","flowers":"rita_flores"}[kind]
		var host: CharacterBody2D = by_id[host_id]
		if not is_open(kind) or not host.available() or host.state=="commuting": return "A banca abre das 9h às 19h30, com pausa para almoço das 12h30 às 14h."
		if player==null: return host.entry.greeting
		var index: int = sales.get(kind+str(player.kind),0)
		var names: Array = {"fruit":["Maçã da Dona Ana","Laranja da Dona Ana","Pêra da Dona Ana"],"sweets":["Fartura do Quim","Queijada do Quim","Doce de canela do Quim"],"flowers":["Flor da Rita"]}[kind]
		var item := {"type":"festival_"+kind,"name":names[index%names.size()],"porte":1,"variant":index%names.size()}
		if not player.inventory.try_add(item): return "Liberta um espaço na bolsa antes de levar a tua escolha."
		sales[kind+str(player.kind)] = index+1
		return player.name+" levou "+str(item.name).to_lower()+". "+host.entry.name+" deseja um bom passeio!"
	if kind=="chess":
		if not is_open(kind) or not by_id.idalina_xadrez.available(): return "A Idalina volta ao tabuleiro depois do descanso. Fica um problema de xadrez para experimentar."
		var turn: int = sales.get("chess",0)
		sales.chess = turn+1
		world.social_life._say(by_id.idalina_xadrez,["Boa abertura! Agora repara no meu cavalo…","Esse peão veio visitar o centro do tabuleiro.","Xeque! Mas ainda tens uma boa saída."][turn%3],"speak")
		return "Idalina convida os dois para um problema de xadrez: encontrar a saída do xeque. Ela mostra a resposta com um sorriso."
	if kind=="results":
		if ranking.is_empty(): return "Ainda não há resultados. As tentativas começam às 16h, e contam os contactos reais com a bola."
		var lines: Array[String] = []
		for row in ranking.slice(0,5): lines.append(str(row.name)+": "+str(row.score))
		return "Classificação dos toques — "+" · ".join(lines)+". Há sempre espaço para tentar outra vez!"
	if kind=="poetry":
		var poems: Array = ["Entre a pedra e o céu / uma rua devagar / cabe o dia inteiro.","O vento perde o mapa / e encontra uma varanda / onde ficar.","Uma fonte conta o tempo / sem relógio / nem pressa."]
		var i: int = sales.get("poem",0)
		sales.poem = i+1
		return ("Emmanuel lê: «" if by_id.emmanuel_poeta.available() and by_id.emmanuel_poeta.position.distance_to(event_props.poetry.position)<500 else "Num papel da banca, lê-se: «")+str(poems[i%poems.size()])+"»"
	return "Susana afina uma roda, enche um pneu e avisa: nas descidas de Sintra, os travões merecem respeito." if by_id.susana_bicicletas.available() and by_id.susana_bicicletas.position.distance_to(event_props.bicycle.position)<450 else "Uma bicicleta e ferramentas esperam pela próxima reparação."

func _trade_between_people() -> void:
	if not is_instance_valid(world.social_life): return
	var social: Node2D = world.social_life
	if social.encounters.size()>=12: return
	for kind in ["fruit","sweets"]:
		if not is_open(kind): continue
		var host: CharacterBody2D = by_id["ana_fruta" if kind=="fruit" else "quim_doces"]
		if not social._eligible(host,25): continue
		for client in social.actors:
			if client==host or not social._eligible(client,30) or social._is_grouped(client) or social._working(client) or int(client.entry.age)<13: continue
			if client.position.distance_to(host.position)>650 or (day-1)*1440.0+minute<float(client.memory.get("snack_"+kind,-INF)): continue
			if social._start(kind,[client,host],host.position): return

func _small_happening() -> void:
	var social: Node2D = world.social_life
	if social.encounters.size()>=12 or minute<540 or minute>1170: return
	for pair in [["cris_magia","magic"],["emmanuel_poeta","poetry"],["idalina_xadrez","chess"]]:
		var host: CharacterBody2D = by_id[pair[0]]
		if not social._eligible(host,25): continue
		for visitor in social.actors:
			if visitor==host or int(visitor.entry.age)<13 or not social._eligible(visitor,25) or social._is_grouped(visitor) or social._working(visitor): continue
			if visitor.position.distance_to(host.position)<420 and social._start(pair[1],[visitor,host],host.position): return

func _explore_quiet_street() -> void:
	if is_instance_valid(world.get("neighbourhood")): return
	if minute<540 or minute>1330: return
	var social: Node2D = world.social_life
	var now: float = (day-1)*1440.0+minute
	var candidates: Array[Vector2] = []
	for key in DATA.data.places:
		if key in ["cinema","fruit","sweets","football","chess","flowers"]: continue
		var at: Array = DATA.data.places[key].at
		candidates.append(Vector2(at[0],at[1]))
	for road in world.ground_segments:
		if road.surface!="earth": candidates.append(road.a.lerp(road.b,.5))
	var visitors: Array = residents.duplicate()
	visitors.shuffle()
	for actor in visitors:
		if not actor.entry.tourist or actor.entry.role=="cinema" or actor.profile.has("guardian") or not social._eligible(actor,70): continue
		if now<float(explorer_cooldowns.get(actor.entry.id,-INF)) or actor.motion.rng.randf()>float(actor.motion.personality.curiosity)*.7: continue
		var local: int = social.actors.filter(func(a): return a.available() and a.position.distance_to(actor.position)<750).size()
		if local<3: continue
		var best := Vector2.INF
		var score := INF
		for point in candidates:
			var distance: float = point.distance_to(actor.position)
			if distance<500 or distance>3300 or not world.is_walkable(point,22): continue
			var people: int = social.actors.filter(func(a): return a.available() and a.position.distance_to(point)<650).size()
			var value: float = people*8+distance/1200
			if value<score: score = value; best = point
		if best==Vector2.INF: continue
		best = routines.clear_destination(best,[])
		if world.find_path(actor.position,best).is_empty(): continue
		actor.anchor = best
		actor.appointment.destination = best
		actor.appointment.location = world.area_at(best)
		actor.prepare_stroll()
		if actor._begin_walk(best,"commuting"):
			explorer_cooldowns[actor.entry.id] = now+100
			exploratory_walks += 1
			return
