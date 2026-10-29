extends Node2D
const World = preload("res://scripts/sintra_open_world.gd")
const Person = preload("res://scripts/open_world_person.gd")
const HUD = preload("res://scripts/hud.gd")
const DialogueDirector = preload("res://scripts/dialogue_director.gd")
const DialoguePanel = preload("res://scripts/dialogue_panel.gd")
const ExplorationMap = preload("res://scripts/exploration_map.gd")
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
	camera = Camera2D.new()
	camera.name = "ExplorationCamera"
	camera.position = _camera_target()
	add_child(camera)
	camera.make_current()
	var layer := CanvasLayer.new()
	layer.layer = 5
	add_child(layer)
	hud = HUD.new()
	hud.open_world = true
	hud.area_title = "Entrada da mata"
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(hud)
	hud.person_selected.connect(_select_person)
	hud.pause_requested.connect(_toggle_pause)
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
	_select_person(0)
	process_mode = Node.PROCESS_MODE_ALWAYS

func _input(event: InputEvent) -> void:
	if event.is_echo():
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

func _toggle_pause() -> void:
	get_tree().paused = not get_tree().paused
	hud.paused = get_tree().paused
	hud.queue_redraw()

func _toggle_map() -> void:
	exploration_map.visible = not exploration_map.visible
	exploration_map.selected = selected
	for person in people:
		person.in_dialogue = exploration_map.visible
		person.velocity = Vector2.ZERO
	if exploration_map.visible:
		exploration_map.queue_redraw()

func dialogue_context() -> Dictionary:
	var nearby: Array[String] = []
	for place in world.landmarks:
		if people[selected].position.distance_to(place.position) < place.radius:
			nearby.append(place.id)
	return {"scene":scene_id,"location":location_id,"initiator":selected,"near":nearby}

func _talk() -> void:
	if get_tree().paused or exploration_map.visible:
		return
	if dialogue.is_active():
		dialogue.advance()
		return
	if dialogue.start(dialogue_context()):
		for person in people:
			person.in_dialogue = true
			person.velocity = Vector2.ZERO
			person.moving = false
			person._finish_phone()
			person.facing = person.position.direction_to(person.partner.position)
		hud.dialogue_active = true
		hud.queue_redraw()

func _end_dialogue() -> void:
	dialogue_panel.hide()
	for person in people:
		person.in_dialogue = false
		person.phone_idle_time = 0
	hud.dialogue_active = false
	hud.queue_redraw()

func _camera_target() -> Vector2:
	return (people[selected].position-Vector2(0,95)).clamp(Vector2(640,360),WORLD_SIZE-Vector2(640,360))

func _process(delta: float) -> void:
	if get_tree().paused or people.is_empty() or exploration_map.visible:
		return
	camera.position = camera.position.lerp(_camera_target(),1-exp(-5*delta))
	discovery_clock += delta
	if discovery_clock >= 0.2:
		discovery_clock = 0
		exploration_map.record_positions()
	var area: String = world.area_at(people[selected].position)
	if hud.area_title != area:
		hud.area_title = area
		hud.queue_redraw()

func _setup_input() -> void:
	var bindings := {"walk_left":[KEY_A,KEY_LEFT],"walk_right":[KEY_D,KEY_RIGHT],"walk_up":[KEY_W,KEY_UP],"walk_down":[KEY_S,KEY_DOWN],"sprint":[KEY_SHIFT],"talk":[KEY_T],"map":[KEY_M],"swap":[KEY_TAB],"pause":[KEY_ESCAPE]}
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
	for binding in [["talk",JOY_BUTTON_A],["swap",JOY_BUTTON_RIGHT_SHOULDER],["sprint",JOY_BUTTON_B],["map",JOY_BUTTON_BACK],["pause",JOY_BUTTON_START]]:
		var event := InputEventJoypadButton.new()
		event.button_index = binding[1]
		InputMap.action_add_event(binding[0],event)
