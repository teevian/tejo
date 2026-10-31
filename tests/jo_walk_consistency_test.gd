extends SceneTree
## The painted Jo identity follows the existing body lean in complete sprites.
const Art = preload("res://scripts/open_world_art.gd")
const HEIGHTS := [219,213,212,212,232]
const REPAIRS := [84,84,88,84,84]
const FACE_ROWS := [52,49,50,49,49] # The diagonal shirt moves behind the lower nape.
var failed := false
func check(ok: bool,message: String) -> void:
	if not ok:
		failed = true
		push_error(message)
func neck_skin(colour: Color) -> bool:
	return colour.a>.5 and colour.r>.5 and colour.r>colour.g*1.12 and colour.g>colour.b*1.18
func check_neck_join(image: Image,recipe: Dictionary,row: int,top: int) -> void:
	# The front and rear used to retain different blocks of the old neck in
	# different steps. Check the skin boundary as well as the opaque connection.
	var last_rows: Array[int] = []
	var base: int = roundi(float(recipe.views[row].neckBase)*4.0)
	for key in 5:
		var shift: int = recipe.headOffsets[row*5+key]
		var origin: int = key*800+shift
		var last_skin := 0
		var continuous := true
		var clean_collar := true
		for y in range(55*4,base+6*4):
			for x in range(95*4,105*4):
				var colour := image.get_pixel(origin+x,top+y)
				if neck_skin(colour):
					last_skin = maxi(last_skin,y)
					if y>base+2*4:
						clean_collar = false
				if y>60*4 and colour.a<.95:
					continuous = false
		last_rows.append(last_skin)
		check(continuous,"Hole between Jo's neck and shirt: view %d key %d"%[row,key])
		check(clean_collar,"Old skin block extends over Jo's collar: view %d key %d"%[row,key])
	check(last_rows.max()-last_rows.min()<=4,"Jo's neckline jumps between steps: view %d"%row)
func _initialize() -> void:
	var body := Image.new()
	var final := Image.new()
	var identity := Image.new()
	check(identity.load_png_from_buffer(FileAccess.get_file_as_bytes("res://assets/characters/open_world/sources/jo-identity-mask-v9.png"))==OK,"Portrait identity mask must load")
	check(body.load_png_from_buffer(FileAccess.get_file_as_bytes("res://assets/characters/open_world/sources/jo-body-v8.png"))==OK,"Jo body reference must load")
	check(final.load_png_from_buffer(FileAccess.get_file_as_bytes("res://assets/characters/open_world/jo-walk-v9.png"))==OK,"New Jo atlas must load")
	body.convert(Image.FORMAT_RGBA8)
	final.convert(Image.FORMAT_RGBA8)
	var recipe = JSON.parse_string(FileAccess.get_file_as_string("res://assets/characters/open_world/jo-walk-v9.recipe.json"))
	check(Art.ATLASES[1].resource_path.ends_with("jo-walk-v9.png"),"Use Jo's painted face atlas")
	check(FileAccess.get_sha256("res://assets/characters/open_world/te-walk-v9.png")=="f3536d224b6e786e39ccbfb76f1c2ff5fa4c2e35e5eb1f950bfab1ae3a1d98ba","Approved Te sprites must stay unchanged")
	check(Art.HEIGHTS==[156.0,153.0] and Art.STRIDE==112.0 and Art.GAIT_FRAMES==8,"Keep approved proportions and gait timing")
	for row in 5:
		var top: int = (row*280+260-HEIGHTS[row])*4
		var neutral := final.get_region(Rect2i(65*4,top,80*4,FACE_ROWS[row]*4))
		var keys := {}
		for key in 5:
			var rect := Rect2i(key*800,top+REPAIRS[row]*4,800,(HEIGHTS[row]-REPAIRS[row])*4)
			check(body.get_region(rect).get_data()==final.get_region(rect).get_data(),"Jo body/clothes/limbs changed below the neck: view %d key %d"%[row,key])
			var shift: int = recipe.headOffsets[row*5+key]
			var face := final.get_region(Rect2i(key*800+65*4+shift,top,80*4,FACE_ROWS[row]*4))
			check(face.get_data()==neutral.get_data(),"Jo's head size/identity changes rather than following body lean: view %d key %d"%[row,key])
			# Every opaque source portrait pixel must retain the same colour.
			# The alpha edge mixes with each moving collar and is not identity.
			var identical := true
			for y in REPAIRS[row]*4:
				for x in 800:
					if identity.get_pixel(x,top+y).a>.5:
						if final.get_pixel(x,top+y)!=final.get_pixel(key*800+x+shift,top+y):
							identical = false
			check(identical,"Jo's opaque portrait paint changed in view %d key %d"%[row,key])
			if key>0:
				keys[hash(final.get_region(rect).get_data())] = true
		check(keys.size()==4,"Retain Jo's four gait keys")
		if row==0 or row==4:
			check_neck_join(final,recipe,row,top)
		for frame in 9:
			var region := Art.pose_region(1,row,frame)
			var anchor := Art.JO_ANCHORS[row*9+frame]
			var key: int = 0 if frame==0 else 1+(frame-1)/2
			check(region.position.x+anchor.x==key*800+400,"Jo horizontal foot anchor changed")
			check(region.position.y+anchor.y==(row*280+260)*4,"Jo ground baseline changed")
	if not failed:
		print("PASS: consistent painted Jo identity, continuous front/rear neck joins, no old skin blocks; approved body, feet, timing and Te preserved")
	quit(1 if failed else 0)
