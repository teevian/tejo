extends SceneTree
const Art = preload("res://scripts/sleep_art.gd")
const Person = preload("res://scripts/open_world_person.gd")
const DATA = preload("res://assets/characters/interactions/sleep-eyes.json")
var failed := false

func check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		push_error(message)

func png(path: String) -> Image:
	var image := Image.new()
	image.load_png_from_buffer(FileAccess.get_file_as_bytes(path))
	return image

func _initialize() -> void:
	for kind in 2:
		var name_value: String = ["te","jo"][kind]
		var original := png("res://assets/characters/interactions/"+name_value+"-rest-side.png")
		var closed := png(Art.ROLLS[kind].resource_path)
		check(hash(original.get_data())!=hash(closed.get_data()),"Sleeping rolls must contain newly painted closed eyes")
		for patch in DATA.data.patches:
			if patch.character!=name_value or patch.kind=="supine": continue
			var a: Array = patch.rect
			var region := Rect2i(a[0],a[1],a[2],a[3])
			original.fill_rect(region,Color.TRANSPARENT)
			closed.fill_rect(region,Color.TRANSPARENT)
			if patch.kind=="side-supine":
				region.position.y += 560
				original.fill_rect(region,Color.TRANSPARENT)
				closed.fill_rect(region,Color.TRANSPARENT)
		check(original.get_data()==closed.get_data(),"Every hair, nose, mouth, body, hand, clothing and phone pixel outside the eye masks must stay identical")
		var posed := png(Art.POSES[kind].resource_path)
		var rolling := png(Art.ROLLS[kind].resource_path)
		for side in 2:
			check(posed.get_region(Rect2i((side+1)*640,0,640,560)).get_data()==rolling.get_region(Rect2i(1920,side*560,640,560)).get_data(),"The final closed-eye shoulder pose must match the rolling endpoint")
		var look := png("res://assets/characters/interactions/"+name_value+"-rest-look.png")
		var supine := Image.create(640,560,false,Image.FORMAT_RGBA8)
		supine.blit_rect(look,Rect2i(960,560,480,560),Vector2i(80,0))
		var asleep := posed.get_region(Rect2i(0,0,640,560))
		check(supine.get_data()!=asleep.get_data(),"The supine sleep pose must also close the eyes")
		for patch in DATA.data.patches:
			if patch.character!=name_value or patch.kind!="supine": continue
			var a: Array = patch.rect
			var region := Rect2i(a[0]-960+80,a[1]-560,a[2],a[3])
			supine.fill_rect(region,Color.TRANSPARENT)
			asleep.fill_rect(region,Color.TRANSPARENT)
		check(supine.get_data()==asleep.get_data(),"Closing the supine eyes must preserve every pixel elsewhere")
	var person := Person.new()
	person.ground_seated = true
	for pose in 5:
		person.ground_pose = pose
		person.eyes_closed = false
		check(not person.is_sleeping(),"Every resting pose must initially keep eyes open")
		person.close_rest_eyes()
		check(person.is_sleeping()==(pose in [1,2,3]),"Only settled flat/shoulder poses may close their eyes")
	person.stand_up(true)
	check(not person.is_sleeping(),"Waking must immediately restore the awake eyes")
	person.free()
	if not failed: print("PASS: all sleep/roll drawings close their eyes; every pixel outside eyelid masks, full bodies and the shared phone preserved; wake opens eyes")
	quit(1 if failed else 0)
