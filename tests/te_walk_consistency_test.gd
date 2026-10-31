extends SceneTree
## Repaired complete poses, fixed approved facial identity and dark hair.
const Art = preload("res://scripts/open_world_art.gd")
const FACTOR := 4
const HEIGHTS := [219,213,212,212,232]
const REPAIRS := [84,80,76,76,78]
const FIXED_HEAD_ROWS := [52,52,51,52,52] # Side nape ends at row 51; the sleeve below it must move.
var failed := false
func check(ok: bool,message: String) -> void:
	if not ok:
		failed = true
		push_error(message)
func _initialize() -> void:
	# Compare source PNG bytes rather than imported, possibly compressed textures.
	var incoming := Image.new()
	var merged := Image.new()
	check(incoming.load_png_from_buffer(FileAccess.get_file_as_bytes("res://assets/characters/open_world/sources/te-natural-body-v9.png"))==OK,"Incoming reference PNG must load")
	check(merged.load_png_from_buffer(FileAccess.get_file_as_bytes("res://assets/characters/open_world/te-walk-v9.png"))==OK,"Final sprite PNG must load")
	incoming.convert(Image.FORMAT_RGBA8)
	merged.convert(Image.FORMAT_RGBA8)
	var recipe = JSON.parse_string(FileAccess.get_file_as_string("res://assets/characters/open_world/te-walk-v9.recipe.json"))
	check(recipe.wholePoseRepair==true,"Use repaired complete poses, without frozen shirt/arm cutouts")
	check(recipe.bodyWidth==0.95,"Body must be only five percent slimmer")
	check(recipe.paintedFace=="sources/te-heads-dark-v9.png","Use the painted version of the chosen local identity")
	check(incoming.get_size()==merged.get_size(),"Complete atlas size must match the incoming reference")
	check(FileAccess.get_sha256("res://assets/characters/open_world/sources/te-heads-v7.png")=="ecb33f65cfd123e1861acb2b1f34719ea7f6e1f7478bee37185b5d862e02d3a7","Local face source must be unchanged")
	check(Art.STRIDE==112.0 and Art.GAIT_FRAMES==8,"Incoming stride and eight-tick timing must be preserved")
	check(Art.HEIGHTS==[156.0,153.0],"Use the incoming display proportions")
	for row in 5:
		var top: int = (row*280+260-HEIGHTS[row])*FACTOR
		var fixed_head := merged.get_region(Rect2i(65*FACTOR,top,80*FACTOR,FIXED_HEAD_ROWS[row]*FACTOR))
		var lower_frames := {}
		for key in 5:
			var body_rect := Rect2i(key*800,top+REPAIRS[row]*FACTOR,800,(HEIGHTS[row]-REPAIRS[row])*FACTOR)
			check(incoming.get_region(body_rect).get_data()==merged.get_region(body_rect).get_data(),"Body differs from the corrected whole-pose reference in view %d key %d"%[row,key])
			var head := merged.get_region(Rect2i(key*800+65*FACTOR,top,80*FACTOR,FIXED_HEAD_ROWS[row]*FACTOR))
			check(head.get_data()==fixed_head.get_data(),"Local face or cranial position changes in view %d key %d"%[row,key])
			if key>0:
				lower_frames[hash(merged.get_region(body_rect).get_data())] = true
		check(lower_frames.size()==4,"Incoming four distinct gait poses must remain in view %d"%row)
		for frame in 9:
			var key := 0 if frame==0 else 1+(frame-1)/2
			var region := Art.pose_region(0,row,frame)
			var anchor := Art.TE_ANCHORS[row*9+frame]
			check(int(region.position.x/800)==key,"Incoming pose order changed")
			check(region.position.x+anchor.x==key*800+400,"Incoming planted-foot horizontal anchor changed")
			check(region.position.y+anchor.y==(row*280+260)*FACTOR,"Incoming ground baseline changed")
	if not failed:
		print("PASS: local head source preserved; all 25 complete sprites retain corrected complete body with moving sleeves and low diagonal steps, four gait keys, scale, stride and foot anchors")
	quit(1 if failed else 0)
