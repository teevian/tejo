extends RefCounted
## Preserve the original face and reuse exactly two barely different head images.
const Art = preload("res://scripts/open_world_art.gd")
const HEIGHTS := [219,213,212,212,232]
var failed := false

func check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		push_error(message)

func sample(image: Image, point: Vector2) -> Color:
	var p := Vector2i(floori(point.x),floori(point.y))
	var f := point-Vector2(p)
	return image.get_pixelv(p).lerp(image.get_pixelv(p+Vector2i.RIGHT),f.x).lerp(image.get_pixelv(p+Vector2i.DOWN).lerp(image.get_pixelv(p+Vector2i.ONE),f.x),f.y)

func run(kind: int) -> bool:
	var who := "te" if kind==0 else "jo"
	var original := Image.new()
	var final := Image.new()
	check(original.load_png_from_buffer(FileAccess.get_file_as_bytes("res://assets/characters/open_world/%s-walk-v9.png"%who))==OK,"Approved identity atlas must load")
	check(final.load_png_from_buffer(FileAccess.get_file_as_bytes("res://assets/characters/open_world/%s-walk-v14.png"%who))==OK,"Joined neck-motion atlas must load")
	original.convert(Image.FORMAT_RGBA8)
	final.convert(Image.FORMAT_RGBA8)
	var recipe: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/characters/open_world/neck-motion-v14.recipe.json"))
	check(Art.ATLASES[kind].resource_path.ends_with("%s-walk-v14.png"%who),"Use the restored original faces")
	check(int(recipe.headStates)==2,"Only two walking head states are allowed per direction")
	check(not recipe.characters[who].has("yaw"),"Do not consume regenerated face paintings")
	var south := Image.new()
	if kind==1:
		check(south.load_png_from_buffer(FileAccess.get_file_as_bytes("res://assets/characters/open_world/sources/jo-south-gait-v12.png"))==OK,"Corrected low passing steps must load")
		south.convert(Image.FORMAT_RGBA8)
		# Detect a substantial bare-knee patch, excluding isolated beige folds.
		# The old third key exposed the knee around row 132, beside the waist.
		for pair in [[2,102,125],[4,76,98]]:
			var first_skin := 180
			for y in range(120,180):
				var skin := 0
				for x in range(int(pair[1])*4,int(pair[2])*4):
					var colour := south.get_pixel(int(pair[0])*800+x,164+y*4)
					if colour.a>.8 and colour.r>105.0/255 and colour.r>colour.g*1.2 and colour.g>colour.b*1.2:
						skin += 1
				if skin>(int(pair[2])-int(pair[1]))*2:
					first_skin = y
					break
			check(first_skin>=150,"Jo's south-facing passing knee is too high")
	check(Art.HEIGHTS==[156.0,153.0] and Art.STRIDE==112.0 and Art.GAIT_FRAMES==8,"Keep proportions, stride and gait timing")
	check(final.get_size()==Vector2i(7200,5600),"Keep the body animation layout")
	var approved_hash := "f3536d224b6e786e39ccbfb76f1c2ff5fa4c2e35e5eb1f950bfab1ae3a1d98ba" if kind==0 else "f213d87a65f4ffa75f6f001b9374e05ff4454c51a18e76883af918bdae6c905a"
	check(FileAccess.get_sha256("res://assets/characters/open_world/%s-walk-v9.png"%who)==approved_hash,"Approved face/body reference must remain unchanged")
	if kind==0:
		check(FileAccess.get_sha256("res://assets/characters/open_world/sources/te-heads-v7.png")=="ecb33f65cfd123e1861acb2b1f34719ea7f6e1f7478bee37185b5d862e02d3a7","Keep the approved Te identity source")
	for row in 5:
		var top: int = (row*280+260-HEIGHTS[row])*4
		var local_top: int = (260-HEIGHTS[row])*4
		var head_images := {}
		for frame in 9:
			var pose: Dictionary = recipe.characters[who].poses[row*9+frame]
			var shift: int = int(pose.neutralShift)
			var angle := deg_to_rad(float(pose.headYaw))
			check(absf(float(pose.headYaw))<=2.0,"Head turn must stay subtle")
			if frame>0:
				head_images[hash(final.get_region(Rect2i(frame*800,top,800,50*4)).get_data())] = true
				check(int(pose.headState)==int((frame-1)/4),"Alternate head direction with each step")
			var error := 0.0
			var count := 0
			# Compare rendered facial pixels with the original through the inverse yaw.
			for y in range(4*4,50*4,3):
				for x in range(65*4,143*4,3):
					var xx := x-float(pose.pivot[0])
					var sx := xx*cos(angle)-sqrt(maxf(0,144.0*144.0-xx*xx))*sin(angle) if absf(xx)<144 else xx
					if row==0:
						var yy := float(y)/4.0
						var edge := pow(maxf(0,1-pow(xx/88.0,2)),2)
						var vertical := smoothstep(20.0,29.0,yy)*(1-smoothstep(float(pose.headEnd)-7,float(pose.headEnd),yy))
						var eye := 40.0 if kind==0 else 34.0
						var nose := exp(-pow(xx/24.0,2)-pow((yy-eye-10)/7,2))
						sx = xx-(12+24*nose)*4*edge*vertical*sin(angle)
					var reference := sample(original,Vector2(float(pose.pivot[0])+sx-shift,top+y))
					var actual := final.get_pixel(frame*800+x,top+y)
					if reference.a>.98 and actual.a>.98:
						error += absf(reference.r-actual.r)+absf(reference.g-actual.g)+absf(reference.b-actual.b)
						count += 3
			check(count>1000 and error/maxi(count,1)<.003,"Original face was altered: %s direction %d frame %d (%f)"%[who,row,frame,error/maxi(count,1)])
			var continuous := true
			for y in range(int(pose.headEnd)*4,(int(pose.collar)+6)*4):
				for x in range(-4,5):
					if final.get_pixel(frame*800+int(pose.pivot[0])+x-(32 if row==2 else 0),top+y).a<.95:
						continuous = false
			check(continuous,"Gap between neck and shirt: %s direction %d frame %d"%[who,row,frame])
			var lower := Rect2i(frame*800,top+178*4,800,(HEIGHTS[row]-178)*4)
			var reference := south if kind==1 and row==0 else original
			var expected := Image.create(800,lower.size.y,false,Image.FORMAT_RGBA8)
			var source := reference.get_region(Rect2i(int(pose.key)*800,lower.position.y,800,lower.size.y))
			var delta := int(pose.sourceShift)
			expected.blit_rect(source,Rect2i(maxi(0,-delta),0,800-absi(delta),lower.size.y),Vector2i(maxi(0,delta),0))
			check(expected.get_data()==final.get_region(lower).get_data(),"Lower legs changed")
			check(is_equal_approx(Art.SOURCE_HEIGHTS[row]*Art.pose_scale(kind,row),Art.HEIGHTS[kind]),"Directional height changed")
			var region := Art.pose_region(kind,row,frame)
			var anchor := Art.TE_ANCHORS[row*9+frame] if kind==0 else Art.JO_ANCHORS[row*9+frame]
			check(region.position+anchor==Vector2(frame*800+400,(row*280+260)*4),"Ground anchor moved")
		check(head_images.size()==2,"Walking must contain exactly two head images")
	if not failed:
		print("PASS: %s original facial pixels, two subtle head turns, connected neck, preserved lower legs and fixed directional scale"%who)
	return not failed
