extends Node2D
## Shares the game's actual character physics and rendering, with an empty floor.
signal return_requested
const Person = preload("res://scripts/open_world_person.gd")
const Floor = preload("res://scripts/walking_test_floor.gd")
const STARTS := [Vector2(2320,1800),Vector2(2480,1800)]
var world: Node2D
var people: Array = []
var selected := 0
var camera: Camera2D
var pause_menu: Control
var continue_button: Button
var return_button: Button
var reset_button: Button
var selector_buttons: Array[Button] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_input()
	RenderingServer.set_default_clear_color(Color("304632"))
	world = Floor.new()
	world.name = "FloorOnlyWorld"
	add_child(world)
	for kind in 2:
		var person := Person.new()
		person.kind = kind
		person.name = "Te" if kind==0 else "Jo"
		person.world = world
		person.position = STARTS[kind]
		# No companion link: the other character stays put and has no idle gestures.
		people.append(person)
		world.actors.add_child(person)
	camera = Camera2D.new()
	camera.name = "WalkingTestCamera"
	camera.zoom = Vector2(1.6,1.6)
	add_child(camera)
	camera.make_current()
	_build_interface()
	_select_person(0)
	camera.position = _camera_target()

func _setup_input() -> void:
	var bindings := {"walk_left":[KEY_A,KEY_LEFT],"walk_right":[KEY_D,KEY_RIGHT],"walk_up":[KEY_W,KEY_UP],"walk_down":[KEY_S,KEY_DOWN],"sprint":[KEY_SHIFT],"swap":[KEY_TAB],"pause":[KEY_ESCAPE]}
	for action in bindings:
		if InputMap.has_action(action): continue
		InputMap.add_action(action,0.2)
		for key in bindings[action]:
			var event := InputEventKey.new()
			event.physical_keycode = key
			InputMap.action_add_event(action,event)

func _build_interface() -> void:
	var layer := CanvasLayer.new()
	layer.name = "TestInterface"
	layer.layer = 5
	add_child(layer)
	var info := Label.new()
	info.position = Vector2(24,18)
	info.text = "Teste de caminhada · só chão\nWASD / Setas: mover   ·   Shift: correr   ·   Tab: trocar   ·   Esc: menu"
	info.add_theme_font_size_override("font_size",18)
	info.add_theme_color_override("font_color",Color("2d483b"))
	info.add_theme_color_override("font_shadow_color",Color(0,0,0,0))
	info.add_theme_constant_override("shadow_offset_x",1)
	info.add_theme_constant_override("shadow_offset_y",2)
	layer.add_child(info)
	for kind in 2:
		var button := Button.new()
		button.position = Vector2(1030+kind*110,24)
		button.size = Vector2(96,42)
		button.text = "Te" if kind==0 else "Jo"
		button.toggle_mode = true
		button.add_theme_stylebox_override("normal",TejoPerson._box(Color("355b50"),8))
		button.add_theme_stylebox_override("pressed",TejoPerson._box(Color("f1e6c7"),8))
		button.add_theme_color_override("font_color",Color("fff4db"))
		button.add_theme_color_override("font_pressed_color",Color("355b50"))
		button.pressed.connect(func(): _select_person(kind))
		layer.add_child(button)
		selector_buttons.append(button)
	pause_menu = Control.new()
	pause_menu.name = "WalkingTestPauseMenu"
	pause_menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(pause_menu)
	var shade := ColorRect.new()
	shade.color = Color(0.12,0.23,0.20,0.65)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_menu.add_child(shade)
	var panel := Panel.new()
	panel.position = Vector2(415,205)
	panel.size = Vector2(450,310)
	panel.add_theme_stylebox_override("panel",TejoPerson._box(Color("f1e6c7"),18))
	pause_menu.add_child(panel)
	var title := Label.new()
	title.text = "Teste de caminhada"
	title.position = Vector2(0,24)
	title.size = Vector2(450,40)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size",26)
	title.add_theme_color_override("font_color",Color("355b50"))
	panel.add_child(title)
	for index in 3:
		var button := Button.new()
		button.text = ["Continuar teste","Repor posições","Voltar ao jogo"][index]
		button.position = Vector2(60,95+index*56)
		button.size = Vector2(330,42)
		button.add_theme_font_size_override("font_size",18)
		panel.add_child(button)
		match index:
			0:
				continue_button = button
				button.pressed.connect(_toggle_pause)
			1:
				reset_button = button
				button.pressed.connect(reset_positions)
			2:
				return_button = button
				button.pressed.connect(leave)
	pause_menu.hide()

func _input(event: InputEvent) -> void:
	if not is_node_ready() or event.is_echo(): return
	if event.is_action_pressed("pause"):
		_toggle_pause()
	elif event.is_action_pressed("swap") and not get_tree().paused:
		_select_person(1-selected)
	else:
		return
	get_viewport().set_input_as_handled()

func _toggle_pause() -> void:
	get_tree().paused = not get_tree().paused
	pause_menu.visible = get_tree().paused
	for button in selector_buttons: button.disabled = get_tree().paused
	if get_tree().paused: continue_button.grab_focus()

func _select_person(index: int) -> void:
	if get_tree().paused: return
	selected = index
	for kind in 2:
		people[kind].controlled = kind==selected
		people[kind].velocity = Vector2.ZERO
		selector_buttons[kind].set_pressed_no_signal(kind==selected)

func reset_positions() -> void:
	for kind in 2:
		var person = people[kind]
		person.position = STARTS[kind]
		person.velocity = Vector2.ZERO
		person.facing = Vector2.DOWN
		person.visual_facing = Vector2.DOWN
		person.moving = false
		person.turning = false
		person.walked = 0
		person.body.queue_redraw()
	camera.position = _camera_target()
	if get_tree().paused: _toggle_pause()

func _camera_target() -> Vector2:
	var half := get_viewport_rect().size/(camera.zoom*2)
	var target: Vector2 = people[selected].position-Vector2(0,Person.Art.HEIGHTS[selected]*.45)
	return target.clamp(half,Floor.WORLD_SIZE-half)

func _process(delta: float) -> void:
	if get_tree().paused or people.is_empty(): return
	camera.position = camera.position.lerp(_camera_target(),1-exp(-8*delta))

func leave() -> void:
	get_tree().paused = false
	pause_menu.hide()
	for button in selector_buttons: button.disabled = false
	for person in people: person.velocity = Vector2.ZERO
	if return_requested.get_connections().is_empty():
		get_tree().change_scene_to_file("res://scenes/garden.tscn")
	else:
		return_requested.emit()
