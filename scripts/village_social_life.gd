extends Node2D
## Autonomous, interruptible encounters. Decisions do not depend on the camera/player.
var world: Node2D
var actors: Array[CharacterBody2D] = []
var by_id: Dictionary = {}
var encounters: Array[Dictionary] = []
var history: Array[Dictionary] = []
var stats: Dictionary = {}
var cooldowns: Dictionary = {}
var rng := RandomNumberGenerator.new()
var elapsed := 0.0
var now := 0.0
var last_time := -INF
var next_decision := 1.0
var serial := 0
var concert_cue := -INF

func _ready() -> void:
	name = "AutonomousVillageEncounters"
	rng.seed = 11032026
	actors.assign(world.population.residents+world.street_life.residents+world.festival_life.residents+world.living_life.residents)
	for actor in actors: by_id[actor.entry.id] = actor

func reset(cycle: RefCounted) -> void:
	for event in encounters.duplicate(): _finish(event,false,"time")
	for actor in actors:
		actor.social_line = ""
		actor.social_pose = ""
		actor.snack_until = 0
	now = (cycle.day-1)*1440.0+cycle.minutes
	last_time = now
	next_decision = 1.5
	queue_redraw()

func step(delta: float, cycle: RefCounted) -> void:
	elapsed += delta
	now = (cycle.day-1)*1440.0+cycle.minutes
	if absf(now-last_time)>5: reset(cycle)
	last_time = now
	queue_redraw()
	for actor in actors:
		if actor.speech_until<actor.clock:
			actor.social_line = ""
			if actor.encounter_id<0: actor.social_pose = ""
	for event in encounters.duplicate(): _advance(event,delta)
	next_decision -= delta
	if next_decision>0 or encounters.size()>=12: return
	next_decision = rng.randf_range(1.2,2.4)
	if cycle.minutes<465 or cycle.minutes>1365: return
	if _photo() or _service("gelato") or _service("raffle") or _delivery() or _guided_stop() or _concert() or _directions() or _window_shopping(): return
	if not _chat(): _curiosity()

func _eligible(actor: CharacterBody2D, budget := 30.0) -> bool:
	# The bar owns its small conversations and dance partners, including after midnight.
	if actor.appointment.get("place","")=="nightlife": return false
	if actor.get("story_reserved")==true: return false
	var errand: Variant = actor.get("delivery_mode")
	if (errand is String and not str(errand).is_empty()) or actor.get_meta("seeking_bench",false): return false
	if actor.event_busy or (actor.entry.get("role","")=="cinema" and actor.appointment.get("place","")=="cinema" and fposmod(now,1440)>=1140 and fposmod(now,1440)<1320): return false
	if not actor.available() or actor.encounter_id>=0 or actor.greet_time>0 or actor.state not in ["activity","walking"]: return false
	if now<float(cooldowns.get(actor.entry.id,-INF)): return false
	if actor.appointment.get("mode","")=="inside": return false
	var next: Dictionary = actor.schedule[(actor.routine_index+1)%actor.schedule.size()]
	var left := fposmod(float(next.minute)-fposmod(now,1440),1440)
	return left>budget+12

func _is_grouped(actor: CharacterBody2D) -> bool:
	var place: String = actor.appointment.get("place","")
	return actor.profile.has("guardian") or place.begins_with("guide_") or place.begins_with("family_") or not actor.dependants.is_empty()

func _working(actor: CharacterBody2D) -> bool:
	return actor.motion.personality.style in ["gelato","raffle","leader","pottery","fruit","textile","painting","bread","guitar","violin"]

func _chat() -> bool:
	var available: Array = actors.filter(func(a): return _eligible(a,18) and int(a.entry.age)>=13 and not _is_grouped(a) and not _working(a))
	available.shuffle()
	for a in available:
		if rng.randf()>float(a.motion.personality.sociability): continue
		var candidates: Array = actors.filter(func(b): return b!=a and _eligible(b,18) and int(b.entry.age)>=13 and not _is_grouped(b) and not _working(b) and a.position.distance_to(b.position)<320)
		candidates.sort_custom(func(b,c): return _affinity(a,b)>_affinity(a,c))
		for b in candidates:
			if _start("chat",[a,b],b.position): return true
	return false

func _affinity(a: CharacterBody2D, b: CharacterBody2D) -> float:
	return (200.0 if a.motion.personality.friends.has(b.entry.id) else 0.0)+float(a.memory.get("met_"+b.entry.id,0))*10-a.position.distance_to(b.position)*.2

func _service(kind: String) -> bool:
	var open: bool = world.street_life.is_open("icecream" if kind=="gelato" else "raffles")
	if not open: return false
	var hosts: Array = [by_id.enzo_gelados] if kind=="gelato" else [by_id.ines_escuteira,by_id.pedro_escuteiro]
	var free_hosts: Array = hosts.filter(func(a): return _eligible(a,20) and a.position.distance_to(a.anchor)<40)
	if free_hosts.is_empty(): return false
	var host: CharacterBody2D = free_hosts[rng.randi_range(0,free_hosts.size()-1)]
	var clients: Array = actors.filter(func(a): return a!=host and _eligible(a,22+a.position.distance_to(host.position)/maxf(40,float(a.entry.speed))) and int(a.entry.age)>=13 and not _working(a) and not _is_grouped(a) and a.position.distance_to(host.position)<1050)
	clients.shuffle()
	for client in clients:
		if kind=="raffle" and client.memory.get("raffle_day",-1)==floori(now/1440): continue
		if kind=="gelato" and now<float(client.memory.get("next_snack",-INF)): continue
		if rng.randf()>float(client.motion.personality.curiosity)*.85: continue
		if _start(kind,[client,host],host.position): return true
	return false

func _delivery() -> bool:
	var courier: CharacterBody2D = by_id.joao
	if not _eligible(courier,50): return false
	for id in ["nuno","luis","samira","fatima"]:
		var shopkeeper: CharacterBody2D = by_id[id]
		if _eligible(shopkeeper,50) and courier.position.distance_to(shopkeeper.position)<750:
			return _start("delivery",[courier,shopkeeper],shopkeeper.position)
	return false

func _photo() -> bool:
	var photographer: CharacterBody2D = by_id.leonor
	var child: CharacterBody2D = by_id.matilde
	var father: CharacterBody2D = by_id.daniel_familia
	if _eligible(photographer,18) and _eligible(child,18) and _eligible(father,18) and photographer.position.distance_to(child.position)<260 and photographer.position.distance_to(father.position)<300:
		return _start("family_photo",[photographer,father,child],photographer.position,false)
	for id in ["alexandre","harry_kane","yuki"]:
		var camera: CharacterBody2D = by_id[id]
		if not _eligible(camera,18) or _is_grouped(camera): continue
		for subject in actors:
			if subject==camera or not _eligible(subject,18) or _is_grouped(subject) or _working(subject) or int(subject.entry.age)<13: continue
			if camera.position.distance_to(subject.position)<240 and rng.randf()<.18:
				return _start("photo",[camera,subject],camera.position,false)
	return false

func _guided_stop() -> bool:
	var guide: CharacterBody2D = by_id.teresa
	if not _eligible(guide,15): return false
	var group: Array = [guide]
	for id in ["oliver_turista","helena_turista","mariana_montras"]:
		var visitor: CharacterBody2D = by_id[id]
		if _eligible(visitor,15) and str(visitor.appointment.place).begins_with("guide_") and visitor.position.distance_to(guide.position)<370: group.append(visitor)
	if group.size()<3: return false
	return _start("guide",group,guide.position,false)

func _concert() -> bool:
	if not world.street_life.is_open("concert") or now-concert_cue<28: return false
	var guitar: CharacterBody2D = by_id.farid
	var violin: CharacterBody2D = by_id.clara_violinista
	if not guitar.available() or not violin.available() or guitar.position.distance_to(violin.position)>350: return false
	var audience: Array = actors.filter(func(a): return a!=guitar and a!=violin and _eligible(a,12) and a.position.distance_to(guitar.position)<600 and not _is_grouped(a))
	if audience.size()>=2:
		audience.sort_custom(func(a,b): return a.position.distance_to(guitar.position)<b.position.distance_to(guitar.position))
		if _start("applause",audience.slice(0,mini(4,audience.size())),guitar.position,false): concert_cue = now; return true
	if _eligible(guitar,9) and _eligible(violin,9):
		if _start("duet",[guitar,violin],guitar.position,false): concert_cue = now; return true
	return false

func _curiosity() -> void:
	var choices: Array = actors.filter(func(a): return _eligible(a,12) and a.state=="activity" and not _working(a) and not _is_grouped(a))
	choices.shuffle()
	for actor in choices:
		if rng.randf()>float(actor.motion.personality.curiosity)*.45: continue
		var line: String = actor.motion.personality.lines[rng.randi_range(0,actor.motion.personality.lines.size()-1)]
		_say(actor,line,"observe")
		cooldowns[actor.entry.id] = now+rng.randf_range(25,55)
		if rng.randf()<float(actor.motion.personality.restlessness):
			var desired: Vector2 = actor.anchor+Vector2.from_angle(rng.randf()*TAU)*rng.randf_range(50,130)
			var at: Vector2 = actor.population.clear_stroll_point(actor,desired)
			if at!=Vector2.INF: actor._begin_walk(at,"walking")
		break

func _directions() -> bool:
	var officer: CharacterBody2D = by_id.sofia_policia
	if not _eligible(officer,25): return false
	for id in ["amadou","ravi","yuki","harry_kane","tiago"]:
		var visitor: CharacterBody2D = by_id[id]
		if _eligible(visitor,35) and not _is_grouped(visitor) and visitor.position.distance_to(officer.position)<420:
			return _start("directions",[visitor,officer],officer.position)
	return false

func _window_shopping() -> bool:
	var shopper: CharacterBody2D = by_id.mariana_montras
	if not _eligible(shopper,20) or not str(shopper.appointment.place).begins_with("window_"): return false
	for visitor in actors:
		if visitor!=shopper and int(visitor.entry.age)>=13 and _eligible(visitor,20) and not _is_grouped(visitor) and not _working(visitor) and visitor.position.distance_to(shopper.position)<240:
			return _start("window",[visitor,shopper],shopper.position)
	return false

func _meeting_spot(visitor: CharacterBody2D, host: CharacterBody2D) -> Vector2:
	var angle := host.position.direction_to(visitor.position).angle()
	# Keep the gelato handover on the clear side of the canopy, away from the house.
	if host.entry.get("role","")=="gelato": angle = -.25
	elif host.entry.get("role","")=="scout": angle = PI*.5
	for radius in [95.0,135.0,185.0]:
		for turn in [0.0,.5,-.5,1.0,-1.0,1.5,-1.5,PI]:
			var at: Vector2 = host.position+Vector2.from_angle(angle+turn)*radius
			if host.entry.get("role","")=="gelato" and at.x<host.position.x+50: continue
			if not world.is_walkable(at,22): continue
			if actors.any(func(a): return a!=visitor and a!=host and a.visible and a.position.distance_to(at)<62): continue
			if not world.population.routines.clear_paint(at): continue
			var ray := PhysicsRayQueryParameters2D.create(at,host.position,1)
			var hit: Dictionary = world.get_world_2d().direct_space_state.intersect_ray(ray)
			if not hit.is_empty():
				var body: Object = hit.collider
				if not body.has_meta("street_kind") and not body.has_meta("festival_counter") and body not in world.activity_props: continue
			if not world.find_path(visitor.position,at).is_empty(): return at
	return Vector2.INF

func _start(kind: String, people: Array, focus: Vector2, approach := true) -> bool:
	if people.size()<2: return false
	for actor in people:
		if not _eligible(actor,15): return false
	var destination: Vector2 = people[0].position
	if approach:
		destination = _meeting_spot(people[0],people[1])
		if destination==Vector2.INF: return false
	serial += 1
	var event := {"id":serial,"kind":kind,"people":people,"phase":"approach" if approach else "scene","age":0.0,"remaining":0.0,"turn":-1,"focus":focus,"destination":destination,"lines":_lines(kind,people)}
	for actor in people:
		actor.encounter_id = serial
		actor.social_pose = "listen"
		actor.social_lock = true
		actor.velocity = Vector2.ZERO
		actor.route.clear()
		actor.state = "activity"
	if approach:
		people[0].social_lock = false
		people[0].social_pose = ""
		if people[0].position.distance_to(destination)>35 and not people[0]._begin_walk(destination,"walking"):
			for actor in people: _release(actor)
			return false
	encounters.append(event)
	return true

func _lines(kind: String, people: Array) -> Array:
	var a: CharacterBody2D = people[0]
	var b: CharacterBody2D = people[1]
	match kind:
		"gelato": return [[1,"Pistácio, morango ou stracciatella?","speak"],[0,["Hoje vou provar pistácio.","Morango, por favor!","Uma stracciatella para o passeio."][rng.randi_range(0,2)],"speak"],[1,"Aqui tens. Bom passeio!","offer"],[0,"Obrigado! Estava mesmo a apetecer.","thanks"]]
		"fruit": return [[1,"Olha que maçãs bonitas! Queres fruta para o caminho?","offer"],[0,"Quero sim. Uma maçã, por favor!","speak"],[1,"Aqui tens. Boa caminhada e volta sempre!","thanks"]]
		"sweets": return [[1,"Saíram agora estas farturas. Queres provar?","offer"],[0,"Com canela, por favor!","speak"],[1,"Aqui vai. Cuidado que ainda está quentinha!","thanks"]]
		"magic": return [[1,"Escolhe uma carta. Não a mostres aos meus bolsos!","speak"],[0,"Esta aqui. Agora quero ver como a descobres.","speak"],[1,"Era esta? Se não era, acabou de passar a ser!","offer"],[0,"Essa surpresa valeu a paragem!","thanks"]]
		"poetry": return [[1,"Entre a pedra e o céu, uma rua devagar cabe o dia inteiro.","speak"],[0,"Ficava aqui a ouvir mais um poema.","thanks"],[1,"O próximo vem com a próxima brisa.","speak"]]
		"chess": return [[1,"Se o cavalo vier aqui, onde fica o teu rei?","speak"],[0,"Preciso de pensar mais do que estava a contar!","speak"],[1,"Não há pressa. O melhor lance merece uma pausa.","thanks"]]
		"raffle": return [[1,"Uma rifa para a nossa atividade de Minecraft?","offer"],[0,"Claro! Quero ajudar a construção.","speak"],[1,"Aqui tens o teu número. Muito obrigado!","work"],[0,"Boa atividade, depois mostrem o resultado!","thanks"]]
		"delivery": return [[0,"Tenho uma encomenda para esta loja.","offer"],[1,"É a minha. Obrigado por a trazeres!","thanks"],[0,"Entrega confirmada. Até à próxima!","speak"]]
		"directions": return [[0,"Para chegar ao Palácio, sigo por aqui?","speak"],[1,"Sim, continuem pelo largo. A entrada fica à direita.","offer"],[0,"Obrigado pela ajuda. Bom serviço!","thanks"]]
		"window": return [[1,"Olha para o desenho daqueles azulejos.","speak"],[0,"São lindíssimos. Vamos ver mais de perto?","speak"],[1,"Gosto especialmente dos que foram pintados à mão.","thanks"]]
		"family_photo": return [[0,"Daniel, Matilde: fiquem aí um instante!","speak"],[2,"Assim? Vou fazer a minha melhor pose!","pose"],[0,"Olhem para aqui… já está!","capture"],[1,"Mostra lá como ficou.","speak"],[0,"Ficou mesmo bonita. Vamos guardá-la.","review"]]
		"photo": return [[0,"Posso tirar-te uma fotografia nesta luz?","speak"],[1,"Claro. Assim está bem?","pose"],[0,"Perfeito… já está!","capture"],[1,"Obrigado, depois quero vê-la.","thanks"]]
		"guide": return [[0,"Olhem para as varandas, mesmo por cima de nós.","speak"],[1,"Não tinha reparado naquele desenho!","speak"],[0,"É por estes detalhes que vale a pena abrandar.","speak"],[people.size()-1,"Ainda bem que esperámos para olhar.","thanks"]]
		"applause": return [[0,"Que bonita! Mais uma!","clap"],[1,"Ficamos a ouvir a próxima.","clap"],[0,"Bravo!","clap"]]
		"duet": return [[0,"Faço a ponte e entras tu?","play"],[1,"Combinado, sigo a tua guitarra.","play"],[0,"Vamos a isso.","play"]]
	var known: bool = a.memory.has("met_"+b.entry.id)
	var first: String = a.motion.personality.lines[rng.randi_range(0,a.motion.personality.lines.size()-1)]
	var answer: String = b.motion.personality.lines[rng.randi_range(0,b.motion.personality.lines.size()-1)]
	var goodbye: String = ["Até logo! Vou continuar o passeio.","Ainda nos voltamos a cruzar mais logo.","Ficava aqui a conversar, mas tenho de ir andando.","Foi bom fazer esta pausa contigo."][rng.randi_range(0,3)]
	return [[0,("Ainda estava a pensar na nossa conversa. " if known else "Olá! ")+first,"speak"],[1,answer,"speak"],[0,goodbye,"thanks"]]

func _advance(event: Dictionary, delta: float) -> void:
	event.age += delta
	for actor in event.people:
		if not actor.available() or actor.encounter_id!=event.id or actor.greet_time>0:
			_finish(event,false,"interrupted")
			return
	if event.age>80:
		_finish(event,false,"late")
		return
	if event.phase=="approach":
		var visitor: CharacterBody2D = event.people[0]
		if visitor.position.distance_to(event.destination)>40:
			if visitor.route.is_empty(): visitor._begin_walk(event.destination,"walking")
			return
		visitor.social_lock = true
		visitor.state = "activity"
		event.phase = "scene"
	for i in event.people.size():
		var actor: CharacterBody2D = event.people[i]
		var focus: Vector2 = event.focus if event.kind=="applause" else event.people[(i+1)%event.people.size()].position
		if event.kind in ["photo","family_photo","guide"] and i>0: focus = event.people[0].position
		if absf(focus.x-actor.position.x)>18: actor.facing_left = focus.x<actor.position.x
		actor.travel_direction = focus-actor.position
	event.remaining -= delta
	if event.remaining>0: return
	event.turn += 1
	if event.turn>=event.lines.size(): _finish(event,true); return
	for actor in event.people:
		actor.social_line = ""
		actor.social_pose = "clap" if event.kind=="applause" and actor.entry.has("friend_of") else "listen"
		if event.kind in ["photo","family_photo"] and actor!=event.people[0]: actor.social_pose = "pose"
	var line: Array = event.lines[event.turn]
	var speaker: CharacterBody2D = event.people[int(line[0])]
	_say(speaker,line[1],line[2])
	event.remaining = clampf(str(line[1]).length()/16.0,2.4,4.7)
	if line[2]=="capture":
		speaker.flash_until = speaker.clock+.22
		stats["shutters"] = int(stats.get("shutters",0))+1
	if event.kind=="applause" and event.turn==event.lines.size()-1:
		for id in ["farid","clara_violinista"]:
			var musician: CharacterBody2D = by_id[id]
			if musician.available() and musician.encounter_id<0:
				_say(musician,"Muito obrigado por ficarem a ouvir!" if id=="farid" else "","thanks")

func _say(actor: CharacterBody2D, text: String, pose: String) -> void:
	actor.social_line = text
	actor.social_pose = pose
	actor.speech_until = actor.clock+clampf(text.length()/16.0,2.4,4.7)
	actor.queue_redraw()
	actor.art.queue_redraw()
	queue_redraw()

func _release(actor: CharacterBody2D) -> void:
	actor.encounter_id = -1
	actor.social_lock = false
	actor.social_pose = ""
	actor.social_line = ""
	actor.velocity = Vector2.ZERO
	actor.route.clear()
	actor.state = "activity" if actor.available() else actor.state
	actor.dwell = actor.motion.rng.randf_range(2.0,6.0)
	actor.motion.remaining = 0
	actor.art.queue_redraw()

func _finish(event: Dictionary, completed: bool, _reason := "") -> void:
	if not encounters.has(event): return
	encounters.erase(event)
	if completed:
		stats[event.kind] = int(stats.get(event.kind,0))+1
		var record := {"kind":event.kind,"people":[],"minute":now}
		for actor in event.people:
			record.people.append(actor.entry.id)
			actor.memory.last_event = event.kind
			for other in event.people:
				if other!=actor: actor.memory["met_"+other.entry.id] = int(actor.memory.get("met_"+other.entry.id,0))+1
		history.append(record)
		if history.size()>80: history.pop_front()
		var buyer: CharacterBody2D = event.people[0]
		if event.kind=="gelato":
			buyer.memory.next_snack = now+rng.randf_range(170,290)
			buyer.memory.gelati = int(buyer.memory.get("gelati",0))+1
			buyer.snack_until = buyer.clock+45
		elif event.kind=="raffle": buyer.memory.raffle_day = floori(now/1440)
		elif event.kind in ["fruit","sweets"]: buyer.memory["snack_"+event.kind] = now+180; buyer.memory[event.kind] = int(buyer.memory.get(event.kind,0))+1
		elif event.kind in ["photo","family_photo"]: buyer.memory.photos = int(buyer.memory.get("photos",0))+1
	for actor in event.people:
		cooldowns[actor.entry.id] = now+(rng.randf_range(35,85) if completed else 12)
		_release(actor)

func cancel_for(actor: CharacterBody2D) -> void:
	for event in encounters.duplicate():
		if event.people.has(actor): _finish(event,false,"appointment")

func memory_line(actor: CharacterBody2D) -> String:
	match actor.memory.get("last_event",""):
		"gelato": return " Ainda comenta o gelado que provou durante o passeio."
		"raffle": return " Guardou uma rifa para apoiar a atividade dos escuteiros."
		"photo","family_photo": return " Ficou com uma fotografia deste passeio."
		"delivery": return " Já confirmou a entrega na loja."
		"chat": return " Ainda se lembra da última conversa com os vizinhos."
		"directions": return " Já sabe por onde seguir, depois da ajuda da agente Sofia."
		"window": return " Ficou a falar dos azulejos que viu na montra."
	return ""

func _draw() -> void:
	# Draw after world actors so canopies and roof silhouettes do not erase speech.
	var font := ThemeDB.fallback_font
	var occupied: Array[Rect2] = []
	for actor in actors:
		if not actor.available() or actor.social_line.is_empty(): continue
		if not world.people.any(func(p): return p.position.distance_to(actor.position)<650): continue
		var wrapped: Array[String] = [""]
		for word in actor.social_line.split(" "):
			var last: int = wrapped.size()-1
			if font.get_string_size(wrapped[last]+word,HORIZONTAL_ALIGNMENT_LEFT,-1,12).x>245: wrapped.append(word+" ")
			else: wrapped[last] += word+" "
		var width := 0.0
		for line in wrapped: width = maxf(width,font.get_string_size(line,HORIZONTAL_ALIGNMENT_LEFT,-1,12).x)
		var box := Rect2(actor.position+Vector2(-width*.5-10,-float(actor.entry.height)-22-wrapped.size()*16),Vector2(width+20,wrapped.size()*16+12))
		for i in 5:
			if not occupied.any(func(other): return other.grow(5).intersects(box)): break
			box.position.y -= box.size.y+8
		occupied.append(box)
		draw_style_box(TejoPerson._box(Color("f4e8cd"),6),box)
		for i in wrapped.size(): draw_string(font,box.position+Vector2(10,18+i*16),wrapped[i],HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("365047"))
