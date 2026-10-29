extends Node2D

const ForestWorld = preload("res://scripts/forest_world.gd")
const WORLD_WIDTH := ForestWorld.WORLD_WIDTH
var world: Node2D
var camera: Camera2D

const Foreground = preload("res://scripts/foreground.gd")
const HUD = preload("res://scripts/hud.gd")
const DialogueDirector = preload("res://scripts/dialogue_director.gd")
const DialoguePanel = preload("res://scripts/dialogue_panel.gd")
@export var scene_id := "sintra_trail"
@export var location_id := "serra_sintra"
# Place a Node2D in the dialogue_hotspot group, with metadata dialogue_id and radius,
# to add another point of interest without changing the dialogue controller.
var dialogue = DialogueDirector.new()
var dialogue_panel: Control
var people: Array[TejoPerson] = []
var selected := 0
var hud: Control

func _ready() -> void:
	_setup_input()
	world = ForestWorld.new()
	add_child(world)
	camera = Camera2D.new()
	camera.name = "TrailCamera"
	camera.position = Vector2(640, 360)
	camera.position_smoothing_enabled = false
	add_child(camera)
	camera.make_current()
	RenderingServer.set_default_clear_color(Color("263c36"))
	var ground := StaticBody2D.new()
	ground.name = "ForestTrailFloor"
	ground.collision_layer = 1
	ground.collision_mask = 2
	var collider := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(WORLD_WIDTH + 160,120)
	collider.shape = rectangle
	collider.position = Vector2(WORLD_WIDTH * 0.5,614)
	ground.add_child(collider)
	add_child(ground)
	for i in 2:
		var person := TejoPerson.new()
		person.name = "Te" if i == 0 else "Jo"
		person.kind = i
		person.walk_max_x = WORLD_WIDTH - 85.0
		person.process_mode = Node.PROCESS_MODE_PAUSABLE
		person.position = Vector2(625-i*100,554)
		people.append(person)
		add_child(person)
	people[0].partner = people[1]
	people[1].partner = people[0]
	var foreground := Foreground.new()
	foreground.world_width = WORLD_WIDTH
	foreground.process_mode = Node.PROCESS_MODE_PAUSABLE
	foreground.z_index = 20
	add_child(foreground)
	var layer := CanvasLayer.new()
	layer.layer = 5
	add_child(layer)
	hud = HUD.new()
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(hud)
	dialogue_panel = DialoguePanel.new()
	layer.add_child(dialogue_panel)
	dialogue_panel.advance_requested.connect(_talk)
	dialogue.line_changed.connect(dialogue_panel.show_line)
	dialogue.ended.connect(_end_dialogue)
	var bridge := Node2D.new()
	bridge.name = "LogBridgeConversation"
	bridge.position = Vector2(300, 554)
	bridge.set_meta("dialogue_id", "log_bridge")
	bridge.set_meta("radius", 110.0)
	bridge.add_to_group("dialogue_hotspot")
	add_child(bridge)
	_add_dialogue_hotspot("forest_stream", Vector2(1770, 554), 160.0)
	_add_dialogue_hotspot("old_fountain", Vector2(2230, 554), 145.0)
	_add_dialogue_hotspot("cork_oak", Vector2(3010, 554), 190.0)
	hud.person_selected.connect(_select_person)
	hud.pause_requested.connect(_toggle_pause)
	_select_person(0)
	process_mode = Node.PROCESS_MODE_ALWAYS

func _input(event: InputEvent) -> void:
	if event.is_echo():
		return
	if event.is_action_pressed("talk") and not get_tree().paused:
		_talk()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("pause") and dialogue.is_active() and not get_tree().paused:
		dialogue.cancel()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("pause"):
		_toggle_pause()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("swap") and not get_tree().paused:
		_select_person(1-selected)
		get_viewport().set_input_as_handled()

func _select_person(index: int) -> void:
	if get_tree().paused or dialogue.is_active():
		return
	selected = index
	for i in people.size():
		people[i].controlled = i == selected
	hud.select(index)

func _toggle_pause() -> void:
	get_tree().paused = not get_tree().paused
	hud.paused = get_tree().paused
	hud.queue_redraw()

func _setup_input() -> void:
	var bindings := {
		"walk_left": [KEY_A,KEY_LEFT],
		"walk_right": [KEY_D,KEY_RIGHT],
		"jump": [KEY_SPACE,KEY_W,KEY_UP],
		"swap": [KEY_TAB],
		"talk": [KEY_T],
		"pause": [KEY_ESCAPE],
	}
	for action in bindings:
		if not InputMap.has_action(action):
			InputMap.add_action(action,0.2)
		for key in bindings[action]:
			var event := InputEventKey.new()
			event.physical_keycode = key
			InputMap.action_add_event(action,event)
	for binding in [["walk_left",-1.0],["walk_right",1.0]]:
		var axis := InputEventJoypadMotion.new()
		axis.axis = JOY_AXIS_LEFT_X
		axis.axis_value = binding[1]
		InputMap.action_add_event(binding[0],axis)
	for binding in [["jump",JOY_BUTTON_A],["swap",JOY_BUTTON_RIGHT_SHOULDER],["pause",JOY_BUTTON_START]]:
		var button := InputEventJoypadButton.new()
		button.button_index = binding[1]
		InputMap.action_add_event(binding[0],button)

func dialogue_context() -> Dictionary:
	var nearby: Array[String] = []
	for hotspot in get_tree().get_nodes_in_group("dialogue_hotspot"):
		if hotspot is Node2D and people[selected].global_position.distance_to(hotspot.global_position) <= float(hotspot.get_meta("radius", 110.0)):
			nearby.append(str(hotspot.get_meta("dialogue_id", hotspot.name)))
	return {"scene": scene_id, "location": location_id, "initiator": selected, "near": nearby}

func _talk() -> void:
	if get_tree().paused:
		return
	if dialogue.is_active():
		dialogue.advance()
		return
	# Wait for a landing so conversation cannot suspend someone in mid-jump.
	if not people[0].is_on_floor() or not people[1].is_on_floor():
		return
	if dialogue.start(dialogue_context()):
		for person in people:
			person.in_dialogue = true
			person.velocity.x = 0.0
			person.moving = false
			person._finish_phone()
			person.face = signf(person.partner.position.x - person.position.x)
			if is_zero_approx(person.face):
				person.face = 1.0
		hud.dialogue_active = true
		hud.queue_redraw()

func _end_dialogue() -> void:
	dialogue_panel.hide()
	for person in people:
		person.in_dialogue = false
		person.phone_idle_time = 0.0
	hud.dialogue_active = false
	hud.queue_redraw()

func _add_dialogue_hotspot(id: String, at: Vector2, radius: float) -> void:
	var point := Node2D.new()
	point.name = id
	point.position = at
	point.set_meta("dialogue_id", id)
	point.set_meta("radius", radius)
	point.add_to_group("dialogue_hotspot")
	add_child(point)

func _process(delta: float) -> void:
	if get_tree().paused or people.is_empty():
		return
	var target_x := clampf(people[selected].position.x, 640.0, WORLD_WIDTH - 640.0)
	camera.position.x = lerpf(camera.position.x, target_x, 1.0 - exp(-5.0 * delta))
	world.update_parallax(camera.position.x)
	var x := people[selected].position.x
	var area := "Trilho dos eucaliptos"
	if x >= 2720:
		area = "Clareira do sobreiro"
	elif x >= 2050:
		area = "Fonte antiga"
	elif x >= 1450:
		area = "Ribeira dos fetos"
	if hud.area_title != area:
		hud.area_title = area
		hud.queue_redraw()
