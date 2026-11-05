extends Node2D
## One neighbourhood bar; the same people walk here after dinner and go home later.
const ART = preload("res://data/village/nightlife-art.json")
const BarProp = preload("res://scripts/village_nightlife_prop.gd")
const OPEN := 1230.0 # 20:30
const CLOSE := 90.0 # 01:30, carried across midnight
const CAST := [
	{"id":"gil","arrive":1260,"leave":45,"group":0,"dance":true},
	{"id":"tiago","arrive":1270,"leave":65,"group":0,"dance":false},
	{"id":"alexandre","arrive":1280,"leave":50,"group":0,"dance":false},
	{"id":"martim","arrive":1290,"leave":70,"group":1,"dance":false},
	{"id":"afonso","arrive":1275,"leave":60,"group":2,"dance":true},
	{"id":"yuki","arrive":1285,"leave":30,"group":1,"dance":false},
	{"id":"camila","arrive":1240,"leave":1420,"group":2,"dance":true},
	{"id":"beatriz","arrive":1250,"leave":40,"group":2,"dance":true},
	{"id":"samira","arrive":1265,"leave":1405,"group":1,"dance":false},
	{"id":"nuno","arrive":1210,"leave":90,"group":3,"dance":false}]
const CONVERSATIONS := [
	[["O Tiago já calculou o caminho para casa?","Sim. Mas o Gil encontrou uma padaria no caminho."],["Hoje não tiro mais fotografias.","Disseste isso antes de fotografares o candeeiro."],["Só mais uma música?","Essa já é a terceira última música."]],
	[["À noite esta rua parece outra.","Até os azulejos ficam com outra cor."],["Amanhã abro a loja mais tarde.","Então desta vez podes acabar a conversa."],["Este café ainda conta como o de depois do jantar?","A esta hora já começa a contar como pequeno-almoço."]],
	[["Isto não estava no plano do passeio.","É por isso que o plano melhorou."],["Eu estava só a acompanhar o ritmo.","Já atravessaste a esplanada a acompanhar o ritmo."],["Vou descansar os pés uma música.","Combinado. Depois trocamos de lugar."]]]
var world: Node2D
var building: Node2D
var center := Vector2.ZERO
var counter: Node2D
var objects: Array[Node2D] = []
var patrons: Array[CharacterBody2D] = []
var specs: Dictionary = {}
var spots: Dictionary = {}
var dance_spots: Dictionary = {}
var sprite_paint := ShaderMaterial.new()
var opened := false
var minute := 480.0
var elapsed := 0.0
var talks: Dictionary = {}
var conversation_turns := 0
var dance_changes := 0
var music_requests := 0
var light_level := 0.0
var music: AudioStreamPlayer
var tracks: Array[AudioStreamWAV] = []
var track := 0
var overlay: Node2D
func is_open(at: float) -> bool: return at>=OPEN or at<CLOSE
func build_equipment() -> void:
	sprite_paint.shader = preload("res://shaders/village_neighbour_cutout.gdshader")
	for b in world.buildings:
		if b.label=="Recanto Lord Byron": building = b; break
	assert(building!=null,"The night bar needs its actual Lord Byron frontage")
	center = world._event_space(building.entry_position+Vector2(150,340),420)
	for spec in [[0,Vector2(0,-155),118.0],[1,Vector2(-205,15),94.0],[1,Vector2(100,75),94.0],[2,Vector2(270,-60),145.0],[3,Vector2(-325,-50),119.0]]:
		var object := BarProp.new()
		object.setup(self,int(spec[0]),world._event_space(center+spec[1],125),float(spec[2]))
		objects.append(object)
	counter = objects[0]
func _ready() -> void:
	name = "LordByronAfterDark"
	var occupied: Array = []
	var offsets := [Vector2(-320,70),Vector2(-210,115),Vector2(-305,210),Vector2(20,95),Vector2(120,320),Vector2(155,135),Vector2(265,290),Vector2(-30,300),Vector2(50,225),Vector2(-125,-175)]
	for i in CAST.size():
		var spec: Dictionary = CAST[i]
		var a: CharacterBody2D = world.population.by_id[spec.id]
		patrons.append(a); specs[spec.id] = spec
		var preferred: Vector2 = center+offsets[i]
		if spec.id=="nuno": preferred = counter.position+Vector2(-140,-15)
		spots[spec.id] = a.population.routines.clear_destination(preferred,occupied)
		occupied.append(spots[spec.id])
		if spec.dance:
			dance_spots[spec.id] = a.population.routines.clear_destination(center+Vector2(310+(i%2)*95,160+(i%3)*110),occupied)
			occupied.append(dance_spots[spec.id])
		_plan(a,spec)
	for object in objects:
		world.interactions.targets.append({"id":"night_bar_"+str(object.get_instance_id()),"kind":"street_scene","node":object,"position":object.position,"label":"Lord Byron · bar da noite","reach":165.0,"radius":0.0})
	music = AudioStreamPlayer.new(); music.name = "OriginalBarMusic"; music.volume_db = -80
	tracks.append(_music_loop(false)); tracks.append(_music_loop(true)); music.stream = tracks[0]; add_child(music)
	var layer := CanvasLayer.new(); layer.layer = 4; add_child(layer)
	overlay = preload("res://scripts/village_nightlife_lights.gd").new(); overlay.director = self; layer.add_child(overlay)
	world.visibility_changed.connect(func():
		layer.visible = world.is_visible_in_tree()
		music.stream_paused = not world.is_visible_in_tree()
		if not world.is_visible_in_tree(): release_all()
		_update_warm_light())
func _process(_delta: float) -> void: _update_warm_light()
func _update_warm_light() -> void:
	var grade: ShaderMaterial = world.get_parent().get("daylight")
	if grade==null: return
	var transform: Transform2D = world.get_canvas_transform()
	var size := get_viewport_rect().size
	grade.set_shader_parameter("local_light_center",(transform*(center+Vector2(0,-40)))/size)
	grade.set_shader_parameter("local_light_radius",Vector2(710,540)*transform.get_scale()/size)
	grade.set_shader_parameter("local_light_amount",.78 if opened and world.is_visible_in_tree() else 0.0)
func _block(at: float,destination: Vector2,activity: String,inside := false) -> Dictionary:
	return {"at":"%02d:%02d"%[int(at)/60,int(at)%60],"minute":at,"destination":destination,"place":"nightlife_rest" if inside else "nightlife","mode":"inside" if inside else "activity","activity":activity,"location":"Lord Byron · bar e esplanada" if not inside else "quarto depois da noite","stroll":false}
func _plan(a: CharacterBody2D,spec: Dictionary) -> void:
	var home: Vector2 = a.schedule[0].destination
	if spec.id=="nuno":
		# The potter helps at the bar after closing his stall, and sleeps upstairs.
		home = a.population.routines.doorway(building.entry_position,false,"Recanto Lord Byron")
	var plan: Array = a.schedule.filter(func(b):return float(b.minute)<float(spec.arrive) and float(b.minute)>0)
	var job := "a ajudar ao balcão depois de guardar a cerâmica" if spec.id=="nuno" else "a conversar com os amigos no bar"
	if spec.leave<CLOSE+1:
		plan.append(_block(0,spots[spec.id],job))
		plan.append(_block(spec.leave,home,"a descansar depois da noite",true))
	else:
		plan.append(_block(0,home,"a dormir",true))
	plan.append(_block(spec.arrive,spots[spec.id],job))
	if spec.leave>720: plan.append(_block(spec.leave,home,"a descansar depois da noite",true))
	plan.sort_custom(func(a,b):return a.minute<b.minute)
	a.schedule = plan
	# Sleeping later follows a late closing shift, rather than reopening at dawn.
	if spec.id=="nuno":
		for b in a.schedule:
			if b.minute>90 and b.minute<600:
				b.minute = 600 if b.mode=="inside" else 630
				if b.mode=="inside": b.destination = home; b.activity = "a tomar o pequeno-almoço no quarto do bar"
			if str(b.activity).contains("jantar"):
				b.minute = 1090; b.destination = home; b.activity = "a jantar antes de ajudar no bar"
			b.at = "%02d:%02d"%[int(b.minute)/60,int(b.minute)%60]
		a.schedule.sort_custom(func(a,b):return a.minute<b.minute)
func release_all() -> void:
	for a in patrons: _release(a)
	talks.clear()
func _release(a: CharacterBody2D) -> void:
	if not a.get_meta("nightlife_owned",false): return
	a.event_busy = false; a.social_pose = ""; a.social_line = ""
	a.set_meta("nightlife_owned",false); a.set_meta("nightlife_pose",{})
	a.set_meta("nightlife_mode",""); a.art.material = world.opaque_paint; a.art.queue_redraw()
func prepare(cycle: RefCounted) -> void:
	# Release BEFORE population changes appointments so that closing never freezes a return home.
	for a in patrons:
		var next: Dictionary = a.schedule[a.population.routines.index_at(a,cycle.minutes)]
		if next.place!="nightlife" or not is_open(cycle.minutes): _release(a)
func synchronize(cycle: RefCounted) -> void:
	release_all(); minute = cycle.minutes
	_refresh()
func _refresh() -> void:
	opened = is_open(minute)
	light_level = 1.0 if opened else 0.0
	for object in objects: object.queue_redraw()
	if is_instance_valid(music):
		if opened and not music.playing: music.play()
		elif not opened and music.playing: music.stop()
func step(delta: float,cycle: RefCounted) -> void:
	minute = cycle.minutes; elapsed += delta
	_refresh()
	if not opened:
		release_all()
	else:
		for a in patrons: _act(a)
		_converse(delta)
	if is_instance_valid(music):
		var distance := INF
		for p in world.people:
			if p.controlled: distance = p.position.distance_to(center)
		music.volume_db = -20.0-linear_to_db(1.0+distance/180.0)*2 if opened and distance<1100 else -80
	if is_instance_valid(overlay): overlay.queue_redraw()
func _act(a: CharacterBody2D) -> void:
	if a.appointment.get("place","")!="nightlife" or not a.available(): _release(a); return
	if a.position.distance_to(center)>730: return
	var spec: Dictionary = specs[a.entry.id]
	var phase := fposmod(elapsed+a.ordinal*5.7,87.0)
	var dancing: bool = spec.dance and phase>23 and phase<57 and a.greet_time<=0 and not talks.values().any(func(t):return t.members.has(a.entry.id))
	var target: Vector2 = dance_spots[a.entry.id] if dancing else spots[a.entry.id]
	if a.position.distance_to(target)>27:
		_release(a)
		a.set_meta("nightlife_mode","approach")
		if a.goal.distance_to(target)>8 or a.route.is_empty(): a._begin_walk(target,"walking")
		return
	if not a.get_meta("nightlife_owned",false):
		a._cancel_encounter(); a.route.clear(); a.state = "activity"
		a.set_meta("nightlife_owned",true)
	a.event_busy = true; a.velocity = Vector2.ZERO
	var mode := "dance" if dancing else ("serve" if spec.id=="nuno" else "chat")
	a.set_meta("nightlife_mode",mode)
	var pose := 0
	if dancing:
		# Authored full-body changes, unequal holds and personal footwork; no squashing or bobbing.
		var beat := fposmod(elapsed*(1.02 if track==1 else .87)+a.ordinal*.17,2.4)
		pose = 2 if beat<.68 or beat>1.82 else 3
		a.facing_left = a.entry.id in ["camila","afonso"]
	elif spec.id=="nuno": pose = 1 if fposmod(elapsed,11)>8 else 0
	else:
		pose = 1 if a.social_pose=="speak" and a.speech_until>a.clock else 0
		var partners: Array = patrons.filter(func(b):return b!=a and b.get_meta("nightlife_mode","")=="chat" and specs[b.entry.id].group==spec.group)
		if not partners.is_empty():
			a.facing_left = partners[0].position.x<a.position.x
			a.travel_direction = a.position.direction_to(partners[0].position)
	var frames: Array = ART.data.characters[a.entry.id]
	if int(a.get_meta("nightlife_frame",-1))!=pose and dancing: dance_changes += 1
	a.set_meta("nightlife_frame",pose); a.set_meta("nightlife_pose",frames[pose])
	a.art.material = sprite_paint; a.art.queue_redraw()
func _converse(delta: float) -> void:
	for group in range(3):
		if talks.has(group):
			var t: Dictionary = talks[group]; t.wait -= delta
			var a: CharacterBody2D = world.population.by_id[t.members[0]]
			var b: CharacterBody2D = world.population.by_id[t.members[1]]
			if not _can_chat(a,b) or a.greet_time>0 or b.greet_time>0: talks.erase(group); continue
			if t.wait>0: continue
			if t.stage==0:
				world.social_life._say(b,t.lines[1],"speak"); a.social_pose = "listen"
				t.stage = 1; t.wait = 7; conversation_turns += 1
			else: talks.erase(group)
		elif fposmod(elapsed+group*7,17)<delta:
			var candidates: Array = patrons.filter(func(a):return specs[a.entry.id].group==group and a.get_meta("nightlife_mode","")=="chat" and a.greet_time<=0)
			if candidates.size()<2: continue
			var turn := int(elapsed/17)+group
			var a: CharacterBody2D = candidates[turn%candidates.size()]
			var b: CharacterBody2D = candidates[(turn+1)%candidates.size()]
			if not _can_chat(a,b): continue
			var lines: Array = CONVERSATIONS[group][turn%3]
			talks[group] = {"members":[a.entry.id,b.entry.id],"lines":lines,"wait":6.0,"stage":0}
			world.social_life._say(a,lines[0],"speak"); b.social_pose = "listen"; conversation_turns += 1
			a.memory["night_chat_"+b.entry.id] = int(a.memory.get("night_chat_"+b.entry.id,0))+1
func _can_chat(a: CharacterBody2D,b: CharacterBody2D) -> bool:
	return a.get_meta("nightlife_mode","")=="chat" and b.get_meta("nightlife_mode","")=="chat" and a.available() and b.available() and a.position.distance_to(b.position)<285
func greet(a: CharacterBody2D) -> String:
	a.greet_time = 4.0
	if a.state in ["commuting","walking"]: return a.entry.name+" acena a caminho do Lord Byron. A conversa continua quando chegar ao bar."
	var replies := {"gil":"O Gil baixa a voz para ouvir o Te e o Jo: «O Tiago diz que é a última música. Já vamos na quarta.»","tiago":"O Tiago guarda o telemóvel: «Se formos pela rua de cima poupamos quatro minutos. Se o Gil não vir uma pastelaria.»","alexandre":"O Alexandre mostra uma fotografia tremida: «Não é falta de foco. É o Afonso a dançar.»","martim":"O Martim abre espaço junto à mesa: «Venham para aqui. Ainda se consegue conversar sem gritar.»","afonso":"O Afonso pára os passos e acena: «Eu ia só ouvir. Depois começou esta.»","beatriz":"A Beatriz fechou o caderno por hoje: «À noite não desenho fachadas. Dou descanso às mãos e trabalho os pés.»","camila":"A Camila recupera o fôlego: «A corrida de amanhã fica para mais tarde. Hoje isto conta como treino.»","yuki":"A Yuki pousa a máquina: «A melhor parte desta fotografia não cabe na fotografia.»","samira":"A Samira puxa a conversa: «Hoje fechei a banca a horas. Já merecia ver a vila assim.»","nuno":"O Nuno deixa o pano ao lado dos copos: «A cerâmica já ficou guardada. Até à uma e meia ajudo aqui. Querem escolher a música?»"}
	return replies.get(a.entry.id,"Boa noite! Cheguem para a conversa.")
func interact(_person: CharacterBody2D) -> String:
	if not opened: return "O Lord Byron abre a noite às 20:30 e fecha à 01:30. As mesas esperam pelo encontro depois do jantar."
	world.living_life.panel.show_choices("Lord Byron · a noite na vila","A música chega à esplanada. Uns ficam à conversa junto às mesas; outros afastam as cadeiras para dançar.",["Pedir uma música mais animada" if track==0 else "Pedir uma música mais calma","Meter conversa com quem está no bar","Perguntar a que horas fecha"],func(choice):
		if not opened: world.living_life.tell("A noite entretanto terminou. Amanhã há mais."); return
		if choice==0:
			track = 1-track; music.stream = tracks[track]; music.play(); music_requests += 1
			world.living_life.tell("O Nuno muda a música. O ritmo da dança acompanha a escolha.")
		elif choice==1:
			var nearby: Array = patrons.filter(func(a):return a.get_meta("nightlife_owned",false) and a.entry.id!="nuno")
			world.living_life.tell(greet(nearby[int(elapsed)%nearby.size()]) if not nearby.is_empty() else "O Nuno acena: o pessoal ainda está a chegar.")
		else: world.living_life.tell("«À uma e meia baixamos a música e fechamos. A vila também precisa de dormir.»"))
	return ""
func _music_loop(upbeat: bool) -> AudioStreamWAV:
	# Original procedural instrumental; no recordings, voices or copyrighted music.
	var rate := 16000; var beat := 60.0/(112.0 if upbeat else 96.0)
	var samples := roundi(rate*beat*32); var bytes := PackedByteArray(); bytes.resize(samples*2)
	var bass := [45,45,48,43,41,41,43,45]
	var melody := [69,72,76,72,67,71,74,71,65,69,72,69,67,71,74,76]
	for i in samples:
		var t := float(i)/rate; var k := int(t/beat); var local := fposmod(t,beat)
		var hz := 440.0*pow(2.0,(bass[(k/4)%8]-69)/12.0)
		var lead := 440.0*pow(2.0,(melody[(k/2)%16]-69)/12.0)
		var low := sin(TAU*hz*t)*exp(-local*7)*.18
		var keys := (sin(TAU*lead*t)+.22*sin(TAU*lead*2*t))*exp(-fposmod(t,beat*2)*4)*.08
		var kick := sin(TAU*(48*local+3*(1-exp(-local*25))))*exp(-local*26)*.16
		var hat_time := fposmod(t,beat*.5)
		var hat := sin(t*TAU*6327)*sin(t*TAU*4271)*exp(-hat_time*105)*(.035 if upbeat else .015)
		bytes.encode_s16(i*2,clampi(roundi((low+keys+kick+hat)*23000),-32767,32767))
	var stream := AudioStreamWAV.new(); stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate; stream.data = bytes; stream.loop_mode = AudioStreamWAV.LOOP_FORWARD; stream.loop_end = samples
	return stream
