extends SceneTree
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
		var frame := root.get_texture().get_image()
		var canopy: Image = scene.perspective.core_plane.texture.get_image()
		var green := 0
		var canopy_green := 0
		for y in range(170,615,3):
			for x in range(40,1240,3):
				var pixel := frame.get_pixel(x,y)
				if pixel.g>pixel.r*1.12 and pixel.g>pixel.b*1.12: green += 1
				var leaf := canopy.get_pixel(x,y)
				if leaf.a>0.8 and leaf.g>leaf.r*1.12 and leaf.g>leaf.b*1.12: canopy_green += 1
		check(green>180,"The photographed woodland must actually be visible in view %d at %s; green pixels %d"%[face,label,green])
		check(canopy_green>180,"World-space vegetation must render independently of the distant backdrop")
		frame.save_png("res://output/climbing-sintra-"+label+"-"+str(face)+".png")

func run() -> void:
	var errors := ErrorLog.new()
	OS.add_logger(errors)
	scene = load("res://scenes/rock_climbing.tscn").instantiate()
	root.add_child(scene)
	for i in 120:
		await physics_frame
		if scene.perspective.habitat.ready_for_review: break
	var habitat: Node3D = scene.perspective.habitat
	check(habitat.ready_for_review,"The botanical habitat must finish attaching to the actual rock surfaces")
	check(habitat.plants.size()==164,"The mountain must have all 164 rooted pines, shrubs, heath and trailing ivy")
	check(habitat.colliders.size()==31,"Roots must be sampled against the mountain, its 27 crags and the three broad gallery buttresses")
	var atlas: Image = habitat.atlas.get_image()
	check(atlas.get_pixel(0,0).a<0.01 and atlas.get_pixel(atlas.get_width()-1,0).a<0.01,"Botanical cutouts need real transparency")
	var counts := [0,0,0,0]
	var positions: Array[Vector3] = []
	for entry in habitat.roots:
		counts[entry.kind] += 1
		check(entry.root.distance_to(entry.contact)<10,"A botanical root must touch the sampled mountain surface")
		check(entry.node.layers==2,"Woodland must leave the characters and climbable lips visible")
		positions.append(entry.node.position)
	check(counts[0]==14 and counts[1]>40 and counts[2]>20 and counts[3]>30,"The habitat needs trees and several vegetation types, rather than one repeated shrub")
	var root_count: int = habitat.roots.size()
	scene.rotate_world(1)
	await frames(40)
	for i in habitat.roots.size():
		check(habitat.roots[i].node.position.is_equal_approx(positions[i]),"Rotating must preserve each plant's real 3D location")
	scene.restart()
	check(scene.perspective.habitat==habitat and habitat.roots.size()==root_count,"Restart must preserve the one habitat without duplicating it")
	if preview:
		await capture(0,"base")
		await capture(4,"middle")
		await capture(10,"upper")
		await capture(17,"summit")
	OS.remove_logger(errors)
	check(errors.errors.is_empty(),"Habitat runtime errors: "+str(errors.errors))
	scene.queue_free()
	await frames(3)
	if not failed: print("PASS: 164 rooted Sintra plants, photographic alpha cutouts, real rock contacts, four-view visibility and persistent world positions")
	quit(1 if failed else 0)
