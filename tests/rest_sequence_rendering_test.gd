extends SceneTree
## Every new cutout must be visible at the game's actual scale, without matte debris.
const Person = preload("res://scripts/open_world_person.gd")
const CELL := Vector2i(180,240)
var failed := false

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, message: String) -> void:
	if not value:
		failed = true
		push_error(message)

func run() -> void:
	if DisplayServer.get_name()=="headless": quit(1); return
	var view := SubViewport.new()
	view.size = CELL*Vector2i(10,6)
	view.transparent_bg = true
	view.world_2d = World2D.new()
	view.disable_3d = true
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(view)
	for kind in 2:
		for row in 4:
			for key in 5:
				var person := Person.new()
				person.kind = kind
				person.position = Vector2((kind*5+key)*CELL.x+90,row*CELL.y+220)
				view.add_child(person)
				person.set_physics_process(false)
				person.ground_seated = true
				if row==0:
					person.ground_pose = 4
					person.rest_gaze.key = key
				else:
					person.rest_transition = ["","recline","stretch","call"][row]
					person.rest_duration = 1
					person.rest_time = (float(key)+0.1)/5.0
				person.body.queue_redraw()
		for row in 2:
			for key in 5:
				var person := Person.new()
				person.kind = kind
				person.position = Vector2((kind*5+key)*CELL.x+90,(row+4)*CELL.y+220)
				view.add_child(person)
				person.set_physics_process(false)
				person.ground_seated = true
				person.ground_pose = 1
				person.rest_gaze.key = key
				person.eyes_closed = row==1
				person.body.queue_redraw()
	for i in 3: await process_frame
	RenderingServer.force_draw()
	var rendered := view.get_texture().get_image()
	for kind in 2:
		for row in 6:
			var signatures := {}
			for key in 5:
				var tile := rendered.get_region(Rect2i(Vector2i((kind*5+key)*CELL.x,row*CELL.y),CELL))
				var visible := 0
				var matte := 0
				for y in 210:
					for x in CELL.x:
						var color := tile.get_pixel(x,y)
						if color.a>0.8:
							visible += 1
							if color.r>0.8 and color.g<0.15 and color.b<0.15: matte += 1
				check(visible>1600,"Every semi-reclined, lowering, stretch, call and flat/sleep key must draw a complete figure")
				check(matte==0,"Generated rest cutouts must not leak saturated matte marks into the world")
				signatures[hash(tile.get_region(Rect2i(0,0,180,210)).get_data())] = true
			if row in [0,1,2,3,4]: check(signatures.size()>=3,"Awake gaze and new actions need visibly distinct drawings")
	var preview := Image.create(1100,1560,false,Image.FORMAT_RGBA8)
	preview.fill(Color("a7b29d"))
	# Pair central gaze, complete stretch and call keys for a compact review sheet.
	for row in 6:
		for kind in 2:
			var key := 3 if row==2 else (2 if row!=3 else 1)
			var tile := rendered.get_region(Rect2i(Vector2i((kind*5+key)*CELL.x,row*CELL.y),CELL))
			preview.blend_rect(tile,Rect2i(Vector2i.ZERO,CELL),Vector2i(340+kind*250,row*260+10))
	preview.save_png("res://output/rest-sequence-poses.png")
	if not failed: print("PASS: 60 actual rest renderings, new poses/actions, awake flat head turns, closed eyes and clean alpha")
	quit(1 if failed else 0)
