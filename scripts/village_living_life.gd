extends "res://scripts/village_population.gd"
## Shared community state, real addresses, contextual interactions and environmental stories.
const DATA = preload("res://data/village/living-world.json")
const ART = preload("res://data/village/living-art.json")
const StoryActor = preload("res://scripts/village_story_actor.gd")
const LivingObject = preload("res://scripts/village_living_object.gd")
var textures: Dictionary = {}
var living_paint: ShaderMaterial
var objects: Array[Node2D] = []
var addresses: Array[Dictionary] = []
var windows: Array[Node2D] = []
var state: Dictionary = {"version":1,"people":{},"quests":{},"events":{},"ledger":[],"lost":[],"last_day":1}
var chalk: Array = []
var dirty := false
var save_path := "user://sintra-community-v1.json"
var storage_enabled := true
var minute := 480.0
var day := 1
var calendar_offset := 0
var decision := 0.0
var save_clock := 0.0
var events: Node2D
var panel: CanvasLayer
var conversation: RefCounted
var animals: Node2D
var hat: Node2D
var hat_path := PackedVector2Array()
var hat_owner := "sven"
var parcel: Node2D
var escort := false
var post_target := 0
var post_delivering := false
var rain := false
var wind := false
var window_passes := 0
var last_window_pass := -INF
var current_beat := 0
var beat_started := 0.0
var audio: AudioStreamPlayer
var sound_source := Vector2.ZERO
var sound_left := 0.0
var bells_rung := 0
var sweeps := 0
var rivalry := 0
var loaded_items_pending := true
var rival_park := Vector2.INF

func _ready() -> void:
	name = "LivingSintraCommunity"
	living_paint = ShaderMaterial.new()
	living_paint.shader = preload("res://shaders/village_living_cutout.gdshader")
	var runner: Script = Engine.get_main_loop().get_script()
	var test_run: bool = runner!=null and runner.resource_path.begins_with("res://tests/")
	storage_enabled = not test_run and not OS.get_cmdline_user_args().has("--living-test")
	load_state()
	calendar_offset = maxi(0,int(state.last_day)-1)
	routines.population = self
	by_id.merge(world.population.by_id)
	by_id.merge(world.street_life.by_id)
	by_id.merge(world.festival_life.by_id)
	for key in ART.data.atlases: textures[key] = load(ART.data.atlases[key].path)
	textures.objects = load(ART.data.object_path)
	textures.animals = load(ART.data.animal_path)
	for i in DATA.data.people.size():
		var entry: Dictionary = DATA.data.people[i].duplicate(true)
		entry.wait_seconds = 5+i%7
		if entry.id=="plutonio" and (not DATA.data.cameo.enabled or OS.get_cmdline_user_args().has("--public-release")):
			entry.name = DATA.data.cameo.fallback
			entry.greeting = "O Prumo convida os vizinhos a experimentar uma batida original."
			entry.living_fallback = true
		var actor := StoryActor.new()
		actor.population = self
		actor.entry = entry
		actor.ordinal = i+100
		actor.name = entry.id
		actor.home = free_point(Vector2(entry.home[0],entry.home[1]),true)
		actor.position = actor.home
		actor.anchor = actor.home
		actor.profile = {"residence":"hotel" if entry.role in ["lost","hiker","cameo"] else "local","commute_speed":175 if entry.role=="late" else (105 if entry.age>=65 else 130)}
		actor.memory = state.people.get(entry.id,{})
		state.people[entry.id] = actor.memory
		world.actors.add_child(actor)
		residents.append(actor)
		by_id[entry.id] = actor
		world.interactions.targets.append({"id":"community_"+entry.id,"kind":"resident","label":entry.name,"position":actor.position,"reach":155.0,"radius":12.0,"node":actor})
	_build_addresses()
	for actor in residents: _plan(actor)
	_build_objects()
	_setup_rivals()
	panel = preload("res://scripts/village_living_panel.gd").new()
	panel.director = self
	add_child(panel)
	events = preload("res://scripts/village_living_events.gd").new()
	events.director = self
	world.add_child(events)
	animals = preload("res://scripts/village_living_animals.gd").new()
	animals.director = self
	animals.home = routines.clear_destination(Vector2(8500,8540),[])
	world.add_child(animals)
	object("feed","feed_pigeons",animals.home+Vector2(100,55),"Largo dos pombos")
	object("cat","sardinha",animals.cat,"Sardinha")
	hat = object("hat","wind_hat",by_id.sven.home,"Chapéu do Sven")
	hat.hide()
	parcel = object("box","late_parcel",by_id.dinis.home,"Encomenda do Dinis")
	parcel.hide()
	_restore_objects()
	post_target = int(state.quests.get("post_destination",int(state.quests.get("post_deliveries",0))%addresses.size()))%addresses.size()
	audio = AudioStreamPlayer.new()
	audio.volume_db = -20
	add_child(audio)
	world.visibility_changed.connect(_visibility)

func _visibility() -> void:
	if not world.is_visible_in_tree(): panel.finish(); audio.stop(); save_state()

func player() -> CharacterBody2D:
	for person in world.people:
		if person.controlled: return person
	return null
func remaining(actor: CharacterBody2D) -> float:
	return fposmod(float(actor.schedule[(actor.routine_index+1)%actor.schedule.size()].minute)-minute,1440)
func cameo_active() -> bool: return day%3==0 and minute>=1050 and minute<1170
func say(actor: CharacterBody2D,text: String,pose := "speak") -> void:
	if is_instance_valid(world.social_life): world.social_life._say(actor,text,pose)
func tell(text: String) -> void:
	var scene: Node = world.get_parent()
	if scene.get("hud")!=null: scene.hud.show_comment(text)
func cancel_for(id: String) -> void:
	if is_instance_valid(events): events.cancel_for(id)
func object(kind: String,key: String,at: Vector2,label := "") -> Node2D:
	var node := LivingObject.new()
	node.director = self
	node.kind = kind
	node.key = key
	node.label = label
	node.position = at
	world.actors.add_child(node)
	objects.append(node)
	world.interactions.targets.append({"id":"living_"+key,"kind":"living_scene","node":node,"label":label,"position":at,"reach":125.0,"radius":0.0})
	return node
func _build_addresses() -> void:
	var zones: Array = ["ferraria","padarias","pipa","ferreira","martinho","byron","azulejos","portadas","lawrence","jardins","sassetti","valencas"]
	var used: Array = []
	for i in zones.size():
		var loc: Array = DATA.data.zones[zones[i]]
		var target := Vector2(loc[0],loc[1])
		var houses: Array = world.buildings.filter(func(b):return not used.has(b.entry_id) and b.label=="Habitação" and not b.has_meta("side_facing"))
		houses.sort_custom(func(a,b):return a.entry_position.distance_squared_to(target)<b.entry_position.distance_squared_to(target))
		for building in houses:
			var at: Vector2 = world.interactions.find_drop_position(building.entry_position)
			if at==Vector2.INF or world.find_path(world.menu_spawn,at).is_empty(): continue
			used.append(building.entry_id)
			var address: String = "Rua da Ferraria, 17" if i==0 else world.area_at(at)+", "+str(3+i*2)
			addresses.append({"id":building.entry_id,"name":address,"at":at,"building":building})
			var bell: Node2D = object("bell","bell_"+str(i),at,address)
			bell.contact = at
			bell.building = building
			break
func _plan(actor: CharacterBody2D) -> void:
	var home: Vector2 = routines.doorway(actor.home,true)
	var work: Vector2 = routines.clear_destination(actor.home,[])
	var near: Vector2 = routines.clear_destination(work+Vector2(210,75),[])
	var meal: Vector2 = routines.doorway(work+Vector2(100,50),false,"Café")
	var mode := "window" if actor.entry.role in ["window","plants","shutters","rug"] else "activity"
	if actor.entry.role in ["window","plants","shutters","rug","houses","collector","cat_neighbor","cat_owner","postcards","clock"]:
		var address: Dictionary = _address_near(work)
		work = address.at
		_attach_window(actor,address.building)
	var plan: Array = [[0,home,"home","a descansar","inside"],[465+actor.ordinal%30,work,"work",actor.entry.activity,mode],[745+actor.ordinal%15,meal,"meal","a almoçar","inside"],[820+actor.ordinal%25,near,"afternoon",actor.entry.activity,"activity"],[1120+actor.ordinal%25,work,"work",actor.entry.activity,mode],[1210+actor.ordinal%30,meal,"meal","a jantar","inside"],[1280,near,"evening","a conversar com vizinhos","activity"],[1360,home,"home","a dormir","inside"]]
	if actor.entry.role in ["houses","collector","cat_neighbor","cat_owner","postcards","clock"] and is_instance_valid(actor.window_node):
		plan[6][1] = work
		plan[6][4] = "window"
	if actor.entry.role=="cameo": plan = [[0,home,"home","a descansar","inside"],[1050,work,"work","na roda de ritmo original","activity"],[1170,meal,"meal","a jantar","inside"],[1260,home,"home","a descansar","inside"]]
	if actor.entry.role=="sweep": plan[3][1] = routines.clear_destination(Vector2(11600,6970),[]); plan[4][1] = routines.clear_destination(Vector2(9970,4600),[])
	if actor.entry.role=="steps":
		plan[1][1] = routines.clear_destination(world.stair_rect(world.TERRACES.data.terraces[0]).get_center(),[])
		plan[3][1] = routines.clear_destination(world.stair_rect(world.TERRACES.data.terraces[1]).get_center(),[])
		plan[4][1] = routines.clear_destination(world.stair_rect(world.TERRACES.data.terraces[2]).get_center(),[])
	if actor.entry.role=="late": plan[3][1] = routines.clear_destination(Vector2(8500,8540),[],26)
	if actor.entry.role=="detective": plan[3][1] = routines.clear_destination(Vector2(19000,4840),[])
	if actor.entry.role=="houses": plan[3][1] = routines.clear_destination(Vector2(9950,9600),[])
	if actor.entry.role=="lost":
		plan[1][1] = routines.clear_destination(Vector2(9820,2450),[])
		plan[3][1] = routines.clear_destination(Vector2(13800,6670),[])
		plan[4][1] = routines.clear_destination(Vector2(18400,7770),[])
	for row in plan: actor.schedule.append({"minute":row[0],"destination":row[1],"place":row[2],"activity":row[3],"mode":row[4],"location":world.area_at(row[1]),"stroll":row[4]=="activity" and actor.entry.role not in ["post","steps","bench","cameo"]})
	actor.prepare_stroll()
func _address_near(at: Vector2) -> Dictionary:
	var choices: Array = addresses.duplicate()
	choices.sort_custom(func(a,b):return a.at.distance_squared_to(at)<b.at.distance_squared_to(at))
	return choices[0]
func _attach_window(actor: CharacterBody2D,building: Node2D) -> void:
	var window := LivingObject.new()
	window.director = self
	window.kind = "window"
	window.resident_owner = actor
	window.building = building
	window.contact = building.entry_position
	window.key = "window_"+actor.entry.id
	# Match the native panes through the existing lighting data whenever possible.
	var panes: Array = []
	for spec in world.architecture_data+world.BLOCKS.data.buildings:
		if spec.id!=building.entry_id: continue
		if not world.lighting.GLASS.data.has(spec.atlas): break
		var source: Rect2 = world._source(spec.atlas,int(spec.type))
		var factor: float = spec.width/source.size.x
		for raw in world.lighting.GLASS.data[spec.atlas][int(spec.type)]:
			var rect := Rect2(raw[0],raw[1],raw[2],raw[3])
			var top := (rect.position-source.position)*factor-Vector2(building.visual_size.x*.5,building.visual_size.y)
			if spec.get("sprite_mirror",false): top.x = -top.x-rect.size.x*factor
			panes.append(Rect2(top,rect.size*factor))
			window.shutter_sources.append({"rect":Rect2(top,rect.size*factor),"left":Rect2(rect.position-Vector2(rect.size.x*.6,0),Vector2(rect.size.x*.6,rect.size.y)),"right":Rect2(Vector2(rect.end.x,rect.position.y),Vector2(rect.size.x*.6,rect.size.y))})
		break
	if panes.is_empty(): window.free(); return
	var used := windows.filter(func(w):return w.building==building).size()
	panes.sort_custom(func(a,b):return absf(a.get_center().y+280)<absf(b.get_center().y+280))
	window.pane = panes[used%panes.size()]
	building.add_child(window)
	window.material = living_paint
	if actor.entry.has("living_art") or actor.entry.get("neighbour",false): actor.window_node = window
	windows.append(window)
	objects.append(window)
	world.interactions.targets.append({"id":"living_"+window.key,"kind":"living_scene","node":window,"label":actor.entry.name,"position":window.contact,"reach":165.0,"radius":0.0})
func _build_objects() -> void:
	var frontage_index := 0
	for building in world.buildings:
		if building.label in ["Habitação",""] or building.has_meta("side_facing"): continue
		frontage_index += 1
		if frontage_index%2 or frontage_index>100: continue
		var shop_at: Vector2 = world.interactions.find_drop_position(building.entry_position)
		if shop_at==Vector2.INF: continue
		var shop: Node2D = object("shop","shop_"+building.entry_id,shop_at,building.label)
		shop.building = building
	for zone in DATA.data.zones:
		var raw: Array = DATA.data.zones[zone]
		var at: Vector2 = routines.clear_destination(Vector2(raw[0],raw[1])+Vector2(260,-180),[])
		object("board","board_"+zone,at,"Notícias de "+world.area_at(at))
		object("bin","bin_"+zone,routines.clear_destination(at+Vector2(150,90),[]),"Caixote da rua")
		if zone in ["republic","pipa","portadas","sassetti","hortensias","ferreira"]: object("chalk","chalk_"+zone,routines.clear_destination(at+Vector2(0,170),[]),"Giz na calçada")
		if zone in ["republic","market","azulejos","liberdade"]: object("vending","postcards_"+zone,routines.clear_destination(at+Vector2(-180,80),[]),"Postais da vila")
	object("barter","jacinta_trades",routines.clear_destination(by_id.jacinta.home+Vector2(90,50),[]),"Trocas da Jacinta")
	object("chest","lost_found",routines.clear_destination(by_id.celso.home+Vector2(100,50),[]),"Achados e perdidos do Celso")
	for spec in [["mourisca",Vector2(15780,5240)],["bell",Vector2(6650,4900)],["steps",Vector2(5520,10040)]]:
		object("sound",spec[0],routines.clear_destination(spec[1],[]),{"mourisca":"Água da Fonte Mourisca","bell":"Sino de São Martinho","steps":"Passos na escadaria"}[spec[0]])
	object("fountain","mourisca_water",routines.clear_destination(Vector2(15780,5240)+Vector2(100,100),[]),"Fonte Mourisca · água e inscrição")
	object("clue","painting_detail",routines.clear_destination(Vector2(13800,6850),[]),"O banco que Amália pintou")
	object("pot","irene_pot",routines.clear_destination(by_id.irene.home+Vector2(150,60),[]),"Begónia da Irene")
func synchronize(cycle: RefCounted, force := false) -> void:
	minute = cycle.minutes
	day = cycle.day+calendar_offset
	if is_instance_valid(events): events.reset()
	if is_instance_valid(panel): panel.finish()
	super.synchronize(cycle,force)
	if not cameo_active(): by_id.plutonio._inside()
	for actor in residents: actor._update_window()
	for window in windows: window.queue_redraw()
	_update_weather()
func step(delta: float,cycle: RefCounted) -> void:
	minute = cycle.minutes
	day = cycle.day+calendar_offset
	super.step(delta,cycle)
	if not cameo_active(): by_id.plutonio._inside()
	_restore_bags()
	state.last_day = day
	_update_weather()
	if rain and not chalk.is_empty(): chalk.clear(); dirty = true
	if is_instance_valid(animals): animals.step(delta)
	if is_instance_valid(events): events.step(delta)
	_step_post(delta)
	_step_sven()
	_step_hat(delta)
	_step_audio(delta)
	for node in objects:
		node.clock += delta
		if node.kind=="window":
			node.shutter_closed = move_toward(node.shutter_closed,1.0 if minute<465 or minute>1355 else 0.0,delta*.4)
			node.queue_redraw()
		if node.kind=="cat": node.position = animals.cat
		if node.state>0 and node.kind in ["pot","fountain"]: node.state = maxi(0,node.state-1); node.queue_redraw()
	decision -= delta
	if decision<=0:
		decision = 2
		_observe_street()
		_sweep()
		_rivals()
		_daily_work()
		for window in windows:
			window.queue_redraw()
	save_clock += delta
	if dirty and save_clock>5: save_state(); save_clock = 0
	queue_redraw()
func _update_weather() -> void:
	rain = day%5==0 and minute>=660 and minute<840
	wind = day%2==1 and minute>=780 and minute<1050
func _observe_street() -> void:
	var p: CharacterBody2D = player()
	if not is_instance_valid(p): return
	for address in addresses:
		if p.position.distance_to(address.at)<90 and post_target==addresses.find(address):
			state.quests["post_known_"+str(post_target)] = true
	var watcher: CharacterBody2D = by_id.alzira
	if watcher.state=="window" and p.position.distance_to(watcher.position)<420 and elapsed-last_window_pass>25:
		last_window_pass = elapsed
		window_passes += 1
		watcher.memory.passes = int(watcher.memory.get("passes",0))+1
		var line: String = "Outra vez por aqui? A rua não é assim tão comprida."
		if p.velocity.length()>190: line = "Devagar nessa calçada! O chão não precisa de ser ultrapassado."
		elif not p.inventory.items.is_empty(): line = "Esse objeto veio com explicação ou tenho de a inventar?"
		elif watcher.memory.get("chalk",false) and int(watcher.memory.passes)%3==0: line = "Vi o vosso desenho no chão. Desta vez deixaram a assinatura, muito bem."
		elif watcher.memory.has("noise") and int(watcher.memory.passes)%4==0: line = "Ainda estou a ouvir essa história: "+str(watcher.memory.noise)
		elif int(watcher.memory.passes)%11==0: line = "A casa da esquina espirrou. Foi o senhor a sacudir o tapete, mas prefiro a minha versão."
		elif int(state.quests.get("post_deliveries",0))>0: line = "A carta chegou! Agora o Augusto perdeu o caminho de volta."
		# Window speech is drawn above the real pane, rather than an invisible body.
		tell("Alzira, da janela: "+line)
		watcher.memory.last_remark = line
		dirty = true
	if not state.quests.has("late_drop_day") or int(state.quests.late_drop_day)!=day:
		var late: CharacterBody2D = by_id.dinis
		if late.available() and late.position.distance_to(p.position)<600 and minute>570 and minute<1100:
			parcel.position = routines.clear_destination(late.position+Vector2(-50,25),[])
			parcel.show()
			state.quests.late_drop_day = day
			say(late,"A encomenda! Eu voltava já, mas estou atrasado para voltar!","greet")
			dirty = true
	if state.quests.get("cat_tracking",false) and p.position.distance_to(animals.cat)<160 and minf(animals.cat.distance_to(by_id.dario.home),animals.cat.distance_to(by_id.lurdes_sardinha.home))<85:
		state.quests.cat_seen = true
		dirty = true
	var feeder: CharacterBody2D = by_id.adelia_pombos
	if feeder.available() and feeder.position.distance_to(animals.home)<350 and int(feeder.memory.get("living_feed_day",-1))!=day:
		animals.feed_at(feeder.position+Vector2(50,35),false)
		feeder.memory.living_feed_day = day
		say(feeder,"O Chico, o Malaquias e o Engenheiro chegaram antes das sementes.","offer")
	# Food left on paving attracts the flock just as purchased grain does.
	for target in world.interactions.targets:
		if target.kind=="pickup" and is_instance_valid(target.node) and target.node.visible and str(target.item.type) in ["living_grain","festival_fruit","festival_sweets"] and target.node.position.distance_to(animals.home)<450: animals.feed_at(target.node.position,false)
func _daily_work() -> void:
	for actor in residents:
		if not actor.available() or actor.state!="activity" or (actor.event_busy and not actor.bench_sitting): continue
		match str(actor.entry.role):
			"bench": _bench_routine(actor)
			"lost":
				if int(actor.memory.get("seen_day",-1))!=day: actor.memory.seen_day = day; actor.memory.days = int(actor.memory.get("days",0))+1
			"post":
				if not post_delivering and int(actor.memory.get("ask_day",-1))!=day:
					say(actor,"Alguém viu "+str(addresses[post_target].name)+"?","speak")
					actor.memory.ask_day = day
			"clean": actor.social_pose = "work"
			"boxes": actor.social_pose = "work"
			"steps": actor.frame = int(elapsed/2)%2
			"jobs":
				actor.memory.job = ["jornais","pastelaria","estacionamento de tuk-tuks"][day%3]
func _sweep() -> void:
	var sweeper: CharacterBody2D = by_id.celso
	if not sweeper.available() or minute<480 or minute>1140: return
	if hat.visible and sweeper.position.distance_to(hat.position)<70:
		state.lost.append({"type":"living_hat","name":"Chapéu do Sven","porte":1,"art":0})
		hat.hide()
		say(sweeper,"Um chapéu sem cabeça. Vai para os achados.","work")
		dirty = true
	for drawing in chalk.duplicate():
		var at := Vector2(drawing.at[0],drawing.at[1])
		if sweeper.position.distance_to(at)<90:
			chalk.erase(drawing); sweeps += 1; say(sweeper,"Este desenho teve público. Agora a calçada volta a ser folha branca.","work"); dirty = true
	for target in world.interactions.targets:
		if target.kind!="pickup" or not is_instance_valid(target.node) or not target.node.visible: continue
		if sweeper.position.distance_to(target.node.position)>65: continue
		if state.lost.size()>=12: break
		state.lost.append(target.item.duplicate(true)); target.node.hide(); sweeps += 1
		say(sweeper,"Um objeto encontrado. Vai para a caixa, não vai para o lixo.","work"); dirty = true
	for node in objects:
		if node.kind=="chalk": node.queue_redraw()
func _rivals() -> void:
	var a: CharacterBody2D = by_id.to_tuktuk
	var b: CharacterBody2D = by_id.maya_tuktuk
	if minute<540 or minute>1140 or a.position.distance_to(b.position)>550 or not a.available() or not b.available(): return
	if elapsed<float(state.quests.get("rival_next",0)): return
	rivalry += 1
	state.quests.rival_next = elapsed+95
	say(a,["Esta curva foi desenhada por um rei com pressa!","O meu roteiro tem mais história por metro.","Maya, emprestas-me o mapa? Só para confirmar uma invenção."][rivalry%3],"speak")
	say(b,["Foi desenhada pelo terreno, Tó. Deixa o rei descansar.","Também tem mais metros inventados.","Empresto. Desta vez lemos os dois."][rivalry%3],"speak")
	var tourist: CharacterBody2D = by_id.sven
	if tourist.available() and tourist.position.distance_to(a.position)<650:
		say(tourist,"Se discutirem virados para o palácio, talvez eu descubra para que lado fica.","listen")
		tourist.memory.guides_met = day
	state.quests.rivalries = int(state.quests.get("rivalries",0))+1
	dirty = true
func _step_post(_delta: float) -> void:
	if not post_delivering: return
	var post: CharacterBody2D = by_id.augusto
	var target: Vector2 = addresses[post_target].at
	if not post.available(): post_delivering = false; escort = false; post.delivery_mode = ""; return
	var p: CharacterBody2D = player()
	if by_id.alzira.state=="window" and post.position.distance_to(by_id.alzira.position)<400 and int(post.memory.get("window_day",-1))!=day:
		post.memory.window_day = day
		say(post,"Dona Alzira, esta porta tem o número certo?","speak")
		by_id.alzira.memory.postman = true
		report_noise(post.position,"O carteiro voltou a pedir direções")
	if escort and is_instance_valid(p) and p.position.distance_to(post.position)>260: post.greet_time = .6; return
	if post.position.distance_to(target)<45:
		post_delivering = false; escort = false; post.delivery_mode = ""
		state.quests.post_deliveries = int(state.quests.get("post_deliveries",0))+1
		post.memory.helped_day = day
		say(post,"Entregue! O destinatário confirmou a porta. Amanhã há outra morada.","thanks")
		ledger("Augusto entregou a carta em "+str(addresses[post_target].name))
		post_target = int(state.quests.post_deliveries)%addresses.size()
		if int(state.quests.post_deliveries)%4==0: post_target = addresses.find(_address_near(post.position))
		state.quests.post_destination = post_target
		dirty = true
	elif post.route.is_empty(): post._begin_walk(target,"walking")
func start_delivery(with_player: bool) -> bool:
	var post: CharacterBody2D = by_id.augusto
	cancel_for("augusto")
	post._cancel_encounter()
	post.greet_time = 0
	if post.position.distance_to(addresses[post_target].at)>40 and not post._begin_walk(addresses[post_target].at,"walking"): return false
	post.delivery_mode = "escort" if with_player else "delivery"
	post_delivering = true
	escort = with_player
	return true
func _step_hat(delta: float) -> void:
	if not hat.visible:
		if wind and by_id.sven.available() and int(state.quests.get("hat_day",-1))!=day and not state.quests.get("hat_held",false):
			hat.position = routines.clear_destination(by_id.sven.position+Vector2(35,0),[])
			var destination: Vector2 = routines.clear_destination(hat.position+Vector2(650,240),[])
			hat_path = world.find_path(hat.position,destination)
			if not hat_path.is_empty():
				hat.show(); state.quests.hat_day = day; say(by_id.sven,"O mapa não voa, mas o chapéu está a tentar!","greet"); dirty = true
		return
	if not hat_path.is_empty():
		var next := hat.position.move_toward(hat_path[0],delta*110)
		if world.is_walkable(next,6): hat.position = next
		if hat.position.distance_to(hat_path[0])<5: hat_path.remove_at(0)
		hat.queue_redraw()
func _step_audio(delta: float) -> void:
	sound_left -= delta
	var p: CharacterBody2D = player()
	if sound_left<=0 or not is_instance_valid(p) or p.position.distance_to(sound_source)>850: audio.stop()
func play_sound(midi: int,at: Vector2,rhythm := false) -> void:
	sound_source = at
	sound_left = 4.0 if rhythm else 1.6
	var rate := 16000
	var bytes := PackedByteArray()
	bytes.resize(int(rate*sound_left)*2)
	for i in int(rate*sound_left):
		var t := float(i)/rate
		var hz := 440*pow(2,(midi-69)/12.0)
		var sample := sin(TAU*hz*t)*exp(-fposmod(t,.4)*8)*.13
		if rhythm: sample += sin(TAU*(60-20*fposmod(t,.5))*t)*exp(-fposmod(t,.5)*22)*.3
		bytes.encode_s16(i*2,clampi(int(sample*30000),-32000,32000))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.data = bytes
	audio.stream = stream
	audio.play()
func ledger(line: String) -> void:
	state.ledger.append(line)
	if state.ledger.size()>40: state.ledger.pop_front()
	dirty = true
func consequence(spec: Dictionary,at: Vector2) -> void:
	match str(spec.effect):
		"sweep":
			for target in world.interactions.targets:
				if target.kind=="pickup" and is_instance_valid(target.node) and target.node.visible and target.node.position.distance_to(at)<200: state.lost.append(target.item.duplicate(true)); target.node.hide()
		"cat": animals.cat_goal = by_id.lurdes_sardinha.home; state.quests.cat_treaty = true
		"water": state.quests.begonia_watered = day
		"paint": state.quests.painting_hint = true
		"keys": state.quests.chest_unlocked = true
		"photo": state.quests.community_photo = day
		"count": state.quests.stair_audit = day
		"trade","swap": state.quests["exchange_"+str(spec.id)] = day
		"rhythm","sound": play_sound(64,at,str(spec.effect)=="rhythm")
		"shutter": state.quests.shutter_repaired = true
		"deliver": state.quests.postcard_delivered = true
		"clock": state.quests.clock_repaired = true
	ledger(str(spec.title)+" · dia "+str(day))
func load_state() -> bool:
	if not storage_enabled or not FileAccess.file_exists(save_path): return false
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(save_path))!=OK or not json.data is Dictionary or int(json.data.get("version",0))!=1: return false
	for key in ["people","quests","events"]:
		if not json.data.get(key) is Dictionary: return false
	for key in ["ledger","lost"]:
		if not json.data.get(key) is Array: return false
	state.merge(json.data,true)
	state.quests.rival_next = 0
	chalk = state.get("chalk",[])
	return true
func save_state() -> bool:
	if not storage_enabled: return false
	state.chalk = chalk
	state.bags = {}
	for p in world.people:
		if is_instance_valid(p): state.bags[p.name] = p.inventory.items.filter(func(item):return str(item.type).begins_with("living_") or str(item.type).begins_with("neighbour_") or item.type=="raffle_ticket")
	if is_instance_valid(hat) and is_instance_valid(parcel):
		state.world_objects = {"hat":{"visible":hat.visible,"at":[hat.position.x,hat.position.y],"goal":[hat_path[-1].x,hat_path[-1].y] if not hat_path.is_empty() else [hat.position.x,hat.position.y]},"parcel":{"visible":parcel.visible,"at":[parcel.position.x,parcel.position.y]}}
	for actor in residents:
		if is_instance_valid(actor): state.people[actor.entry.id] = actor.memory
	var file := FileAccess.open(save_path+".tmp",FileAccess.WRITE)
	if file==null: return false
	file.store_string(JSON.stringify(state,"\t"))
	file.close()
	if DirAccess.rename_absolute(ProjectSettings.globalize_path(save_path+".tmp"),ProjectSettings.globalize_path(save_path))!=OK: return false
	dirty = false
	return true
func _exit_tree() -> void:
	if is_instance_valid(audio): audio.stop(); audio.stream = null
	if storage_enabled: save_state()

func open_character(actor: CharacterBody2D,person: CharacterBody2D) -> void:
	if person==null: return
	# A method Callable does not retain a RefCounted dialogue target.
	conversation = preload("res://scripts/village_living_dialogues.gd").new()
	conversation.d = self
	conversation.open(actor,person)
func open_object(node: Node2D,person: CharacterBody2D) -> void:
	if node.kind=="window": open_character(node.resident_owner,person); return
	match str(node.kind):
		"feed": tell(feed_birds(person))
		"cat":
			animals.cat_frame = 1
			state.quests.cat_seen = true
			tell("O Sardinha lava a pata, aceita festas e volta à sua ronda de taças. Dário e Lurdes continuam convencidos de que é de cada um.")
		"shop":
			if minute<540 or minute>1110: tell(node.label+" está fechado. O horário fica na montra.")
			else:
				node.state += 1
				tell("A montra de "+node.label+" tem uma nova seleção. O comerciante acena da entrada.")
				state.quests["shop_"+node.key] = int(state.quests.get("shop_"+node.key,0))+1
		"bell":
			bells_rung += 1
			var count: int = int(state.quests.get(node.key,0))+1
			state.quests[node.key] = count
			var owner: CharacterBody2D
			for window in windows:
				if window.building==node.building: owner = window.resident_owner; break
			if str(state.quests.get("delivery_target",""))==node.building.entry_id and take_type(person,"living_parcel"):
				state.quests.delivery_target = ""; state.quests.box_deliveries = int(state.quests.get("box_deliveries",0))+1; tell("A porta abre e a caixa é recebida. Entrega confirmada no placard."); ledger("Mercadoria entregue em "+node.label)
			elif minute<450 or minute>1290: tell("Uma voz sonolenta: a campainha não precisa de trabalhar a estas horas!" if count%2 else "Ouve-se um cão a ladrar lá dentro."); play_sound(42,node.position)
			elif is_instance_valid(owner) and owner.state=="window": tell(str(owner.entry.name)+" responde da janela: estou cá em cima! Podes chamar-me junto à porta.")
			elif count%4==0: tell("Ninguém responde. O morador saiu; a campainha fica registada para a próxima visita.")
			else:
				node.state = 1
				tell("A porta entreabre-se: "+("Outra vez? Ainda agora aqui estiveram!" if count>2 else "Bom dia! Procuram alguém em "+node.label+"?"))
				play_sound(76,node.position)
		"chalk": panel.show_choices("Giz na calçada","Escolhe o desenho. Fica aqui até à chuva ou até o varredor passar.",["Uma flor","Uma macaca","Te + Jo","Uma cara sorridente"],func(i): draw_chalk(node,person,i))
		"fountain": panel.show_choices("Fonte Mourisca","A água, os azulejos e a inscrição convidam a parar.",["Ouvir a água e guardar o som","Encher a garrafa","Examinar a inscrição","Procurar no rebordo"],func(i): fountain_action(node,person,i))
		"sound":
			state.quests["sound_"+node.key] = true
			play_sound({"mourisca":64,"bell":67,"steps":60}.get(node.key,64),node.position)
			tell("Som recolhido: "+node.label+". A Ema e a Milena podem ouvi-lo contigo.")
		"bin": tell(clean_near(node.position)); node.state += 1
		"vending": panel.show_choices("Postais da vila","Escolhe um postal, giz ou alimento próprio para os pombos. Cada objeto ocupa espaço real na bolsa.",["Postal de Sintra","Caixa de giz","Sementes para pombos"],func(i):tell(give(person,["postcard","chalk","grain"][i],["Postal de Sintra","Caixa de giz","Sementes para pombos"][i])))
		"board": panel.show_choices(node.label,"\n".join(state.ledger.slice(maxi(0,state.ledger.size()-4))) if not state.ledger.is_empty() else "Cinema · 19h30 nas Hortênsias. Toques · 16h nos Jardins. Novidades e entregas confirmadas aparecem aqui.",["Ver pessoas e pequenas histórias","Consultar a morada do carteiro","Comprar sementes para os pombos"],func(i): board_action(i,person))
		"barter": open_character(by_id.jacinta,person)
		"chest": open_lost(person)
		"hat":
			var reply := give(person,"hat","Chapéu do Sven")
			if reply.begins_with("Guardaste"): hat.hide(); state.quests.hat_held = true
			tell(reply)
		"box":
			var reply := give(person,"box","Encomenda do Dinis")
			if reply.begins_with("Guardaste"): parcel.hide()
			tell(reply)
		"clue": state.quests.painting_found = true; tell("A árvore azul era inventada. O banco e o pequeno pormenor do quadro existem mesmo. Podes contar à Amália.")
		"pot": node.state = 90; node.rotation += .1; state.quests.begonia_watered = day; tell("Rodaste o vaso para a luz e regaste a begónia. A Irene vai reconhecer a ajuda.")
	node.queue_redraw()
	dirty = true
func board_action(index: int,person: CharacterBody2D) -> void:
	if index==0:
		var text := ""
		for id in ["alzira","augusto","ema","jacinta","alvaro","sven"]: text += str(by_id[id].entry.name)+" · "+world.area_at(by_id[id].position)+"\n"
		tell(text)
	elif index==1: state.quests.post_search = post_target; tell(str(addresses[post_target].name)+" · procurar a campainha marcada no mapa.")
	else: tell(give(person,"grain","Sementes para pombos"))
func draw_chalk(node: Node2D,person: CharacterBody2D,design: int) -> void:
	# A shared open box at the authored drawing areas; optional carried chalk works too.
	var drawing := {"at":[node.position.x,node.position.y],"design":design,"color":["e3dab8","e4b5ab","b9c9cf","d5c58d"][design],"day":day,"artist":person.name}
	chalk.append(drawing)
	if chalk.size()>24: chalk.pop_front()
	node.queue_redraw()
	state.quests.chalk_drawn = int(state.quests.get("chalk_drawn",0))+1
	by_id.alzira.memory.chalk = true
	ledger(person.name+" desenhou com giz em "+world.area_at(node.position))
	tell("O desenho ficou na calçada. Os vizinhos poderão comentá-lo; a chuva e a vassoura apagam-no.")
func fountain_action(node: Node2D,person: CharacterBody2D,index: int) -> void:
	node.state = 90
	match index:
		0: state.quests.sound_mourisca = true; play_sound(64,node.position); tell("O som da água fica no caderno de escuta.")
		1: tell(exchange(person,["living_bottle"],"water","Garrafa com água da fonte"))
		2: tell("O arco, os azulejos e a cantaria ligam esta fonte ao passeio da Volta do Duche. O registo fica no caderno."); state.quests.fountain_read = true
		3:
			if not state.quests.get("fountain_find",false):
				var reply := give(person,"clock","Pequeno mecanismo parado")
				if reply.begins_with("Guardaste"): state.quests.fountain_find = true
				tell(reply)
			else: tell("O rebordo já foi observado. A água continua a correr.")
	dirty = true
func give(person: CharacterBody2D,type: String,label: String) -> String:
	if not person.inventory.try_add({"type":"living_"+type,"name":label,"porte":1,"art":0}): return "A bolsa está cheia. Liberta espaço e volta; o objeto continua disponível."
	dirty = true
	return "Guardaste "+label.to_lower()+" na bolsa."
func take_type(person: CharacterBody2D,type: String) -> bool:
	for i in person.inventory.items.size():
		if person.inventory.items[i].type==type: person.inventory.take(i); return true
	return false
func exchange(person: CharacterBody2D,accepted: Array,type: String,label: String) -> String:
	for i in person.inventory.items.size():
		if not accepted.has(str(person.inventory.items[i].type)): continue
		var old: Dictionary = person.inventory.items[i]
		var result := {"type":"living_"+type,"name":label,"porte":1,"art":0}
		if person.inventory.used_porte()-int(old.porte)+1>person.inventory.CAPACITY: return "Não há espaço para concluir a troca. Conservas o teu objeto."
		person.inventory.take(i)
		person.inventory.try_add(result)
		state.quests.trades = int(state.quests.get("trades",0))+1
		dirty = true
		return "Troca concluída: "+str(old.name)+" por "+label+"."
	return "Não tens o objeto pedido na bolsa. A troca fica à tua espera."
func clean_near(at: Vector2) -> String:
	var found := 0
	for target in world.interactions.targets:
		if target.kind=="pickup" and is_instance_valid(target.node) and target.node.visible and target.node.position.distance_to(at)<150:
			if state.lost.size()>=12: break
			state.lost.append(target.item.duplicate(true)); target.node.hide(); found += 1
	state.quests.cleanups = int(state.quests.get("cleanups",0))+1
	dirty = true
	return "Recolheste "+str(found)+" objetos. Ficam identificados nos achados e perdidos do Celso."
func open_lost(person: CharacterBody2D) -> void:
	var labels: Array = state.lost.map(func(item):return "Recuperar "+str(item.name))
	if labels.is_empty(): tell("O Celso ainda não recolheu objetos perdidos. Nenhum objeto foi deitado fora."); return
	panel.show_choices("Achados e perdidos","Os objetos conservam a sua identidade e porte. Escolhe o que queres recuperar.",labels.slice(0,6),func(i):
		if i>=state.lost.size(): return
		if person.inventory.try_add(state.lost[i]): state.lost.remove_at(i); dirty = true; tell("Objeto recuperado da caixa do Celso.")
		else: tell("A bolsa está cheia. O objeto fica guardado aqui."))
func feed_birds(person: CharacterBody2D) -> String:
	if not take_type(person,"living_grain"): return "Precisas de sementes próprias. Há nas máquinas de postais e nos placards da vila."
	animals.feed_at(person.position+Vector2(35,20))
	state.quests.birds_fed = int(state.quests.get("birds_fed",0))+1
	dirty = true
	return "Os pombos aproximam-se das sementes. Um deles segue-te enquanto espera mais."
func begin_beat(actor: CharacterBody2D,person: CharacterBody2D) -> void:
	var journey: Node2D = world.get_parent().get("journey")
	if journey!=null and not journey.can("rhythm"): tell(journey.requirement("rhythm")); return
	current_beat = 0
	beat_started = elapsed
	play_sound(48,actor.position,true)
	panel.show_choices("Roda de ritmo original","Escuta o pulso e bate quatro vezes. Cada batida deve cair perto do tempo; não há música do artista.",["Bater no tempo"],beat_press.bind(actor,person))
func beat_press(_index: int,actor: CharacterBody2D,person: CharacterBody2D) -> void:
	var phase: float = fposmod(elapsed-beat_started,.5)
	if phase<.14 or phase>.36: current_beat += 1
	else: current_beat = maxi(0,current_beat-1)
	if current_beat>=4:
		state.quests.rhythm_done = true
		world.get_parent().record_shared_activity("rhythm",str(day),8,actor.position,150)
		tell("Quatro batidas certas. A roda responde com palmas!")
		for a in residents:
			if a.available() and a.position.distance_to(actor.position)<500: say(a,"Boa!","clap")
		dirty = true
	else: panel.show_choices("A tua vez · "+str(current_beat)+"/4","O pulso continua. Bate perto da próxima marca.",["Bater no tempo"],beat_press.bind(actor,person))
func handle_input(event: InputEvent) -> bool:
	return panel.handle_input(event) if is_instance_valid(panel) else false
func _draw() -> void:
	var p: CharacterBody2D = player()
	if not is_instance_valid(p): return
	if state.quests.has("post_search") or post_delivering:
		var at: Vector2 = addresses[post_target].at
		if p.position.distance_to(at)<1000:
			draw_arc(at,35,0,TAU,30,Color("edce76"),2,true)
			draw_string(ThemeDB.fallback_font,at+Vector2(-60,35),addresses[post_target].name,HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("f6e5b7"))
	if rain:
		for i in 45:
			var at: Vector2 = p.position+Vector2(fposmod(i*97,1300)-650,fposmod(elapsed*380+i*61,800)-400)
			draw_line(at,at+Vector2(-7,18),Color(.68,.79,.84,.35),1,true)
func draw_map(canvas: Control,paper: Rect2) -> void:
	var factor: Vector2 = paper.size/world.WORLD_SIZE
	var marks: Array = []
	if state.quests.has("post_search") or post_delivering: marks.append({"at":addresses[post_target].at,"name":addresses[post_target].name})
	if state.quests.get("sound_quest",false):
		for node in objects:
			if node.kind=="sound" and not state.quests.get("sound_"+node.key,false): marks.append({"at":node.position,"name":node.label})
	if state.quests.get("cat_tracking",false): marks.append({"at":animals.cat,"name":"Sardinha"})
	if state.quests.get("painting_hint",false) and not state.quests.get("painting_found",false):
		for node in objects:
			if node.kind=="clue": marks.append({"at":node.position,"name":"Pormenor de Amália"})
	if state.quests.get("serra_route",false): marks.append({"at":world.forest_access,"name":"Caminho da serra"})
	for mark in marks:
		var at: Vector2 = paper.position+mark.at*factor
		canvas.draw_circle(at,4,Color("f7ce65"))
		canvas.draw_string(ThemeDB.fallback_font,at+Vector2(7,-4),mark.name,HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("fff1ce"))

func _setup_rivals() -> void:
	var green: CharacterBody2D = world.festival_life.vehicles[0]
	var yellow: CharacterBody2D = world.festival_life.vehicles[1]
	rival_park = green.position
	green.community_hub = rival_park
	var next: Vector2 = yellow._nearest(rival_park+Vector2(256,0))
	if next==Vector2.INF or green.navigation.get_point_path(Vector2i(green.position/green.GRID),Vector2i(next/green.GRID)).is_empty(): next = green.stops[0]
	yellow.community_hub = next
	yellow.position = next
	yellow.stops.assign(green.stops)
	for vehicle in [green,yellow]:
		for block in vehicle.driver.schedule:
			if block.mode!="inside": block.destination = vehicle.community_hub
		vehicle.path.clear()
func park_guide(vehicle: CharacterBody2D) -> bool:
	if vehicle.kind=="carriage" or vehicle.community_hub==Vector2.INF: return false
	if not ((minute>=540 and minute<585) or (minute>=880 and minute<920)): return false
	if vehicle.position.distance_to(vehicle.community_hub)<45:
		vehicle.wait = 2
		vehicle.path.clear()
		return true
	if vehicle.path.is_empty() or vehicle.path[-1].distance_to(vehicle.community_hub)>80: vehicle._route(vehicle.community_hub)
	return false
func guide_choice(vehicle: CharacterBody2D,person: CharacterBody2D) -> void:
	panel.show_choices(str(vehicle.driver.entry.name)+" · roteiros rivais","Tó inventa uma história para cada curva; Maya insiste em consultar o mapa.",["Pedir informações","Escolher este guia para uma paragem comentada","Pedir que os dois colaborem"],func(i):
		vehicle.wait = 8
		vehicle.conversation_count += 1
		if i==0: say(vehicle.driver,"Palácio Nacional aqui; Pena na serra. Esta parte está confirmada no mapa.","speak")
		elif i==1:
			state.quests["clients_"+vehicle.kind] = int(state.quests.get("clients_"+vehicle.kind,0))+1
			var rival: CharacterBody2D = by_id.maya_tuktuk if vehicle.kind=="tuk_green" else by_id.to_tuktuk
			say(vehicle.driver,"Uma paragem para a dupla! O passeio continua a pé, com vista para o roteiro.","greet")
			if rival.position.distance_to(vehicle.position)<550: say(rival,"Quando acabarem a história, eu confirmo os factos.","speak")
		else:
			state.quests.guides_collaborated = true
			say(by_id.to_tuktuk,"Eu conto. A Maya confirma. E dividimos a pausa para o café.","speak")
			say(by_id.maya_tuktuk,"Pela primeira vez, concordamos no café.","speak")
		dirty = true)

func _restore_bags() -> void:
	if not loaded_items_pending or world.people.is_empty(): return
	loaded_items_pending = false
	if not storage_enabled: return
	var journey: Node2D = world.get_parent().get("journey")
	# A journey save owns the complete bags. Do not restore a second stale quest copy.
	if journey!=null and journey.restored_bags: return
	for p in world.people:
		for item in state.get("bags",{}).get(p.name,[]):
			if not item is Dictionary: continue
			var type: String = str(item.get("type",""))
			if not type.begins_with("living_") and not type.begins_with("neighbour_") and type!="raffle_ticket": continue
			if not p.inventory.try_add(item): state.lost.append(item)

func report_noise(at: Vector2,title: String) -> void:
	for window in windows:
		if window.resident_owner.state=="window" and window.contact.distance_to(at)<650:
			window.resident_owner.memory.noise = title
			window.mark = {"text":"Já ouvi!","until":window.clock+4}
			window.queue_redraw()
	dirty = true

func _bench_routine(actor: CharacterBody2D) -> void:
	if minute<840 or minute>960:
		actor.set_meta("seeking_bench",false)
		if actor.bench_sitting:
			actor.bench_sitting = false
			actor.event_busy = false
			actor._begin_walk(actor.anchor,"returning")
		return
	var bench: Node2D
	var best := INF
	for prop in world.props:
		if int(prop.get_meta("kind"))==5 and prop.position.distance_squared_to(actor.home)<best: bench = prop; best = prop.position.distance_squared_to(actor.home)
	if bench==null: return
	actor.set_meta("favourite_bench",bench)
	var occupied: bool = world.people.any(func(p):return (p.seated or p.seating) and p.position.distance_to(bench.position)<180)
	actor.bench_waiting = occupied
	if occupied:
		actor.set_meta("seeking_bench",false)
		if actor.bench_sitting: yield_bench(bench)
		if int(actor.memory.get("bench_day",-1))!=day:
			actor.memory.bench_day = day; actor.memory.waits = int(actor.memory.get("waits",0))+1
			say(actor,"O banco está ocupado. Espero. Já treinei isto ontem.","listen")
		return
	var seat: Vector2 = bench.seat_position(0)
	if actor.position.distance_to(seat)<10:
		actor.set_meta("seeking_bench",false)
		actor.bench_sitting = true
		actor.event_busy = true
		actor.route.clear()
	elif not actor.bench_sitting:
		actor.set_meta("seeking_bench",true)
		actor._begin_walk(seat,"walking")
func yield_bench(bench: Node2D) -> void:
	var actor: CharacterBody2D = by_id.teodoro
	if not actor.bench_sitting or actor.get_meta("favourite_bench",null)!=bench: return
	actor.bench_sitting = false
	actor.event_busy = false
	actor.greet_time = 0
	actor.memory.waits = int(actor.memory.get("waits",0))+1
	var side: Vector2 = routines.clear_destination(bench.position+Vector2(160,70),[])
	actor._begin_walk(side,"walking")
	say(actor,"Sentem-se. Eu fico aqui a acabar esta notícia.","speak")
func open_episode(actor: CharacterBody2D,person: CharacterBody2D) -> bool:
	if person==null: return false
	for episode in events.active:
		if not episode.people.has(actor): continue
		var action: String = {"sweep":"Ajudar a recolher os objetos","rhythm":"Entrar na roda de ritmo","photo":"Ficar parado para a fotografia","water":"Ajudar a regar sem molhar os vizinhos","trade":"Propor uma troca real","swap":"Trocar um objeto da bolsa","sound":"Responder com um som","count":"Conferir a contagem real"}.get(str(episode.spec.effect),"Dar uma mão nesta situação")
		panel.show_choices(str(episode.spec.title),str(episode.spec.line)+" A cena continua com os vizinhos, mesmo que só fiques a observar.",["Observar sem interromper",action,"Anotar no placard"],func(i): episode_choice(episode,person,i))
		return true
	return false
func episode_choice(episode: Dictionary,person: CharacterBody2D,index: int) -> void:
	if not events.active.has(episode): tell("A conversa já terminou. O resultado fica no placard."); return
	if index==0: tell("Os vizinhos continuam a tratar do assunto."); return
	if index==2: ledger("A acompanhar: "+str(episode.spec.title)); tell("O relato ficou no placard; a conclusão será acrescentada quando acontecer."); return
	var at: Vector2 = episode.at
	if person.position.distance_to(at)>350: tell("Aproxima-te do grupo antes de participar."); return
	var effect: String = episode.spec.effect
	match effect:
		"rhythm": begin_beat(episode.people[0],person)
		"sweep": tell(clean_near(at))
		"photo":
			if episode.phase!="action": tell("A Rute ainda está a chegar ao enquadramento."); return
			person.collecting_time = 2
			episode.people[0].flash_until = episode.people[0].clock+.35
			tell(give(person,"photo","Retrato do encontro"))
		"swap","trade":
			var reply := exchange(person,["pebble","living_cap"],"postcard","Postal da comunidade")
			tell(reply)
			if not reply.begins_with("Troca"): return
		"sound": play_sound(67,at); tell("O teu som recebe uma resposta na conversa.")
		"water":
			state.quests.water_warning = true
			for node in objects:
				if node.kind=="pot": node.state = 90
			tell("Avisas os passantes e ajudas a orientar o regador.")
		"count":
			var spec: Dictionary = world.TERRACES.data.terraces[0]
			for candidate in world.TERRACES.data.terraces:
				if world.stair_rect(candidate).get_center().distance_to(at)<world.stair_rect(spec).get_center().distance_to(at): spec = candidate
			state.quests["count_"+str(spec.id)] = int(spec.steps)
			tell("A contagem confirma os "+str(spec.steps)+" degraus da escada real.")
		_:
			episode.people[1].frame = 1
			say(episode.people[1],"Obrigado pela mão. Agora já conseguimos acabar isto.","thanks")
			tell("Participaste na situação. Os vizinhos vão lembrar-se da ajuda quando a concluírem.")
	episode.assisted = true
	world.get_parent().record_shared_activity("help",str(episode.spec.id),3,at,100)
	dirty = true

func _restore_objects() -> void:
	if not storage_enabled: return
	var saved: Dictionary = state.get("world_objects",{})
	for pair in [["hat",hat],["parcel",parcel]]:
		var data: Dictionary = saved.get(pair[0],{})
		if not data.get("visible",false) or not data.get("at") is Array or data.at.size()!=2: continue
		var at := Vector2(float(data.at[0]),float(data.at[1]))
		if not world.is_walkable(at,6): continue
		pair[1].position = at
		pair[1].show()
		if pair[0]=="hat" and data.get("goal") is Array and data.goal.size()==2: hat_path = world.find_path(at,Vector2(data.goal[0],data.goal[1]))

func _step_sven() -> void:
	var tourist: CharacterBody2D = by_id.sven
	if tourist.delivery_mode!="trail": return
	if tourist.position.distance_to(world.forest_access)<90:
		tourist.delivery_mode = ""
		state.quests.lost_finale = true
		state.quests.lost_finale_pending = false
		say(tourist,"Cheguei ao caminho certo! Agora já sei onde começa a subida.","thanks")
		ledger("Depois de vários encontros, Sven chegou à saída real para a serra.")
	elif tourist.route.is_empty(): tourist._begin_walk(world.forest_access,"walking")
