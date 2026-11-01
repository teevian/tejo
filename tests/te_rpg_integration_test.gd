extends SceneTree
## Check the actual character renderer against the newly selected whole sprites.
const Art = preload("res://scripts/open_world_art.gd")
const Rpg = preload("res://scripts/te_rpg_walk.gd")
const Person = preload("res://scripts/open_world_person.gd")
const CELL := Vector2i(200,230)
const DIRECTIONS := [Vector2.DOWN,Vector2.RIGHT,Vector2.LEFT]
var failed := false

class Expected extends Node2D:
	var direction := Vector2.DOWN
	var moving := false
	var distance := 0.0
	func _draw() -> void:
		draw_set_transform(Vector2.ZERO,0,Vector2(-1 if direction.x<0 else 1,1))
		Rpg.draw_pose(self,Art.direction_row(direction),moving,distance,Art.HEIGHTS[0])

func _initialize() -> void:
	call_deferred("run")
	create_timer(30.0,true,false,true).timeout.connect(func(): quit(1))

func check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		push_error(message)

func run() -> void:
	check(Rpg.ATLAS.get_size()==Vector2(2800,1120),"Selected Te atlas must contain both directions, idle and six walking poses")
	check(Rpg.frame_for(false,10000)==0,"Stopping must use the matching new idle")
	check(Rpg.frame_for(true,0)==Rpg.frame_for(true,Rpg.STRIDE),"The six-pose walk must loop by travelled distance")
	check(Rpg.supports(0) and Rpg.supports(2) and not Rpg.supports(1) and not Rpg.supports(3) and not Rpg.supports(4),"Only approved down and lateral drawings may change")
	if DisplayServer.get_name()=="headless":
		push_error("Run with graphics to validate the real sprite pixels")
		quit(1)
		return
	var view := SubViewport.new()
	view.size = CELL*Vector2i(7,6)
	view.transparent_bg = true
	view.world_2d = World2D.new()
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(view)
	for direction in 3:
		for frame in 7:
			var stride: float = Rpg.STRIDE if direction==0 else Rpg.SIDE_STRIDE
			var distance := (frame-1+.1)*stride/Rpg.WALK_FRAMES if frame>0 else 0.0
			var person := Person.new()
			person.kind = 0
			person.facing = DIRECTIONS[direction]
			person.visual_facing = person.facing
			person.moving = frame>0
			person.velocity = person.facing*235 if frame>0 else Vector2.ZERO
			person.walked = distance
			person.position = Vector2(frame*CELL.x+CELL.x/2,direction*CELL.y+210)
			view.add_child(person)
			person.set_physics_process(false)
			var expected := Expected.new()
			expected.direction = DIRECTIONS[direction]
			expected.moving = frame>0
			expected.distance = distance
			expected.position = person.position+Vector2(0,3*CELL.y)
			var ink := ShaderMaterial.new()
			ink.shader = preload("res://shaders/opaque_cutout.gdshader")
			expected.material = ink
			view.add_child(expected)
	for i in 3: await process_frame
	RenderingServer.force_draw()
	var image := view.get_texture().get_image()
	for direction in 3:
		var unique := {}
		for frame in 7:
			var body := image.get_region(Rect2i(Vector2i(frame,direction)*CELL,CELL))
			var expected := image.get_region(Rect2i(Vector2i(frame,direction+3)*CELL,CELL))
			var n := 0
			var error := 0.0
			for y in 195:
				for x in CELL.x:
					var a := body.get_pixel(x,y)
					var b := expected.get_pixel(x,y)
					if b.a>.8:
						n += 1
						error += absf(a.r-b.r)+absf(a.g-b.g)+absf(a.b-b.b)+absf(a.a-b.a)
			check(n>2500 and error/maxi(n*4,1)<.002,"Actual Te must render the selected complete painting: direction %d frame %d"%[direction,frame])
			check(body.get_pixel(0,0).a<.01 and body.get_pixel(CELL.x-1,100).a<.01,"Dark presentation background must not enter the game")
			if frame>0: unique[hash(body.get_data())] = true
		check(unique.size()==6,"All six selected steps must appear in each direction")
	image.get_region(Rect2i(Vector2i.ZERO,CELL*Vector2i(7,3))).save_png("res://output/te-propostas-rpg/te-v20-no-motor.png")
	if not failed: print("PASS: Te complete front and lateral paintings, matching idle, clean transparency and distance-driven movement")
	quit(1 if failed else 0)
