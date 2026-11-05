extends "res://scripts/village_population.gd"
## Twenty authored lives, seven connected street stories and public-space presence.
const DATA = preload("res://data/village/neighbourhood-stories.json")
const ART = preload("res://data/village/neighbourhood-art.json")
const Actor = preload("res://scripts/village_neighbour_actor.gd")
const StoryProp = preload("res://scripts/village_neighbour_prop.gd")
var places: Dictionary = {}
var objects: Dictionary = {}
var minute := 480.0
var day := 1
var episodes: Node2D
var dialogues: RefCounted
var presence: Node2D
var state: Dictionary = {}
var sprite_paint := ShaderMaterial.new()
func build_equipment() -> void:
	sprite_paint.shader = preload("res://shaders/village_neighbour_cutout.gdshader")
	# Runs before the navigation bake. These are real obstacles, not painted walk-through tables.
	var locations := {"picnic":Vector2(8470,12240),"pigeon":Vector2(8510,8580),"queue":Vector2(9890,4620),"window":Vector2(18100,12980),"foosball":Vector2(4720,6770),"raffle":Vector2(6650,4930),"papers":Vector2(13700,6630)}
	for key in locations: places[key] = world._event_space(locations[key],360 if key in ["picnic","foosball"] else 280)
	var piriquita: Array = world.buildings.filter(func(b):return b.label=="Piriquita")
	if not piriquita.is_empty(): places.queue = world._event_space(piriquita[0].entry_position+Vector2(0,150),210)
	for spec in [["picnic",0,130,Vector2(0,170)],["thermos",1,38,Vector2(125,50)],["foosball",3,132,Vector2.ZERO],["raffle",4,110,Vector2.ZERO],["papers",5,52,Vector2(0,10)],["pigeon",7,80,Vector2(0,-20)]]:
		var key: String = spec[0]
		var center: Vector2 = places["picnic" if key=="thermos" else key]
		var p := StoryProp.new(); p.setup(self,key,center+spec[3],spec[1],spec[2]); objects[key] = p
func _ready() -> void:
	name = "TwentyNeighboursAndStreetStories"
	routines.population = self
	state = world.living_life.state.quests.get("neighbourhood",{})
	world.living_life.state.quests.neighbourhood = state
	if int(state.get("thermos_opened",0))>0: objects.thermos.index = 2
	for i in DATA.data.people.size():
		var entry: Dictionary = DATA.data.people[i].duplicate(true)
		entry.neighbour = true
		entry.column = i%4
		var actor := Actor.new()
		actor.population = self; actor.entry = entry; actor.ordinal = 150+i; actor.name = entry.id
		var center: Vector2 = places[entry.role]
		actor.home = free_point(center+Vector2((i%4-1.5)*95,105),true)
		actor.position = actor.home; actor.anchor = actor.home
		actor.profile = {"residence":"local","commute_speed":100}
		actor.memory = world.living_life.state.people.get(entry.id,{})
		world.living_life.state.people[entry.id] = actor.memory
		world.actors.add_child(actor); residents.append(actor); by_id[entry.id] = actor
		world.interactions.targets.append({"id":"neighbour_"+entry.id,"kind":"resident","node":actor,"label":entry.name,"position":actor.position,"reach":150.0,"radius":12.0})
	by_id.leo_merenda.profile.guardian = "rosario_merenda"
	by_id.rosario_merenda.dependants.append(by_id.leo_merenda)
	var house: Vector2 = routines.doorway(places.window,true)
	var building: Node2D
	for b in world.buildings:
		if b.entry_id==routines.doors.get(house,""): building = b; break
	if building!=null:
		world.living_life._attach_window(by_id.odete_janela,building)
		places.window = house
	for actor in residents: _plan_neighbour(actor)
	for object in objects.values():
		world.interactions.targets.append({"id":"neighbour_scene_"+object.kind,"kind":"street_scene","node":object,"label":object.kind,"position":object.position,"reach":160.0,"radius":0.0})
	dialogues = preload("res://scripts/village_neighbour_dialogues.gd").new(); dialogues.director = self
	episodes = preload("res://scripts/village_neighbour_episodes.gd").new(); episodes.director = self; add_child(episodes)
	presence = preload("res://scripts/village_presence.gd").new(); presence.director = self; add_child(presence)
	world.visibility_changed.connect(_visibility)
func _visibility() -> void:
	if not world.is_visible_in_tree():
		world.living_life.panel.finish()
		world.living_life.save_state()
func _plan_neighbour(a: CharacterBody2D) -> void:
	var role: String = a.entry.role
	var slot: int = residents.filter(func(b):return b.entry.role==role).find(a)
	var site: Vector2 = places[role]
	var offsets: Array = [Vector2(-100,60),Vector2(100,60),Vector2(-100,155),Vector2(100,155)]
	if role=="foosball": offsets = [Vector2(-110,0),Vector2(110,0),Vector2(35,130)]
	if role=="raffle": offsets = [Vector2(-70,-45),Vector2(140,30),Vector2(0,120)]
	if role=="pigeon": offsets = [Vector2(-100,80),Vector2(190,100)]
	var spot: Vector2 = routines.clear_destination(site+offsets[slot%offsets.size()],[])
	if role=="window" and a.entry.id=="odete_janela": spot = places.window
	var home: Vector2 = routines.doorway(a.home,true)
	var shop: Vector2 = routines.doorway(site,false,"Café" if role!="picnic" else "Padaria")
	var walk: Vector2 = routines.clear_destination(site+Vector2(-400+slot*170,250),[])
	var morning := 525+slot*4
	var lunch := 755+slot*5
	var second := 835+slot*4
	var close := 1170+slot*9
	if role=="picnic": morning = 680; lunch = 870; second = 970; close = 1170
	if role=="foosball": morning = 610; lunch = 755; second = 955; close = 1340
	if role=="window": morning = 480; lunch = 770; second = 825; close = 1350
	var mode: String = "window" if a.entry.id=="odete_janela" else "activity"
	var plan: Array = [[0,home,"home","inside","a dormir"],[440+slot*5,walk,"errands","activity","a preparar o dia na vizinhança"],[morning,spot,role,mode,a.entry.activity],[lunch,shop,"lunch","inside","a almoçar no café"],[second,spot,role,mode,a.entry.activity],[close,home,"home","inside","a descansar em casa"]]
	if role=="picnic": plan[3] = [870,shop,"shopping","inside","a devolver a cesta e comprar pão"]
	if role=="window" and a.entry.id=="odete_janela":
		plan.insert(5,[1100,home,"novela","inside","a ver a novela; a rua tem vinte minutos de descanso"])
		plan.insert(6,[1120,spot,role,"window","a descobrir o que aconteceu durante a novela"])
	for row in plan:
		a.schedule.append({"minute":row[0],"destination":row[1],"place":row[2],"mode":row[3],"activity":row[4],"location":world.area_at(row[1]),"stroll":row[2]=="errands"})
	a.schedule.sort_custom(func(x,y):return x.minute<y.minute)
	a.prepare_stroll()
func bind() -> void:
	world.social_life.actors.append_array(residents)
	world.social_life.by_id.merge(by_id)
	world.living_life.by_id.merge(by_id)
	presence.bind()
func synchronize(cycle: RefCounted,force := false) -> void:
	minute = cycle.minutes; day = world.living_life.day
	if is_instance_valid(episodes): episodes.reset()
	super.synchronize(cycle,force)
	if is_instance_valid(presence): presence.synchronize(cycle)
func step(delta: float,cycle: RefCounted) -> void:
	minute = cycle.minutes; day = world.living_life.day
	super.step(delta,cycle)
	episodes.step(delta,cycle)
	presence.step(delta,cycle)
func player() -> CharacterBody2D: return world.living_life.player()
func say(id: String,text: String,pose := "speak") -> void:
	world.social_life._say(by_id[id],text,pose)
func record(key: String,amount := 1) -> void:
	state[key] = int(state.get(key,0))+amount
	world.living_life.dirty = true
func tell(text: String) -> void: world.living_life.tell(text)
func open_person(actor: CharacterBody2D) -> void: dialogues.open_person(actor,player())
func pose_for(actor: CharacterBody2D) -> Dictionary:
	if not ART.data.characters.has(actor.entry.id): return {}
	var frames: Array = ART.data.characters[actor.entry.id].frames
	var walking: bool = actor.motion.phase=="walk" and not actor.story_locked and actor.state!="window"
	var back: bool = actor.travel_direction.y<-absf(actor.travel_direction.x)*.35
	var frame: int = (6 if back else 4)+posmod(actor.frame-2,2) if walking else (actor.story_frame if actor.story_frame>=0 else 0)
	if not walking and actor.appointment.get("place","")!=actor.entry.role: frame = 4
	return frames[clampi(frame,0,7)]
