extends SceneTree
const Person = preload("res://scripts/open_world_person.gd")
const Prop = preload("res://scripts/discovery_prop.gd")
const Art = preload("res://scripts/football_art.gd")
const Floor = preload("res://tests/football_preview.gd").Floor

func _initialize() -> void: call_deferred("run")

func run() -> void:
	if DisplayServer.get_name()=="headless":
		quit(1)
		return
	var view := SubViewport.new()
	view.size = Vector2i(1050,440)
	view.world_2d = World2D.new()
	view.disable_3d = true
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(view)
	var bg := ColorRect.new()
	bg.size = Vector2(1050,440)
	bg.color = Color("a7b29d")
	view.add_child(bg)
	for key in 3:
		var floor_node := Floor.new()
		floor_node.opaque_paint = ShaderMaterial.new()
		floor_node.opaque_paint.shader = preload("res://shaders/opaque_cutout.gdshader")
		floor_node.position = Vector2(175+key*350,410)
		floor_node.scale = Vector2(2.0,2.0)
		view.add_child(floor_node)
		var person := Person.new()
		person.kind = 0
		person.football_action = "foot"
		person.football_variant = maxi(0,key-1)
		person.football_time = 0.28 if key==0 else 0.1
		floor_node.add_child(person)
		person.set_physics_process(false)
		var point := Art.contact("foot",maxi(0,key-1),1,0)
		var ball := Prop.new()
		ball.kind = 3
		ball.paint_height = 31
		ball.world = floor_node
		ball.position = Vector2(33 if key==0 else point.x,0)
		floor_node.add_child(ball)
		ball.juggling.height = 0 if key==0 else -point.y
		ball.step_ball(0)
		var label := Label.new()
		label.text = ["Preparar","Primeiro toque","Segundo toque"][key]
		label.position = Vector2(100+key*350,20)
		label.add_theme_font_size_override("font_size",23)
		label.add_theme_color_override("font_color",Color("2b4036"))
		view.add_child(label)
	for frame in 3: await process_frame
	RenderingServer.force_draw()
	view.get_texture().get_image().save_png("res://output/te-football-preview.png")
	print("PASS: Te's three real football drawings and ball contacts captured")
	quit()
