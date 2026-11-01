extends Node2D
## A self-contained vertical scene. Garden keeps its live state while this is open.
signal return_requested
const Route = preload("res://scripts/climbing_route.gd")
const Space = preload("res://scripts/climbing_space.gd")
const Motion = preload("res://scripts/climbing_motion.gd")
const Person = preload("res://scripts/climbing_person.gd")
const Scenery = preload("res://scripts/climbing_scenery.gd")
const Interface = preload("res://scripts/climbing_hud.gd")
const DialoguePanel = preload("res://scripts/dialogue_panel.gd")
var platforms: Array[Dictionary] = Route.platforms()
var links: Array[Dictionary] = Route.links()
var people: Array = []
var selected := 0
var flags: Dictionary = {}
var visited: Dictionary = {}
var checkpoint := 0
var completed := false
var camera: Camera2D
var scenery: Node2D
var wall: Node2D
var hud: Control
var dialogue_panel: Control
var dialogue_lines: Array = []
var dialogue_index := 0
var dialogue_initiator := 0
var rock_time := 0.0
var rock_falling := false
var clock := 0.0
var boulders: Array[Dictionary] = Route.boulders()
var motion = Motion.new()
var space = Space.new()
var expedition = preload("res://scripts/climbing_expedition.gd").new()
var perspective: Node2D
var rope_taut := false
var summit_reveal := 0.0
var recoveries := 0
var overlap_order := 1.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	motion.scene = self
	space.scene = self
	expedition.scene = self
	_setup_input()
	RenderingServer.set_default_clear_color(Color("8ba6a7"))
	wall = preload("res://scripts/climbing_wall.gd").new()
	wall.scene = self
	add_child(wall)
	scenery = Scenery.new()
	scenery.scene = self
	add_child(scenery)
	for i in 2:
		var person := Person.new()
		person.kind = i
		person.name = "Te" if i==0 else "Jo"
		person.position = Vector2(370-i*95,Route.START_Y)
		person.z_index = 5+i
		people.append(person)
		add_child(person)
	space.setup()
	camera = Camera2D.new()
	camera.name = "ClimbingCamera"
	camera.position = camera_target()
	add_child(camera)
	camera.make_current()
	wall.update_view()
	perspective = preload("res://scripts/climbing_perspective.gd").new()
	perspective.scene = self
	add_child(perspective)
	var layer := CanvasLayer.new()
	layer.layer = 5
	add_child(layer)
	hud = Interface.new()
	hud.scene = self
	layer.add_child(hud)
	dialogue_panel = DialoguePanel.new()
	layer.add_child(dialogue_panel)
	dialogue_panel.advance_requested.connect(_talk)
	_select_person(0)
	hud.message("Q / E: rodar o penedo. A perspetiva abre caminhos. Cima salta ou escala.",6.0)

func _setup_input() -> void:
	var bindings := {"walk_left":[KEY_LEFT,KEY_A],"walk_right":[KEY_RIGHT,KEY_D],"walk_up":[KEY_UP,KEY_W],"walk_down":[KEY_DOWN,KEY_S],"interact":[KEY_SPACE],"talk":[KEY_T],"swap":[KEY_TAB],"pause":[KEY_ESCAPE],"rotate_left":[KEY_Q],"rotate_right":[KEY_E]}
	for action in bindings:
		if not InputMap.has_action(action): InputMap.add_action(action,0.2)
		# Keep the shared world's controller bindings; avoid duplicates on re-entry.
		for key in bindings[action]:
			var event := InputEventKey.new()
			event.physical_keycode = key
			if not InputMap.action_has_event(action,event): InputMap.action_add_event(action,event)
	for binding in [["interact",JOY_BUTTON_X],["talk",JOY_BUTTON_A],["swap",JOY_BUTTON_RIGHT_SHOULDER],["pause",JOY_BUTTON_START]]:
		var event := InputEventJoypadButton.new()
		event.button_index = binding[1]
		if not InputMap.action_has_event(binding[0],event): InputMap.action_add_event(binding[0],event)
	for binding in [["walk_left",JOY_AXIS_LEFT_X,-1.0],["walk_right",JOY_AXIS_LEFT_X,1.0],["walk_up",JOY_AXIS_LEFT_Y,-1.0],["walk_down",JOY_AXIS_LEFT_Y,1.0]]:
		var axis := InputEventJoypadMotion.new()
		axis.axis = binding[1]
		axis.axis_value = binding[2]
		if not InputMap.action_has_event(binding[0],axis): InputMap.action_add_event(binding[0],axis)

func any_busy() -> bool:
	return people.any(func(person): return person.busy() or person.jump_buffer>0) or rock_falling or space.rotating

func _input(event: InputEvent) -> void:
	if not is_node_ready() or event.is_echo(): return
	if event.is_action_pressed("pause"):
		if not dialogue_lines.is_empty():
			_end_talk()
		else:
			get_tree().paused = not get_tree().paused
			hud.refresh_pause()
	elif get_tree().paused: return
	elif event.is_action_pressed("talk"): _talk()
	elif not dialogue_lines.is_empty(): return
	elif event.is_action_pressed("rotate_left"): rotate_world(-1)
	elif event.is_action_pressed("rotate_right"): rotate_world(1)
	elif space.rotating: return
	elif event.is_action_pressed("swap"): _select_person(1-selected)
	elif event.is_action_pressed("interact"): interact()
	elif event.is_action_pressed("walk_left"): direction_pressed(-1)
	elif event.is_action_pressed("walk_right"): direction_pressed(1)
	elif event.is_action_pressed("walk_up"): people[selected].jump_buffer = 0.18
	elif event.is_action_pressed("walk_down"): descend()
	else: return
	get_viewport().set_input_as_handled()

func _select_person(index: int) -> void:
	if people.is_empty() or get_tree().paused or not dialogue_lines.is_empty() or space.rotating: return
	selected = index
	for i in 2: people[i].controlled = i==index
	if is_instance_valid(hud): hud.select(index)

func edge_for(person, direction := 0) -> Dictionary:
	if person.shelf<0: return {}
	if expedition.belay_ready(person):
		for edge in links:
			if edge.from==person.shelf and edge.mode=="belay": return edge
	var fallback: Dictionary = {}
	var candidates: Array[Dictionary] = []
	for edge in links:
		if edge.from!=person.shelf or not platforms[edge.to].enabled: continue
		if direction!=0 and edge.dir!=direction: continue
		if edge.mode=="belay": continue
		if not edge_viewable(edge):
			if fallback.is_empty(): fallback = edge
			continue
		if edge.get("optional",false): return edge
		candidates.append(edge)
	if candidates.is_empty(): return fallback
	return candidates[0]

func edge_viewable(edge: Dictionary) -> bool:
	return not edge.has("views") or space.view in edge.views

func platform_visible(id: int) -> bool:
	var platform: Dictionary = platforms[id]
	if not platform.has("views"): return true
	if people.any(func(person): return person.shelf==id or (person.traversing() and person.arrival_shelf==id)): return true
	var face := posmod(roundi(space.angle/(PI*0.5)),4)
	return face in platform.views

func edge_x(person, direction: int) -> float:
	var edge := edge_for(person,direction)
	if not edge.is_empty():
		var target: Dictionary = platforms[edge.to]
		var source: Dictionary = platforms[person.shelf]
		var lip := float(target.x)-Motion.RADIUS if direction>0 else float(target.end)+Motion.RADIUS
		return clampf(lip,float(source.x)+Motion.RADIUS,float(source.end)-Motion.RADIUS)
	var shelf: Dictionary = platforms[maxi(0,person.shelf)]
	return float(shelf.end)-Motion.RADIUS if direction>0 else float(shelf.x)+Motion.RADIUS

func edge_gap(edge: Dictionary) -> float:
	var source: Dictionary = platforms[edge.from]
	var target: Dictionary = platforms[edge.to]
	return maxf(0,float(target.x)-float(source.end)) if edge.dir>0 else maxf(0,float(source.x)-float(target.end))

func near_edge(person, edge: Dictionary, reach := 85.0) -> bool:
	if not person.grounded or person.shelf<0: return false
	if not edge_viewable(edge): return false
	return edge_gap(edge)<75 and absf(person.position.x-edge_x(person,int(edge.dir)))<=reach

func direction_pressed(direction: int) -> void:
	var person = people[selected]
	if person.traversing(): return
	if not person.anchor.is_empty(): release_anchor(person)
	person.face = direction

func attempt_climb(direction := 0) -> bool:
	if get_tree().paused or not dialogue_lines.is_empty() or space.rotating: return false
	var person = people[selected]
	if person.busy(): return false
	if not person.anchor.is_empty(): return false
	if expedition.climb_rope(person): return true
	var edge := edge_for(person,direction)
	if edge.is_empty(): return false
	if not near_edge(person,edge):
		hud.message("A fenda é larga de mais. Q / E para procurar outro alinhamento." if edge_gap(edge)>=75 else "Aproxima-te da face do penedo.")
		return false
	person.face = edge.dir
	person.blocked_dir = edge.dir
	var rise: float = person.position.y-_landing(edge,false,person).y
	if edge.mode=="reunite" and (not people[1-selected].grounded or people[1-selected].shelf!=person.shelf):
		hud.message("O caminho continua do outro lado. Primeiro, segura a corda para trazer o companheiro.")
		return false
	if edge.mode in ["solo","reunite","bridge"] and rise<=Route.SOLO_REACH:
		if not _start_climb(person,edge,"climb"): return false
		var friend = people[1-selected]
		# Ordinary shelves stay fluid; a partner never solves a cooperative gate.
		if not edge.get("single",false) and friend.grounded and friend.shelf==edge.from and friend.anchor.is_empty():
			_start_climb(friend,edge,"climb",true)
		return true
	if edge.mode=="rope" and rope_ready():
		_start_climb(person,edge,"rope",false,2.15)
		return true
	match edge.mode:
		"boulder": hud.message("Falta um apoio. Salta para o outro lado da pedra e empurra-a até à parede.")
		"rock": hud.message("É demasiado alto. Um dá pé; lá em cima, a pedra solta pode criar um degrau.")
		"balance": hud.message("A laje mexe. Um segura o lado esquerdo enquanto o outro sobe.")
		"chimney": hud.message("A fenda pede os dois: aproxima o companheiro e usa Espaço.")
		"rope": hud.message("Um dá pé. Depois, lá em cima, é preciso segurar a corda.")
		_: hud.message("Sozinho não chega. Aproximem-se e usem Espaço para dar pé.")
	return false

func _landing(edge: Dictionary, companion := false, person = null) -> Vector2:
	var target: Dictionary = platforms[edge.to]
	var width := float(target.end)-float(target.x)
	var inset := 88.0 if companion else 36.0
	if width<160: inset = width*(0.70 if companion else 0.30)
	var x := float(target.x)+inset if edge.dir>0 else float(target.end)-inset
	return Vector2(x,surface_y(target,x,person))

func _start_climb(person, edge: Dictionary, action: String, companion := false, _duration := 1.05) -> bool:
	var target := _landing(edge,companion,person)
	var friend = people[1-person.kind]
	var surface: Dictionary = platforms[edge.to]
	if float(surface.end)-float(surface.x)<160 and friend.grounded and friend.shelf==edge.to and absf(target.x-friend.position.x)<30:
		target.x = clampf(friend.position.x+36,float(surface.x)+20,float(surface.end)-20)
		target.y = surface_y(surface,target.x,person)
	if not platforms[edge.to].enabled or not rope_allows(person,target,int(edge.to)):
		hud.message("A corda está esticada. Aproxima o companheiro antes de continuar.")
		return false
	var seconds: float = {"climb":0.34,"boost":0.90,"pull":0.85,"chimney":1.35,"rope":1.15}.get(action,0.40)
	var world_start: Vector3 = space.world_point(person)
	var world_target: Vector3 = space.point_for(person,target,int(edge.to))
	person.travel(target,int(edge.to),action,seconds+(0.10 if companion else 0.0))
	person.traversal["world_from"] = world_start
	person.traversal["world_to"] = world_target
	visited[str(edge.from)+":"+str(edge.to)] = true
	return true

func _support_ready(person, friend, edge: Dictionary) -> bool:
	return friend.grounded and not friend.busy() and friend.shelf==person.shelf and friend.anchor.is_empty() and near_edge(person,edge) and space.world_point(person).distance_to(space.world_point(friend))<155.0

func interact() -> void:
	if get_tree().paused or not dialogue_lines.is_empty() or rock_falling or space.rotating: return
	var person = people[selected]
	if person.busy(): return
	var friend = people[1-selected]
	if friend.hanging and friend.position.distance_to(person.position)<=Route.ROPE_LENGTH+1:
		pull_hanging(friend,person)
		return
	if not person.anchor.is_empty():
		release_anchor(person)
		return
	if expedition.enter_passage(person): return
	if expedition.hold_belay(person): return
	if space.prop_near(person,0,160,60):
		leave()
		return
	if person.shelf==4 and not flags.get("rock_step",false):
		if space.prop_near(person,4,511,100):
			rock_falling = true
			rock_time = 0
			person.pose = "support"
			hud.message("A pedra rola para a saliência de baixo. Agora há dois degraus.")
		else: hud.message("A pedra solta está junto à borda direita.")
		return
	if person.shelf==6 and space.prop_near(person,6,260,90) and not flags.get("balance_locked",false):
		person.anchor = "balance"
		platforms[Route.BALANCE_STEP].enabled = true
		hud.message("%s segura a laje. Tab para o outro subir pelo lado direito."%person.name)
		return
	if person.shelf==7 and not flags.get("balance_locked",false):
		if space.prop_near(person,7,750,95):
			flags.balance_locked = true
			platforms[Route.BALANCE_STEP].enabled = true
			for climber in people:
				if climber.anchor=="balance": climber.anchor = ""
			hud.message("A cunha prende a laje. O companheiro já pode largá-la e subir.")
		else: hud.message("Há uma cunha de pedra mais à direita. Pode prender a laje.")
		return
	if person.shelf==13 and friend.shelf<13:
		if space.prop_near(person,13,820,95):
			person.anchor = "rope"
			flags.rope_lowered = true
			hud.message("%s segura a corda. Tab para o companheiro; Cima para subir."%person.name,6)
		else: hud.message("Leva a corda ao anel de granito, mais à direita.")
		return
	# A hand can only reach a partner at the actual lip of a boost wall.
	for edge in links:
		if edge.to!=person.shelf or edge.from!=friend.shelf or edge.mode!="boost": continue
		var lip := _landing(edge,false,person).x
		if absf(person.position.x-lip)>100 or not near_edge(friend,edge,125):
			hud.message("Aproxima-te da borda para lhe estender a mão.")
			return
		person.pose = "support"
		person.anchor = "support"
		_start_climb(friend,edge,"pull",true,1.65)
		hud.message("%s estende a mão e puxa %s."%[person.name,friend.name])
		return
	var edge := edge_for(person)
	if edge.is_empty():
		if completed: _talk()
		return
	if not near_edge(person,edge):
		hud.message("Procura uma saliência ou aproxima-te do companheiro junto à parede.")
		return
	if edge.mode in ["boost","rock","rope"]:
		if not _support_ready(person,friend,edge):
			hud.message("Precisam de estar os dois junto à base deste penedo.")
			return
		var rise := float(platforms[edge.from].y)-float(platforms[edge.to].y)
		if rise>Route.BOOST_REACH: return
		friend.position.x = edge_x(person,edge.dir)-edge.dir*36
		friend.pose = "support"
		friend.anchor = "support"
		_start_climb(person,edge,"boost",false,1.8)
		hud.message("%s dá pé a %s. Falta encontrar uma passagem para os dois."%[friend.name,person.name])
	elif edge.mode=="chimney":
		if not _support_ready(person,friend,edge):
			hud.message("Juntem-se junto à fenda. Só conseguem subir apoiados um no outro.")
			return
		_start_climb(person,edge,"chimney",true,2.4)
		_start_climb(friend,edge,"chimney",false,2.4)
		person.face = -1
		friend.face = 1
		hud.message("Costas com costas, alternam os apoios e sobem os dois.")
	elif edge.mode=="balance":
		hud.message("Um fica sobre a laje, à esquerda. O outro usa o degrau que ela levanta.")
	else:
		attempt_climb(edge.dir)

func rope_ready() -> bool:
	return bool(flags.get("rope_secured",false)) or people.any(func(person): return person.anchor=="rope" and person.shelf==13)

func release_anchor(person) -> void:
	var previous: String = person.anchor
	person.anchor = ""
	if not person.traversing(): person.pose = "idle"
	if previous=="balance" and not flags.get("balance_locked",false):
		platforms[Route.BALANCE_STEP].enabled = false
		for climber in people:
			if climber.shelf==Route.BALANCE_STEP:
				motion.depart(climber)
		hud.message("A laje voltou a baixar. É preciso mantê-la segura até a prender lá em cima.")
	elif previous=="rope" and not flags.get("rope_secured",false):
		flags.rope_lowered = false
		hud.message("A corda fica recolhida. Segura-a de novo para ajudar o companheiro.")
	elif previous=="belay":
		var friend = people[1-person.kind]
		if friend.traversing() and friend.pose=="rope":
			friend.traversal.clear()
			motion.depart(friend)
			friend.hanging = true
			hud.message("O seguro foi largado. A corda ainda segura o companheiro; recupera o apoio antes de continuar.")

func descend() -> bool:
	if get_tree().paused or not dialogue_lines.is_empty() or space.rotating: return false
	var person = people[selected]
	person.jump_buffer = 0
	var passage: Dictionary = expedition.passage_for(person)
	if not passage.is_empty() and passage.reverse and expedition.near_passage(person,passage):
		return expedition.enter_passage(person)
	if not person.anchor.is_empty(): release_anchor(person)
	if person.traversing(): person.traversal.clear()
	if not person.grounded: return false
	for edge in links:
		if edge.to!=person.shelf or not platforms[edge.from].enabled: continue
		if not visited.has(str(edge.from)+":"+str(edge.to)): continue
		var target: Dictionary = platforms[edge.from]
		var x := float(target.end)-30 if edge.dir>0 else float(target.x)+30
		var point := Vector2(x,surface_y(target,x,person))
		if absf(person.position.x-x)<125 and rope_allows(person,point,int(edge.from)):
			var world_start: Vector3 = space.world_point(person)
			var world_target: Vector3 = space.point_for(person,point,int(edge.from))
			person.travel(point,edge.from,"descend",0.40)
			person.traversal["world_from"] = world_start
			person.traversal["world_to"] = world_target
			return true
	person.ignore_shelf = person.shelf
	person.ignore_time = 0.30
	motion.depart(person)
	person.position.y += 6
	person.velocity.y = 90
	return true

func _physics_process(delta: float) -> void:
	if get_tree().paused or not dialogue_lines.is_empty() or space.rotating: return
	clock += delta
	rope_taut = false
	motion.step_crumbles(delta)
	motion.step_boulders(delta)
	for person in people:
		if space.step_person(person,delta) and person.shelf>=0:
			person.position.y = surface_y(platforms[person.shelf],person.position.x,person)
			person.ground_slope = float(platforms[person.shelf].get("slope",0))
	var active = people[selected]
	var direction := Input.get_axis("walk_left","walk_right")
	for person in people:
		var axis := direction if person==active else 0.0
		# Walking across a low lateral step must not strand the companion on the
		# previous rock. Scout paths and cooperative high walls keep their rules.
		if person!=active and person.grounded and active.grounded and person.shelf!=active.shelf and person.anchor.is_empty():
			for edge in links:
				if edge.from!=person.shelf or edge.to!=active.shelf or edge.get("single",false) or not edge_viewable(edge): continue
				if edge.mode not in ["solo","bridge","reunite"]: continue
				if absf(float(platforms[edge.from].y)-float(platforms[edge.to].y))>90: continue
				if space.world_point(person).distance_to(space.world_point(active))<325: _start_climb(person,edge,"climb",true)
				break
		if person!=active and person.grounded and active.grounded and person.shelf==active.shelf and person.anchor.is_empty() and not active.traversing():
			var gap: float = active.position.x-person.position.x
			if absf(gap)>100: axis = signf(gap)*minf(1,absf(gap)/130)
		if person==active and absf(axis)>0.1 and not person.anchor.is_empty(): release_anchor(person)
		motion.advance(person,axis,delta)
		if person==active and person.jump_buffer>0 and not person.traversing(): _jump_or_climb(person)
	if rock_falling:
		rock_time += delta
		for climber in people:
			if climber.grounded and climber.shelf==3 and rock_time<0.85:
				_walk(climber,1.0,delta)
		if rock_time>=1.5:
			rock_falling = false
			flags.rock_step = true
			platforms[Route.ROCK_STEP].enabled = true
	if not people.any(func(person): return person.traversing()) and not rock_falling:
		for person in people:
			if person.pose=="support" and person.anchor in ["","support"]: person.pose = "idle"
			if person.anchor=="support": person.anchor = ""
	motion.constrain_rope()
	var checkpoint_y := float(platforms[checkpoint].y)
	if people.all(func(person): return not person.grounded and person.position.y>checkpoint_y+480) or people.any(func(person): return person.position.y>4770): recover_pair()
	_check_progress()
	space.sync_people()

func _walk(person, direction: float, delta: float) -> void:
	motion.walk(person,direction,delta)

func surface_y(platform: Dictionary, x: float, person = null) -> float:
	return Route.surface(platform,x) if space.boxes.is_empty() else space.surface_y(platform,x,person)

func rotate_world(direction: int) -> bool:
	return space.turn(direction)

func rope_allows(person, point: Vector2, target := -2) -> bool:
	return space.rope_allows(person,point,target)

func rope_separation() -> float:
	return space.rope_length()

func rope_points() -> PackedVector2Array:
	return space.rope_points()

func _jump_or_climb(person) -> void:
	if person.hanging:
		var friend = people[1-person.kind]
		if friend.grounded: pull_hanging(person,friend)
		person.jump_buffer = 0
		return
	if not person.grounded:
		if person.coyote>0: motion.jump(person)
		return
	person.jump_buffer = 0
	if not person.anchor.is_empty(): release_anchor(person)
	if expedition.enter_passage(person,false): return
	if expedition.climb_rope(person): return
	# A loose stone is a physical obstacle approached from either side.
	for stone in boulders:
		if person.shelf!=stone.parent or not platforms[stone.id].enabled: continue
		var side := int(signf(float(stone.x)-person.position.x))
		if side==int(person.face) and absf(person.position.x-float(stone.x))<float(stone.radius)+82:
			var edge := {"from":person.shelf,"to":stone.id,"dir":side,"mode":"solo"}
			if _start_climb(person,edge,"climb"):
				var friend = people[1-person.kind]
				if friend.grounded and friend.shelf==edge.from and friend.anchor.is_empty(): _start_climb(friend,edge,"climb",true)
			return
	var edge := edge_for(person)
	if not edge.is_empty() and near_edge(person,edge):
		if edge.mode in ["solo","reunite","bridge"] or (edge.mode=="rope" and rope_ready()):
			if attempt_climb(): return
	motion.jump(person)

func pull_hanging(person, friend) -> void:
	if not friend.grounded or person.traversing(): return
	var target: Dictionary = platforms[friend.shelf]
	var x := clampf(friend.position.x+(-50 if friend.position.x>640 else 50),float(target.x)+25,float(target.end)-25)
	var point := Vector2(x,surface_y(target,x,person))
	if not rope_allows(person,point,friend.shelf): return
	var world_start: Vector3 = space.world_point(person)
	var world_target: Vector3 = space.point_for(person,point,friend.shelf)
	person.travel(point,friend.shelf,"rope",0.95)
	person.traversal["world_from"] = world_start
	person.traversal["world_to"] = world_target
	friend.pose = "support"
	hud.message("A corda segurou a queda. O companheiro ajuda a recuperar o apoio.")

func recover_pair() -> void:
	recoveries += 1
	platforms[Route.BALANCE_STEP].enabled = bool(flags.get("balance_locked",false))
	for i in 2:
		var person = people[i]
		var box: Dictionary = space.boxes[checkpoint]
		var offset := (i*2-1)*45.0
		var world := Vector3((float(box.left)+float(box.right))*0.5+cos(space.angle)*offset,0,(float(box.back)+float(box.front))*0.5+sin(space.angle)*offset)
		world.y = space.surface_world(box,world.x,world.z)
		person.traversal.clear()
		person.anchor = ""
		person.grounded = true
		person.hanging = false
		person.shelf = checkpoint
		space.set_world(person,world)
		person.modulate = Color.WHITE
		person.velocity = Vector2.ZERO
		person.jump_buffer = 0
		person.pose = "idle"
	hud.message("Recuperaram o último apoio seguro. Atenção às pedras fissuradas.")

func _check_progress() -> void:
	for person in people:
		if not person.grounded or person.shelf<34: continue
		var key := "discovered_"+str(person.shelf)
		if not flags.get(key,false):
			flags[key] = true
			hud.message(platforms[person.shelf].title+" · Uma nova varanda à volta do penedo.",5)
	if people.all(func(person): return person.grounded and person.shelf==Route.SCOUT_TOP):
		for person in people:
			if person.anchor=="belay": person.anchor = ""
		flags.scout_reunited = true
	if people[0].grounded and people[1].grounded and people[0].shelf==13 and people[1].shelf==13:
		flags.rope_secured = true
		for person in people:
			if person.anchor=="rope": person.anchor = ""
	if people[0].grounded and people[1].grounded and people[0].shelf==people[1].shelf and people[0].shelf in [0,1,4,7,10,13,16,17,22,24,28,30,31,15]:
		if float(platforms[people[0].shelf].y)<float(platforms[checkpoint].y): checkpoint = people[0].shelf
	if not completed and people[0].grounded and people[1].grounded and people[0].shelf==Route.SUMMIT and people[1].shelf==Route.SUMMIT:
		completed = true
		hud.message("Penedo da Amizade. Chegaram os dois.",9)
		hud.reached_summit()

func camera_target() -> Vector2:
	if people.is_empty(): return Vector2(640,3950)
	var y: float = (people[0].position.y+people[1].position.y)*0.5
	var x: float = (people[0].position.x+people[1].position.x)*0.5
	return Vector2(x,clampf(y-150,1000,4480))

func _process(delta: float) -> void:
	if get_tree().paused: return
	space.step_turn(delta)
	# Keep both existing paintings legible when depth projects them onto one point.
	var dx: float = people[0].position.x-people[1].position.x
	if absf(dx)>2: overlap_order = signf(dx)
	var overlap := maxf(0,52-absf(dx))*0.5*clampf(1-absf(people[0].position.y-people[1].position.y)/90,0,1)
	for i in 2:
		var offset := Vector2(overlap*overlap_order*(1 if i==0 else -1),0)
		people[i].view_offset = people[i].view_offset.lerp(offset,1-exp(-14*delta))
	if completed: summit_reveal = minf(1,summit_reveal+delta*0.75)
	var separation: float = absf(people[0].position.y-people[1].position.y)
	var horizontal: float = absf(people[0].position.x-people[1].position.x)
	var zoom_value := clampf(minf(0.88,minf(470.0/(separation+165.0),1000.0/(horizontal+300))),0.58,0.88)
	camera.zoom = camera.zoom.lerp(Vector2.ONE*zoom_value,1-exp(-8*delta))
	camera.position = camera.position.lerp(camera_target(),1-exp(-8*delta))
	wall.update_view()
	perspective.update_view()
	scenery.queue_redraw()
	hud.queue_redraw()

func context_prompt() -> String:
	if not dialogue_lines.is_empty(): return ""
	if space.rotating: return "A rodar o penedo…"
	var person = people[selected]
	var friend = people[1-selected]
	if person.hanging: return "↑ · subir pela corda    Tab · trocar para o companheiro"
	if person.busy(): return ""
	if friend.hanging: return "Espaço · puxar o companheiro suspenso"
	if rope_taut: return "Corda esticada · aproxima o companheiro"
	for stone in boulders:
		if person.shelf==stone.parent and absf(person.position.x-float(stone.x))<float(stone.radius)+85:
			return "Andar contra a pedra · empurrar    ↑ · subir"
	if not person.anchor.is_empty(): return "Tab · trocar de personagem    Espaço · largar o apoio"
	var exploration_prompt: String = expedition.prompt(person)
	if not exploration_prompt.is_empty(): return exploration_prompt
	if space.prop_near(person,0,160,60): return "Espaço · regressar à floresta"
	if person.shelf==4 and not flags.get("rock_step",false) and space.prop_near(person,4,511,100): return "Espaço · soltar a pedra"
	if person.shelf==6 and space.prop_near(person,6,260,90) and not flags.get("balance_locked",false): return "Espaço · segurar a laje"
	if person.shelf==7 and not flags.get("balance_locked",false) and space.prop_near(person,7,750,95): return "Espaço · prender a laje com a cunha"
	if person.shelf==13 and friend.shelf<13 and space.prop_near(person,13,820,95): return "Espaço · segurar e baixar a corda"
	for edge in links:
		if edge.to==person.shelf and edge.from==friend.shelf and edge.mode=="boost": return "Espaço · puxar o companheiro da borda"
	var edge := edge_for(person)
	if edge.is_empty(): return "T · conversar" if completed else ""
	if edge_gap(edge)>=75: return "Q / E · rodar o penedo e procurar outro alinhamento"
	if not near_edge(person,edge): return ""
	if not edge_viewable(edge): return "Q / E · procurar o caminho na outra face do penedo"
	if edge.mode in ["solo","reunite","bridge"] or (edge.mode=="rope" and rope_ready()):
		return "↑ · escalar    ↓ · descer"
	if edge.mode=="chimney": return "Espaço · subir a fenda em conjunto"
	if edge.mode in ["boost","rock","rope"]: return "Espaço · pedir pé ao companheiro"
	return "T · pensar o caminho em conjunto"

func _hint_lines() -> Array:
	var person = people[selected]
	var exploration_hints: Array = expedition.hints(person)
	if not exploration_hints.is_empty(): return exploration_hints
	var stage := Route.stage(maxi(0,person.shelf))
	if person.shelf==5: return ["Saímos do túnel na outra encosta. Estas varandas estendem-se à volta da montanha.","De lado, vemos onde os penedos se tocam. Q ou E para encontrar o próximo apoio."]
	if person.shelf in [2,20] and not flags.get("push_step",false): return ["Precisamos daquela pedra junto à parede.","Cima para passar por cima dela. Depois empurra-a para a direita, andando contra ela."]
	if person.shelf in Route.FRAGILE: return ["Esta pedra está fissurada. Vai ceder se demorarmos.","Cima para saltar ou escalar. Continuamos os dois, antes que o apoio caia."]
	if completed: return ["Conseguimos. Olha a serra toda daqui.","Este penedo tem mesmo o nome certo."]
	match stage:
		3:
			if flags.get("rock_step",false): return ["A pedra ficou bem presa. Já tens um degrau para subir.","Troca para mim com Tab. Junto à rocha, usa Cima para escalar."]
			return ["Dá-me pé junto à parede. Lá de cima consigo soltar aquela pedra.","Ela fica na saliência de baixo e faz dois degraus. Depois sobes tu."]
		6:
			if flags.get("balance_locked",false): return ["A cunha já segura a laje.","Agora posso largar o apoio e seguir pelos mesmos degraus."]
			return ["Se um de nós ficar na ponta esquerda da laje, o outro lado levanta.","Usa Espaço à esquerda para segurar; Tab para trocar. Lá em cima, a cunha prende tudo."]
		9: return ["Esta fenda é estreita. Sozinhos escorregamos.","Se encostarmos as costas, fazemos força um contra o outro. Juntos, com Espaço."]
		12: return ["Dá-me pé. Depois levo a corda ao anel de granito, mais à direita.","Seguras a corda com Espaço; trocamos com Tab e eu subo com Cima."]
		_: return ["Este penedo é alto de mais para um só. Chega-te à base e eu dou-te pé.","Espaço para me ajudares. Depois, da borda de cima, puxo-te com Espaço. Nos pequenos, Cima escala; longe da parede, salta."]

func _talk() -> void:
	if get_tree().paused or any_busy(): return
	if dialogue_lines.is_empty():
		dialogue_lines = _hint_lines()
		dialogue_index = 0
		dialogue_initiator = selected
		for person in people: person.moving = false
	else:
		dialogue_index += 1
		if dialogue_index>=dialogue_lines.size():
			_end_talk()
			return
	dialogue_panel.show_line({"speaker":dialogue_initiator if dialogue_index%2==0 else 1-dialogue_initiator,"text":dialogue_lines[dialogue_index]},dialogue_initiator)

func _end_talk() -> void:
	dialogue_lines.clear()
	dialogue_panel.hide()

func restart() -> void:
	get_tree().paused = false
	_end_talk()
	flags.clear()
	visited.clear()
	platforms = Route.platforms()
	links = Route.links()
	boulders = Route.boulders()
	summit_reveal = 0
	recoveries = 0
	checkpoint = 0
	completed = false
	rock_falling = false
	for i in 2:
		var person = people[i]
		person.traversal.clear()
		person.anchor = ""
		person.pose = "idle"
		person.shelf = 0
		person.grounded = true
		person.velocity = Vector2.ZERO
		person.jump_buffer = 0
		person.hanging = false
		person.ignore_time = 0
		person.face = 1
		person.moving = false
		person.distance = 0
		person.view_offset = Vector2.ZERO
		person.modulate = Color.WHITE
		person.position = Vector2(370-i*95,Route.START_Y)
		person.blocked_dir = 0
	space.setup()
	perspective.rebuild()
	_select_person(0)
	camera.position = camera_target()
	camera.zoom = Vector2.ONE
	hud.arrival_time = 0
	hud.note_time = 0
	hud.refresh_pause()

func leave() -> void:
	get_tree().paused = false
	_end_talk()
	hud.refresh_pause()
	if return_requested.get_connections().is_empty():
		get_tree().change_scene_to_file("res://scenes/garden.tscn")
	else:
		return_requested.emit()
