extends SceneTree
const Art = preload("res://scripts/open_world_art.gd")
const Person = preload("res://scripts/open_world_person.gd")
const CELL := Vector2i(260,340)
const DISPLAY_SCALE := 1.5
var failed := false

class Reference extends Node2D:
	var kind := 0
	var facing := Vector2.RIGHT
	var phase := 0.0
	func _draw() -> void:
		var row := 2
		var frame := Art.frame_for(true,phase*Art.STRIDE)
		var region := Art.pose_region(kind,row,frame)
		var anchor := Art.TE_ANCHORS[row*9+frame] if kind==0 else Art.JO_ANCHORS[row*9+frame]
		var size_value := Art.pose_scale(kind,row)
		draw_set_transform(Vector2.ZERO,0,Vector2(-1 if facing.x<0 else 1,1))
		draw_texture_rect_region(Art.ATLASES[kind],Rect2(-anchor*size_value,region.size*size_value),region)

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		push_error(message)

func run() -> void:
	# Te now uses the selected six-frame whole-body RPG sheet, checked separately
	# by te_rpg_integration_test. Keep the v16 identity checks for unchanged Jo.
	for kind in [1]:
		var who := "te" if kind==0 else "jo"
		var atlas := Image.new()
		atlas.load_png_from_buffer(FileAccess.get_file_as_bytes("res://assets/characters/open_world/%s-side-walk-v16.png"%who))
		var neutral := atlas.get_region(Rect2i(0,0,400,145)).get_data()
		var bodies := {}
		var shoulders := {}
		for frame in 9:
			check(atlas.get_region(Rect2i(frame*400,0,400,145)).get_data()==neutral,"Approved head and neck must be exact and stationary")
			if frame>0:
				bodies[hash(atlas.get_region(Rect2i(frame*400,159,400,361)).get_data())] = true
				shoulders[hash(atlas.get_region(Rect2i(frame*400,159,400,60)).get_data())] = true
		check(bodies.size()==8,"Use eight distinct painted steps, not held duplicate poses")
		check(shoulders.size()==8,"Shoulder and sleeve poses must be painted for every step")
	if DisplayServer.get_name()=="headless":
		if not failed: print("PASS: unchanged Jo eight-pose lateral source and approved face")
		quit(1 if failed else 0)
		return
	var view := SubViewport.new()
	view.size = CELL*Vector2i(4,2)
	view.transparent_bg = true
	view.world_2d = World2D.new()
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(view)
	var references: Array = []
	var people: Array = []
	for direction in 2:
		for kind in 2:
			for state in 2:
				var origin := Vector2((kind*2+state)*CELL.x+CELL.x/2,direction*CELL.y+310)
				var facing := Vector2.RIGHT if direction==0 else Vector2.LEFT
				if state==0:
					var paint := Reference.new()
					paint.kind = kind
					paint.facing = facing
					paint.position = origin
					paint.scale = Vector2.ONE*DISPLAY_SCALE
					view.add_child(paint)
					references.append(paint)
				else:
					var person := Person.new()
					person.kind = kind
					person.position = origin
					person.facing = facing
					person.visual_facing = facing
					person.moving = true
					person.velocity = facing*235
					person.scale = Vector2.ONE*DISPLAY_SCALE
					view.add_child(person)
					person.set_physics_process(false)
					people.append(person)
	DirAccess.make_dir_recursive_absolute("/tmp/tejo-side-walk")
	var first_heads := {}
	for phase in 32:
		var cycle := phase/32.0
		for ref in references:
			ref.phase = cycle
			ref.queue_redraw()
		for person in people:
			person.walked = cycle*Art.STRIDE
			person.body.queue_redraw()
		for i in 2: await process_frame
		RenderingServer.force_draw()
		var image := view.get_texture().get_image()
		image.save_png("/tmp/tejo-side-walk/%02d.png"%phase)
		for direction in 2:
			for kind in 2:
				var origin := Vector2i((kind*2+1)*CELL.x,direction*CELL.y)
				var head := image.get_region(Rect2i(origin+Vector2i(70,50),Vector2i(120,63))).get_data()
				var key := direction*2+kind
				if phase==0: first_heads[key] = head
				elif kind==1:
					var error := 0.0
					for i in head.size(): error += absf(float(head[i])-float(first_heads[key][i]))
					# Atlas UVs can round by one or two colour levels on the GPU.
					check(error/(head.size()*255.0)<.00001,"The rendered face must not rock, stretch or wobble")
				for y in [132,144,152,164]:
					var sample_at := origin+Vector2i(CELL.x/2,310)+Vector2i(0,roundi((y-520)*Art.pose_scale(kind,2)*DISPLAY_SCALE))
					check(image.get_pixelv(sample_at).a>.85,"Rendered neck must remain connected in both lateral directions")
				var floor_y := -1
				for yy in range(290,320):
					for xx in range(origin.x,origin.x+CELL.x):
						if image.get_pixel(xx,origin.y+yy).a>.8: floor_y = yy
				check(floor_y>=308 and floor_y<=310,"Rendered feet must keep the floor baseline")
	if not failed: print("PASS: selected Te and unchanged Jo lateral rendering, connected necks, floor registration and stable original Jo faces left/right")
	quit(1 if failed else 0)
