extends SceneTree
## Real game actors; waiting periods shortened only in this disposable review.
var scene: Node2D
var count := 0
var output_dir := "/tmp/tejo-rest-sequence/preview"

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	if DisplayServer.get_name()=="headless": quit(1); return
	DirAccess.make_dir_recursive_absolute(output_dir)
	scene = load("res://scenes/garden.tscn").instantiate()
	root.add_child(scene)
	while not scene._initialization_complete: await process_frame
	scene.set_process(false)
	var spot := Vector2.ZERO
	for y in range(2900,3300,40):
		for x in range(650,1150,40):
			var at := Vector2(x,y)
			if scene._ground_rest_clear(at) and scene._ground_rest_clear(at+Vector2(132,0)):
				spot = at
				break
		if spot!=Vector2.ZERO: break
	if spot==Vector2.ZERO: quit(1); return
	for collection in [scene.world.props,scene.world.low_foliage,scene.world.scenery_props]:
		for prop in collection: prop.hide()
	scene.hud.hide()
	scene.inventory_panel.hide()
	scene.camera.position = spot+Vector2(66,-70)
	scene.camera.zoom = Vector2(2.5,2.5)
	scene._select_person(0)
	for person in scene.people:
		person.stand_up(true)
		person._finish_phone()
		person.position = spot+Vector2(person.kind*132,0)
		person.ground_seated = true
		person.ground_rest = true
		person.seat_id = "ground_rest"
		person.facing = Vector2.DOWN
		person.set_physics_process(false)
	var layer := CanvasLayer.new()
	root.add_child(layer)
	var label := Label.new()
	label.position = Vector2(36,30)
	label.add_theme_font_size_override("font_size",25)
	layer.add_child(label)
	var te = scene.people[0]
	var jo = scene.people[1]
	for frame in 360:
		match frame:
			0: label.text = "Sentados a observar o mundo"
			30: te.begin_reclining(); label.text = "Semi-repouso · cada um ao seu ritmo"
			45: jo.begin_reclining()
			100: te.begin_lying(); label.text = "Deitados, ainda de olhos abertos"
			115: jo.begin_lying()
			150: te.close_rest_eyes(); label.text = "Adormecem em momentos diferentes"
			165: jo.close_rest_eyes()
			185: te.request_pair_wake(); label.text = "Te acorda primeiro"
		if te.rest_transition=="stretch": label.text = "Espreguiça-se antes de chamar o Jo"
		if te.rest_transition=="call": label.text = "Chama o companheiro para acordar"
		if jo.rest_target=="partner_ready": label.text = "Jo acorda e senta-se"
		if te.rest_target=="standing": label.text = "Levantam-se os dois em conjunto"
		for person in scene.people: person._physics_process(1.0/30)
		if frame%3==0:
			await process_frame
			RenderingServer.force_draw()
			root.get_texture().get_image().save_png(output_dir+"/%03d.png"%count)
			count += 1
	print("PASS: real seated, staggered semi/flat rest, separate sleep and selected-first stretch/call/wake captured")
	quit()
