extends SceneTree
## Actual GPU body rendering: every run key, eight directions, both characters.
const Person = preload("res://scripts/open_world_person.gd")
const Run = preload("res://scripts/running_art.gd")
const Walk = preload("res://scripts/open_world_art.gd")
const CELL := Vector2i(180,220)
const DIRECTIONS := [Vector2.DOWN,Vector2(1,1),Vector2.RIGHT,Vector2(1,-1),Vector2.UP,Vector2(-1,-1),Vector2.LEFT,Vector2(-1,1)]
var failed := false

func _initialize() -> void:
	call_deferred("run")
	create_timer(40,true,false,true).timeout.connect(func():
		push_error("Running rendering check timed out")
		quit(1))

func check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		push_error(message)

func run() -> void:
	if DisplayServer.get_name()=="headless":
		push_error("Running sprite verification requires a graphics window")
		quit(1)
		return
	var view := SubViewport.new()
	view.size = Vector2i(CELL.x*7,CELL.y*16)
	view.transparent_bg = true
	view.disable_3d = true
	view.world_2d = World2D.new()
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(view)
	for kind in 2:
		check(Run.ATLASES[kind].get_size()==Vector2(3456,2800),"Incomplete running atlas")
		for direction in 8:
			for key in 7:
				var person := Person.new()
				person.kind = kind
				person.facing = DIRECTIONS[direction].normalized()
				person.visual_facing = person.facing
				person.moving = true
				person.velocity = person.facing*340
				person.running = key<6
				person.run_distance = (float(key)+0.1)*Run.STRIDE/Run.FRAMES
				person.walked = Walk.STRIDE*0.2
				person.position = Vector2(Vector2i(key,kind*8+direction)*CELL)+Vector2(90,195)
				view.add_child(person)
				person.set_physics_process(false)
				check(person.is_running()==(key<6),"The body must choose running only for locomotion")
				if key<6:
					var region := Run.pose_region(Walk.direction_row(person.facing),key)
					check(Rect2(Vector2.ZERO,Run.ATLASES[kind].get_size()).encloses(region),"Running cutout is outside the atlas")
	for i in 3: await process_frame
	RenderingServer.force_draw()
	var image := view.get_texture().get_image()
	check(not image.is_empty(),"GPU returned no running sprites")
	if not image.is_empty():
		for row in 16:
			var hashes := {}
			var walk_hash := hash(image.get_region(Rect2i(Vector2i(6,row)*CELL,CELL)).get_data())
			for key in 6:
				var crop := image.get_region(Rect2i(Vector2i(key,row)*CELL,CELL))
				var opaque := 0
				var edge := 0
				for y in range(10,180):
					for x in CELL.x:
						if crop.get_pixel(x,y).a<0.8: continue
						opaque += 1
						if x<3 or x>=CELL.x-3 or y<13: edge += 1
				check(opaque>1800,"Incomplete running body at %d/%d"%[row,key])
				check(edge==0,"Clipped running head or limbs at %d/%d"%[row,key])
				var fingerprint := hash(crop.get_data())
				check(fingerprint!=walk_hash,"Run must have its own painted pose, not a faster walking frame")
				hashes[fingerprint] = true
			check(hashes.size()==6,"Every direction needs six distinct complete running drawings")
		DirAccess.make_dir_recursive_absolute("/tmp/tejo-running-work")
		image.save_png("/tmp/tejo-running-work/gpu-check.png")
	if not failed: print("PASS: 96 rendered running bodies, six distinct keys in eight directions for Te and Jo; separate from walking, no clipped limbs")
	quit(1 if failed else 0)
