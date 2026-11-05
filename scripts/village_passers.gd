extends "res://scripts/village_population.gd"
## Background circulation reuses the village's painted crowd wardrobe; story cast is unique.
const Passer = preload("res://scripts/village_passer.gd")
var stops: Array[Vector2] = []
var doors_used: Dictionary = {}
var night_people: Array[CharacterBody2D] = []
func _ready() -> void:
	name = "StreetCirculationAndShopVisitors"
	routines.population = self
	var samples: Array[Vector2] = world.neighbourhood.presence.samples
	# Farthest-first cover of the public network. Never depends on the camera.
	var remaining: Array[Vector2] = samples.duplicate()
	while not remaining.is_empty() and stops.size()<240:
		var best: Vector2 = remaining[0]; var gap := -1.0
		for p in remaining:
			var closest := INF
			for s in stops: closest = minf(closest,s.distance_to(p))
			if closest>gap: gap = closest; best = p
		stops.append(best)
		remaining = remaining.filter(func(p):return p.distance_to(best)>590)
	var sources: Array = (world.population.residents+world.festival_life.residents).filter(func(a):return int(a.entry.age)>=18 and int(a.entry.age)<70 and not a.entry.get("seated",false) and not a.entry.has("friend_of") and not a.entry.has("vehicle") and a.entry.id not in ["harry_kane","rogerio_colaco","arlindo_oliveira","ines_lynce","duarte","lurdes","celeste","antonio"] and not a.entry.get("cameo",false) and str(a.entry.get("role","")) not in ["cinema","driver","carriage_driver","footballer","projectionist","referee","announcer"])
	var first_names := ["Mariana","Rafael","Inês","Sandro","Carla","Dário","Helena","Rui","Sofia","Daniel","Alice","Ivo","Clara","José","Diana","Lucas"]
	var surnames := ["Faria","Matos","Lopes","Costa","Pires","Silva","Duarte","Nunes","Rocha","Alves","Cabral","Reis"]
	var lines := ["Vou buscar o pão antes de subir outra vez. Se me esquecer, cá me encontram de novo.","A loja que procuro está sempre na rua ao lado. Já percorri três ruas ao lado.","Combinámos encontrar-nos à porta do café. Faltou combinar qual café.","Vim comprar fruta e já trouxe duas coisas que não estavam na lista.","Estou à espera de uma amiga. Ela reconhece-me pelo saco das compras.","A luz nesta rua muda completamente ao fim da tarde. Volto sempre para ver.","Parei para ver a montra e agora estou a tentar lembrar-me para onde ia.","A subida custa menos quando se encontra alguém pelo caminho."]
	for i in stops.size()+18:
		var night: bool = i>=stops.size()
		var at: Vector2 = stops[i] if not night else Vector2(world.living_life.DATA.data.zones.values()[i-stops.size()][0],world.living_life.DATA.data.zones.values()[i-stops.size()][1])
		at = routines.clear_destination(at,[])
		var original: CharacterBody2D = sources[(i*17+i/9)%sources.size()]
		# Avoid recognisable twins in one stretch of street. Appearances are stable after setup.
		for shift in sources.size():
			var candidate: CharacterBody2D = sources[(i*17+i/9+shift)%sources.size()]
			if candidate.home.distance_to(at)>1800 and not residents.any(func(a):return a.entry.ambient_source==candidate.entry.id and a.home.distance_to(at)<1700): original = candidate; break
		var a := Passer.new(); a.population = self; a.ordinal = 230+i
		a.entry = original.entry.duplicate(true)
		a.entry.id = "street_passer_"+str(i); a.entry.name = first_names[i%first_names.size()]+" "+surnames[(i/first_names.size())%surnames.size()]
		a.entry.ambient_source = original.entry.id
		a.entry.erase("guardian"); a.entry.erase("friend_of"); a.entry.erase("follow")
		a.entry.personality = original.motion.personality.duplicate(true)
		a.entry.personality.style = ["map","reader","camera","notes"][i%4]
		a.entry.personality.lines = [lines[i%lines.size()],lines[(i+3)%lines.size()]]
		a.entry.greeting = lines[i%lines.size()]; a.entry.activity = "a visitar as lojas e conversar na vizinhança"
		a.entry.wait_seconds = 6+i%10
		a.profile = {"residence":"local","commute_speed":110}
		a.name = a.entry.id; a.home = at; a.position = at; a.anchor = at
		world.actors.add_child(a); residents.append(a); by_id[a.entry.id] = a
		a.door = routines.doorway(at)
		var shops: Array = world.buildings.filter(func(b):return b.label not in ["","Habitação"] and b.entry_position.distance_to(at)<500)
		shops.sort_custom(func(x,y):return x.entry_position.distance_squared_to(at)<y.entry_position.distance_squared_to(at))
		if not shops.is_empty(): a.door = routines.clear_destination(shops[0].entry_position,[],20)
		a.circuit.append(at)
		for offset in [Vector2(135,60),Vector2(-135,60)]:
			var next: Vector2 = routines.clear_destination(at+offset,[],22)
			if next.distance_to(at)<250 and not world.find_path(at,next).is_empty(): a.circuit.append(next)
		var start: int = 425+i%20 if not night else 0
		var end: int = 1360+i%25 if not night else 390+i%25
		var home: Vector2 = reachable_house(at)
		var outside := {"minute":start,"destination":at,"place":"local_street","mode":"activity","activity":"a circular entre as lojas" if not night else "a fazer uma ronda noturna da vizinhança","location":world.area_at(at),"stroll":false}
		var inside := {"minute":0,"destination":home,"place":"home","mode":"inside","activity":"a descansar em casa","location":"casa","stroll":false}
		if not night:
			a.schedule = [inside,outside,{"minute":end,"destination":home,"place":"home","mode":"inside","activity":"a dormir","location":"casa","stroll":false}]
		else:
			a.schedule = [outside,{"minute":end,"destination":home,"place":"home","mode":"inside","activity":"a descansar depois do turno","location":"casa","stroll":false},outside.duplicate(true)]
			a.schedule[-1].minute = 1280+i%30; night_people.append(a)
		a.prepare_stroll()
		world.interactions.targets.append({"id":a.entry.id,"kind":"resident","node":a,"label":a.entry.name,"position":at,"reach":130.0,"radius":12.0})
	world.social_life.actors.append_array(residents); world.social_life.by_id.merge(by_id)
func reachable_house(at: Vector2) -> Vector2:
	var first: Vector2 = routines.doorway(at,true)
	var path: PackedVector2Array = world.find_path(at,first)
	if not path.is_empty() and (path[-1].distance_to(first)<40 or world.can_walk_line(path[-1],first)): return first
	var houses: Array = world.buildings.filter(func(b):return b.label=="Habitação")
	houses.sort_custom(func(a,b):return a.entry_position.distance_squared_to(at)<b.entry_position.distance_squared_to(at))
	for house in houses:
		for offset in [Vector2.ZERO,Vector2(0,32),Vector2(-32,32),Vector2(32,32)]:
			var door: Vector2 = house.entry_position+offset
			if not world.is_walkable(door,20): continue
			path = world.find_path(at,door)
			if not path.is_empty() and (path[-1].distance_to(door)<40 or world.can_walk_line(path[-1],door)): return door
	return first
