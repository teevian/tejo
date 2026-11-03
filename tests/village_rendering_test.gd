extends SceneTree
var scene: Node2D
var failed := false
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		push_error(message)
func frame() -> Image:
	await process_frame
	await process_frame
	RenderingServer.force_draw()
	return root.get_texture().get_image()
func different(a: Image, b: Image, rect: Rect2i) -> int:
	var count := 0
	for x in range(rect.position.x,rect.end.x):
		for y in range(rect.position.y,rect.end.y):
			var delta := a.get_pixel(x,y)-b.get_pixel(x,y)
			if absf(delta.r)+absf(delta.g)+absf(delta.b)>.08: count += 1
	return count
func run() -> void:
	scene = load("res://scenes/sintra_village.tscn").instantiate()
	root.add_child(scene)
	await physics_frame
	scene.set_process(false)
	for person in scene.people: person.process_mode = Node.PROCESS_MODE_DISABLED
	scene.people[1].hide()
	scene.hud.get_parent().hide()
	var building: Node2D = scene.world.buildings.filter(func(b): return b.name=="Piriquita")[0]
	var person: Node2D = scene.people[0]
	scene.camera.position = building.position-Vector2(0,180)
	scene.day_cycle.minutes = 720
	scene.daylight.set_shader_parameter("daylight",scene.day_cycle.light_color())
	person.position = building.position-Vector2(0,140)
	person.hide()
	var empty := await frame()
	person.show()
	var behind := await frame()
	check(different(empty,behind,Rect2i(590,240,100,140))<10,"Opaque facade fully hides a character whose feet are behind it")
	person.position = building.position+Vector2(0,40)
	person.hide()
	empty = await frame()
	person.show()
	var front := await frame()
	check(different(empty,front,Rect2i(590,420,100,140))>400,"Character renders in front when the feet pass the facade")
	front.save_png("res://output/village-depth-day.png")
	scene.day_cycle.minutes = 1380
	scene.daylight.set_shader_parameter("daylight",scene.day_cycle.light_color())
	var night := await frame()
	night.save_png("res://output/village-depth-night.png")
	var day_luma := 0.0
	var night_luma := 0.0
	for x in range(100,1100,25):
		for y in range(100,650,25):
			day_luma += front.get_pixel(x,y).get_luminance()
			night_luma += night.get_pixel(x,y).get_luminance()
	check(night_luma<day_luma*.8,"Shared daylight shader grades both the village and people at night")
	scene.queue_free()
	await physics_frame
	if not failed: print("PASS: painted facade opacity, foot-depth ordering in both directions and shared day/night grade")
	quit(1 if failed else 0)
