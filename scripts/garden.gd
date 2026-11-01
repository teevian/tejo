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
var day_cycle = preload("res://scripts/day_cycle.gd").new()
var daylight: ShaderMaterial
var climbing_scene: Node2D
var climbing_sign: Node2D
var climbing_button: Button
var walking_test_button: Button
var walking_test_scene: Node2D
var suspended_exploration: Array[Dictionary] = []

func _ready() -> void:
	_setup_input()
	RenderingServer.set_default_clear_color(Color("304632"))
	world = World.new()
	add_child(world)
	for i in 2:
		var person := Person.new()
		person.name = "Te" if i == 0 else "Jo"
		person.kind = i
		person.world = world
		person.position = Vector2(850-i*80,2890+i*30)
		people.append(person)
		world.actors.add_child(person)
	people[0].partner = people[1]
	people[1].partner = people[0]
	world.attach_people(people)
	world.wildlife.day_cycle = day_cycle
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
	hud.area_title = "Entrada da mata"
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
	var puppy_panel := preload("res://scripts/puppy_panel.gd").new()
	puppy_panel.world = world
	puppy_panel.scene = self
	layer.add_child(puppy_panel)
	_select_person(0)
	_setup_climbing_entrance()
	_setup_walking_test_entry()
	process_mode = Node.PROCESS_MODE_ALWAYS

func _toggle_debug_time() -> void:
	day_cycle.minutes = 1380.0 if world.wildlife.is_day() else 480.0
	world.wildlife.sync_debug_time()
	daylight.set_shader_parameter("daylight",day_cycle.light_color())
	day_cycle.phase_changed.emit(day_cycle.phase())
	day_cycle.time_changed.emit()
	hud._sync_debug_time_button()

func _input(event: InputEvent) -> void:
	# Child initialization can pump input before the map and HUD exist.
	if not is_node_ready() or event.is_echo():
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
	selected = index
	for i in people.size():
		people[i].controlled = i == selected
		people[i].path.clear()
		people[i].route_time = 0
	hud.select(index)
	if is_instance_valid(inventory_panel):
		inventory_panel.selected = index
		inventory_panel.refresh()
	_update_interaction_focus()

func _toggle_pause() -> void:
	get_tree().paused = not get_tree().paused
	hud.paused = get_tree().paused
	hud.queue_redraw()
	climbing_button.visible = get_tree().paused
	walking_test_button.visible = get_tree().paused

func _toggle_map() -> void:
	exploration_map.visible = not exploration_map.visible
	hud.map_open = exploration_map.visible
	exploration_map.selected = selected
	for person in people:
		person.in_dialogue = exploration_map.visible
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
		for person in people:
			person.cancel_shoulder()
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
	if people[0].seated and people[1].seated and people[0].seat_id==people[1].seat_id:
		point = (people[0].position+people[1].position)*0.5
	return (point-Vector2(0,Person.Art.HEIGHTS[selected]*0.52)).clamp(Vector2(640,360),WORLD_SIZE-Vector2(640,360))

func _process(delta: float) -> void:
	if is_instance_valid(climbing_button): climbing_button.visible = get_tree().paused
	if is_instance_valid(walking_test_button): walking_test_button.visible = get_tree().paused
	if get_tree().paused or people.is_empty() or exploration_map.visible:
		return
	day_cycle.advance(delta)
	world.wildlife.step(delta)
	world.puppy.step(delta)
	world.Discoveries.step(world,delta)
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

func _update_interaction_focus() -> void:
	if people.is_empty() or not is_instance_valid(hud):
		return
	var target: Dictionary = {} if dialogue.is_active() or exploration_map.visible else world.interactions.nearest(people[selected])
	world.interactions.highlight(target if not people[selected].is_busy() else {})
	if is_instance_valid(climbing_sign):
		climbing_sign.highlighted = not dialogue.is_active() and not exploration_map.visible and not people[selected].is_busy() and people[selected].position.distance_to(climbing_sign.position)<145
		if climbing_sign.highlighted: world.interactions.highlight({})
		climbing_sign.queue_redraw()
	hud.queue_redraw()

func _interact() -> void:
	if not is_node_ready() or get_tree().paused or dialogue.is_active() or exploration_map.visible:
		return
	if is_instance_valid(climbing_sign) and not people[selected].is_busy() and people[selected].position.distance_to(climbing_sign.position)<145:
		_enter_climbing()
		return
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
	climbing_sign = preload("res://scripts/climbing_trail_sign.gd").new()
	climbing_sign.name = "ClimbingTrailEntrance"
	# Place the entrance on free ground beside the existing granite lookout.
	climbing_sign.position = world.interactions.find_drop_position(Vector2(4180,650))
	if climbing_sign.position==Vector2.INF: climbing_sign.position = Vector2(4230,700)
	world.actors.add_child(climbing_sign)
	world.landmarks.append({"id":"climbing_approach","name":"Escalada · Penedo da Amizade","position":climbing_sign.position,"radius":220.0})
	climbing_button = Button.new()
	climbing_button.text = "Escalar o Penedo da Amizade"
	climbing_button.position = Vector2(490,410)
	climbing_button.size = Vector2(300,42)
	climbing_button.add_theme_font_size_override("font_size",17)
	climbing_button.add_theme_stylebox_override("normal",TejoPerson._box(Color("355b50"),8))
	climbing_button.add_theme_stylebox_override("hover",TejoPerson._box(Color("527461"),8))
	climbing_button.add_theme_color_override("font_color",Color("f2e6c7"))
	climbing_button.pressed.connect(_enter_climbing)
	hud.add_child(climbing_button)
	climbing_button.hide()

func _enter_climbing() -> void:
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
	walking_test_button.position = Vector2(490,466)
	walking_test_button.size = Vector2(300,42)
	walking_test_button.add_theme_font_size_override("font_size",17)
	walking_test_button.add_theme_stylebox_override("normal",TejoPerson._box(Color("355b50"),8))
	walking_test_button.add_theme_stylebox_override("hover",TejoPerson._box(Color("527461"),8))
	walking_test_button.add_theme_color_override("font_color",Color("f2e6c7"))
	walking_test_button.pressed.connect(_enter_walking_test)
	hud.add_child(walking_test_button)
	walking_test_button.hide()

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
	var bindings := {"walk_left":[KEY_A,KEY_LEFT],"walk_right":[KEY_D,KEY_RIGHT],"walk_up":[KEY_W,KEY_UP],"walk_down":[KEY_S,KEY_DOWN],"sprint":[KEY_SHIFT],"talk":[KEY_T],"map":[KEY_M],"swap":[KEY_TAB],"pause":[KEY_ESCAPE],"interact":[KEY_SPACE]}
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
	for binding in [["talk",JOY_BUTTON_A],["interact",JOY_BUTTON_X],["swap",JOY_BUTTON_RIGHT_SHOULDER],["sprint",JOY_BUTTON_B],["map",JOY_BUTTON_BACK],["pause",JOY_BUTTON_START]]:
		var event := InputEventJoypadButton.new()
		event.button_index = binding[1]
		InputMap.action_add_event(binding[0],event)
