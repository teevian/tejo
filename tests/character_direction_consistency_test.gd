extends SceneTree
## Render the real sprites to catch size/position jumps that metadata misses.
const Art = preload("res://scripts/open_world_art.gd")
const CELL := Vector2i(160,210)
const DIRECTIONS := [Vector2.DOWN,Vector2(1,1),Vector2.RIGHT,Vector2(1,-1),Vector2.UP,Vector2(-1,-1),Vector2.LEFT,Vector2(-1,1)]
var failed := false

class Paint extends Node2D:
	var kind := 0
	var direction := Vector2.DOWN
	var frame := 0
	func _draw() -> void:
		Art.draw_pose(self,kind,direction,frame>0,maxf(0,frame-1)*Art.STRIDE/Art.GAIT_FRAMES)

func check(ok: bool,message: String) -> void:
	if not ok:
		failed = true
		push_error(message)

func mean_difference(a: Image,b: Image) -> float:
	var sum := 0.0
	for y in a.get_height():
		for x in a.get_width():
			var ca := a.get_pixel(x,y)
			var cb := b.get_pixel(x,y)
			sum += absf(ca.r-cb.r)+absf(ca.g-cb.g)+absf(ca.b-cb.b)+absf(ca.a-cb.a)
	return sum/(a.get_width()*a.get_height()*4)

func _initialize() -> void:
	call_deferred("run")
	create_timer(30.0,true,false,true).timeout.connect(func(): quit(1))

func run() -> void:
	if DisplayServer.get_name()=="headless":
		push_error("This check needs the graphics renderer")
		quit(1)
		return
	var view := SubViewport.new()
	view.size = CELL*Vector2i(9,16)
	view.transparent_bg = true
	view.world_2d = World2D.new()
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(view)
	for kind in 2:
		for direction in 8:
			for frame in 9:
				var paint := Paint.new()
				paint.kind = kind
				paint.direction = DIRECTIONS[direction]
				paint.frame = frame
				paint.position = Vector2(Vector2i(frame,kind*8+direction)*CELL)+Vector2(80,200)
				view.add_child(paint)
	for i in 3:
		await process_frame
	RenderingServer.force_draw()
	var image := view.get_texture().get_image()
	for kind in 2:
		for frame in 9:
			var tops: Array[int] = []
			var floors: Array[int] = []
			for direction in 8:
				var origin := Vector2i(frame,kind*8+direction)*CELL
				var top := CELL.y
				var bottom := -1
				for y in CELL.y:
					for x in CELL.x:
						if image.get_pixelv(origin+Vector2i(x,y)).a>0.5:
							top = mini(top,y)
							bottom = maxi(bottom,y)
				tops.append(top)
				floors.append(bottom)
				check(bottom>top,"Missing rendered character")
				var row := Art.direction_row(DIRECTIONS[direction])
				var limit := floori(200-Art.HEIGHTS[kind]+140*Art.pose_scale(kind,row))
				var left := CELL.x
				var right := -1
				for y in range(top,limit):
					for x in CELL.x:
						if image.get_pixelv(origin+Vector2i(x,y)).a>0.5:
							left = mini(left,x)
							right = maxi(right,x)
				check(absf((left+right)*.5-80)<1.6,"Rendered head position jumps: person %d direction %d phase %d"%[kind,direction,frame])
			check(tops.max()-tops.min()<=2,"Rendered height changes with direction: person %d phase %d"%[kind,frame])
			check(floors.max()-floors.min()<=1,"Rendered ground baseline moves with direction")
		for direction in 8:
			var heads: Array[Image] = []
			for frame in range(1,9):
				var origin := Vector2i(frame,kind*8+direction)*CELL+Vector2i(32,36)
				var head := image.get_region(Rect2i(origin,Vector2i(96,44)))
				var state := int((frame-1)/4)
				if frame==1 or frame==5:
					heads.append(head)
				else:
					# Atlas UV rounding can differ by a colour level between cells.
					check(mean_difference(head,heads[state])<0.0001,"Walking added a third rendered head state")
			var difference := mean_difference(heads[0],heads[1])
			check(difference>0.0001 and difference<0.025,"The two rendered head states must differ only very slightly")
	image.save_png("res://output/character-motion-v14-directions.png")
	if not failed:
		print("PASS: rendered height, head position and ground baseline agree across eight directions; exactly two walking head images")
	quit(1 if failed else 0)
