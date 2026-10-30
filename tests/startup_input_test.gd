extends SceneTree
var scene: Node2D
var failed := false

class ErrorLog:
	extends Logger
	var errors: Array[String] = []
	func _log_error(_function: String, file: String, line: int, code: String, _rationale: String, _editor_notify: bool, _error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
		errors.append("%s:%d %s"%[file,line,code])

class EarlyInput:
	extends Node
	var injected := false
	func _ready() -> void:
		var garden := get_parent()
		assert(not garden.is_node_ready() and garden.exploration_map==null)
		# Reproduce input arriving while a child initializes, before the map exists.
		garden._input(InputEventMouseMotion.new())
		for key in [KEY_M,KEY_ESCAPE,KEY_TAB,KEY_T,KEY_SPACE]:
			var event := InputEventKey.new()
			event.physical_keycode = key
			event.pressed = true
			garden._input(event)
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

func run() -> void:
	var error_log := ErrorLog.new()
	OS.add_logger(error_log)
	scene = load("res://scenes/garden.tscn").instantiate()
	var early := EarlyInput.new()
	scene.add_child(early)
	root.add_child(scene)
	check(early.injected,"Startup input was not exercised")
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
	OS.remove_logger(error_log)
	check(error_log.errors.is_empty(),"Runtime errors during startup/input: "+str(error_log.errors))
	if not failed:
		print("PASS: input before map initialization is ignored; map, pause, selection and dialogue work after startup")
	quit(1 if failed else 0)
