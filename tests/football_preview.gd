extends SceneTree
const Person = preload("res://scripts/open_world_person.gd")
const Prop = preload("res://scripts/discovery_prop.gd")
const Art = preload("res://scripts/football_art.gd")

class Floor extends Node2D:
	const WORLD_SIZE := Vector2(12000,7560)
	var opaque_paint: ShaderMaterial
	func is_walkable(_at: Vector2, _radius := 0.0) -> bool: return true
	func can_walk_line(_from: Vector2, _to: Vector2) -> bool: return true

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	if DisplayServer.get_name()=="headless":
		quit(1)
		return
	var view := SubViewport.new()
	view.size = Vector2i(1050,1080)
	view.world_2d = World2D.new()
	view.disable_3d = true
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(view)
	var bg := ColorRect.new()
	bg.size = Vector2(1050,1080)
	bg.color = Color("a7b29d")
	view.add_child(bg)
	for row in 3:
		for key in 3:
			var floor_node := Floor.new()
			floor_node.opaque_paint = ShaderMaterial.new()
			floor_node.opaque_paint.shader = preload("res://shaders/opaque_cutout.gdshader")
			floor_node.position = Vector2(175+key*350,340+row*355)
			floor_node.scale = Vector2(1.8,1.8)
			view.add_child(floor_node)
			var person := Person.new()
			person.kind = 1
			person.football_action = ["foot","knee","head"][row]
			person.football_variant = key
			person.football_time = 0.1
			floor_node.add_child(person)
			person.set_physics_process(false)
			var point := Art.contact(person.football_action,key)
			var ball := Prop.new()
			ball.kind = 3
			ball.paint_height = 31
			ball.world = floor_node
			ball.position = Vector2(point.x,0)
			floor_node.add_child(ball)
			ball.juggling.height = -point.y
			ball.step_ball(0)
			var label := Label.new()
			label.text = ["Pé","Joelho","Cabeça"][row]+" · "+str(key+1)
			label.position = Vector2(130+key*350,10+row*355)
			label.add_theme_font_size_override("font_size",22)
			label.add_theme_color_override("font_color",Color("2b4036"))
			view.add_child(label)
	for i in 3: await process_frame
	RenderingServer.force_draw()
	view.get_texture().get_image().save_png("res://output/football-contacts-preview.png")
	print("PASS: nine actual Jo football sprites and real ball contact positions captured")
	quit()
