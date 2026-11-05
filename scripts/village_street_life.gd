extends "res://scripts/village_population.gd"
## Additional street groups share the resident movement engine and the village clock.
const DATA = preload("res://data/village/street-life.json")
const StreetActor = preload("res://scripts/village_street_actor.gd")
var activity_props: Dictionary = {}
var minute := 480.0
var day := 1
var group_clock := 0.0
var raffle_sales: Dictionary = {}
var gelato_sales: Dictionary = {}
var applause := 0
var shop_windows: Dictionary = {}
var concert: Node2D

func _ready() -> void:
	name = "StreetLifeAndGroups"
	routines.population = self
	by_id.merge(world.population.by_id)
	for i in DATA.data.people.size():
		var entry: Dictionary = DATA.data.people[i]
		var actor := StreetActor.new()
		actor.population = self
		actor.entry = entry
		actor.ordinal = i+40
		actor.name = entry.id
		actor.home = free_point(Vector2(entry.home[0],entry.home[1]),true)
		actor.position = actor.home
		actor.anchor = actor.home
		actor.profile = {"residence":"local","commute_speed":80 if entry.role in ["scout","family"] else 105}
		if entry.has("follow"): actor.profile.guardian = entry.follow
		world.actors.add_child(actor)
		residents.append(actor)
		by_id[entry.id] = actor
		world.interactions.targets.append({"id":"street_person_"+entry.id,"kind":"resident","label":entry.name,"position":actor.position,"reach":160.0,"radius":12.0,"node":actor})
	for actor in residents:
		for authored in actor.entry.plan:
			var block: Dictionary = authored.duplicate(true)
			block.minute = routines.minute(block.at)
			block.destination = destination_for(actor,block.place,block.minute)
			block.location = place_name(block.place)
			actor.schedule.append(block)
		actor.prepare_stroll()
	for object in world.activity_props:
		object.life = self
		activity_props[object.kind] = object
		world.interactions.targets.append({"id":"street_scene_"+object.kind,"kind":"street_scene","label":object.kind,"position":object.position+Vector2(0,40),"reach":175.0,"radius":0.0,"node":object})
	concert = preload("res://scripts/village_concert.gd").new()
	concert.position = Vector2(6600,4950)
	concert.world = world
	add_child(concert)

func place_name(place: String) -> String:
	if place.begins_with("guide_"): return "visita guiada com a Teresa"
	if place.begins_with("family_"): return "passeio da Leonor, Daniel e Matilde"
	return {"raffles":"mesa de rifas do agrupamento","concert_player":"concerto no adro de São Martinho","concert_audience":"público do concerto","icecream_vendor":"banca Nannarella"}.get(place,"lojas e largos da vila")

func destination_for(actor: CharacterBody2D, place: String, at_minute: float) -> Vector2:
	if place.begins_with("family_"):
		var mother: CharacterBody2D = world.population.by_id.leonor
		var block: Dictionary = mother.schedule[routines.index_at(mother,at_minute)]
		if block.mode=="inside":
			routines.doors[block.destination] = world.population.routines.doors.get(block.destination,"")
			return block.destination
		return routines.clear_destination(block.destination+Vector2(-140,45),[])
	if place=="home":
		var key: String = "scouts" if actor.entry.role=="scout" else actor.entry.id
		if not routines.residences.has(key):
			var hotel: bool = actor.entry.role in ["tourist","shopper"]
			routines.residences[key] = routines.doorway(actor.home+Vector2(220,0),not hotel,"Lawrence’s Hotel" if hotel else "")
		return routines.residences[key]
	if place=="meal": return routines.doorway(actor.home,false,"Café")
	var preferred: Vector2 = actor.home
	if place.begins_with("guide_"):
		var guide: CharacterBody2D = world.population.by_id.teresa
		var block: Dictionary = guide.schedule[routines.index_at(guide,at_minute)]
		preferred = block.destination+Vector2(actor.entry.offset[0],actor.entry.offset[1])
	elif place.begins_with("window_"):
		var label: String = {"window_ceramics":"Loja de louças","window_crafts":"Artesanato","window_bakery":"Padaria"}[place]
		var shops: Array = world.buildings.filter(func(b): return b.label==label)
		shops.sort_custom(func(a,b): return a.entry_position.distance_squared_to(Vector2(10100,5200))<b.entry_position.distance_squared_to(Vector2(10100,5200)))
		for shop in shops:
			var spot: Vector2 = shop.entry_position+Vector2(0,55)
			if world.is_walkable(spot,20):
				preferred = spot
				shop_windows[place] = shop
				break
	else:
		preferred = {"raffles":Vector2(8850,3210),"palace":Vector2(10280,2380),"republic":Vector2(10000,3330),"market":Vector2(12150,8050),"church":Vector2(6920,5040),"icecream_vendor":Vector2(10835,2440),"concert_player":Vector2(6760,4930),"concert_audience":Vector2(6660,5170)}.get(place,actor.home)
		if place=="concert_audience": preferred = Vector2(6880+(int(actor.entry.column)-2)*110,5190+actor.ordinal%2*62)
		elif actor.entry.has("offset"): preferred += Vector2(actor.entry.offset[0],actor.entry.offset[1])
	return routines.clear_destination(preferred,[])

func step(delta: float, cycle: RefCounted) -> void:
	minute = cycle.minutes
	day = cycle.day
	super.step(delta,cycle)
	group_clock -= delta
	if group_clock<=0:
		group_clock = 1.2
		_follow_groups(false)
	_update_props()
	concert.step(delta,cycle)

func synchronize(cycle: RefCounted, force := false) -> void:
	minute = cycle.minutes
	day = cycle.day
	super.synchronize(cycle,force)
	_follow_groups(true)
	_update_props()
	if is_instance_valid(concert): concert.step(0,cycle)

func _follow_groups(catch_up: bool) -> void:
	for actor in residents:
		if not actor.available() or actor.encounter_id>=0: continue
		if actor.appointment.place.begins_with("window_"):
			var shop: Node2D = shop_windows.get(actor.appointment.place)
			if shop!=null: actor.facing_left = shop.position.x<actor.position.x
		var leader: CharacterBody2D
		if actor.appointment.place.begins_with("guide_"): leader = world.population.by_id.teresa
		elif actor.appointment.place.begins_with("family_") and actor.appointment.mode!="inside": leader = world.population.by_id.leonor
		else: continue
		if not leader.available(): continue
		var preferred: Vector2 = leader.position+Vector2(actor.entry.offset[0],actor.entry.offset[1])
		var target: Vector2 = preferred if world.is_walkable(preferred,20) else free_point(preferred)
		if target==Vector2.INF: continue
		if catch_up:
			actor.position = target
			actor.anchor = target
			actor._arrive()
		elif actor.position.distance_to(target)>100 and actor.greet_time<=0:
			actor.anchor = target
			actor._begin_walk(target,"commuting")

func _update_props() -> void:
	for kind in activity_props:
		var object: Node2D = activity_props[kind]
		object.refresh(is_open(kind))
		object.visible = true if kind=="icecream" else object.opened
		object.queue_redraw()

func is_open(kind: String) -> bool:
	match kind:
		"icecream": return minute>=660 and minute<1200 and not (minute>=870 and minute<900)
		"raffles": return (minute>=540 and minute<750) or (minute>=840 and minute<1065)
		"concert": return minute>=1080 and minute<1260
	return false

func interact_role(role: String, player: CharacterBody2D, actor: CharacterBody2D = null) -> String:
	if role=="scout":
		if not is_open("raffles"): return "As rifas voltam às 9h e às 14h. Depois, o agrupamento vai preparar a sua atividade de Minecraft!"
		if player==null: return "Uma rifa para a atividade de Minecraft do agrupamento?"
		var key := str(day)+":"+str(player.kind)
		if raffle_sales.has(key): return "Já tens a rifa n.º %03d de hoje. Obrigado por ajudares a nossa atividade de Minecraft!"%raffle_sales[key]
		var number := day*100+raffle_sales.size()+1
		var ticket := {"type":"raffle_ticket","name":"Rifa Minecraft n.º %03d"%number,"porte":1,"number":number,"id":"raffle_"+key}
		if not player.inventory.try_add(ticket): return "Liberta um espaço na bolsa para guardar a rifa."
		raffle_sales[key] = number
		return "%s comprou a rifa n.º %03d. O agrupamento agradece: já falta menos para a atividade de Minecraft!"%[player.name,number]
	if role=="gelato":
		if not is_open("icecream"): return "Nannarella · gelados das 11h às 20h, com pausa das 14h30 às 15h."
		if player==null: return "Pistácio, morango e stracciatella: gelados Nannarella feitos para passear."
		var flavors := ["pistácio","morango","stracciatella"]
		var index := int(gelato_sales.get(player.kind,0))
		var flavor: String = flavors[index%3]
		if not player.inventory.try_add({"type":"gelato","name":"Gelado Nannarella de "+flavor,"porte":1,"flavor":index%3,"id":"gelato_"+str(player.kind)+"_"+str(index)}): return "A bolsa está cheia. Liberta um lugar para levar o gelado."
		gelato_sales[player.kind] = index+1
		return "%s escolheu um gelado Nannarella de %s. O Enzo prepara o cone e deseja um bom passeio."%[player.name,flavor]
	if role=="musician":
		if not is_open("concert"): return "Clara e Farid tocam juntos no adro de São Martinho, das 18h às 21h."
		applause += 1
		return "Te e Jo ficam a ouvir o violino e a guitarra. No fim da frase, juntam-se às palmas; os músicos agradecem com um sorriso."
	return actor.entry.greeting if actor!=null else "A vila está cheia de histórias."
