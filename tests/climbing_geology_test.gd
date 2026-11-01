extends SceneTree
const Geology = preload("res://scripts/climbing_geology.gd")
var scene: Node2D
var failed := false
var preview := false

class ErrorLog:
	extends Logger
	var errors: Array[String] = []
	func _log_error(_function: String, file: String, line: int, code: String, _rationale: String, _editor_notify: bool, _error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
		errors.append("%s:%d %s"%[file,line,code])

func _initialize() -> void:
	preview = "--preview" in OS.get_cmdline_user_args()
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failed = true
		push_error(message)

func frames(count: int) -> void:
	for i in count: await physics_frame

func capture(shelf: int, label: String) -> void:
	scene.restart()
	var box: Dictionary = scene.space.boxes[shelf]
	for i in 2:
		var person = scene.people[i]
		person.shelf = shelf
		person.anchor = "review"
		person.grounded = true
		var x := (float(box.left)+float(box.right))*0.5+35-i*70
		scene.space.set_world(person,Vector3(x,scene.space.surface_world(box,x),0))
	scene.checkpoint = shelf
	scene.hud.note_time = 0
	if shelf==17: scene.summit_reveal = 1
	for face in 4:
		if face>0:
			scene.rotate_world(1)
			for i in 45: await process_frame
		scene.camera.position = scene.camera_target()
		scene.perspective.update_view()
		await process_frame
		await process_frame
		RenderingServer.force_draw()
		root.get_texture().get_image().save_png("res://output/climbing-natural-"+label+"-"+str(face)+".png")

func run() -> void:
	var errors := ErrorLog.new()
	OS.add_logger(errors)
	scene = load("res://scenes/rock_climbing.tscn").instantiate()
	root.add_child(scene)
	await frames(3)
	var root_count := 0
	for p in scene.platforms:
		if p.get("boulder",false) or p.id in [18,19,29]: continue
		var support: MeshInstance3D
		for item in scene.perspective.supports:
			if item.get_meta("shelf")==p.id: support = item
		check(is_instance_valid(support),"Every lateral gallery must have a rooted buttress")
		var box: Dictionary = support.get_meta("base")
		var rings := Geology.ledge_rings(box,int(p.id),true)
		var buried := 0
		for point in rings[-1]:
			if Geology.inside_mountain(point): buried += 1
		check(buried>=rings[-1].size()*0.8,"Outcrop %d must intersect the actual mountain volume, including fragile supports"%p.id)
		var x_levels := {}
		var z_levels := {}
		for ring in rings:
			for point in ring:
				x_levels[roundi(point.x)] = true
				z_levels[roundi(point.z)] = true
		check(x_levels.size()>50 and z_levels.size()>40,"Each rock must have an irregular curved hull rather than a cuboid")
		root_count += 1
	check(root_count==33 and scene.perspective.supports.size()==33,"All 33 fixed main ledges and galleries need permanent roots into the mountain")
	check(scene.perspective.supports.filter(func(support): return support.get_meta("fragile")).size()==5,"The five falling plates must keep their permanent support")
	var mountain: MeshInstance3D = scene.perspective.root_3d.get_node("Mountain/ContinuousGranite")
	var vertices: PackedVector3Array = mountain.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = mountain.mesh.surface_get_arrays(0)[Mesh.ARRAY_NORMAL]
	check(vertices.size()>5000 and normals.size()==vertices.size(),"The continuous mountain needs a detailed hull and real surface normals")
	var pebble: Array = Geology.boulder_mesh(Vector3(100,100,100),1).surface_get_arrays(0)
	var outward := 0.0
	for i in pebble[Mesh.ARRAY_VERTEX].size():
		outward += pebble[Mesh.ARRAY_VERTEX][i].normalized().dot(pebble[Mesh.ARRAY_NORMAL][i])
	check(outward/pebble[Mesh.ARRAY_VERTEX].size()>0.85,"Rock normals must face outwards so solid stone cannot render as hollow or inside out")
	for y in [1500.0,2200.0,3000.0,3800.0,4500.0]:
		for face in 4:
			var a := face*PI/2
			var one := Geology.mountain_point(y,a)
			var other := Geology.mountain_point(y,a+PI)
			var center: float = scene.space.project((one+other)*0.5,a).x
			check(absf(center-640)<55,"The mountain must remain in the center from every face and height")
	# The loose puzzle props sit on the rock instead of straddling empty air.
	var loose: MeshInstance3D = scene.perspective.props.loose
	check(absf(-loose.position.y+34-scene.surface_y(scene.platforms[4],511))<0.1,"The loose stone must rest on ledge 4")
	var wedge: MeshInstance3D = scene.perspective.props.wedge
	check(absf(-wedge.position.y+21-scene.surface_y(scene.platforms[7],750))<0.1,"The wedge must rest on ledge 7")
	if preview:
		await capture(0,"base")
		await capture(4,"middle")
		await capture(10,"upper")
		await capture(17,"summit")
	OS.remove_logger(errors)
	check(errors.errors.is_empty(),"Geology runtime errors: "+str(errors.errors))
	scene.queue_free()
	await frames(2)
	if not failed: print("PASS: 33 physically rooted outcrops and lateral galleries, five permanent fragile supports, detailed central mountain in all views, irregular hulls and grounded props")
	quit(1 if failed else 0)
