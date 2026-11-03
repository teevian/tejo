## Requires a graphics window: checks actual rendered pixels, not just game state.
extends SceneTree
const Person = preload("res://scripts/open_world_person.gd")
const Art = preload("res://scripts/open_world_art.gd")
const CELL := Vector2i(160,240)
var directions: Array[Vector2] = [Vector2.DOWN,Vector2(1,1).normalized(),Vector2.RIGHT,Vector2(1,-1).normalized(),Vector2.UP,Vector2(-1,-1).normalized(),Vector2.LEFT,Vector2(-1,1).normalized()]
var failed := false

func _initialize() -> void:
	call_deferred("run")
	create_timer(30.0,true,false,true).timeout.connect(func():
		push_error("Character rendering check timed out")
		quit(1))

func check(condition: bool, message: String) -> void:
	if not condition:
		failed = true
		push_error(message)

func add_pose(view: SubViewport, kind: int, direction: Vector2, frame: int, cell: Vector2i) -> CharacterBody2D:
	var person := Person.new()
	person.kind = kind
	person.facing = direction
	person.visual_facing = direction
	person.moving = frame>0
	person.velocity = direction*235 if frame>0 else Vector2.ZERO
	person.walked = maxf(0,float(frame-1))*Art.STRIDE/Art.GAIT_FRAMES
	person.position = Vector2(cell*CELL)+Vector2(80,220)
	# Exercise the real character and its body without movement or a game world.
	view.add_child(person)
	person.set_physics_process(false)
	return person

func painted_pixels(image: Image, cell: Vector2i) -> int:
	# Ignore the foot shadow and selection indicator: only the body can pass.
	var count := 0
	var origin := cell*CELL+Vector2i(0,20)
	for y in 165:
		for x in CELL.x:
			if image.get_pixelv(origin+Vector2i(x,y)).a>0.8:
				count += 1
	return count

func run() -> void:
	if DisplayServer.get_name()=="headless":
		push_error("Run character_rendering_test.gd with a graphics window; headless mode cannot verify sprites")
		quit(1)
		return
	var view := SubViewport.new()
	view.size = Vector2i(CELL.x*9,CELL.y*37)
	view.transparent_bg = true
	view.world_2d = World2D.new()
	view.disable_3d = true
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(view)
	for key in 3:
		var person := add_pose(view,0,Vector2.DOWN,0,Vector2i(key,36))
		person.football_action = "foot"
		person.football_variant = mini(key,1)
		person.football_time = 0.10 if key<2 else 0.28
		person.body.queue_redraw()
	for row in 4:
		for key in 4:
			var cell := Vector2i((row%2)*4+key,34+row/2)
			var person := add_pose(view,1,Vector2.DOWN,0,cell)
			person.football_action = ["lift","foot","knee","head"][row]
			person.football_variant = mini(key,2)
			person.football_time = (float(key)+0.2)/4.0*person.football_duration if row==0 else (0.10 if key<3 else 0.28)
			person.body.queue_redraw()
	for kind in 2:
		for direction in directions.size():
			for frame in 9:
				var region := Art.pose_region(kind,Art.direction_row(directions[direction]),frame)
				check(Rect2(Vector2.ZERO,Art.ATLASES[kind].get_size()).encloses(region),"Character frame extends outside its atlas")
				add_pose(view,kind,directions[direction],frame,Vector2i(frame,kind*8+direction))
	# All four pocket poses and all four reading poses use the same real body.
	for frame in 8:
		var person := add_pose(view,1,Vector2.DOWN,0,Vector2i(frame,16))
		person.phone_state = person.PhoneState.TAKING_OUT if frame<4 else person.PhoneState.READING
		person.phone_time = float(frame)*0.72/4.0 if frame<4 else float(frame-4)/2.0
		person.body.queue_redraw()
	for index in 3:
		var person := add_pose(view,1 if index==1 else 0,Vector2.DOWN,0,Vector2i(index*3,17))
		if index<2:
			person.seated = true
		else:
			person.collecting_time = 0.55
		person.body.queue_redraw()
	for frame in 4:
		var person := add_pose(view,0,Vector2.DOWN,0,Vector2i(frame*2,23))
		person.sand_state = person.SandState.DRAWING
		person.sand_time = frame*0.4+0.01
		person.body.queue_redraw()
	# Render both independent resting figures at their real separation.
	for kind in 2:
		for frame in 8:
			var person := add_pose(view,kind,Vector2.DOWN,0,Vector2i(frame,30+kind))
			person.ground_seated = true
			person.ground_pose = 1
			person.rest_transition = "roll"
			person.rest_roll_from = 1
			person.rest_roll_to = 2+frame/4
			person.rest_duration = Person.RestArt.ROLL_SECONDS
			person.rest_time = (float(frame%4)+0.2)/4.0*person.rest_duration
			person.body.queue_redraw()
		for side in 2:
			var person := add_pose(view,kind,Vector2.DOWN,0,Vector2i(side*3,32+kind))
			person.ground_seated = true
			person.ground_pose = side+2
			person.body.queue_redraw()
	for kind in 2:
		for pose in 2:
			for key in 5:
				var person := add_pose(view,kind,Vector2.DOWN,0,Vector2i(key,26+kind*2+pose))
				person.ground_seated = true
				person.ground_pose = pose
				person.eyes_closed = pose==1
				person.rest_gaze.key = key
				person.body.queue_redraw()
	for kind in 2:
		for frame in 8:
			var person := add_pose(view,kind,Vector2.DOWN,0,Vector2i(frame,24+kind))
			person.rest_transition = "sit" if frame<4 else "lie"
			person.rest_target = "ground" if frame<4 else "lying"
			person.rest_duration = 1.0
			person.rest_time = (float(frame%4)+0.2)/4.0
			person.body.queue_redraw()
	for pose in 3:
		for kind in 2:
			var person := add_pose(view,kind,Vector2.DOWN,0,Vector2i(1,18+pose))
			person.position.x += kind*104
			person.seated = true
			person.seated_pose = pose
			person.body.queue_redraw()
	for pose in 2:
		for kind in 2:
			var person := add_pose(view,kind,Vector2.DOWN,0,Vector2i(kind*4,21+pose))
			person.ground_seated = true
			person.ground_pose = pose
			person.body.queue_redraw()
	for i in 3:
		await process_frame
	RenderingServer.force_draw()
	var image := view.get_texture().get_image()
	check(not image.is_empty(),"Graphics renderer returned no image")
	if not image.is_empty():
		var te_keys := {}
		for key in 3:
			var cell := Vector2i(key,36)
			check(painted_pixels(image,cell)>1800,"Incomplete Te football drawing")
			te_keys[hash(image.get_region(Rect2i(cell*CELL,CELL)).get_data())] = true
		check(te_keys.size()==3,"Te needs two distinct touches and a recovery drawing")
		for row in 4:
			var keys := {}
			for key in 4:
				var cell := Vector2i((row%2)*4+key,34+row/2)
				check(painted_pixels(image,cell)>1800,"Incomplete football pose %d/%d"%[row,key])
				keys[hash(image.get_region(Rect2i(cell*CELL,CELL)).get_data())] = true
			check(keys.size()==4,"Football lift, three contact variations and recovery need distinct drawings")
		for row in 17:
			var unique_frames := {}
			for frame in (8 if row==16 else 9):
				var cell := Vector2i(frame,row)
				check(painted_pixels(image,cell)>1800,"Invisible/incomplete character at row %d, frame %d"%[row,frame])
				var crop := image.get_region(Rect2i(cell*CELL,CELL))
				unique_frames[hash(crop.get_data())] = true
			check(unique_frames.size()>=4,"Walking/phone animation has no distinct frames at row %d"%row)
		for index in 3:
			check(painted_pixels(image,Vector2i(index*3,17))>1800,"Invisible seated/pickup pose "+str(index))
		var drawing_frames := {}
		for frame in 4:
			var cell := Vector2i(frame*2,23)
			check(painted_pixels(image,cell)>1800,"Invisible sand-drawing frame "+str(frame))
			drawing_frames[hash(image.get_region(Rect2i(cell*CELL,CELL)).get_data())] = true
		check(drawing_frames.size()==4,"The hand and sand must have four distinct drawing frames")
		for pose in 3:
			for kind in 2:
				check(painted_pixels(image,Vector2i(1+kind,18+pose))>1800,"Incomplete resting pair %d, side %d"%[pose,kind])
		for pose in 2:
			for kind in 2:
				check(painted_pixels(image,Vector2i(kind*4,21+pose))>1800,"Invisible ground posture %d for character %d"%[pose,kind])
		for kind in 2:
			for frame in 8:
				check(painted_pixels(image,Vector2i(frame,24+kind))>1800,"Missing complete rest transition %d for character %d"%[frame,kind])
		for row in range(26,30):
			var heads := {}
			var bodies := {}
			var kind := (row-26)/2
			var pose := (row-26)%2
			var atlas: Image = Person.InteractionArt.REST_LOOK_ATLASES[kind].get_image()
			for key in 5:
				var origin := Vector2i(key,row)*CELL
				check(painted_pixels(image,Vector2i(key,row))>1800,"Missing gaze figure at row %d, key %d"%[row,key])
				heads[hash(image.get_region(Rect2i(origin+Vector2i(0,100),Vector2i(160,55))).get_data())] = true
				# Compare source pixels: GPU filtering can round UVs differently between columns.
				bodies[hash(atlas.get_region(Rect2i(key*480,pose*560+350,480,210)).get_data())] = true
			if pose==0:
				check(heads.size()==5,"Seated rest needs five distinct painted head directions")
			else:
				var reference := image.get_region(Rect2i(Vector2i(0,row)*CELL+Vector2i(0,100),Vector2i(160,55)))
				for key in range(1,5):
					var head := image.get_region(Rect2i(Vector2i(key,row)*CELL+Vector2i(0,100),Vector2i(160,55)))
					var difference := 0.0
					for y in 55:
						for x in 160:
							var a := reference.get_pixel(x,y)
							var b := head.get_pixel(x,y)
							difference += absf(a.r-b.r)+absf(a.g-b.g)+absf(a.b-b.b)
					check(difference/(160*55*3)<0.002,"Sleeping faces must keep closed eyes instead of looking around")
			check(bodies.size()==1,"Head turns must preserve the feet, legs and lower body")
		for kind in 2:
			for frame in 8:
				check(painted_pixels(image,Vector2i(frame,30+kind))>1800,"Missing side-roll key")
			for side in 2:
				check(painted_pixels(image,Vector2i(side*3,32+kind))>1800,"Missing fully side-lying sprite")
	if not failed:
		print("PASS: rendered bodies, eight directions, walking, phone, sand, bench/ground rest and transitions; all sixteen football drawings including nine distinct contacts")
	quit(1 if failed else 0)
