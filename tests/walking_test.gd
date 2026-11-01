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

func press(key: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = key
	event.pressed = true
	root.push_input(event)
	event = event.duplicate()
	event.pressed = false
	root.push_input(event)

func screenshot(file: String) -> void:
	if DisplayServer.get_name()=="headless": return
	for i in 3: await process_frame
	RenderingServer.force_draw()
	root.get_texture().get_image().save_png(file)

func run() -> void:
	var errors := ErrorLog.new()
	OS.add_logger(errors)
	garden = load("res://scenes/garden.tscn").instantiate()
	root.add_child(garden)
	await frames(3)
	var original_positions := [garden.people[0].position,garden.people[1].position]
	garden.dialogue.flags["walking_test_sentinel"] = true
	garden.people[0].inventory.try_add(preload("res://scripts/item_art.gd").ITEMS[0])
	press(KEY_ESCAPE)
	check(paused and garden.walking_test_button.visible,"Escape must immediately expose the walking test option")
	await screenshot("res://output/walking-test-menu.png")
	garden.walking_test_button.pressed.emit()
	var test: Node2D = garden.walking_test_scene
	check(is_instance_valid(test) and test.visible and not paused,"Menu button must open and run the test scene")
	check(not garden.visible and garden.process_mode==Node.PROCESS_MODE_DISABLED,"The forest must suspend during walking tests")
	check(test.camera.is_current(),"Walking test must own the camera")
	check(test.world.get_child_count()==2 and test.world.get_node("Ground") is Sprite2D,"Test world must contain only ground and character layer")
	check(test.world.actors.get_child_count()==2,"Only Te and Jo belong on the ground")
	var minutes: float = garden.day_cycle.minutes
	var animal: Node2D = garden.world.wildlife.animals[0]
	var animal_position := animal.position
	var parked: Vector2 = test.people[1].position
	for direction in [Vector2.DOWN,Vector2(1,1),Vector2.RIGHT,Vector2(1,-1),Vector2.UP,Vector2(-1,-1),Vector2.LEFT,Vector2(-1,1)]:
		if direction.x!=0: Input.action_press("walk_right" if direction.x>0 else "walk_left")
		if direction.y!=0: Input.action_press("walk_down" if direction.y>0 else "walk_up")
		var before: Vector2 = test.people[0].position
		var walked: float = test.people[0].walked
		await frames(18)
		var delta: Vector2 = test.people[0].position-before
		check(delta.length()>20 and delta.normalized().dot(direction.normalized())>.95,"Actual character physics must walk in all eight directions")
		check(test.people[0].moving and test.people[0].walked>walked,"Movement must advance the real sprite gait")
		for action in ["walk_left","walk_right","walk_up","walk_down"]: Input.action_release(action)
		await frames(12)
	check(test.people[1].position==parked,"The unselected character must stay still for independent comparisons")
	press(KEY_TAB)
	check(test.selected==1 and test.people[1].controlled and not test.people[0].controlled,"Tab must switch control to Jo")
	await frames(2)
	Input.action_press("walk_right")
	await frames(18)
	check(test.people[1].position.x>parked.x+20,"Jo must use the same playable movement")
	Input.action_release("walk_right")
	await frames(12)
	await screenshot("res://output/walking-test-ground.png")
	press(KEY_ESCAPE)
	check(paused and test.pause_menu.visible,"Escape must open the test's own menu")
	var paused_position: Vector2 = test.people[1].position
	Input.action_press("walk_right")
	await frames(18)
	Input.action_release("walk_right")
	check(test.people[1].position==paused_position,"Characters must freeze while the test menu is open")
	test.reset_button.pressed.emit()
	check(not paused and not test.pause_menu.visible,"Reset must close the menu and resume the test")
	check(test.people[0].position==test.STARTS[0] and test.people[1].position==test.STARTS[1],"Reset must restore both characters")
	await frames(450)
	check(test.people[1].phone_state==0 and test.people[0].shoulder_state==0,"Idle phone/shoulder gestures must not interrupt sprite comparisons")
	check(garden.day_cycle.minutes==minutes and animal.position==animal_position,"Forest time and wildlife must remain frozen")
	check(garden.people[0].position==original_positions[0] and garden.people[1].position==original_positions[1],"Forest positions must remain intact")
	press(KEY_ESCAPE)
	test.return_button.pressed.emit()
	check(not paused and garden.visible and not test.visible and garden.camera.is_current(),"Returning must restore forest rendering and camera")
	check(garden.dialogue.flags.get("walking_test_sentinel",false) and garden.people[0].inventory.items.size()==1,"Returning must preserve game progress and inventory")
	await frames(4)
	check(garden.day_cycle.minutes>minutes,"The forest must resume after leaving the test")
	var inactive_position: Vector2 = test.people[0].position
	Input.action_press("walk_right")
	await frames(18)
	Input.action_release("walk_right")
	check(test.people[0].position==inactive_position,"Hidden test characters must not respond to forest input")
	press(KEY_ESCAPE)
	garden.walking_test_button.pressed.emit()
	check(garden.walking_test_scene==test and test.camera.is_current(),"Re-entry must reuse the test scene safely")
	Input.action_press("walk_right")
	await frames(18)
	Input.action_release("walk_right")
	check(test.people[1].position.x>test.STARTS[1].x+20,"Re-entry must resume paused world descendants")
	test.leave()
	garden.queue_free()
	await frames(3)
	check(not is_instance_valid(test),"Closing the game must free the extra test scene")
	OS.remove_logger(errors)
	check(errors.errors.is_empty(),"Walking test runtime errors: "+str(errors.errors))
	if not failed: print("PASS: Escape-menu ground-only test, real eight-way movement, selection, idle comparison, pause/reset, frozen forest, safe return/re-entry and cleanup")
	quit(1 if failed else 0)
