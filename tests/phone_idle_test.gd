extends SceneTree

var failed := false
var scene: Node2D
var te: TejoPerson
var jo: TejoPerson

func _initialize() -> void:
	call_deferred("run_checks")
	create_timer(80.0, true, false, true).timeout.connect(func():
		push_error("Phone integration check timed out")
		quit(1))

func frames(count: int) -> void:
	for i in count:
		await physics_frame

func check(condition: bool, message: String) -> void:
	if not condition:
		failed = true
		push_error(message)
		quit(1)

func capture(filename: String) -> void:
	if DisplayServer.get_name() == "headless" or not "--capture-phone" in OS.get_cmdline_user_args():
		return
	# An occluded game window may not emit frame_post_draw. Explicitly render previews.
	RenderingServer.force_draw()
	check(root.get_texture().get_image().save_png("res://output/" + filename + ".png") == OK, "Could not save scene preview")

func run_checks() -> void:
	scene = load("res://scenes/side_trail.tscn").instantiate()
	root.add_child(scene)
	te = scene.people[0]
	jo = scene.people[1]
	await frames(60)
	check(te.is_on_floor() and jo.is_on_floor(), "Larger characters must stay grounded")
	check(absf(te.position.y - 554.0) < 1.0 and absf(jo.position.y - 554.0) < 1.0, "Feet must stay aligned with the trail")
	for region in JoPhoneArt.FRAMES:
		check(Rect2(Vector2.ZERO, JoPhoneArt.ATLAS.get_size()).encloses(region), "Phone pose extends outside the atlas")
	await capture("characters-scale-preview")
	print("Checking idle threshold...")
	await frames(300)
	check(jo.phone_state == TejoPerson.PhoneState.NONE, "Jo must wait at least five seconds before taking his phone out")
	await frames(165)
	check(jo.phone_state == TejoPerson.PhoneState.READING, "Jo should read his phone after seven quiet seconds and the pocket gesture")
	check(jo.phone_frame() >= 4, "Reading must use the downward-looking phone poses")
	await capture("jo-phone-scene-preview")
	print("Checking sustained reading and pause...")
	await frames(600)
	check(jo.phone_state == TejoPerson.PhoneState.READING, "Reading must continue until selection or Te's movement")
	scene._toggle_pause()
	var held_time := jo.phone_time
	await frames(30)
	check(jo.phone_time == held_time, "Pausing must freeze phone animation")
	scene._toggle_pause()
	scene._select_person(1)
	check(jo.phone_state == TejoPerson.PhoneState.PUTTING_AWAY, "Selecting Jo must immediately start putting the phone away")
	await frames(6)
	await capture("jo-phone-stowing-preview")
	await frames(24)
	check(jo.phone_state == TejoPerson.PhoneState.NONE, "Phone should be back in the pocket after the stow gesture")
	await frames(480)
	check(jo.phone_state == TejoPerson.PhoneState.NONE and jo.phone_idle_time == 0.0, "Selected Jo must never start using his phone")
	print("Checking Te movement and interrupted pocket gesture...")
	# A tiny move should cancel the phone even while Te is well inside the follow gap.
	scene._select_person(0)
	te.position.x = 700.0
	jo.position.x = 650.0
	te.velocity = Vector2.ZERO
	jo.velocity = Vector2.ZERO
	await frames(480)
	check(jo.phone_state == TejoPerson.PhoneState.READING, "Jo should start a fresh idle cycle after being deselected")
	Input.action_press("walk_right")
	await frames(2)
	check(absf(te.position.x - jo.position.x) < 89.0, "This check needs Te inside the companion's follow gap")
	check(jo.phone_state == TejoPerson.PhoneState.PUTTING_AWAY, "Te's first movement must cancel phone use immediately")
	var jo_before_follow := jo.position.x
	await frames(55)
	check(jo.phone_state == TejoPerson.PhoneState.NONE and jo.position.x > jo_before_follow + 20.0, "Jo must resume following after putting the phone away")
	Input.action_release("walk_right")
	await frames(40)
	check(jo.phone_state == TejoPerson.PhoneState.NONE, "Jo must finish stowing when Te stops again")
	check(jo.phone_idle_time < 1.0, "Cancellation must restart the full idle wait")
	# Put the timer just before its boundary to check pause and an interrupted pull.
	await frames(30)
	jo.phone_idle_time = TejoPerson.PHONE_IDLE_SECONDS - 0.01
	scene._toggle_pause()
	var idle_before_pause := jo.phone_idle_time
	await frames(30)
	check(jo.phone_state == TejoPerson.PhoneState.NONE and jo.phone_idle_time == idle_before_pause, "Pause must also freeze the initial wait")
	scene._toggle_pause()
	await frames(4)
	check(jo.phone_state == TejoPerson.PhoneState.TAKING_OUT, "The unpaused timer should begin the pocket gesture")
	scene._select_person(1)
	check(jo.phone_state == TejoPerson.PhoneState.PUTTING_AWAY, "Selecting Jo halfway through the pull must reverse it")
	Input.action_press("walk_left")
	var x_before := jo.position.x
	await frames(15)
	Input.action_release("walk_left")
	check(jo.phone_state == TejoPerson.PhoneState.NONE and jo.position.x < x_before - 10.0, "Movement must respond immediately when Jo is selected")
	Input.action_press("jump")
	await frames(5)
	Input.action_release("jump")
	check(jo.position.y < 535.0 and jo.phone_state == TejoPerson.PhoneState.NONE, "Jo's normal jump must work after interrupting the phone")
	await frames(75)
	check(jo.is_on_floor(), "Jo should land normally after the interrupted phone gesture")
	scene._select_person(0)
	await frames(30)
	Input.action_press("jump")
	await frames(5)
	Input.action_release("jump")
	check(te.position.y < 535.0, "The taller Te must still jump normally")
	await frames(75)
	check(te.is_on_floor(), "Te should land normally with the resized collision shape")
	if not failed:
		print("PASS: scale/ground alignment, real idle delay, indefinite phone reading, pause, selection, Te movement inside follow gap, fresh wait, interrupted pull and immediate movement/jump.")
	quit(1 if failed else 0)
