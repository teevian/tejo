extends Node2D
## Physical terraces and owned seats: people walk here, eat, and continue their real day.
const Furniture = preload("res://scripts/village_terrace_furniture.gd")
const ART = preload("res://data/village/individuality-art.json")
var world: Node2D
var terraces: Array[Dictionary] = []
var seats: Array[Dictionary] = []
var props: Array[Node2D] = []
var diners: Array[CharacterBody2D] = []
var clock := 0.0
var next_conversation := 25.0
func _ready() -> void:
	var used: Array = []
	for preferred in [Vector2(9970,4600),Vector2(8400,8500),Vector2(18400,7770),Vector2(13700,6630),Vector2(3880,9200),Vector2(13000,12500)]:
		var cafes: Array = world.buildings.filter(func(b):return b.label=="Café" and not used.has(b.entry_id))
		cafes.sort_custom(func(a,b):return a.entry_position.distance_squared_to(preferred)<b.entry_position.distance_squared_to(preferred))
		var cafe: Node2D = cafes[0]; used.append(cafe.entry_id)
		var center: Vector2 = world._event_space(cafe.entry_position+Vector2(0,190),360)
		var terrace: Dictionary = {"id":cafe.entry_id,"at":center,"cafe":cafe,"tables":[]}
		for j in (3 if terraces.size()==4 else 2):
			var at: Vector2 = table_space(center+Vector2((j*2-1)*155,0))
			var table: Node2D = prop(0,at+Vector2(0,28),88)
			table.caption = "Observar a esplanada · "+world.area_at(at)
			terrace.tables.append(table)
			for side in [-1,1]:
				var foot: Vector2 = world._event_space(at+Vector2(side*78,0),65)
				var chair: Node2D = prop(2,foot,86)
				chair.mirrored = side>0
				seats.append({"at":foot,"kind":"cafe","table":table,"chair":chair,"owner":"","left":side>0})
		prop(4,world._event_space(center+Vector2(-45,-76),60),290)
		prop(5,world._event_space(center+Vector2(235,75),65),95)
		terraces.append(terrace)
	for preferred in [Vector2(9520,2590),Vector2(5510,10090),Vector2(19020,4890),Vector2(13030,12620),Vector2(8500,8680)]:
		var at: Vector2 = world._event_space(preferred,220)
		prop(7,at,93)
		for side in [-1,1]: seats.append({"at":at+Vector2(side*45,0),"kind":"bench","owner":"","left":side>0})
func prop(index: int,at: Vector2,height: float) -> Node2D:
	var p := Furniture.new(); p.setup(world,at,index,height); props.append(p); return p
func table_space(preferred: Vector2) -> Vector2:
	for radius in range(0,833,32):
		for i in (1 if radius==0 else 16):
			var at: Vector2 = preferred+Vector2.from_angle(i*TAU/16)*radius
			if not world.is_walkable(at,115): continue
			var bodies := Rect2(at-Vector2(145,160),Vector2(290,180))
			if world.buildings.any(func(b):return b.position.y>=at.y and b.screen_bounds.intersects(bodies)): continue
			return at
	return world._event_space(preferred,300)
func bind() -> void:
	var all: Array = world.population.residents+world.street_life.residents+world.festival_life.residents+world.living_life.residents
	for a in all:
		a.profile = a.profile.duplicate(true)
		a.profile.commute_speed = a.gait.commute_speed*(.6 if a.gait.kind=="cane" else 1.0)
		a.gait.localize_schedule(a)
		if a.entry.id=="helena_turista":
			# Her supported cane pace needs nearby lodging, not a late crossing
			# of the entire town after the guided walk. Keep a real house door.
			var lodging: Vector2 = a.population.routines.doorway(a.home,true)
			for block in a.schedule:
				if block.place=="home": block.destination = lodging; block.location = "o alojamento perto do Palácio"
		if a.entry.id=="anibal":
			var nearby: Vector2 = world.stair_rect(world.TERRACES.data.terraces[0]).get_center()
			for block in a.schedule:
				if block.mode!="inside": block.destination = a.population.routines.clear_destination(nearby,[],26); block.location = world.area_at(block.destination)
		if a.entry.id=="alvaro":
			for block in a.schedule:
				if block.place=="afternoon": block.destination = a.population.routines.clear_destination(Vector2(5510,10090),[],26); block.location = world.area_at(block.destination)
	for id in ["lurdes","antonio","celeste","manuel","matilde","leonor","tomas","miguel","gil","tiago","alexandre","martim","afonso"]:
		var actor: CharacterBody2D = world.living_life.by_id[id]
		var source: Array = actor.schedule.duplicate(true)
		var routine: RefCounted = actor.population.routines
		var work: Dictionary = source.filter(func(b):return b.mode!="inside")[0]
		var morning: Dictionary = reserve(actor,"breakfast",source[0].destination)
		var midday: Dictionary = reserve(actor,"lunch",work.destination)
		if morning.is_empty() or midday.is_empty(): continue
		diners.append(actor)
		var ordinal: int = actor.ordinal
		if actor.profile.has("guardian"): ordinal = int(world.living_life.by_id[actor.profile.guardian].ordinal)
		var breakfasts: Array = source.filter(func(b):return str(b.activity).contains("pequeno-almoço"))
		var lunches: Array = source.filter(func(b):return str(b.activity).contains("almoçar"))
		var dinners: Array = source.filter(func(b):return str(b.activity).contains("jantar"))
		var breakfast: int = int(breakfasts[0].minute) if not breakfasts.is_empty() else 440+ordinal%12
		var lunch: int = int(lunches[0].minute) if not lunches.is_empty() else 735+ordinal%15
		var afternoon: Dictionary = source[routine.index_at(actor,900)]
		var evening: Dictionary = source[routine.index_at(actor,1050)]
		var dinner: Dictionary = dinners[0] if not dinners.is_empty() else source[-1]
		actor.schedule = [source[0],meal_block(morning,breakfast,"breakfast"),retime(work,555+ordinal%10),meal_block(midday,lunch,"lunch"),retime(afternoon,825+ordinal%15),retime(evening,mini(1020+ordinal%8,int(dinner.minute)-75)),dinner,source[-1]]
		actor.schedule.sort_custom(func(a,b):return a.minute<b.minute)
	for p in props:
		if p.kind in [0,7]: world.interactions.targets.append({"id":"terrace_"+str(p.get_instance_id()),"kind":"street_scene","node":p,"label":p.caption,"position":p.position+Vector2(0,70),"reach":110.0,"radius":0.0})
func reserve(actor: CharacterBody2D,meal: String,near: Vector2) -> Dictionary:
	var kind: String = "bench" if int(actor.entry.age)>=70 else "cafe"
	var key: String = meal+"_owner"
	var choices: Array = seats.filter(func(s):return s.get(key,"")=="" and s.kind==kind)
	var partner: String = {"matilde":"leonor","leonor":"matilde","tomas":"miguel","miguel":"tomas"}.get(actor.entry.id,"")
	var paired: Array = seats.filter(func(s):return s.get(key,"")==partner and s.has("table")) if partner!="" else []
	if not paired.is_empty():
		var same_table: Array = choices.filter(func(s):return s.get("table")==paired[0].table)
		if not same_table.is_empty(): choices = same_table
	choices.sort_custom(func(a,b):return a.at.distance_squared_to(near)<b.at.distance_squared_to(near))
	if choices.is_empty(): return {}
	var seat: Dictionary = choices[0]; seat[key] = actor.entry.id
	if int(actor.entry.age)<13 and seat.has("chair"): seat.chair.painted_height = 76
	return seat
func retime(block: Dictionary,minute: int) -> Dictionary:
	var result: Dictionary = block.duplicate(true)
	result.minute = minute; result.at = "%02d:%02d"%[minute/60,minute%60]
	return result
func meal_block(seat: Dictionary,start: int,meal: String) -> Dictionary:
	return {"at":"%02d:%02d"%[start/60,start%60],"minute":start,"destination":seat.at,"place":"outdoor_"+meal,"mode":"outdoor_meal","activity":"a tomar o pequeno-almoço" if meal=="breakfast" else "a almoçar","location":world.area_at(seat.at),"stroll":false,"meal":meal,"seat":seat}
func step(delta: float,cycle: RefCounted) -> void:
	clock += delta
	for p in props:
		if p.kind==0:
			var lunch: bool = cycle.minutes>=720 and cycle.minutes<940
			if lunch!=p.lunch: p.lunch = lunch; p.queue_redraw()
	for a in diners:
		if a.appointment.get("mode","")!="outdoor_meal": continue
		var seat: Dictionary = a.appointment.seat
		if a.position.distance_to(seat.at)>8 or a.greet_time>0: continue
		if not a.meal_seated:
			a._cancel_encounter(); a.meal_seated = true; a.route.clear(); a.state = "meal"
			a.social_pose = ""; a.motion.phase = "eat"; a.motion.extra = -1; a.velocity = Vector2.ZERO
			a.facing_left = seat.left
			a.memory.last_outdoor_meal = str(a.appointment.meal)
		if a.position.distance_to(seat.at)>1: a.move_and_collide((seat.at-a.position).limit_length(12*delta))
		var t: float = fposmod(clock+float(a.ordinal)*1.73,13+float(a.ordinal%5))
		a.meal_frame = (0 if t>3 else 1) if a.appointment.meal=="breakfast" else (2 if t<2.5 else 3)
		a.art.queue_redraw()
	next_conversation -= delta
	if next_conversation>0 or not is_instance_valid(world.social_life): return
	next_conversation = 33
	var seated: Array = diners.filter(func(a):return a.meal_seated and a.visible)
	if seated.size()<2: return
	var speaker: CharacterBody2D = seated[int(clock/33)%seated.size()]
	var neighbours: Array = seated.filter(func(a):return a!=speaker and a.position.distance_to(speaker.position)<240)
	if not neighbours.is_empty():
		var lines: Dictionary = {"lurdes":"A malha pode esperar. A comida é que convém não arrefecer.","antonio":"Pouso a bengala aqui. Não quero que ela se vá embora sem mim.","celeste":"Só mais um bocadinho. Depois volto ao capítulo.","manuel":"As notícias podem esperar pelo fim da refeição.","matilde":"Acabo o sumo e ainda chego à macaca antes de ti!","tomas":"Depois disto quero tentar mais dez toques.","leonor":"A fotografia fica para depois. Agora podem comer à vontade.","miguel":"Vou guardar o caderno antes que acabe cheio de migalhas.","gil":"Isto dá forças para as subidas? Então convém não deixar nada.","tiago":"No mapa, a esplanada fica precisamente… aqui.","alexandre":"A luz está boa, mas a fotografia espera até acabarmos.","martim":"Podem conversar, eu vou acabando este café.","afonso":"A seguir escolhemos o caminho que tiver mais sombra."}
		world.social_life._say(speaker,lines.get(speaker.entry.id,"Acaba primeiro. A vila não vai fugir."),"speak")
