extends Node2D
## Data-driven episodes: approach, visible action, consequence, release. Never teleport cast.
var director: Node2D
var active: Array[Dictionary] = []
var history: Array[Dictionary] = []
var clock := 0.0
var next_decision := 5.0
var serial := 0
func cancel_for(id: String) -> void:
	for episode in active.duplicate():
		if episode.spec.cast.has(id): finish(episode,false)
func reset() -> void:
	for episode in active.duplicate(): finish(episode,false)
func step(delta: float) -> void:
	clock += delta
	for episode in active.duplicate():
		episode.age += delta
		if episode.age>240 or episode.people.any(func(a): return not a.available() or a.greet_time>0): finish(episode,false); continue
		if episode.phase=="approach":
			var ready := true
			for i in episode.people.size():
				var actor: CharacterBody2D = episode.people[i]
				var destination: Vector2 = episode.destinations[i]
				if actor.position.distance_to(destination)<38:
					actor.event_busy = true
					actor.social_pose = "listen"
					actor.route.clear()
				else:
					ready = false
					if actor.route.is_empty(): actor._begin_walk(destination,"walking")
			if ready:
				episode.phase = "action"
				episode.left = 9.0
				for a in episode.people: a.event_busy = true; a.social_pose = "work"; a.route.clear()
				director.say(episode.people[0],episode.spec.line,"speak")
				director.report_noise(episode.at,episode.spec.title)
		else:
			episode.left -= delta
			if episode.left<5 and not episode.get("answered",false):
				episode.answered = true
				director.say(episode.people[1],_answer(episode.spec.effect),"speak")
			if episode.left<=0: finish(episode,true)
	next_decision -= delta
	if next_decision>0 or active.size()>=3: queue_redraw(); return
	next_decision = 11
	var candidates: Array = director.DATA.data.events.duplicate()
	candidates.shuffle()
	for spec in candidates:
		if start(spec): break
	queue_redraw()
func start(spec: Dictionary, force := false) -> bool:
	var day: int = director.day
	if not force:
		if director.minute<float(spec.start) or director.minute>float(spec.end) or day%int(spec.every)!=0: return false
		if int(director.state.events.get(spec.id,-1))==day: return false
		if spec.cast.has("plutonio") and not director.cameo_active(): return false
	if active.any(func(e): return e.spec.id==spec.id): return false
	var people: Array = []
	for id in spec.cast:
		var a: CharacterBody2D = director.by_id[id]
		var window_visit: bool = a.state=="window" and spec.effect in ["rug","shutter","water"]
		if (not a.available() and not window_visit) or a.event_busy or a.encounter_id>=0 or a.delivery_mode!="" or a.greet_time>0: return false
		if not force and (a.state not in ["activity","window"] or director.remaining(a)<22): return false
		if active.any(func(e):return e.people.has(a)): return false
		people.append(a)
	var zone: Array = director.DATA.data.zones[spec.zone]
	var at: Vector2 = director.routines.clear_destination(Vector2(zone[0],zone[1]),[])
	var destinations: Array[Vector2] = _meeting_places(at)
	if destinations.size()!=people.size(): return false
	for i in people.size():
		var path: PackedVector2Array = director.world.find_path(people[i].position,destinations[i])
		if path.is_empty(): return false
		if not force and director.routines.path_length(path)/maxf(40,float(people[i].entry.speed))+22>director.remaining(people[i]): return false
	for i in people.size():
		if people[i].state=="window": people[i]._outside(); people[i].art.show()
		people[i].story_reserved = true
		people[i]._begin_walk(destinations[i],"walking")
	serial += 1
	active.append({"spec":spec,"people":people,"at":destinations[0].lerp(destinations[1],.5),"destinations":destinations,"phase":"approach","age":0.0,"left":9.0,"serial":serial})
	return true
func finish(episode: Dictionary, completed: bool) -> void:
	if not active.has(episode): return
	active.erase(episode)
	if completed:
		director.state.events[episode.spec.id] = director.day
		director.state.quests["event_"+str(episode.spec.id)] = int(director.state.quests.get("event_"+str(episode.spec.id),0))+1
		for a in episode.people:
			a.memory.last_living_event = episode.spec.title
			if episode.get("assisted",false): a.memory.helped_by_player = int(a.memory.get("helped_by_player",0))+1
		director.consequence(episode.spec,episode.at)
		history.append({"id":episode.spec.id,"day":director.day,"at":[episode.at.x,episode.at.y]})
		if history.size()>64: history.pop_front()
		director.dirty = true
	for a in episode.people:
		a.story_reserved = false
		a.event_busy = false
		a.social_pose = ""
		if a.available(): a._begin_walk(a.anchor,"returning")
func _answer(effect: String) -> String:
	return {"rhythm":"Outra vez, mas agora sem a caixa de queijadas!","swap":"Trocamos de volta antes de alguém resolver as notícias.","clock":"Acertamos o mecanismo, deixamos os fusos em paz.","photo":"Ficou uma fotografia. Até o banco parece contente.","paint":"O quadro vai para o placard, com a pista no verso.","trade":"Uma troca de cada vez; ninguém fica sem o seu objeto.","sound":"Ouvi. Agora deixamos espaço para ouvir os outros.","sign":"A etiqueta vai para a caixa certa, desta vez.","water":"Primeiro avisar quem passa por baixo!","deliver":"Entregue em mão. O postal também precisava de passeio.","keys":"A caixa é comunitária. As portas das casas ficam fechadas.","stamp":"Um carimbo não substitui uma visita, pois não?","sweep":"Eu seguro a pá. Tu varres. Está negociado.","shoe":"Ao menos chegaste antes de a conversa acabar.","cat":"O gato declarou-se morador de todas as casas.","map":"Esquerda do mapa ou esquerda de quem está virado ao contrário?","queue":"Uma fila tão pequena e já conseguiu ter princípio e fim.","count":"Anotamos o número real e repetimos amanhã.","rug":"Não, a franja não é a entrada para a serra.","shutter":"Aberta! A casa também merece apanhar ar."}.get(effect,"Combinado. Amanhã vemos como correu.")
func _draw() -> void:
	for episode in active:
		if episode.phase!="action": continue
		if not director.world.people.any(func(p):return p.position.distance_to(episode.at)<1000): continue
		var at: Vector2 = episode.at
		var t: float = 9-float(episode.left)
		match str(episode.spec.effect):
			"rhythm","sound":
				for i in 3: draw_arc(at+Vector2(0,-100),15+i*12+fposmod(t*10,12),-PI*.8,-PI*.2,20,Color("dfc47e"),2,true)
			"photo":
				if t>4 and t<4.3: draw_circle(at-Vector2(40,100),80,Color(1,1,.8,.4))
			"water":
				for i in 7: draw_line(at+Vector2(i*7-20,-90),at+Vector2(i*7-15,-10+sin(t+i)*8),Color("a9c3d4"),2,true)
			"sweep":
				for i in 5: draw_circle(at+Vector2(20-i*7+t*3,6-i%2*4),3,Color("a18a58"))
			"count": draw_string(ThemeDB.fallback_font,at-Vector2(25,70),str(int(t)*3+1),HORIZONTAL_ALIGNMENT_LEFT,-1,22,Color("eed8a1"))
			"queue":
				for i in 3: draw_line(at+Vector2(-70+i*55,25),at+Vector2(-30+i*55,25),Color("ded9c2"),2,true)
			"rug": draw_rect(Rect2(at-Vector2(40,25),Vector2(80,45)),Color("b77968"),false,3)
			_:
				var x: float = sin(t*.7)*40
				preload("res://scripts/item_art.gd").draw_item(self,{"type":"living_"+str(episode.spec.object),"porte":1,"art":0},Rect2(at+Vector2(x-15,-45),Vector2(30,30)))

func _meeting_places(preferred: Vector2) -> Array[Vector2]:
	for projection in [true,false]:
		for radius in [0.0,32.0,64.0,96.0,160.0,224.0]:
			for i in (1 if radius==0 else 8):
				var base: Vector2 = preferred+Vector2.from_angle(i*TAU/8)*radius
				if not director.world.is_walkable(base,26) or (projection and not director.routines.clear_paint(base)): continue
				for j in 16:
					var second: Vector2 = base+Vector2.from_angle(j*TAU/16)*90
					if not director.world.is_walkable(second,26) or not director.world.can_walk_line(base,second): continue
					if projection and not director.routines.clear_paint(second): continue
					return [base,second]
	return []
