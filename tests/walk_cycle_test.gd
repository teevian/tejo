extends SceneTree
## Verify ground contacts against the incoming gait in its projected viewpoints.
const Art = preload("res://scripts/open_world_art.gd")
const Incoming = preload("res://tools/pulled_walk_reference.gd")
const HEIGHTS := [219,213,212,212,232]
var failed := false
func check(ok: bool,message: String) -> void:
	if not ok:
		failed = true
		push_error(message)
func planted_x(image: Image,anchor: Vector2) -> float:
	var weight := 0.0
	var weighted_x := 0.0
	for y in range(roundi(image.get_height()*0.95),image.get_height()):
		for x in image.get_width():
			var alpha := image.get_pixel(x,y).a
			if alpha>0.5:
				weighted_x += (x-anchor.x)*alpha
				weight += alpha
	check(weight>0,"Missing planted shoe")
	return weighted_x/maxf(weight,1.0)
func _initialize() -> void:
	var original_te := Image.new()
	var original_jo := Image.new()
	var recipe: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/characters/open_world/neck-motion-v14.recipe.json"))
	check(original_jo.load_png_from_buffer(FileAccess.get_file_as_bytes("res://assets/characters/open_world/sources/jo-body-v8.png"))==OK,"Jo body reference must load")
	check(original_te.load_png_from_buffer(FileAccess.get_file_as_bytes("res://assets/characters/open_world/sources/te-natural-body-v9.png"))==OK,"Incoming body reference must load")
	for kind in 2:
		var atlas := Art.ATLASES[kind].get_image()
		for row in [0,1,3,4]:
			var contacts: Array[float] = []
			for frame in [1,5]:
				var region := Art.pose_region(kind,row,frame)
				var anchor := Art.TE_ANCHORS[row*9+frame] if kind==0 else Art.JO_ANCHORS[row*9+frame]
				var actual := planted_x(atlas.get_region(Rect2i(region)),anchor)/4.0
				var who := "te" if kind==0 else "jo"
				var registration: Dictionary = recipe.characters[who].poses[row*9+frame]
				var expected: float
				if kind==0:
					var key: int = 1+(int(frame)-1)/2
					var source := original_te.get_region(Rect2i(key*800,(row*280+260-HEIGHTS[row])*4,800,HEIGHTS[row]*4))
					expected = planted_x(source,Vector2(400,HEIGHTS[row]*4))/4.0
				else:
					var key: int = 1+(int(frame)-1)/2
					var source := original_jo.get_region(Rect2i(key*800,(row*280+260-HEIGHTS[row])*4,800,HEIGHTS[row]*4))
					expected = planted_x(source,Vector2(400,HEIGHTS[row]*4))/4.0
				expected += float(registration.sourceShift)/4.0
				check(absf(actual-expected)<0.3,"Foot paint differs from the registered gait: person %d view %d phase %d"%[kind,row,frame])
				contacts.append(actual)
			check(absf(contacts[0]-contacts[1])>1.0,"Contact phases must have distinct planted feet")
			# Diagonals project forward/backward motion onto x too, so both contacts
			# can be on the same side of the vertical body axis. Only front/back
			# views must straddle it; all views must match their incoming anatomy.
			if row==0 or row==4:
				check(contacts[0]*contacts[1]<0,"Front/back contacts must alternate sides")
	if not failed:
		print("PASS: incoming foot contacts preserved in front, rear and both projected diagonals; Te uses repaired whole poses")
	quit(1 if failed else 0)
