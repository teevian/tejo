extends RefCounted
## Validate the visible identity and neck continuity on the active complete sprites.
const Art = preload("res://scripts/open_world_art.gd")
const OLD_HEIGHTS := [219,213,212,212,232]
var failed := false

func check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		push_error(message)

func read_image(path: String) -> Image:
	var image := Image.new()
	check(image.load_png_from_buffer(FileAccess.get_file_as_bytes(path))==OK,"Sprite source must load: "+path)
	image.convert(Image.FORMAT_RGBA8)
	return image

func run(kind: int) -> bool:
	var who := "te" if kind==0 else "jo"
	var reference_path := "res://assets/characters/open_world/%s-walk-v9.png"%who
	var original := read_image(reference_path)
	var final := read_image("res://assets/characters/open_world/%s-walk-v15.png"%who)
	var recipe: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/characters/open_world/character-walk-v15.recipe.json"))
	var approved_hash := "f3536d224b6e786e39ccbfb76f1c2ff5fa4c2e35e5eb1f950bfab1ae3a1d98ba" if kind==0 else "f213d87a65f4ffa75f6f001b9374e05ff4454c51a18e76883af918bdae6c905a"
	check(FileAccess.get_sha256(reference_path)==approved_hash,"Approved face reference was overwritten")
	check(Art.ATLASES[kind].resource_path.ends_with("%s-walk-v15.png"%who),"Runtime must use the new complete painted atlas")
	check(final.get_size()==Vector2i(3600,2800),"Unexpected atlas dimensions")
	check(float(recipe.headHeight)/float(recipe.sourceHeight)<0.23,"Head is too large relative to the body")
	check(Art.HEIGHTS==[164.0,161.0] and Art.STRIDE==112.0,"Keep the taller shared scale and established stride")
	for row in 5:
		var neutral: Dictionary = recipe.characters[who].neutrals[row]
		var head: Dictionary = neutral.head
		var box: Dictionary = head.sourceBounds
		var old_top: int = (row*280+260-OLD_HEIGHTS[row])*4
		var expected := original.get_region(Rect2i(int(box.left),old_top+int(box.top),int(box.width),int(box.height)))
		expected.resize(int(head.width),int(head.height),Image.INTERPOLATE_LANCZOS)
		var body_frames := {}
		for frame in 9:
			var pose: Dictionary = recipe.characters[who].poses[row*9+frame]
			var error := 0.0
			var count := 0
			# Compare with the original painted face through a uniform resize.
			# Stop above the jaw mask; no generated facial image is accepted.
			for y in range(4,74,2):
				for x in range(2,int(head.width)-2,2):
					var a := expected.get_pixel(x,y)
					var b := final.get_pixel(frame*400+int(head.left)+x,row*560+40+y)
					if a.a>.99 and b.a>.99:
						error += absf(a.r-b.r)+absf(a.g-b.g)+absf(a.b-b.b)
						count += 3
			check(count>1000 and error/maxi(count,1)<.015,"Original face changed: %s direction %d frame %d"%[who,row,frame])
			for y in range(132,174):
				for dx in range(-2,3):
					check(final.get_pixel(frame*400+int(neutral.neck[0])+dx,row*560+y).a>.9,"Transparent gap at neck/collar: %s direction %d frame %d"%[who,row,frame])
			var region := Art.pose_region(kind,row,frame)
			var anchor := Art.TE_ANCHORS[row*9+frame] if kind==0 else Art.JO_ANCHORS[row*9+frame]
			check(region.position+anchor==Vector2(frame*400+200,row*560+520),"Ground registration moved")
			check(is_equal_approx(Art.pose_scale(kind,row)*480,Art.HEIGHTS[kind]),"Direction changes character height")
			if frame>0:
				body_frames[hash(final.get_region(Rect2i(frame*400,row*560+210,400,310)).get_data())] = true
		check(body_frames.size()==4,"Each direction requires four different complete walking paintings")
	if not failed:
		print("PASS: %s original faces, smaller heads, continuous neck/collar, complete painted steps and fixed directional scale"%who)
	return not failed
