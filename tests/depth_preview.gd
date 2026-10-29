extends SceneTree
var scene: Node2D
func _initialize() -> void:
	call_deferred("run")
func frames(n: int) -> void:
	for i in n:
		await physics_frame
func capture(name_value: String) -> void:
	await process_frame
	await process_frame
	RenderingServer.force_draw()
	root.get_texture().get_image().save_png("res://output/"+name_value+".png")
func place(a: Vector2,b: Vector2) -> void:
	scene.people[0].position = a
	scene.people[1].position = b
	for person in scene.people:
		person.in_dialogue = true
		person._finish_phone()
		person.facing = Vector2.UP
func run() -> void:
	scene = load("res://scenes/garden.tscn").instantiate()
	root.add_child(scene)
	await frames(25)
	await capture("characters-large-opaque")
	scene.set_process(false)
	var door: Vector2 = scene.world.ARCH_CENTER
	scene.camera.position = door-Vector2(0,80)
	scene.hud.area_title = "Ruínas da capela"
	scene.hud.queue_redraw()
	for item in [[Vector2(0,110),"arch-approach"],[Vector2(0,-10),"arch-underpass"],[Vector2(0,-105),"arch-behind"]]:
		place(door+item[0],door+Vector2(125,150))
		await frames(3)
		await capture(item[1])
	var plant: Node2D = scene.world.low_foliage[0]
	for candidate in scene.world.low_foliage:
		if candidate.position.x<900 or candidate.position.x>3900 or candidate.position.y<700 or candidate.position.y>2900:
			continue
		if absf(candidate.position.x-scene.world.river_x(candidate.position.y))<450:
			continue
		if not scene.world.is_walkable(candidate.position+Vector2(0,-15)) or not scene.world.is_walkable(candidate.position+Vector2(110,35)):
			continue
		var clear := true
		var actor_area := Rect2(candidate.position+Vector2(-50,-210),Vector2(210,270))
		for prop in scene.world.props:
			var crown := Rect2(prop.position+prop.sprite.position,prop.sprite.region_rect.size*prop.sprite.scale)
			if crown.intersects(actor_area):
				clear = false
		if clear:
			plant = candidate
			break
	place(plant.position+Vector2(0,-15),plant.position+Vector2(110,35))
	scene.people[0].facing = Vector2.DOWN
	scene.camera.position = (plant.position-Vector2(0,80)).clamp(Vector2(640,360),scene.WORLD_SIZE-Vector2(640,360))
	scene.hud.area_title = "Entre os fetos"
	scene.hud.queue_redraw()
	await frames(3)
	await capture("opaque-vegetation-depth")
	# Selection remains obvious with either avatar active.
	scene.people[0].in_dialogue = false
	scene.people[1].in_dialogue = false
	scene._select_person(1)
	for person in scene.people:
		person.in_dialogue = true
	await capture("avatar-jo-selected")
	quit()
