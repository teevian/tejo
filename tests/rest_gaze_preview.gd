extends SceneTree
const Person = preload("res://scripts/open_world_person.gd")
var people: Array = []
var output_dir := "/tmp/tejo-gaze-work/preview"

func _initialize() -> void:
	call_deferred("run")

func label_at(text: String, at: Vector2, size: int) -> void:
	var label := Label.new()
	label.text = text
	label.position = at
	label.add_theme_font_size_override("font_size",size)
	label.add_theme_color_override("font_color",Color("2b4036"))
	root.add_child(label)

func run() -> void:
	if DisplayServer.get_name()=="headless":
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(output_dir)
	RenderingServer.set_default_clear_color(Color("a7b29d"))
	label_at("Sentados · observar a natureza",Vector2(420,32),24)
	label_at("Deitados · céu, companheiro e arredores",Vector2(365,378),24)
	label_at("Pré-visualização com as pausas encurtadas",Vector2(405,690),16)
	for pose in 2:
		for kind in 2:
			var person := Person.new()
			person.kind = kind
			person.ground_seated = true
			person.ground_pose = pose
			person.position = Vector2(480+kind*290,335+pose*335)
			person.scale = Vector2(2.1,2.1)
			root.add_child(person)
			person.set_physics_process(false)
			person.rest_gaze.rng.seed = 100+pose*82+kind*1921
			people.append(person)
	for frame in 90:
		for i in people.size():
			var person = people[i]
			var partner = people[i+1 if i%2==0 else i-1]
			var side := 1 if person.kind==0 else -1
			# Keep authored turns readable; shorten only the pauses in this review.
			person.rest_gaze.step(0.06 if person.rest_gaze.key!=person.rest_gaze.target else 0.5,person.ground_pose,side,partner.rest_gaze.target==(0 if side>0 else 4))
			person.body.queue_redraw()
		await process_frame
		RenderingServer.force_draw()
		root.get_texture().get_image().save_png(output_dir+"/%03d.png"%frame)
	print("PASS: actual character head turns captured for both ground postures")
	quit()
