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
	view.size = Vector2i(CELL.x*9,CELL.y*18)
	view.transparent_bg = true
	view.world_2d = World2D.new()
	view.disable_3d = true
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(view)
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
	for index in 5:
		var person := add_pose(view,1 if index==3 else 0,Vector2.DOWN,0,Vector2i(index*2,17))
		if index<2:
			person.shoulder_state = person.ShoulderState.TOUCHING
			person.shoulder_side = 1.0 if index==0 else -1.0
		elif index<4:
			person.seated = true
		else:
			person.collecting_time = 0.55
		person.body.queue_redraw()
	for i in 3:
		await process_frame
	RenderingServer.force_draw()
	var image := view.get_texture().get_image()
	check(not image.is_empty(),"Graphics renderer returned no image")
	if not image.is_empty():
		for row in 17:
			var unique_frames := {}
			for frame in (8 if row==16 else 9):
				var cell := Vector2i(frame,row)
				check(painted_pixels(image,cell)>1800,"Invisible/incomplete character at row %d, frame %d"%[row,frame])
				var crop := image.get_region(Rect2i(cell*CELL,CELL))
				unique_frames[hash(crop.get_data())] = true
			check(unique_frames.size()>=4,"Walking/phone animation has no distinct frames at row %d"%row)
		for index in 5:
			check(painted_pixels(image,Vector2i(index*2,17))>1800,"Invisible shoulder/seated/pickup pose "+str(index))
	if not failed:
		print("PASS: rendered bodies for both characters, eight directions, idle, walking, phone, shoulder in both orientations, seated and pickup poses")
	quit(1 if failed else 0)
