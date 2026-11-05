extends Node2D
## Shared relationship, individual needs and a wallet, owned by the persistent exploration scene.
signal changed
const Catalog = preload("res://scripts/bakery_catalog.gd")
const HUNGER_RATE := .075 # points per game minute, same clock as the village
const REST_RATE := .32
const UNLOCKS := {"climbing":{"at":20.0,"name":"Escalar o Penedo da Amizade"},"rhythm":{"at":40.0,"name":"Entrar na roda de ritmo"},"viewpoint":{"at":60.0,"name":"Uma conversa só dos dois no miradouro"},"evening":{"at":80.0,"name":"A conversa do fim do dia"}}
const CAPS := {"walk":6.0,"explore":12.0,"talk":12.0,"music":6.0,"cinema":4.0,"football":8.0,"foosball":12.0,"help":8.0,"share":6.0,"rhythm":8.0,"climb":12.0}
var scene: Node2D
var world: Node2D:
	get: return scene.world
var bond := 0.0
var needs: Array[Dictionary] = [{"hunger":18.0,"fatigue":12.0},{"hunger":22.0,"fatigue":16.0}]
var coins := 2400
var awarded: Dictionary = {}
var daily: Dictionary = {}
var earned_today: Dictionary = {}
var meters_together := 0.0
var last_positions: Array[Vector2] = []
var listening: Dictionary = {}
var serial := 0
var dirty := false
var save_clock := 0.0
var storage_enabled := true
var restored_bags := false
var save_path := "user://tejo-journey-v1.json"
var cached_bags: Dictionary = {}
var panel: CanvasLayer
var shop_panel: CanvasLayer
func _ready() -> void:
	name = "SharedJourneyAndNeeds"
	var runner: Script = Engine.get_main_loop().get_script()
	storage_enabled = not (runner!=null and runner.resource_path.begins_with("res://tests/")) and not OS.get_cmdline_user_args().has("--living-test")
	load_state(); align_calendar(world)
	for person in scene.people:
		last_positions.append(person.position)
		person.inventory.changed.connect(_bags_changed)
	_bags_changed()
	panel = preload("res://scripts/village_living_panel.gd").new(); panel.director = self; add_child(panel)
	shop_panel = preload("res://scripts/bakery_panel.gd").new(); shop_panel.journey = self; add_child(shop_panel)
func together(radius := 240.0) -> bool:
	return scene.people.size()==2 and scene.people[0].world==world and scene.people[1].world==world and scene.people[0].position.distance_to(scene.people[1].position)<=radius and world.can_walk_line(scene.people[0].position,scene.people[1].position)
func at_activity(at: Vector2,radius := 450.0) -> bool:
	return together(420) and scene.people.all(func(p):return p.position.distance_to(at)<=radius)
func level() -> int: return mini(5,int(bond/20.0))
func can(feature: String) -> bool: return UNLOCKS.has(feature) and bond>=float(UNLOCKS[feature].at)
func requirement(feature: String) -> String:
	var data: Dictionary = UNLOCKS[feature]
	return "%s · ligação %d/100 (atual: %d). Ganhem ligação com passeios, conversas, música e jogos juntos."%[data.name,int(data.at),int(bond)]
func notify(text: String) -> void:
	if is_instance_valid(scene.hud): scene.hud.show_comment(text)
func award(kind: String,key: String,points: float,reward := 0,once_ever := false) -> bool:
	if not CAPS.has(kind) or points<=0: return false
	var day := int(scene.day_cycle.day)
	var stamp := kind+":"+key+("" if once_ever else ":"+str(day))
	if awarded.has(stamp): return false
	var budget_key := str(day)+":"+kind
	var given: float = minf(points,maxf(0,float(CAPS[kind])-float(daily.get(budget_key,0))))
	if given<=0: return false
	awarded[stamp] = true; daily[budget_key] = float(daily.get(budget_key,0))+given
	var before := level(); bond = clampf(bond+given,0,100)
	# Paid rounds are capped separately; replaying menu choices cannot mint money.
	if reward>0 and int(earned_today.get(budget_key,0))<3:
		coins += reward; earned_today[budget_key] = int(earned_today.get(budget_key,0))+1
	dirty = true; changed.emit()
	if level()>before:
		var unlocked: Array[String] = []
		for feature in UNLOCKS:
			if float(UNLOCKS[feature].at)<=bond and float(UNLOCKS[feature].at)>before*20: unlocked.append(str(UNLOCKS[feature].name))
		notify("Ligação · nível %d. %s"%[level(),"Disponível: "+" · ".join(unlocked) if not unlocked.is_empty() else "O caminho já tem muitas histórias dos dois."])
	return true
func record_activity(kind: String,key: String,points: float,at: Vector2,reward := 0,once_ever := false) -> bool:
	if not at_activity(at): return false
	return award(kind,key,points,reward,once_ever)
func step_needs(minutes: float,people: Array,climbing := false) -> void:
	if minutes<=0: return
	for i in mini(2,people.size()):
		var person: CharacterBody2D = people[i]
		needs[i].hunger = clampf(float(needs[i].hunger)+minutes*HUNGER_RATE,0,100)
		var sleep: bool = not climbing and person.is_sleeping()
		var bench: bool = not climbing and person.seated and not person.seating
		if sleep or bench:
			needs[i].fatigue = clampf(float(needs[i].fatigue)-minutes*REST_RATE*(1.0 if sleep else .25),0,100)
		else:
			var rate := .10 if climbing or person.running else (.065 if person.moving else .045)
			needs[i].fatigue = clampf(float(needs[i].fatigue)+minutes*rate,0,100)
	dirty = true; changed.emit()
func step(delta: float) -> void:
	if delta<=0 or scene.get_tree().paused or scene.exploration_map.visible: return
	step_needs(delta*scene.day_cycle.minutes_per_second,scene.people)
	var close := together()
	if last_positions.size()!=2: last_positions = [scene.people[0].position,scene.people[1].position]
	var distances: Array[float] = []
	for i in 2:
		distances.append(scene.people[i].position.distance_to(last_positions[i])); last_positions[i] = scene.people[i].position
	if close and scene.people.all(func(p):return p.moving) and distances.max()<160:
		meters_together += minf(distances[0],distances[1])
		if meters_together>=800:
			meters_together -= 800; serial += 1; award("walk",str(serial),.75)
	if close:
		for place in world.landmarks:
			if scene.people.all(func(p):return p.position.distance_to(place.position)<float(place.radius)):
				award("explore",scene.region_id+":"+str(place.id),2,0,true)
	_listen(delta,close)
	save_clock += delta
	if dirty and save_clock>=20: save_state(); save_clock = 0
func _listen(delta: float,close: bool) -> void:
	var sources: Dictionary = {}
	if close and scene.people.all(func(p):return not p.moving):
		if is_instance_valid(scene.rest_dream) and scene.rest_dream.wanted and scene.rest_dream.player.playing: sources.rest = true
		if world.get("nightlife")!=null and world.nightlife.opened and world.nightlife.music.playing and at_activity(world.nightlife.center,500): sources.bar = true
		if world.get("street_life")!=null and world.street_life.concert.active and at_activity(world.street_life.concert.position,450): sources.concert = true
		if world.get("festival_life")!=null and world.festival_life.cinema_open() and at_activity(world.festival_life.event_props.cinema.position,480): sources.cinema = true
	for key in ["rest","bar","concert","cinema"]:
		if not sources.has(key): listening.erase(key); continue
		listening[key] = float(listening.get(key,0))+delta
		# Each screening lasts 24 game minutes (24 real seconds at the normal clock).
		var duration := 15.0 if key=="cinema" else 45.0
		if float(listening[key])>=duration:
			award("cinema" if key=="cinema" else "music",key,4 if key=="cinema" else 3)
func step_minigame(delta: float) -> void:
	if scene.get_tree().paused: return
	scene.day_cycle.advance(delta)
	step_needs(delta*scene.day_cycle.minutes_per_second,scene.people,true)
	save_clock += delta
	if dirty and save_clock>=20: save_state(); save_clock = 0
func dialogue_completed(id: String) -> void:
	if together(420): award("talk",id,2,0,true)
func controls_blocked() -> bool:
	return scene.get_tree().paused or scene.dialogue.is_active() or scene.exploration_map.visible or modal_open() or (world.get("living_life")!=null and world.living_life.panel.opened)
func modal_open() -> bool: return (is_instance_valid(panel) and panel.opened) or (is_instance_valid(shop_panel) and shop_panel.opened)
func handle_input(event: InputEvent) -> bool:
	if shop_panel.opened: return shop_panel.handle_input(event)
	return panel.handle_input(event)
func open_food(owner: int,index: int) -> void:
	if controls_blocked() or owner!=scene.selected or index<0 or index>=scene.people[owner].inventory.items.size(): return
	var item: Dictionary = scene.people[owner].inventory.items[index]
	if not Catalog.food(item): return
	var other := 1-owner
	var verb: String = "Beber" if item.get("drink",false) else "Comer"
	var id: String = str(item.get("id",""))
	panel.show_choices(item.name,"Saciedade: %d. Partilhar divide a porção entre os dois. Dormir recupera cansaço a ×1; um banco a ×0,25. Bebidas não substituem descanso."%int(Catalog.nutrition(item)),[verb+" · "+scene.people[owner].name,"Dar a "+scene.people[other].name,"Partilhar entre Te e Jo","Pousar no chão"],func(choice):
		if index>=scene.people[owner].inventory.items.size() or str(scene.people[owner].inventory.items[index].get("id",""))!=id: notify("Esse produto já não está nessa posição da bolsa."); return
		if choice==3: scene._drop_item(owner,index)
		else: notify(consume(owner,index,choice)))
func consume(owner: int,index: int,choice: int) -> String:
	if owner<0 or owner>1 or choice<0 or choice>2: return "Escolha inválida."
	var bag: RefCounted = scene.people[owner].inventory
	if index<0 or index>=bag.items.size() or not Catalog.food(bag.items[index]): return "Esse objeto não é um produto da pastelaria."
	if choice>0 and not together(): return "Aproxima o Te e o Jo para passarem ou partilharem o lanche."
	var food: Dictionary = bag.take(index)
	var satiety: float = Catalog.nutrition(food)
	var recipient := owner if choice==0 else 1-owner
	if choice==2:
		for need in needs: need.hunger = maxf(0,float(need.hunger)-satiety*.5)
		award("share",food.type,2 if satiety>0 else 1)
	else: needs[recipient].hunger = maxf(0,float(needs[recipient].hunger)-satiety)
	dirty = true; changed.emit()
	if satiety==0: return "A água refresca o passeio. Para matar a fome, há bolos e amendoins na pastelaria."
	return "Te e Jo partilharam "+food.name.to_lower()+". Cada um comeu metade." if choice==2 else scene.people[recipient].name+" acabou "+food.name.to_lower()+". A fome diminuiu."
func open_progress() -> void:
	if controls_blocked(): return
	var text := "Ligação %d/100 · nível %d. Fome e cansaço aumentam com o tempo. Dormir no chão recupera a ×1; num banco, ×0,25.\n\n"%[int(bond),level()]
	for key in UNLOCKS:
		text += ("Disponível · " if can(key) else "Ligação %d · "%int(UNLOCKS[key].at))+str(UNLOCKS[key].name)+"\n"
	text += "\nGanham ligação a explorar, conversar, ouvir música, assistir ao cinema, partilhar lanches e terminar jogos próximos um do outro. Os primeiros resultados de jogos e ajudas dão dinheiro para a pastelaria."
	panel.show_choices("Te + Jo · o nosso caminho",text,["Continuar juntos"],func(_i):pass)
func align_calendar(target: Node2D) -> void:
	if target.get("living_life")!=null:
		scene.day_cycle.day = maxi(int(scene.day_cycle.day),int(target.living_life.state.last_day))
		target.living_life.calendar_offset = 0
func _bags_changed() -> void:
	if scene==null: return
	for p in scene.people:
		if is_instance_valid(p): cached_bags[p.name] = p.inventory.items.duplicate(true)
	dirty = true; changed.emit()
func snapshot() -> Dictionary:
	_bags_changed()
	return {"version":1,"bond":bond,"needs":needs,"coins":coins,"awarded":awarded,"daily":daily,"earned":earned_today,"serial":serial,"day":scene.day_cycle.day,"minute":scene.day_cycle.minutes,"bags":cached_bags,"dialogue_flags":scene.dialogue.flags,"dialogue_visits":scene.dialogue.visits}
func save_state() -> bool:
	if not storage_enabled: return false
	var file := FileAccess.open(save_path+".tmp",FileAccess.WRITE)
	if file==null: return false
	file.store_string(JSON.stringify(snapshot(),"\t")); file.close()
	if DirAccess.rename_absolute(ProjectSettings.globalize_path(save_path+".tmp"),ProjectSettings.globalize_path(save_path))!=OK: return false
	dirty = false; return true
func restore(data: Dictionary) -> bool:
	if int(data.get("version",0))!=1 or not data.get("needs") is Array or data.needs.size()!=2: return false
	for need in data.needs:
		if not need is Dictionary or not need.get("hunger") is float and not need.get("hunger") is int or not need.get("fatigue") is float and not need.get("fatigue") is int: return false
	bond = clampf(float(data.get("bond",0)),0,100); coins = clampi(int(data.get("coins",2400)),0,999999)
	for i in 2: needs[i] = {"hunger":clampf(float(data.needs[i].hunger),0,100),"fatigue":clampf(float(data.needs[i].fatigue),0,100)}
	awarded = data.get("awarded",{}) if data.get("awarded") is Dictionary else {}
	daily = data.get("daily",{}) if data.get("daily") is Dictionary else {}; earned_today = data.get("earned",{}) if data.get("earned") is Dictionary else {}
	serial = maxi(0,int(data.get("serial",0))); scene.day_cycle.day = maxi(1,int(data.get("day",1))); scene.day_cycle.minutes = clampf(float(data.get("minute",480)),0,1439.999)
	if data.get("dialogue_flags") is Dictionary: scene.dialogue.flags = data.dialogue_flags.duplicate(true)
	if data.get("dialogue_visits") is Dictionary: scene.dialogue.visits = data.dialogue_visits.duplicate(true)
	if data.get("bags") is Dictionary:
		for p in scene.people:
			p.inventory.items.clear()
			for item in data.bags.get(p.name,[]):
				if item is Dictionary and item.get("type") is String and item.get("name") is String and int(item.get("porte",0)) in [1,2,3]: p.inventory.try_add(item)
		restored_bags = true
	changed.emit(); return true
func load_state() -> bool:
	if not storage_enabled or not FileAccess.file_exists(save_path): return false
	var value = JSON.parse_string(FileAccess.get_file_as_string(save_path))
	return restore(value) if value is Dictionary else false
func _exit_tree() -> void:
	if storage_enabled: save_state()
