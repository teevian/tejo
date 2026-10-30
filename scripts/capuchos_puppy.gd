extends Node2D
## A persistent guardian: food, voluntary sniffing and consent to touch are separate gates.
signal trust_changed
const Art = preload("res://scripts/puppy_art.gd")
const SAFE_FOOD_DISTANCE := 190.0
const TERRITORY := 850.0
var world: Node2D
var home := Vector2.ZERO
var trust := 0.0
var meals := 0
var sniffs := 0
var pets := 0
var friendly := false
var state := "guard"
var state_time := 0.0
var elapsed := 0.0
var facing := Vector2.DOWN
var velocity := Vector2.ZERO
var gait := 0.0
var route := PackedVector2Array()
var goal := Vector2.ZERO
var food: Dictionary = {}
var visitor: Node2D
var attack_target: Node2D
var calm_time := 0.0
var sniff_time := 0.0
var sniff_cooldown := 0.0
var meal_cooldown := 0.0
var bite_cooldown := 0.0
var bark_cooldown := 0.0
var path_cooldown := 0.0
var feedback := "Um cachorro guarda os Capuchos. Dá-lhe espaço."
var feedback_time := 0.0
var previous_people: Dictionary = {}
var bark_player: AudioStreamPlayer2D
var food_art: Node2D
var bite_attempts := 0
var last_bitten_kind := -1
var body: Node2D

func _ready() -> void:
	name = "CachorroDosCapuchos"
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var paint := ShaderMaterial.new()
	paint.shader = preload("res://shaders/opaque_cutout.gdshader")
	body = preload("res://scripts/puppy_body.gd").new()
	body.puppy = self
	body.material = paint
	add_child(body)
	bark_player = AudioStreamPlayer2D.new()
	bark_player.stream = _bark_sound()
	bark_player.volume_db = -15
	bark_player.max_distance = 1250
	add_child(bark_player)

func _draw() -> void:
	draw_set_transform(Vector2(0,3),0,Vector2(1,.35))
	draw_circle(Vector2.ZERO,23,Color(0.06,0.09,0.05,.22))
	draw_set_transform(Vector2.ZERO)

func _set_state(value: String) -> void:
	if state==value:
		return
	state = value
	state_time = 0
	if is_instance_valid(body): body.queue_redraw()

func say(value: String) -> void:
	feedback = value
	feedback_time = 6

func nearest_person():
	var result = null
	var distance := INF
	for person in world.people:
		var d: float = position.distance_squared_to(person.position)
		if d<distance:
			distance = d
			result = person
	return result

func _jo():
	for person in world.people:
		if person.kind==1:
			return person
	return null

func _quiet(person: Node2D) -> bool:
	if person.velocity.length()>10 or person.jumping:
		return false
	return not previous_people.has(person.kind) or person.position.distance_to(previous_people[person.kind])<1.2

func _everyone_clear(at: Vector2, distance: float) -> bool:
	for person in world.people:
		if at.distance_to(person.position)<distance or not _quiet(person):
			return false
	return true

func _rushing() -> bool:
	for person in world.people:
		var distance: float = position.distance_to(person.position)
		var movement: Vector2 = person.velocity
		if previous_people.has(person.kind):
			var observed: Vector2 = (person.position-previous_people[person.kind])*30
			if observed.length()>movement.length(): movement = observed
		var closing: bool = movement.dot(person.position.direction_to(position))>16
		if distance<300 and movement.length()>290:
			return true
		if closing and distance<(100 if friendly else 165):
			return true
	return false

func step(delta: float) -> void:
	if world.people.is_empty():
		return
	elapsed += delta
	state_time += delta
	for key in ["sniff_cooldown","meal_cooldown","bite_cooldown","bark_cooldown","path_cooldown","feedback_time"]:
		set(key,maxf(0,float(get(key))-delta))
	velocity = Vector2.ZERO
	var person = nearest_person()
	var nearby: bool = person!=null and position.distance_to(person.position)<650
	if _rushing() and not friendly and state not in ["chase_jo","nip","retreat"] and bite_cooldown<=0:
		_begin_warning()
	if state=="chase_jo":
		_chase(delta)
	elif state=="nip":
		if state_time>.40:
			attack_target = null
			_set_state("retreat")
			_go(home)
	elif state=="retreat":
		_walk(delta,160)
		if route.is_empty(): _set_state("guard")
	elif not food.is_empty():
		_food_step(delta)
	elif state in ["approach","sniff","invite","pet","happy"]:
		_social_step(delta)
	elif nearby:
		facing = position.direction_to(person.position)
		if _quiet(person) and _everyone_clear(position,185):
			calm_time += delta
			trust = minf(.08 if meals==0 else .48,trust+delta*.0015) if trust<.48 else trust
		else:
			calm_time = 0
		if friendly:
			visitor = person
			_set_state("happy")
		elif meals>=2 and trust>=.28 and calm_time>=6 and sniff_cooldown<=0 and _quiet(person) and person.position.distance_to(home)<TERRITORY:
			visitor = person
			sniff_time = 0
			_set_state("approach")
			say("Ele decidiu aproximar-se. Fica quieto e deixa-o cheirar.")
		elif trust<.28 and position.distance_to(person.position)<520:
			_set_state("bark")
			_bark()
		else:
			_set_state("guard")
	else:
		calm_time = 0
		_set_state("guard")
		if position.distance_to(home)>90:
			if route.is_empty(): _go(home)
			_walk(delta,75)
	for friend in world.people:
		previous_people[friend.kind] = friend.position
	gait += velocity.length()*delta
	if velocity.length()>1: facing = velocity.normalized()
	queue_redraw()
	body.queue_redraw()

func _begin_warning() -> void:
	trust = maxf(0,trust-.07)
	calm_time = 0
	sniff_time = 0
	sniff_cooldown = 8
	bite_cooldown = 12
	attack_target = _jo() # Identity, never whichever character happens to be selected.
	_bark()
	if attack_target!=null and attack_target.position.distance_to(home)<TERRITORY:
		bite_attempts += 1
		_set_state("chase_jo")
		say("Assustou-se e foi atrás do Jo! Recuem e parem de correr.")
		_go(attack_target.position)
	else:
		_set_state("retreat")
		_go(home)
		say("Está assustado. Recuem e deixem-no acalmar.")

func _chase(delta: float) -> void:
	# Every update revalidates Jo's identity and the guard's limited territory.
	var jo = _jo()
	if jo==null or attack_target!=jo or jo.kind!=1 or jo.position.distance_to(home)>TERRITORY or position.distance_to(home)>TERRITORY or state_time>3.2:
		attack_target = null
		_set_state("retreat")
		_go(home)
		return
	if position.distance_to(jo.position)<39:
		last_bitten_kind = jo.kind
		jo.puppy_recoil = position.direction_to(jo.position)*85
		jo.puppy_recoil_time = .35
		_set_state("nip")
		_bark()
		return
	if path_cooldown<=0:
		_go(jo.position)
		path_cooldown = .2
	_walk(delta,285)

func _food_step(delta: float) -> void:
	var at: Vector2 = food.position
	if not _everyone_clear(at,SAFE_FOOD_DISTANCE):
		if state=="eat": _set_state("wait_food")
		_set_state("wait_food")
		return
	if meal_cooldown>0:
		_set_state("wait_food")
		return
	if position.distance_to(at)>25:
		_set_state("to_food")
		if path_cooldown<=0:
			_go(at)
			path_cooldown = 1
		_walk(delta,62)
		return
	_set_state("eat")
	if state_time<3.8:
		return
	meals += 1
	trust = minf(.50,trust+.16) if trust<.50 else trust
	meal_cooldown = 14
	food_art.queue_free()
	food.clear()
	trust_changed.emit()
	_set_state("guard")
	say("Comeu com calma. A confiança cresce aos poucos; deixa-o escolher o próximo passo.")

func _social_step(delta: float) -> void:
	if not is_instance_valid(visitor):
		_set_state("guard")
		return
	facing = position.direction_to(visitor.position)
	if not _quiet(visitor) and state in ["approach","sniff","invite","pet"]:
		_abort_greeting()
		return
	if state=="approach":
		var destination: Vector2 = visitor.position+visitor.position.direction_to(position)*62
		if position.distance_to(visitor.position)>78:
			if path_cooldown<=0:
				_go(destination)
				path_cooldown = .8
			_walk(delta,42)
		else:
			_set_state("sniff")
			sniff_time = 0
	elif state=="sniff":
		if position.distance_to(visitor.position)>110:
			_abort_greeting()
			return
		sniff_time += delta
		if sniff_time>=4.5:
			sniffs += 1
			trust = minf(.90,trust+.14)
			trust_changed.emit()
			if sniffs>=2:
				_set_state("invite")
				say("Ficou ao teu lado e procura a tua mão. Espaço para uma festa suave.")
			else:
				_set_state("retreat")
				_go(home)
				sniff_cooldown = 10
				calm_time = 0
				say("Cheirou-te e voltou ao seu canto. Dá-lhe tempo para voltar.")
	elif state=="invite":
		if state_time>18:
			_abort_greeting()
	elif state=="pet":
		if state_time>=3:
			pets += 1
			trust = minf(1,trust+.16)
			friendly = meals>=2 and sniffs>=2 and pets>=1 and trust>=.72
			trust_changed.emit()
			_set_state("happy")
			say("Já confia em vocês. Continua a guardar os Capuchos, agora de cauda a abanar." if friendly else "Gostou da festa. Continuem com calma.")
	elif state=="happy":
		if position.distance_to(visitor.position)>200 or state_time>12:
			_set_state("guard")
		elif friendly and position.distance_to(visitor.position)>90:
			if path_cooldown<=0:
				_go(visitor.position+visitor.position.direction_to(position)*70)
				path_cooldown = 1
			_walk(delta,60)

func _abort_greeting() -> void:
	trust = maxf(0,trust-.025)
	calm_time = 0
	sniff_time = 0
	sniff_cooldown = 10
	_set_state("retreat")
	_go(home)
	say("Preferiu afastar-se. Fica quieto; ele voltará quando estiver pronto.")

func food_index(person: Node2D) -> int:
	for i in person.inventory.items.size():
		if person.inventory.items[i].type=="dog_food": return i
	return -1

func target_for(person: Node2D) -> Dictionary:
	var distance: float = person.position.distance_to(position)
	if distance>480 or not world.can_walk_line(person.position,position): return {}
	if food_index(person)<0 and distance>115: return {}
	return {"id":"capuchos_puppy","kind":"puppy","label":"Cachorro dos Capuchos","position":position,"reach":480.0,"radius":0.0,"node":self}

func interact(person: Node2D) -> String:
	var distance: float = person.position.distance_to(position)
	if distance>480: return "Aproxima-te devagar, mantendo alguma distância."
	if state=="invite" and visitor==person and distance<100 and _quiet(person):
		_set_state("pet")
		person.facing = person.position.direction_to(position)
		say("Uma festa suave. Ele ficou porque quis.")
	elif friendly and distance<100 and _quiet(person):
		visitor = person
		_set_state("pet")
		say("Reconheceu-te e aceita a festa.")
	elif food_index(person)>=0 and food.is_empty() and state not in ["chase_jo","nip","approach","sniff","pet"]:
		var drop: Vector2 = world.interactions.find_drop_position(person.position+person.position.direction_to(position)*45,person.position)
		if drop==Vector2.INF: return "Procura um pouco de chão livre para a comida."
		if drop.distance_to(home)>TERRITORY: return "Deixa a comida nos arredores dos Capuchos; é aí que ele se sente seguro."
		person.inventory.take(food_index(person))
		leave_food(drop)
	else:
		say("Deixa-o escolher aproximar-se e cheirar. Ainda não pediu festas." if meals>=2 else "Precisa de comida e de espaço. Encontras ração junto aos bancos e nos caminhos.")
	return feedback

func leave_food(at: Vector2) -> void:
	food = {"position":at}
	food_art = preload("res://scripts/world_pickup.gd").new()
	food_art.item = Art.FOOD
	food_art.position = at
	food_art.scale = Vector2.ONE*1.7
	world.actors.add_child(food_art)
	if state not in ["chase_jo","nip"]: _set_state("wait_food")
	say("Comida no chão. Afastem-se os dois; ele aproxima-se ao ritmo dele.")

func _go(at: Vector2) -> void:
	goal = at
	if world.can_walk_line(position,at): route = PackedVector2Array([at])
	else: route = world.find_path(position,at)

func _walk(delta: float, speed: float) -> void:
	var remaining := delta*speed
	while remaining>0 and not route.is_empty():
		var at := route[0]
		if position.distance_to(at)<3:
			route.remove_at(0)
			continue
		var direction := position.direction_to(at)
		var travel := minf(8,minf(remaining,position.distance_to(at)))
		var candidate := position+direction*travel
		if not world.is_walkable(candidate,8):
			route.clear()
			return
		position = candidate
		velocity = direction*speed
		remaining -= travel

func hint() -> String:
	if feedback_time>0: return feedback
	if state in ["approach","sniff"]: return "Fiquem quietos. É ele que vem cheirar."
	if state=="invite": return "Pediu uma festa. Espaço, sem avançar para ele."
	if not food.is_empty(): return "Recuem os dois e esperem; só come quando se sentir seguro."
	if friendly: return "O pequeno guardião já confia em vocês."
	if meals<2: return "Espaço com ração na bolsa: pousar comida. Depois recuem e esperem."
	return "Mantenham distância e fiquem quietos. Deixem-no vir ter convosco."

func _bark() -> void:
	if bark_cooldown>0: return
	bark_cooldown = 2.8
	# Do not play off-screen calls at the listener's origin.
	if is_instance_valid(bark_player): bark_player.play()

func _bark_sound() -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	var bytes := PackedByteArray()
	var rng := RandomNumberGenerator.new()
	rng.seed = 8327
	for i in 7056:
		var t := float(i)/22050
		var phase := fmod(t,.16)
		var envelope := pow(maxf(0,sin(phase/.16*PI)),3)*exp(-phase*14)
		var frequency := 290+120*exp(-phase*22)
		var tone := sin(TAU*frequency*t)*.45+sin(TAU*frequency*2.03*t)*.24+rng.randf_range(-.3,.3)
		var sample := int(clampf(tone*envelope,-1,1)*16000)
		bytes.append(sample&255)
		bytes.append((sample>>8)&255)
	stream.data = bytes
	return stream
