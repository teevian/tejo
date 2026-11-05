extends Node2D
## Visible, clock-driven comedy with actual routes, deliveries and collectible loose papers.
var director: Node2D
var age := 0.0
var timers: Dictionary = {}
var stages: Dictionary = {}
var papers: Array[Node2D] = []
var courier: Node2D
var table_ball := Vector2.ZERO
var ball_from := Vector2.ZERO
var ball_to := Vector2.ZERO
var ball_time := 0.0
var table_scores := [0,0]
var shots := 0
var visits: Dictionary = {}
var observations: Dictionary = {}
var seen_passes: Dictionary = {}
var queue_positions: Array[Vector2] = []
var queue_shop := Vector2.ZERO
var parcel_phase := "idle"
var parcel_goal := Vector2.ZERO
var player_match: Dictionary = {}
var histories: Array[Dictionary] = []
func _ready() -> void:
	courier = preload("res://scripts/village_neighbour_pigeon.gd").new(); courier.director = director
	director.world.actors.add_child(courier)
	queue_shop = director.routines.doorway(director.places.queue,false,"Piriquita")
	for i in 3: queue_positions.append(director.routines.clear_destination(director.places.queue+Vector2(60,i*90+75),[]))
func reset() -> void:
	clear_papers()
	visits.clear(); stages.clear(); timers.clear(); parcel_phase = "idle"
	if is_instance_valid(courier): courier.reset()
	player_match.clear()
func clear_papers() -> void:
	director.world.interactions.targets = director.world.interactions.targets.filter(func(t):return not papers.has(t.get("node")))
	if papers.has(director.world.interactions.current_target.get("node")): director.world.interactions.current_target = {}
	for p in papers:
		if is_instance_valid(p): p.queue_free()
	papers.clear()
func cast(role: String) -> Array:
	return director.residents.filter(func(a):return a.entry.role==role and a.appointment.get("place","")==role and a.available())
func ready_cast(role: String,minimum: int) -> Array:
	var people: Array = cast(role).filter(func(a):return a.state!="commuting" and a.position.distance_to(a.anchor)<820)
	return people if people.size()>=minimum else []
func express(id: String,pose: int,seconds := 4.0) -> void:
	var a: CharacterBody2D = director.by_id[id]
	a.set_meta("reaction",pose); a.set_meta("reaction_until",a.clock+seconds)
func move(a: CharacterBody2D,to: Vector2) -> bool:
	a.story_locked = false
	a.set_meta("story_goal",to)
	return a._begin_walk(to,"walking")
func _hold(a: CharacterBody2D) -> void:
	if visits.has(a.entry.id) or not a.route.is_empty() or a.state=="commuting": return
	var to: Vector2 = a.get_meta("story_goal",a.anchor)
	if a.position.distance_to(to)>35: return
	a.story_reserved = true; a.story_locked = true
	if a.entry.role=="foosball": a.facing_left = director.places.foosball.x<a.position.x
	# Authored holds belong to the person. Panic, pouring and celebrating must
	# follow their actual causes instead of appearing in a universal idle loop.
	var duration := 0.0
	for beat in a.entry.beats: duration += float(beat[1])
	var elapsed: float = fposmod(a.clock+float(a.ordinal)*.31,duration)
	for beat in a.entry.beats:
		a.story_frame = int(beat[0])
		elapsed -= float(beat[1])
		if elapsed<0: break
	if a.entry.id=="nelson_termos" and director.objects.thermos.index==2: a.story_frame = 2 if fposmod(a.clock,9)<2 else 3
	if float(a.get_meta("reaction_until",0))>a.clock: a.story_frame = int(a.get_meta("reaction",0))
func step(delta: float,cycle: RefCounted) -> void:
	age += delta
	for a in director.residents:
		if a.appointment.get("place","")==a.entry.role and a.state!="inside": _hold(a)
	for key in visits.keys(): _visit_step(key,delta)
	for p in papers:
		if not is_instance_valid(p) or p.collected: continue
		var motion: Vector2 = p.drift*delta
		if director.world.is_walkable(p.position+motion,4): p.position += motion
		p.drift *= maxf(0,1-delta*.7)
	courier.step(delta)
	ball_time = minf(1,ball_time+delta*1.7)
	table_ball = ball_from.lerp(ball_to,ball_time)
	director.objects.foosball.queue_redraw()
	for key in ["picnic","pigeon","queue","window","foosball","raffle","papers"]:
		timers[key] = float(timers.get(key,0))+delta
	_picnic(); _pigeon(); _queue(); _window(cycle); _foosball(); _raffle(); _papers(cycle)
func _next(key: String,seconds: float) -> bool:
	if float(timers.get(key,0))<seconds: return false
	timers[key] = 0
	stages[key] = int(stages.get(key,0))+1
	return true
func _mark(key: String) -> void:
	director.record("episodes_"+key)
	histories.append({"story":key,"day":director.day,"minute":director.minute})
	if histories.size()>80: histories.pop_front()
func _picnic() -> void:
	var people: Array = ready_cast("picnic",4)
	director.objects.picnic.active = not people.is_empty()
	director.objects.thermos.active = not people.is_empty()
	director.objects.picnic.queue_redraw(); director.objects.thermos.queue_redraw()
	if people.is_empty() or not _next("picnic",19): return
	match int(stages.picnic)%4:
		1:
			director.say("rosario_merenda","Trouxe doze sandes. Estamos quatro. Quem é que já fez as contas?")
			express("rosario_merenda",1); express("iris_merenda",1)
		2:
			director.say("nelson_termos","O termo não está preso. Está a conservar a pressão.")
			director.say("leo_merenda","As formigas já começaram o segundo turno.")
			express("nelson_termos",1); express("leo_merenda",2)
		3:
			director.say("iris_merenda","No desenho ainda estão as doze. Posso mostrar.")
			express("iris_merenda",3); express("rosario_merenda",3)
		0:
			director.say("rosario_merenda","Nelson, o café tem prazo de validade. A tua explicação já passou dele.")
			_mark("picnic")
func _pigeon() -> void:
	var people: Array = ready_cast("pigeon",2)
	if people.is_empty() or courier.busy: return
	if not _next("pigeon",23): return
	var returning: bool = int(stages.pigeon)%2==0
	var from: CharacterBody2D = director.by_id.olinda_pasteis if returning else director.by_id.ernesto_pombos
	var to: CharacterBody2D = director.by_id.ernesto_pombos if returning else director.by_id.olinda_pasteis
	courier.deliver(from.position+Vector2(30,-30),to.position+Vector2(20,-30),returning)
	if returning:
		director.say("olinda_pasteis","Leva a resposta. E diz-lhe que as migalhas também entram na conta.")
		express("olinda_pasteis",0)
	else:
		director.say("ernesto_pombos","Funcionário Engenheiro: entrega direta. A pastelaria não é um entreposto.")
		express("ernesto_pombos",0)
func pigeon_arrived(receipt: bool) -> void:
	if receipt:
		director.record("pigeon_receipts"); express("ernesto_pombos",3,7)
		director.say("ernesto_pombos","Boa orientação. Fraca ética. Outra fatura de bolos.")
		_mark("pigeon")
	else:
		director.record("pigeon_deliveries"); express("olinda_pasteis",2)
func visit(a: CharacterBody2D,door: Vector2,back: Vector2) -> void:
	if visits.has(a.entry.id): return
	if move(a,door): visits[a.entry.id] = {"phase":"approach","door":door,"back":back,"left":5.0}
func _visit_step(id: String,delta: float) -> void:
	var a: CharacterBody2D = director.by_id[id]
	var v: Dictionary = visits[id]
	if a.appointment.get("place","")!=a.entry.role: visits.erase(id); return
	if v.phase=="approach" and a.position.distance_to(v.door)<44:
		a.story_locked = false; a._inside(); v.phase = "inside"; a.entered_shops += 1
	elif v.phase=="inside":
		v.left -= delta
		if v.left<=0:
			a._outside(); move(a,v.back); v.phase = "return"
	elif v.phase=="return" and a.position.distance_to(v.back)<35:
		visits.erase(id); director.record("shop_visits")
func _queue() -> void:
	if ready_cast("queue",3).is_empty() or not visits.is_empty() or not _next("queue",22): return
	var b: CharacterBody2D = director.by_id.beatriz_fila
	var r: CharacterBody2D = director.by_id.ricardo_tempos
	var e: CharacterBody2D = director.by_id.estela_cliente
	match int(stages.queue)%4:
		1:
			director.say(b.entry.id,"Se invertermos a fila e separarmos pedidos de pagamentos, poupamos quarenta segundos.")
			move(r,queue_positions[2]); express(b.entry.id,0)
		2:
			director.say(e.entry.id,"Eu estou aqui desde antes do vosso diagrama. Daqui não saio.")
			express(e.entry.id,0); express(r.entry.id,1)
		3:
			visit(b,queue_shop,b.anchor)
			director.say(r.entry.id,"Dois de cada, Beatriz. Desta vez já recolhemos os pedidos." if int(director.state.get("queue_orders_known",0))>0 else "Já sabemos quanto demora a fila. Falta saber o que vamos pedir.")
		0:
			express(b.entry.id,1 if int(director.state.get("queue_orders_known",0))>0 else 3,8); express(e.entry.id,2,7)
			director.say(b.entry.id,"Pedido certo. Agora só falta admitir que perguntar à Estela também conta como otimização." if int(director.state.get("queue_orders_known",0))>0 else "Ricardo! Era um ou dois de cada? Tenho de voltar atrás.")
			_mark("queue")
func _window(cycle: RefCounted) -> void:
	var odete: CharacterBody2D = director.by_id.odete_janela
	if odete.state=="window":
		var near: Array = director.world.social_life.actors.filter(func(a):return a!=odete and a.available() and a.position.distance_to(odete.position)<650)
		for a in near:
			var key: String = a.entry.id+":"+str(cycle.day)
			if seen_passes.has(key): continue
			seen_passes[key] = true
			observations[a.entry.id] = {"minute":int(cycle.minutes),"day":cycle.day,"name":a.entry.name}
		if _next("window",31) and not near.is_empty():
			var target: CharacterBody2D = near[int(stages.window)%near.size()]
			var text: String = "%s, já cá passou às %02d:%02d. Não foi ontem."%[target.entry.name,int(cycle.minutes)/60,int(cycle.minutes)%60]
			director.say("odete_janela",text); express("odete_janela",0,5)
			if is_instance_valid(odete.window_node): odete.window_node.mark = {"text":"Não foi terça. Foi quarta!","until":odete.window_node.clock+5}
	if cycle.minutes>=1100 and cycle.minutes<1120 and parcel_phase=="idle":
		var fausto: CharacterBody2D = director.by_id.fausto_merceeiro
		if fausto.available() and fausto.appointment.place=="window":
			parcel_goal = director.routines.doorway(director.places.window+Vector2(550,100),true)
			visit(fausto,parcel_goal,fausto.anchor)
			if visits.has(fausto.entry.id): parcel_phase = "out"; director.say(fausto.entry.id,"Começou a novela. Tenho vinte minutos para levar o cabaz sem relatório público.")
	if parcel_phase=="out" and director.by_id.fausto_merceeiro.state=="inside" and director.by_id.fausto_merceeiro.position.distance_to(parcel_goal)<45:
		parcel_phase = "done"; director.record("quiet_deliveries"); _mark("window")
		express("fausto_merceeiro",2,8)
	if cycle.minutes<1000: parcel_phase = "idle"
func shoot_ball(side: int,lane: int) -> void:
	ball_from = Vector2(-.95 if side==0 else .95,0)
	ball_to = Vector2(.95 if side==0 else -.95,lane*.8)
	ball_time = 0
func _foosball() -> void:
	if ready_cast("foosball",3).is_empty() or not player_match.is_empty() or not _next("foosball",7): return
	shots += 1
	var side: int = shots%2
	shoot_ball(side,(shots%3)-1)
	express("dora_matraquilhos",2,2); express("toni_matraquilhos",0,2)
	if shots%3: return
	table_scores[side] += 1
	express("simao_marcador",1,4); express("toni_matraquilhos",2,5)
	director.say("simao_marcador","Resultado real: Tóni %d, Dora %d. Na classificação do avô ainda está zero a zero."%table_scores)
	director.say("toni_matraquilhos","A bola entrou, sim. Mas antes disso houve uma situação.")
	_mark("foosball")
func _raffle() -> void:
	if ready_cast("raffle",3).is_empty() or not _next("raffle",24): return
	if int(stages.raffle)%2:
		director.say("vasco_rifas","A caneta já chegou. Agora tenho de carimbar a declaração de que tenho caneta." if director.state.get("vasco_pen",false) else "Para uma rifa basta preencher os três exemplares. Alguém tem uma caneta?")
		express("vasco_rifas",0 if director.state.get("vasco_pen",false) else 1,7); express("raul_comprador",0,7)
	else:
		director.say("lia_rifas","Raul, toma a rifa. Já podes ir almoçar. O requerimento pode ficar com ele.")
		director.say("vasco_rifas","Isso é uma venda sem procedimento! Quem é o tesoureiro aqui?")
		express("lia_rifas",2,6); express("vasco_rifas",3,7); express("raul_comprador",2,5)
		director.record("lia_sales"); _mark("raffle")
func _papers(cycle: RefCounted) -> void:
	if ready_cast("papers",3).is_empty(): return
	var restore: bool = int(director.state.get("paper_wind_day",-1))==director.day
	if restore and not papers.is_empty(): return
	if restore:
		var missing := false
		for i in 5:
			if not director.state.get("picked_"+str(director.day)+"_"+str(i),false): missing = true
		if not missing: return
	if not restore and not _next("papers",38): return
	if not restore: clear_papers()
	director.state.paper_wind_day = director.day
	for i in 5:
		if director.state.get("picked_"+str(director.day)+"_"+str(i),false): continue
		var p := preload("res://scripts/village_neighbour_prop.gd").new()
		var at: Vector2 = director.routines.clear_destination(director.places.papers+Vector2(80+i*35,90+(i%2)*55),[],12)
		p.setup(director,"paper",at,6,29); p.number = i; p.drift = Vector2(32+i*8,-4+i*3)
		papers.append(p)
		director.world.interactions.targets.append({"id":"loose_test_"+str(director.day)+"_"+str(i),"kind":"street_scene","node":p,"label":"Teste levado pelo vento","position":at,"reach":95.0,"radius":0.0})
	if restore: return
	express("margarida_testes",2,12); express("sara_aluna",2,8); express("ruben_esplanada",2,8)
	director.say("margarida_testes","Ninguém leia as notas! Os resultados ainda são provisórios!")
	director.say("sara_aluna","Professora, esta conta está certa. O vento fez melhor revisão do que nós.")
	_mark("papers")
func collect_paper(p: Node2D,person: CharacterBody2D) -> String:
	if p.collected: return "Esta folha já foi apanhada."
	var item := {"type":"neighbour_exam","name":"Teste de cálculo · folha "+str(p.number+1),"porte":1,"art":0,"sheet":p.number,"day":director.day}
	if not person.inventory.try_add(item): return "A bolsa está cheia. A folha fica aqui, pousada na calçada."
	p.collected = true; p.hide(); director.record("papers_collected")
	director.state["picked_"+str(director.day)+"_"+str(p.number)] = true
	express("sara_aluna",3,6)
	return "Apanhaste um teste. A Sara reconheceu a conta; podes devolver a folha à professora."
