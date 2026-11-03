extends Node2D
const World = preload("res://scripts/sintra_open_world.gd")
const Person = preload("res://scripts/open_world_person.gd")
const HUD = preload("res://scripts/hud.gd")
const DialogueDirector = preload("res://scripts/dialogue_director.gd")
const DialoguePanel = preload("res://scripts/dialogue_panel.gd")
const ExplorationMap = preload("res://scripts/exploration_map.gd")
const InventoryPanel = preload("res://scripts/inventory_panel.gd")
const WORLD_SIZE := World.WORLD_SIZE
@export var scene_id := "sintra_trail"
@export var location_id := "serra_sintra"
@export_enum("forest", "village") var starting_region := "forest"
var region_id := "forest"
var region_worlds: Dictionary = {}
var region_states: Dictionary = {}
var region_signs: Dictionary = {}
var region_sign: Node2D
var puppy_panel: Control
var world: Node2D
var people: Array = []
var camera: Camera2D
var selected := 0
var hud: Control
var dialogue = DialogueDirector.new()
var dialogue_panel: Control
var exploration_map: Control
var discovery_clock := 0.0
var inventory_panel: Control
var interaction_clock := 0.0
var seated_posture_time := 0.0
var seated_pair_id := ""
var rest_sequence = preload("res://scripts/rest_sequence.gd").new()
var ground_idle_time := 0.0
var rest_retry_time := 0.0
var sleep_requested := false
var sleep_button: Button
var rest_dream: Node
var day_cycle = preload("res://scripts/day_cycle.gd").new()
var daylight: ShaderMaterial
var climbing_scene: Node2D
var climbing_sign: Node2D
var climbing_button: Button
var village_button: Button
var walking_test_button: Button
var walking_test_scene: Node2D
var suspended_exploration: Array[Dictionary] = []
var _initialization_complete := false

func _ready() -> void:
	_initialization_complete = false
	_setup_input()
	RenderingServer.set_default_clear_color(Color("304632"))
	region_id = starting_region
	world = _new_region_world(region_id)
	add_child(world)
	region_worlds[region_id] = world
	for i in 2:
		var person := Person.new()
		person.name = "Te" if i == 0 else "Jo"
		person.kind = i
		person.world = world
		person.position = Vector2(850-i*80,2890+i*30) if region_id=="forest" else world.menu_spawn+Vector2(-i*100,i*20)
		people.append(person)
		world.actors.add_child(person)
	people[0].partner = people[1]
	people[1].partner = people[0]
	world.attach_people(people)
	if is_instance_valid(world.wildlife): world.wildlife.day_cycle = day_cycle
	world.interactions.discovered.connect(_interaction_discovered)
	camera = Camera2D.new()
	camera.name = "ExplorationCamera"
	camera.position = _camera_target()
	add_child(camera)
	camera.make_current()
	# Grade the entire painted world, including custom shaders, below the UI.
	var light_layer := CanvasLayer.new()
	light_layer.layer = 3
	add_child(light_layer)
	var light_screen := ColorRect.new()
	light_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	light_screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	daylight = ShaderMaterial.new()
	daylight.shader = preload("res://shaders/day_light.gdshader")
	daylight.set_shader_parameter("daylight", day_cycle.light_color())
	light_screen.material = daylight
	light_layer.add_child(light_screen)
	var layer := CanvasLayer.new()
	layer.layer = 5
	add_child(layer)
	hud = HUD.new()
	hud.day_cycle = day_cycle
	day_cycle.time_changed.connect(hud.queue_redraw)
	hud.open_world = true
	hud.region_title = world.region_title
	hud.area_title = world.area_at(people[0].position)
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(hud)
	hud.person_selected.connect(_select_person)
	hud.debug_time_toggled.connect(_toggle_debug_time)
	dialogue_panel = DialoguePanel.new()
	layer.add_child(dialogue_panel)
	dialogue_panel.advance_requested.connect(_talk)
	dialogue.line_changed.connect(dialogue_panel.show_line)
	dialogue.ended.connect(_end_dialogue)
	exploration_map = ExplorationMap.new()
	exploration_map.world = world
	exploration_map.people = people
	layer.add_child(exploration_map)
	exploration_map.record_positions()
	inventory_panel = InventoryPanel.new()
	inventory_panel.people = people
	layer.add_child(inventory_panel)
	inventory_panel.drop_requested.connect(_drop_item)
	puppy_panel = preload("res://scripts/puppy_panel.gd").new()
	puppy_panel.world = world
	puppy_panel.scene = self
	layer.add_child(puppy_panel)
	_select_person(0)
	_setup_climbing_entrance()
	_setup_region_entrance()
	_setup_walking_test_entry()
	_setup_sleep_entry()
	_setup_village_entry()
	rest_dream = preload("res://scripts/rest_dream.gd").new()
	rest_dream.scene = self
	add_child(rest_dream)
	process_mode = Node.PROCESS_MODE_ALWAYS
	_initialization_complete = true

func _toggle_debug_time() -> void:
	day_cycle.minutes = 1380.0 if day_cycle.minutes>=360 and day_cycle.minutes<1200 else 480.0
	if is_instance_valid(world.wildlife): world.wildlife.sync_debug_time()
	daylight.set_shader_parameter("daylight",day_cycle.light_color())
	day_cycle.phase_changed.emit(day_cycle.phase())
	day_cycle.time_changed.emit()
	hud._sync_debug_time_button()

func _input(event: InputEvent) -> void:
	# Godot marks this node ready before _ready() returns. Rendering child nodes
	# can pump input while the world, map and HUD are still being constructed.
	if not _initialization_complete or event.is_echo():
		return
	if exploration_map.visible:
		if event.is_action_pressed("map") or event.is_action_pressed("pause"):
			_toggle_map()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("pause"):
		if dialogue.is_active() and not get_tree().paused:
			dialogue.cancel()
		else:
			_toggle_pause()
	elif event.is_action_pressed("talk") and not get_tree().paused:
		_talk()
	elif event.is_action_pressed("swap") and not get_tree().paused:
		_select_person(1-selected)
	elif event.is_action_pressed("map") and not get_tree().paused and not dialogue.is_active():
		_toggle_map()
	elif event.is_action_pressed("interact") and not get_tree().paused and not dialogue.is_active():
		_interact()
	else:
		return
	get_viewport().set_input_as_handled()

func _select_person(index: int) -> void:
	if get_tree().paused or dialogue.is_active() or (is_instance_valid(exploration_map) and exploration_map.visible):
		return
	if people.size()==2 and not people.any(func(person): return person.ground_rest):
		_reset_rest_wait()
	selected = index
	for i in people.size():
		if i!=index and people[i].is_juggling(): people[i].football_ball.juggling.stop()
		people[i].controlled = i == selected
		people[i].path.clear()
		people[i].route_time = 0
	hud.select(index)
	if is_instance_valid(inventory_panel):
		inventory_panel.selected = index
		inventory_panel.refresh()
	_update_interaction_focus()

func _toggle_pause() -> void:
	for person in people: person.run_input.reset()
	get_tree().paused = not get_tree().paused
	hud.paused = get_tree().paused
	hud.queue_redraw()
	climbing_button.visible = get_tree().paused and region_id=="forest"
	village_button.visible = get_tree().paused
	village_button.text = "Explorar a Vila de Sintra" if region_id=="forest" else "Regressar à Serra de Sintra"
	walking_test_button.visible = get_tree().paused
	sleep_button.visible = get_tree().paused

func _toggle_map() -> void:
	exploration_map.visible = not exploration_map.visible
	hud.map_open = exploration_map.visible
	exploration_map.selected = selected
	for person in people:
		person.in_dialogue = exploration_map.visible
		person.map_blocked = exploration_map.visible
		person.velocity = Vector2.ZERO
	if exploration_map.visible:
		exploration_map.queue_redraw()
	world.interactions.highlight({})
	inventory_panel.visible = not exploration_map.visible

func dialogue_context() -> Dictionary:
	var nearby: Array[String] = []
	for place in world.landmarks:
		if people[selected].position.distance_to(place.position) < place.radius:
			nearby.append(place.id)
	var puppy_mood := ""
	if is_instance_valid(world.puppy) and people[selected].position.distance_to(world.puppy.position)<420:
		nearby.append("capuchos_puppy")
		puppy_mood = preload("res://scripts/puppy_art.gd").expression(world.puppy)
		if puppy_mood=="angry": puppy_mood = "guard"
	return {"scene":scene_id,"location":location_id,"initiator":selected,"near":nearby,
		"hour":day_cycle.minutes / 60.0,"day":day_cycle.day,"day_phase":day_cycle.phase(),"puppy_mood":puppy_mood}

func _talk() -> void:
	if get_tree().paused or exploration_map.visible:
		return
	for person in people:
		if person.jumping:
			return
	if dialogue.is_active():
		dialogue.advance()
		return
	if dialogue.start(dialogue_context()):
		sleep_requested = false
		ground_idle_time = 0
		for person in people:
			if person.is_juggling(): person.football_ball.juggling.stop()
			person.cancel_sand_drawing()
			person.stand_up()
			person.in_dialogue = true
			person.velocity = Vector2.ZERO
			person.moving = false
			person._finish_phone()
			person.facing = person.position.direction_to(person.partner.position)
		hud.dialogue_active = true
		inventory_panel.hide()
		world.interactions.highlight({})
		hud.queue_redraw()

func _end_dialogue() -> void:
	dialogue_panel.hide()
	for person in people:
		person.in_dialogue = false
		person.phone_idle_time = 0
	hud.dialogue_active = false
	inventory_panel.show()
	hud.queue_redraw()

func _camera_target() -> Vector2:
	var point: Vector2 = people[selected].position
	if (people[0].seated or people[0].ground_seated) and (people[1].seated or people[1].ground_seated) and people[0].seat_id==people[1].seat_id:
		point = (people[0].position+people[1].position)*0.5
	return (point-Vector2(0,Person.Art.HEIGHTS[selected]*0.52)).clamp(Vector2(640,360),world.WORLD_SIZE-Vector2(640,360))

func _process(delta: float) -> void:
	if not _initialization_complete:
		return
	if is_instance_valid(climbing_button): climbing_button.visible = get_tree().paused and region_id=="forest"
	if is_instance_valid(walking_test_button): walking_test_button.visible = get_tree().paused
	if is_instance_valid(village_button):
		village_button.visible = get_tree().paused
		village_button.text = "Explorar a Vila de Sintra" if region_id=="forest" else "Regressar à Serra de Sintra"
		village_button.disabled = dialogue.is_active() or people.any(func(p): return p.jumping or p.collecting_time>0 or p.puppy_recoil_time>0)
	if is_instance_valid(sleep_button):
		sleep_button.visible = get_tree().paused
		sleep_button.disabled = dialogue.is_active() or people.any(func(person): return person.jumping or person.collecting_time>0 or person.puppy_recoil_time>0)
	if get_tree().paused or people.is_empty() or exploration_map.visible:
		return
	_update_ground_rest(delta)
	_advance_seated_posture(delta)
	day_cycle.advance(delta)
	world.step_environment(delta,day_cycle)
	daylight.set_shader_parameter("daylight", day_cycle.light_color())
	camera.position = camera.position.lerp(_camera_target(),1-exp(-5*delta))
	interaction_clock -= delta
	if interaction_clock<=0:
		interaction_clock = 0.12
		_update_interaction_focus()
	discovery_clock += delta
	if discovery_clock >= 0.2:
		discovery_clock = 0
		exploration_map.record_positions()
	var area: String = world.area_at(people[selected].position)
	if hud.area_title != area:
		hud.area_title = area
		hud.queue_redraw()

func _reset_rest_wait() -> void:
	ground_idle_time = 0
	rest_retry_time = 0
	rest_sequence.reset()
	for person in people:
		person.idle_delay = rest_sequence.companion_delay
		person.phone_idle_time = 0
		person.sand_idle_time = 0

func _update_ground_rest(delta: float) -> void:
	if get_tree().paused or exploration_map.visible: return
	if people.size()!=2 or dialogue.is_active():
		_reset_rest_wait()
		return
	var input := Input.get_vector("walk_left","walk_right","walk_up","walk_down")
	if people.any(func(p): return p.wake_leader or p.wake_waiting or (p.rest_target=="standing" and not p.ground_rest)):
		rest_sequence.advance(0,people,selected)
		ground_idle_time = 0
		return
	var manual_busy: bool = people.any(func(p): return p.jumping or p.seated or p.collecting_time>0 or p.puppy_recoil_time>0 or p.is_juggling() or not p.football_action.is_empty())
	if not input.is_zero_approx() or manual_busy or (is_instance_valid(world.puppy) and world.puppy.state=="pet"):
		if not input.is_zero_approx(): sleep_requested = false
		_reset_rest_wait()
		return
	if people[selected].moving and not people[selected].ground_rest:
		_reset_rest_wait()
		return
	ground_idle_time += delta
	for person in people: person.idle_delay = rest_sequence.companion_delay
	if not rest_sequence.advance(delta,people,selected,sleep_requested):
		if rest_sequence.stage=="sleep": sleep_requested = false
		return
	rest_retry_time -= delta
	if rest_retry_time>0: return
	rest_retry_time = 0.5
	# Prefer the existing independent places: a seated Te need not get up merely
	# to move a few pixels. Reserve enough space for the later supine silhouettes.
	var separation: Vector2 = people[1].position-people[0].position
	if separation.x>=128 and separation.x<=170 and absf(separation.y)<=30 and _ground_rest_clear(people[0].position) and _ground_rest_clear(people[1].position):
		for person in people: person.begin_ground_sitting(person.position,true)
		rest_sequence.stage = "approach"
		return
	# Keep the selected character nearby and let both approach clear resting spots.
	# Wide clearance protects the folded legs; never teleport or cross an obstacle.
	var anchor: Vector2 = people[0].position if people[0].sand_state==Person.SandState.DRAWING else people[selected].position-Vector2(132*selected,0)
	var centre: Vector2 = anchor+Vector2(66,0)
	var offsets: Array[Vector2] = [Vector2.ZERO,Vector2(0,55),Vector2(0,-55),Vector2(55,0),Vector2(-55,0)]
	# A stop near a trunk must retry genuinely different nearby clearings.
	var search_radius := 420 if sleep_requested else 180
	for y in range(-search_radius,search_radius+1,60):
		for x in range(-search_radius,search_radius+1,60): offsets.append(Vector2(x,y))
	offsets.sort_custom(func(a,b): return a.length_squared()<b.length_squared())
	for offset in offsets:
		var goals := [centre+offset-Vector2(66,0),centre+offset+Vector2(66,0)]
		var clear := true
		for kind in 2:
			if people[kind].position.distance_to(goals[kind])>(750 if sleep_requested else 210) or not _ground_rest_clear(goals[kind]) or (not sleep_requested and not world.can_walk_line(people[kind].position,goals[kind])) or world.find_path(people[kind].position,goals[kind]).is_empty():
				clear = false
				break
		if not clear:
			continue
		for kind in 2:
			people[kind].begin_ground_sitting(goals[kind],true)
		rest_sequence.stage = "approach"
		return
	if sleep_requested:
		sleep_requested = false
		ground_idle_time = 0
		hud.show_comment("Precisamos de um pouco mais de espaço livre para nos deitarmos.")

func _ground_rest_clear(at: Vector2) -> bool:
	if not world.allows_ground_rest(at): return false
	# Reserve the full length of a supine body before starting either ground pose.
	for depth in [0.0,-50.0,-100.0]:
		if not world.allows_ground_rest(at+Vector2(0,depth)) or not world.is_walkable(at+Vector2(0,depth),100):
			return false
	return true

func _advance_seated_posture(delta: float) -> void:
	if get_tree().paused:
		return
	if people.size()!=2 or not people[0].seated or not people[1].seated or people[0].seat_id!=people[1].seat_id:
		seated_posture_time = 0.0
		seated_pair_id = ""
		return
	if seated_pair_id!=people[0].seat_id:
		seated_pair_id = people[0].seat_id
		seated_posture_time = 0.0
	var art = Person.InteractionArt
	seated_posture_time = fposmod(seated_posture_time+delta,art.SEATED_POSE_SECONDS*art.SEATED_POSE_COUNT)
	var pose := int(seated_posture_time/art.SEATED_POSE_SECONDS)
	for person in people:
		if person.seated_pose!=pose:
			person.seated_pose = pose
			person.body.queue_redraw()
			person.queue_redraw()

func _update_interaction_focus() -> void:
	if people.is_empty() or not is_instance_valid(hud):
		return
	var target: Dictionary = {} if dialogue.is_active() or exploration_map.visible else world.interactions.nearest(people[selected])
	world.interactions.highlight(target if not people[selected].is_busy() else {})
	hud.interaction_prompt = world.interactions.prompt(people[selected],target)
	if region_id=="forest" and is_instance_valid(climbing_sign):
		climbing_sign.highlighted = not dialogue.is_active() and not exploration_map.visible and not people[selected].is_busy() and people[selected].position.distance_to(climbing_sign.position)<145
		if climbing_sign.highlighted: world.interactions.highlight({})
		climbing_sign.queue_redraw()
	if is_instance_valid(region_sign):
		region_sign.highlighted = not dialogue.is_active() and not exploration_map.visible and not people[selected].is_busy() and _near_region_exit()
		if region_sign.highlighted:
			world.interactions.highlight({})
			hud.interaction_prompt = "Descer à Vila de Sintra" if region_id=="forest" else "Continuar para a Serra de Sintra"
		region_sign.queue_redraw()
	hud.queue_redraw()

func _interact() -> void:
	if not _initialization_complete or get_tree().paused or dialogue.is_active() or exploration_map.visible:
		return
	if is_instance_valid(region_sign) and not people[selected].is_busy() and _near_region_exit():
		_travel_region("village" if region_id=="forest" else "forest")
		return
	if region_id=="forest" and is_instance_valid(climbing_sign) and not people[selected].is_busy() and people[selected].position.distance_to(climbing_sign.position)<145:
		_enter_climbing()
		return
	sleep_requested = false
	ground_idle_time = 0.0
	hud.show_comment(world.interactions.interact(people[selected]))
	_update_interaction_focus()

func _drop_item(owner: int, index: int) -> void:
	if owner!=selected or get_tree().paused or dialogue.is_active() or exploration_map.visible:
		return
	hud.show_comment(world.interactions.drop(people[owner],index))
	_update_interaction_focus()

func _interaction_discovered(flag: String) -> void:
	dialogue.flags[flag] = true
	dialogue.flag_changed.emit(flag,true)

func _setup_climbing_entrance() -> void:
	if region_id=="forest": _place_climbing_sign()
	climbing_button = Button.new()
	climbing_button.text = "Escalar o Penedo da Amizade"
	climbing_button.position = Vector2(490,466)
	climbing_button.size = Vector2(300,42)
	climbing_button.add_theme_font_size_override("font_size",17)
	climbing_button.add_theme_stylebox_override("normal",TejoPerson._box(Color("355b50"),8))
	climbing_button.add_theme_stylebox_override("hover",TejoPerson._box(Color("527461"),8))
	climbing_button.add_theme_color_override("font_color",Color("f2e6c7"))
	climbing_button.pressed.connect(_enter_climbing)
	hud.add_child(climbing_button)
	climbing_button.hide()

func _enter_climbing() -> void:
	if region_id!="forest": return
	if dialogue.is_active() or exploration_map.visible or people.any(func(person): return person.jumping): return
	get_tree().paused = false
	hud.paused = false
	climbing_button.hide()
	walking_test_button.hide()
	for person in people: person.velocity = Vector2.ZERO
	if not is_instance_valid(climbing_scene):
		climbing_scene = load("res://scenes/rock_climbing.tscn").instantiate()
		get_tree().root.add_child(climbing_scene)
		climbing_scene.return_requested.connect(_return_from_climbing)
	else:
		climbing_scene.show()
		climbing_scene.process_mode = Node.PROCESS_MODE_ALWAYS
		for child in climbing_scene.get_children():
			if child is CanvasLayer: child.show()
		climbing_scene.camera.make_current()
	_suspend_exploration()

func _suspend_exploration() -> void:
	rest_dream.stop_immediately(false)
	# Several forest children explicitly use PAUSABLE/ALWAYS, so suspending only
	# their parent would leave wildlife, comments or gestures running off-screen.
	suspended_exploration.clear()
	for node in find_children("*","",true,false):
		suspended_exploration.append({"node":node,"mode":node.process_mode})
		node.process_mode = Node.PROCESS_MODE_DISABLED
	hide()
	for child in get_children():
		if child is CanvasLayer: child.hide()
	process_mode = Node.PROCESS_MODE_DISABLED

func _return_from_climbing() -> void:
	climbing_scene.hide()
	climbing_scene.process_mode = Node.PROCESS_MODE_DISABLED
	for child in climbing_scene.get_children():
		if child is CanvasLayer: child.hide()
	_resume_exploration()

func _resume_exploration() -> void:
	show()
	for saved in suspended_exploration:
		if is_instance_valid(saved.node): saved.node.process_mode = saved.mode
	suspended_exploration.clear()
	for child in get_children():
		if child is CanvasLayer: child.show()
	process_mode = Node.PROCESS_MODE_ALWAYS
	camera.make_current()
	RenderingServer.set_default_clear_color(Color("304632"))

func _setup_walking_test_entry() -> void:
	walking_test_button = Button.new()
	walking_test_button.name = "WalkingTestButton"
	walking_test_button.text = "Testar caminhada · só chão"
	walking_test_button.position = Vector2(490,522)
	walking_test_button.size = Vector2(300,42)
	walking_test_button.add_theme_font_size_override("font_size",17)
	walking_test_button.add_theme_stylebox_override("normal",TejoPerson._box(Color("355b50"),8))
	walking_test_button.add_theme_stylebox_override("hover",TejoPerson._box(Color("527461"),8))
	walking_test_button.add_theme_color_override("font_color",Color("f2e6c7"))
	walking_test_button.pressed.connect(_enter_walking_test)
	hud.add_child(walking_test_button)
	walking_test_button.hide()

func _setup_sleep_entry() -> void:
	sleep_button = Button.new()
	sleep_button.name = "SleepButton"
	sleep_button.text = "Dormir"
	sleep_button.position = Vector2(490,410)
	sleep_button.size = Vector2(300,42)
	sleep_button.add_theme_font_size_override("font_size",17)
	sleep_button.add_theme_stylebox_override("normal",TejoPerson._box(Color("355b50"),8))
	sleep_button.add_theme_stylebox_override("hover",TejoPerson._box(Color("527461"),8))
	sleep_button.add_theme_color_override("font_color",Color("f2e6c7"))
	sleep_button.pressed.connect(_request_sleep)
	hud.add_child(sleep_button)
	sleep_button.hide()

func _request_sleep() -> void:
	if dialogue.is_active() or exploration_map.visible or people.any(func(person): return person.jumping or person.collecting_time>0 or person.puppy_recoil_time>0): return
	if get_tree().paused: _toggle_pause()
	for person in people:
		if person.is_juggling(): person.football_ball.juggling.stop()
		person.football_action = ""
		if person.seated: person.stand_up()
		person.velocity = Vector2.ZERO
		person.moving = false
		person.queued_jump.clear()
		person.run_input.reset()
	sleep_requested = true
	rest_retry_time = 0
	_update_ground_rest(0)

func _enter_walking_test() -> void:
	if dialogue.is_active() or exploration_map.visible or people.any(func(person): return person.jumping): return
	get_tree().paused = false
	hud.paused = false
	climbing_button.hide()
	walking_test_button.hide()
	for person in people: person.velocity = Vector2.ZERO
	if not is_instance_valid(walking_test_scene):
		walking_test_scene = load("res://scenes/walking_test.tscn").instantiate()
		get_tree().root.add_child(walking_test_scene)
		walking_test_scene.return_requested.connect(_return_from_walking_test)
	else:
		walking_test_scene.show()
		walking_test_scene.process_mode = Node.PROCESS_MODE_ALWAYS
		walking_test_scene.world.process_mode = Node.PROCESS_MODE_PAUSABLE
		for child in walking_test_scene.get_children():
			if child is CanvasLayer: child.show()
		walking_test_scene.camera.make_current()
	_suspend_exploration()

func _return_from_walking_test() -> void:
	walking_test_scene.hide()
	walking_test_scene.process_mode = Node.PROCESS_MODE_DISABLED
	walking_test_scene.world.process_mode = Node.PROCESS_MODE_DISABLED
	for child in walking_test_scene.get_children():
		if child is CanvasLayer: child.hide()
	_resume_exploration()

func _exit_tree() -> void:
	if is_instance_valid(climbing_scene): climbing_scene.queue_free()
	if is_instance_valid(walking_test_scene): walking_test_scene.queue_free()

func _setup_input() -> void:
	if InputMap.has_action("sprint"): InputMap.erase_action("sprint")
	var bindings := {"walk_left":[KEY_A,KEY_LEFT],"walk_right":[KEY_D,KEY_RIGHT],"walk_up":[KEY_W,KEY_UP],"walk_down":[KEY_S,KEY_DOWN],"talk":[KEY_T],"map":[KEY_M],"swap":[KEY_TAB],"pause":[KEY_ESCAPE],"interact":[KEY_SPACE]}
	for action in bindings:
		if not InputMap.has_action(action):
			InputMap.add_action(action,0.2)
		InputMap.action_erase_events(action)
		for key in bindings[action]:
			var event := InputEventKey.new()
			event.physical_keycode = key
			InputMap.action_add_event(action,event)
	for binding in [["walk_left",JOY_AXIS_LEFT_X,-1.0],["walk_right",JOY_AXIS_LEFT_X,1.0],["walk_up",JOY_AXIS_LEFT_Y,-1.0],["walk_down",JOY_AXIS_LEFT_Y,1.0]]:
		var event := InputEventJoypadMotion.new()
		event.axis = binding[1]
		event.axis_value = binding[2]
		InputMap.action_add_event(binding[0],event)
	for binding in [["talk",JOY_BUTTON_A],["interact",JOY_BUTTON_X],["swap",JOY_BUTTON_RIGHT_SHOULDER],["map",JOY_BUTTON_BACK],["pause",JOY_BUTTON_START]]:
		var event := InputEventJoypadButton.new()
		event.button_index = binding[1]
		InputMap.action_add_event(binding[0],event)

func _new_region_world(id: String) -> Node2D:
	return World.new() if id=="forest" else load("res://scripts/sintra_village.gd").new()

func _place_climbing_sign() -> void:
	if is_instance_valid(climbing_sign): return
	climbing_sign = preload("res://scripts/climbing_trail_sign.gd").new()
	climbing_sign.name = "ClimbingTrailEntrance"
	climbing_sign.position = world.interactions.find_drop_position(Vector2(4180,650))
	if climbing_sign.position==Vector2.INF: climbing_sign.position = Vector2(4230,700)
	world.actors.add_child(climbing_sign)
	world.landmarks.append({"id":"climbing_approach","name":"Escalada · Penedo da Amizade","position":climbing_sign.position,"radius":220.0})

func _setup_region_entrance() -> void:
	if region_signs.has(region_id):
		region_sign = region_signs[region_id]
		return
	region_sign = preload("res://scripts/region_trail_sign.gd").new()
	region_sign.name = "VillageAccess" if region_id=="forest" else "ForestAccess"
	region_sign.to_village = region_id=="forest"
	var preferred: Vector2 = Vector2(840,3320) if region_id=="forest" else world.forest_access
	region_sign.position = world.interactions.find_drop_position(preferred)
	world.actors.add_child(region_sign)
	region_signs[region_id] = region_sign
	world.landmarks.append({"id":"village_access" if region_id=="forest" else "forest_access","name":"Caminho da Vila de Sintra" if region_id=="forest" else "Acesso à Serra de Sintra","position":region_sign.position,"radius":220.0})

func _travel_region(destination: String, from_menu := false) -> bool:
	if destination==region_id or destination not in ["forest","village"]: return false
	if get_tree().paused or dialogue.is_active() or exploration_map.visible or people.any(func(p): return p.is_busy()): return false
	# Keep the actual world instances, their encounters and pickups. The two people,
	# their bags, the director and the single clock stay owned by this controller.
	rest_dream.stop_immediately(false)
	var source_id := region_id
	var source_world := world
	var safe: Array[Vector2] = []
	for i in 2:
		var point: Vector2 = source_world.interactions.find_drop_position(people[i].position if from_menu else region_sign.position+Vector2(-55+i*110,70))
		if point==Vector2.INF: return false
		safe.append(point)
	region_states[source_id] = {"explored":exploration_map.explored,"discovered":exploration_map.discovered,"positions":safe,"modes":[]}
	if not region_worlds.has(destination):
		var next := _new_region_world(destination)
		add_child(next)
		region_worlds[destination] = next
		next.interactions.discovered.connect(_interaction_discovered)
	world = region_worlds[destination]
	region_id = destination
	if region_states.has(destination):
		for saved in region_states[destination].modes:
			if is_instance_valid(saved.node): saved.node.process_mode = saved.mode
	world.show()
	world.attach_people(people)
	_setup_region_entrance()
	if region_id=="forest": _place_climbing_sign()
	for i in 2:
		var person: CharacterBody2D = people[i]
		person.stand_up(true)
		person._finish_phone()
		person.run_input.reset()
		person.queued_jump.clear()
		person.velocity = Vector2.ZERO
		person.moving = false
		person.world = world
		person.reparent(world.actors)
		var preferred: Vector2 = world.menu_spawn+Vector2(-i*100,i*20) if from_menu and destination=="village" else region_sign.position+Vector2(-55+i*110,-80)
		person.position = region_states[destination].positions[i] if region_states.has(destination) else world.interactions.find_drop_position(preferred)
		person.path.clear()
		person.route_time = 0
		person.facing = Vector2.UP
	# CollisionObject2D's default DISABLE_MODE_REMOVE also removes inactive bases
	# from the shared physics space; explicit child process modes must be suspended.
	var modes: Array = region_states[source_id].modes
	for node in [source_world]+source_world.find_children("*","",true,false):
		modes.append({"node":node,"mode":node.process_mode})
		node.process_mode = Node.PROCESS_MODE_DISABLED
	source_world.hide()
	exploration_map.world = world
	exploration_map.explored = region_states[destination].explored if region_states.has(destination) else {}
	exploration_map.discovered = region_states[destination].discovered if region_states.has(destination) else {}
	exploration_map.record_positions()
	puppy_panel.world = world
	scene_id = "sintra_trail" if region_id=="forest" else "sintra_village"
	location_id = "serra_sintra" if region_id=="forest" else "vila_sintra"
	hud.region_title = world.region_title
	hud.area_title = world.area_at(people[selected].position)
	hud.comment_time = 0
	_reset_rest_wait()
	camera.position = _camera_target()
	_update_interaction_focus()
	return true

func _near_region_exit() -> bool:
	if people[selected].position.distance_to(region_sign.position)>=160: return false
	var target: Dictionary = world.interactions.nearest(people[selected])
	return target.is_empty() or target.kind!="pickup" or people[selected].position.distance_to(target.position)>70

func _setup_village_entry() -> void:
	village_button = Button.new()
	village_button.name = "VillageButton"
	village_button.text = "Explorar a Vila de Sintra"
	village_button.position = Vector2(490,578)
	village_button.size = Vector2(300,42)
	village_button.add_theme_font_size_override("font_size",17)
	village_button.add_theme_stylebox_override("normal",TejoPerson._box(Color("355b50"),8))
	village_button.add_theme_stylebox_override("hover",TejoPerson._box(Color("527461"),8))
	village_button.add_theme_color_override("font_color",Color("f2e6c7"))
	village_button.pressed.connect(_travel_from_menu)
	hud.add_child(village_button)
	village_button.hide()

func _travel_from_menu() -> void:
	if dialogue.is_active() or exploration_map.visible or people.any(func(p): return p.jumping or p.collecting_time>0 or p.puppy_recoil_time>0): return
	for person in people:
		if person.is_juggling(): person.football_ball.juggling.stop()
		person.football_action = ""
		person.stand_up(true)
		person.cancel_sand_drawing(false)
	sleep_requested = false
	if get_tree().paused: _toggle_pause()
	_travel_region("village" if region_id=="forest" else "forest",true)
