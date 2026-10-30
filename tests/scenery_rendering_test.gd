## Requires a graphics window. Compares actual composited pixels in both depth orders.
extends SceneTree
const Person = preload("res://scripts/open_world_person.gd")
var failed := false
var world: Node2D
var view: SubViewport
var sort_root: Node2D
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		push_error(message)
func snapshot() -> Image:
	await process_frame
	await process_frame
	RenderingServer.force_draw()
	return view.get_texture().get_image()
func exercise(label: String, visual: Node2D, partial := false) -> void:
	var scenery := Node2D.new()
	scenery.position = Vector2(520,800)
	scenery.add_child(visual)
	sort_root.add_child(scenery)
	var person := Person.new()
	person.world = world
	person.in_dialogue = true
	person.facing = Vector2.DOWN
	person.visual_facing = Vector2.DOWN
	sort_root.add_child(person)
	person.set_physics_process(false)
	var behind := -100.0 if label.ends_with("Lintel") or label.ends_with("Roof") else -30.0
	for offset in [behind,32.0]:
		person.position = scenery.position+Vector2(0,offset)
		scenery.visible = false
		var body_only := await snapshot()
		person.visible = false
		scenery.visible = true
		var object_only := await snapshot()
		person.visible = true
		var together := await snapshot()
		var overlaps := 0
		var correct := 0
		var compared := 0
		var exposed := 0
		for y in range(int(person.position.y)-150,int(person.position.y)-5):
			for x in range(455,585):
				var body: Color = body_only.get_pixel(x,y)
				if body.a<.99: continue
				var cover: Color = object_only.get_pixel(x,y)
				if cover.a<.01:
					exposed += 1
				if cover.a>=.99: overlaps += 1
				if offset<0 and cover.a<.99: continue
				compared += 1
				var expected: Color = cover if offset<0 else body
				var actual: Color = together.get_pixel(x,y)
				if Vector3(actual.r-expected.r,actual.g-expected.g,actual.b-expected.b).length()<.025: correct += 1
		if offset<0: check(overlaps>100,"Rendered body overlaps the real silhouette: "+label)
		check(compared>100 and correct>compared*.98,"Correct opaque depth order %s (%s)"%[label,"behind" if offset<0 else "front"])
		if partial and offset<0: check(exposed>1000 and overlaps>100,"Vegetation hides only part of the character")
	scenery.queue_free()
	person.queue_free()
	await process_frame

func check_expansion_alignment() -> void:
	var mirrors := {}
	for floor_node in world.get_children():
		if not floor_node is Sprite2D or floor_node.texture!=world.Expansion.FLOOR[1]: continue
		var mirror_key := Vector2i(int(floor_node.material.get_shader_parameter("mirror_x")),int(floor_node.material.get_shader_parameter("mirror_y")))
		if mirrors.has(mirror_key): continue
		var origin: Vector2 = floor_node.position+Vector2(44,44)
		var prefix := "Heath_%d_%d_"%[int(origin.x),int(origin.y)]
		var selected: Node2D
		for object in world.scenery_objects:
			if str(object.name).begins_with(prefix):
				selected = object
				break
		if selected==null: continue
		await check_ground_alignment(floor_node,selected,"mirrored floor "+str(mirror_key))
		mirrors[mirror_key] = true
	check(mirrors.size()==4,"All four ground mirror combinations have aligned scenery")
	for entry in [[world.TERRAIN[0],"Terrain0_EastStone"],[world.TERRAIN[3],"Terrain3_BridgeNorth"],[world.SOUTH,"Southern_CentralGranite"]]:
		for floor_node in world.get_children():
			if (floor_node is Sprite2D or floor_node is Polygon2D) and floor_node.texture==entry[0]:
				await check_ground_alignment(floor_node,world.actors.get_node(entry[1]),entry[1])
				break
	view.canvas_transform = Transform2D.IDENTITY

func check_ground_alignment(floor_node: Node2D, selected: Node2D, label: String) -> void:
	var floor_copy: Node2D = floor_node.duplicate()
	sort_root.add_child(floor_copy)
	view.canvas_transform = Transform2D(0,-selected.position+Vector2(520,500))
	var ground_only := await snapshot()
	var rock := Node2D.new()
	rock.position = selected.position
	var surface := Polygon2D.new()
	surface.polygon = selected.surface.polygon
	surface.uv = selected.surface.uv
	surface.texture = selected.surface.texture
	surface.material = selected.surface.material
	rock.add_child(surface)
	sort_root.add_child(rock)
	var layered := await snapshot()
	var compared := 0
	var matching := 0
	for y in range(340,580):
		for x in range(380,660):
			var source_point := Vector2(x-520,y-500)
			if not Geometry2D.is_point_in_polygon(source_point,surface.polygon): continue
			var a := ground_only.get_pixel(x,y)
			var b := layered.get_pixel(x,y)
			compared += 1
			if Vector3(a.r-b.r,a.g-b.g,a.b-b.b).length()<.035: matching += 1
	check(compared>200 and matching>compared*.98,"Depth cutout matches ground pixels: %s (%d/%d)"%[label,matching,compared])
	floor_copy.queue_free()
	rock.queue_free()
	await process_frame
func run() -> void:
	if DisplayServer.get_name()=="headless":
		push_error("Scenery rendering requires a graphics window")
		quit(1)
		return
	world = load("res://scripts/sintra_open_world.gd").new()
	root.add_child(world)
	world.visible = false
	world.process_mode = Node.PROCESS_MODE_DISABLED
	view = SubViewport.new()
	view.size = Vector2i(1040,1000)
	view.transparent_bg = true
	view.world_2d = World2D.new()
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(view)
	sort_root = Node2D.new()
	sort_root.y_sort_enabled = true
	view.add_child(sort_root)
	for name_value in ["Terrain2_UpperPair","SisterWest","YellowGranite","RelicOakWest","ChapelArchLintel","MongeEntranceLintel","CapuchosPorchRoof"]:
		var object: Node2D = world.actors.get_node(name_value)
		var surface := Polygon2D.new()
		surface.polygon = object.surface.polygon
		surface.uv = object.surface.uv
		surface.texture = object.surface.texture
		surface.material = object.surface.material
		await exercise(name_value,surface)
	var plant: Node2D = world.low_foliage[0]
	await exercise("Walk-through fern",plant.get_child(0).duplicate(),true)
	await check_expansion_alignment()
	if not failed: print("PASS: rendered occlusion behind rocks, trees, arches and porches; front ordering; partial fern cover; pixel alignment in all four mirrored floor orientations")
	quit(1 if failed else 0)
