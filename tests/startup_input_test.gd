extends SceneTree
var scene: Node2D
var failed := false
var during_ready_stages := 0

class ErrorLog:
	extends Logger
	var errors: Array[String] = []
	func _log_error(_function: String, file: String, line: int, code: String, _rationale: String, _editor_notify: bool, _error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
		errors.append("%s:%d %s"%[file,line,code])

class EarlyInput:
	extends Node
	var injected := false
	var inject: Callable
	func _ready() -> void:
		assert(not get_parent().is_node_ready())
		inject.call()
		injected = true

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failed = true
		push_error(message)

func press(key: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = key
	event.pressed = true
	root.push_input(event)
	event = event.duplicate()
	event.pressed = false
	root.push_input(event)

func inject_startup_events() -> void:
	scene._input(InputEventMouseMotion.new())
	for key in [KEY_M,KEY_ESCAPE,KEY_TAB,KEY_T,KEY_SPACE,KEY_Q,KEY_E,KEY_UP]:
		var event := InputEventKey.new()
		event.physical_keycode = key
		event.pressed = true
		scene._input(event)
		press(key)
	var button := InputEventJoypadButton.new()
	button.button_index = JOY_BUTTON_START
	button.pressed = true
	scene._input(button)
	root.push_input(button)
	button = button.duplicate()
	button.pressed = false
	root.push_input(button)
	scene._process(1.0/60.0)
	if scene.has_method("_physics_process"):
		scene._physics_process(1.0/60.0)
	if scene.has_method("_interact"):
		scene._interact()
	check(not paused and scene.selected == 0,"Startup events must not pause or switch characters")

func inject_during_ready(node: Node) -> void:
	if node.get_parent() != scene or node is EarlyInput or not scene.is_node_ready():
		return
	# Dynamic children are added from inside _ready(), after the engine's ready
	# flag is set. The old is_node_ready() guard missed this entire interval.
	if during_ready_stages == 0:
		check(scene.camera == null and scene.people.is_empty(),"Must inject before scene dependencies exist")
		if scene.get_script() == preload("res://scripts/garden.gd"):
			check(scene.exploration_map == null,"Must reproduce input before the map exists")
	inject_startup_events()
	during_ready_stages += 1

func start_scene(path: String) -> void:
	scene = load(path).instantiate()
	var early := EarlyInput.new()
	early.inject = inject_startup_events
	scene.add_child(early)
	during_ready_stages = 0
	node_added.connect(inject_during_ready)
	root.add_child(scene)
	node_added.disconnect(inject_during_ready)
	check(early.injected,"Startup input was not exercised")
	check(during_ready_stages >= 3,"Input must be exercised throughout _ready(): " + path)
	check(scene.is_node_ready() and scene.people.size() == 2 and is_instance_valid(scene.camera),"Scene must finish initializing: " + path)

func run() -> void:
	var error_log := ErrorLog.new()
	OS.add_logger(error_log)
	start_scene("res://scenes/garden.tscn")
	check(scene.is_node_ready() and is_instance_valid(scene.exploration_map),"Scene must finish initializing")
	check(not paused and scene.selected==0 and not scene.dialogue.is_active() and not scene.exploration_map.visible,"Early input must leave the initial game state untouched")
	press(KEY_M)
	check(scene.exploration_map.visible,"M must open the map after startup")
	press(KEY_ESCAPE)
	check(not scene.exploration_map.visible and not paused,"Esc must close the map")
	press(KEY_ESCAPE)
	check(paused,"Esc must pause after startup")
	press(KEY_ESCAPE)
	check(not paused,"Esc must resume while paused")
	press(KEY_TAB)
	check(scene.selected==1,"Tab must switch characters after startup")
	press(KEY_T)
	check(scene.dialogue.is_active(),"T must start dialogue after startup")
	press(KEY_ESCAPE)
	check(not scene.dialogue.is_active(),"Esc must close dialogue after startup")
	scene.free()
	for path in ["res://scenes/rock_climbing.tscn","res://scenes/walking_test.tscn"]:
		start_scene(path)
		press(KEY_ESCAPE)
		check(paused,"Esc must pause after startup: " + path)
		press(KEY_ESCAPE)
		check(not paused,"Esc must resume after startup: " + path)
		press(KEY_TAB)
		check(scene.selected == 1,"Tab must switch characters after startup: " + path)
		scene.free()
	OS.remove_logger(error_log)
	check(error_log.errors.is_empty(),"Runtime errors during startup/input: "+str(error_log.errors))
	if not failed:
		print("PASS: input and updates before/during _ready() are ignored in all three scenes; map, pause, selection and dialogue work after startup")
	quit(1 if failed else 0)
