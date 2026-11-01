extends SceneTree
## Detect repeated limb poses even if faces/paint differ between atlas cells.
const Rpg = preload("res://scripts/te_rpg_walk.gd")
const COLS := 7
var failed := false

func check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		push_error(message)

func shoes(image: Image, row: int, frame: int) -> Dictionary:
	var mask := PackedByteArray()
	mask.resize(400*135)
	var min_x := 400
	var max_x := -1
	for y in range(400,535):
		for x in 400:
			var c := image.get_pixel(frame*400+x,row*560+y)
			# Shoes are dark neutral paint, unlike warm calves. Ignore all faces,
			# shirts and cloth: differences there cannot disguise repeated steps.
			if c.a>.55 and c.r<=130.0/255.0 and absf(c.r-c.g)<=25.0/255.0 and absf(c.g-c.b)<=25.0/255.0:
				mask[(y-400)*400+x] = 1
				min_x = mini(min_x,x)
				max_x = maxi(max_x,x)
	var groups: Array[Dictionary] = []
	for p in mask.size():
		if mask[p]!=1: continue
		var queue: Array[int] = [p]
		mask[p] = 2
		var cursor := 0
		var total := Vector2.ZERO
		while cursor<queue.size():
			var a := queue[cursor]
			cursor += 1
			var x := a%400
			var y := a/400
			total += Vector2(x,y)
			for b in [a-1 if x>0 else -1,a+1 if x<399 else -1,a-400 if y>0 else -1,a+400 if y<134 else -1]:
				if b>=0 and mask[b]==1:
					mask[b] = 2
					queue.append(b)
		if queue.size()>50:
			groups.append({"size":queue.size(),"centre":total/queue.size()})
	groups.sort_custom(func(a,b): return a.size>b.size)
	var gap := 0.0
	var lead := 0.0
	if groups.size()>=2:
		var a: Vector2 = groups[0].centre
		var b: Vector2 = groups[1].centre
		gap = absf(a.y-b.y)
		lead = signf((a.y-b.y)*(1 if a.x<b.x else -1))
	return {"span":max_x-min_x+1,"gap":gap,"lead":lead,"groups":groups.size()}

func _initialize() -> void:
	var image := Image.new()
	var atlas_path := Rpg.ATLAS.resource_path
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--atlas="): atlas_path = arg.trim_prefix("--atlas=")
	check(image.load_png_from_buffer(FileAccess.get_file_as_bytes(atlas_path))==OK,"Active Te atlas must load")
	var previous := Image.new()
	previous.load_png_from_buffer(FileAccess.get_file_as_bytes("res://assets/characters/open_world/te-rpg-v17.png"))
	for row in [0]:
		check(image.get_region(Rect2i(0,row*560,400,560)).get_data()==previous.get_region(Rect2i(0,row*560,400,560)).get_data(),"Approved Te idle must remain unchanged")
		for frame in [1,4]:
			var old_frame: int = 3 if row==0 and frame==4 else frame
			check(image.get_region(Rect2i(frame*400,row*560,400,560)).get_data()==previous.get_region(Rect2i(old_frame*400,row*560,400,560)).get_data(),"Preserve both approved opposite contact paintings")
	var down := [{}]
	for frame in range(1,7):
		down.append(shoes(image,0,frame))
		check(down[frame].groups>=2,"Both front-facing shoes must remain complete and distinct")
	var contact_gap: float = (down[1].gap+down[4].gap)*.5
	check(contact_gap>50,"Original contact steps must remain recognisable")
	check(down[1].lead==-down[4].lead,"Front contacts must alternate the leading leg")
	for phase in [2,5]:
		check(down[phase].gap<contact_gap*.55,"Front passing phase %d must bring the feet close in depth, not repeat a contact"%phase)
	for phase in [3,6]:
		var contact := 4 if phase==3 else 1
		var passing := 2 if phase==3 else 5
		check(down[phase].lead==down[contact].lead,"The reaching foot must become the next leading foot")
		check(down[phase].gap>down[passing].gap*1.4 and down[phase].gap<down[contact].gap*.9,"Front reach must fall between passing and contact positions")
	if not failed: print("PASS: unchanged front walk alternates contacts, compact passing steps and intermediate reaches; original front idle/contact art preserved")
	quit(1 if failed else 0)
