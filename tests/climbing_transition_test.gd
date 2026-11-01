extends SceneTree
var garden: Node2D
var failed := false

class ErrorLog:
	extends Logger
	var errors: Array[String] = []
	func _log_error(_function: String, file: String, line: int, code: String, _rationale: String, _editor_notify: bool, _error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
		errors.append("%s:%d %s"%[file,line,code])

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failed = true
		push_error(message)

func frames(count: int) -> void:
	for i in count: await physics_frame

func run() -> void:
	var errors := ErrorLog.new()
	OS.add_logger(errors)
	garden = load("res://scenes/garden.tscn").instantiate()
	root.add_child(garden)
	await frames(5)
	check(is_instance_valid(garden.climbing_sign),"The lookout must have a visible climbing entrance")
	check(garden.world.is_walkable(garden.climbing_sign.position,18),"The entrance sign must be reachable on free terrain")
	garden.dialogue.flags["climbing_transition_sentinel"] = true
	garden.people[0].inventory.try_add(preload("res://scripts/item_art.gd").ITEMS[0])
	var forest_position: Vector2 = garden.people[0].position
	var explored: Dictionary = garden.exploration_map.explored.duplicate()
	var animals: Array[Vector2] = []
	for animal in garden.world.wildlife.animals: animals.append(animal.position)
	garden._toggle_pause()
	garden.climbing_button.pressed.emit()
	var climbing: Node2D = garden.climbing_scene
	check(is_instance_valid(climbing) and climbing.visible and not paused,"The pause-menu entrance must open climbing and resume the tree")
	check(not garden.visible and garden.process_mode==Node.PROCESS_MODE_DISABLED,"The forest must suspend while climbing")
	var minutes: float = garden.day_cycle.minutes
	await frames(70)
	check(garden.people[0].position==forest_position and garden.day_cycle.minutes==minutes,"Forest positions and time must stay frozen")
	var wildlife_frozen := true
	for i in animals.size():
		if garden.world.wildlife.animals[i].position!=animals[i]: wildlife_frozen = false
	check(wildlife_frozen,"Animals with explicit process modes must also freeze")
	climbing.flags["transition_sentinel"] = true
	climbing.rotate_world(1)
	await frames(40)
	check(climbing.space.view==1,"The climb must be able to rotate before returning to the forest")
	var world_position: Vector3 = climbing.space.actors[0]
	var climb_position: Vector2 = climbing.people[0].position
	climbing.leave()
	await frames(2)
	check(garden.visible and not climbing.visible and garden.camera.is_current(),"Returning must restore the original forest and camera")
	check(garden.dialogue.flags.get("climbing_transition_sentinel",false) and garden.people[0].inventory.items.size()==1,"Dialogues and inventory must survive a scene visit")
	check(garden.exploration_map.explored==explored,"Discovered terrain must survive a scene visit")
	check(garden.people[0].position==forest_position,"Returning must not reset the forest position")
	await frames(65)
	check(garden.day_cycle.minutes>minutes,"The forest must resume after returning")
	garden.people[garden.selected].position = garden.climbing_sign.position+Vector2(0,35)
	garden._interact()
	check(garden.climbing_scene==climbing and climbing.flags.get("transition_sentinel",false) and climbing.people[0].position==climb_position,"Re-entry must resume the same climb")
	check(climbing.space.view==1 and climbing.space.actors[0].is_equal_approx(world_position),"Re-entry must preserve the face and the hidden world depth")
	climbing.leave()
	garden.queue_free()
	await frames(3)
	check(not is_instance_valid(climbing),"Closing the forest must clean up its suspended climbing scene")
	OS.remove_logger(errors)
	check(errors.errors.is_empty(),"Scene transition runtime errors: "+str(errors.errors))
	if not failed: print("PASS: lookout/menu entrance, frozen wildlife/time, preserved forest inventory/dialogues/map and persistent climbing re-entry")
	quit(1 if failed else 0)
