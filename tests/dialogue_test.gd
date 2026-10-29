extends SceneTree
var scene: Node2D
var failed := false

func _initialize() -> void:
	call_deferred("run_checks")

func check(condition: bool, message: String) -> void:
	if not condition:
		failed = true
		push_error(message)

func frames(count: int) -> void:
	for i in count:
		await physics_frame

func talk() -> void:
	var event := InputEventAction.new()
	event.action = "talk"
	event.pressed = true
	scene._input(event)

func finish() -> void:
	while scene.dialogue.is_active():
		talk()

func run_checks() -> void:
	scene = load("res://scenes/side_trail.tscn").instantiate()
	root.add_child(scene)
	await frames(60)
	check(InputMap.action_has_event("talk", key_event()), "T must be bound to dialogue")
	# Remote characters cannot solve a point-of-interest conversation.
	talk()
	check(scene.dialogue.active_topic.id == "sintra_te", "Te should introduce the location topic away from the bridge")
	check(scene.dialogue_panel.cards[0].visible and not scene.dialogue_panel.cards[1].visible, "The initiator should appear on the left first")
	var start_position: Vector2 = scene.people[0].position
	Input.action_press("walk_right")
	Input.action_press("jump")
	await frames(30)
	Input.action_release("walk_right")
	Input.action_release("jump")
	check(scene.people[0].position == start_position, "Movement and jumping should stop during dialogue")
	scene._select_person(1)
	check(scene.selected == 0, "Selection must remain stable during dialogue")
	talk()
	check(scene.dialogue_panel.cards[1].visible and scene.dialogue_panel.speaker == 1, "The responding character belongs on the right")
	if DisplayServer.get_name() != "headless" and "--capture-dialogue" in OS.get_cmdline_user_args():
		await process_frame
		await process_frame
		RenderingServer.force_draw()
		check(root.get_texture().get_image().save_png("res://output/dialogue-preview.png") == OK, "Could not capture dialogue")
	scene._toggle_pause()
	var index: int = scene.dialogue.line_index
	talk()
	check(scene.dialogue.line_index == index, "Pause must also block dialogue advance")
	scene._toggle_pause()
	finish()
	check(not scene.people[0].in_dialogue and not scene.hud.dialogue_active, "Finishing restores movement and HUD")
	# Point of interest and selected character both matter.
	scene.people[0].position.x = 300
	scene.people[1].position.x = 240
	await frames(4)
	scene._select_person(1)
	talk()
	check(scene.dialogue.active_topic.id == "bridge_jo", "Jo must receive his own bridge topic")
	check(scene.dialogue_panel.initiator == 1 and scene.dialogue_panel.speaker == 1, "Jo must also be able to initiate on the left")
	finish()
	check(not scene.dialogue.flags.get("bridge_inspected", false), "Jo's hint must not solve Te's inspection")
	scene._select_person(0)
	talk()
	check(scene.dialogue.active_topic.id == "bridge_te", "Te can inspect the nearby bridge")
	var escape := InputEventAction.new()
	escape.action = "pause"
	escape.pressed = true
	scene._input(escape)
	check(not scene.dialogue.is_active() and not paused, "Escape closes dialogue without pausing")
	check(not scene.dialogue.flags.get("bridge_inspected", false), "Cancelling must never commit puzzle effects")
	talk()
	finish()
	check(scene.dialogue.flags.get("bridge_inspected", false), "Finishing the correct topic commits its puzzle flag")
	talk()
	check(scene.dialogue.active_topic.id == "bridge_after", "A solved point of interest must receive different dialogue")
	finish()
	# Scene and location filters, generic fallback and repeat rotation.
	scene.people[0].position.x = 700
	scene.people[1].position.x = 650
	await frames(4)
	talk()
	check(scene.dialogue.active_topic.id == "sintra_quiet", "Repeated location conversations should rotate")
	finish()
	scene.location_id = "other_place"
	scene.scene_id = "other_scene"
	talk()
	check(scene.dialogue.active_topic.id == "fallback", "Other locations must not inherit Sintra dialogue")
	finish()
	# Dialogue interrupts phone use and resets the quiet wait.
	scene.location_id = "serra_sintra"
	scene.scene_id = "sintra_trail"
	await frames(500)
	check(scene.people[1].phone_state == TejoPerson.PhoneState.READING, "Phone test needs Jo reading")
	talk()
	check(scene.people[1].phone_state == TejoPerson.PhoneState.NONE, "Jo must put his phone away to join the conversation")
	await frames(500)
	check(scene.people[1].phone_state == TejoPerson.PhoneState.NONE, "Jo must not use his phone while talking")
	finish()
	await frames(30)
	check(scene.people[1].phone_idle_time < 1, "The phone wait must start fresh after dialogue")
	if not failed:
		print("PASS: T input, portraits and sides, movement lock, pause, both initiators, proximity, character-specific puzzle, cancellation, completion effects, changed context, topic rotation, fallback and phone interaction.")
	quit(1 if failed else 0)

func key_event() -> InputEventKey:
	var event := InputEventKey.new()
	event.physical_keycode = KEY_T
	return event
