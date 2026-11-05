extends SceneTree
var scene: Node2D
class CastGallery extends Node2D:
	var residents: Array = []
	func _draw() -> void:
		draw_rect(Rect2(0,0,1680,1516),Color("e8dfc8"))
		var font := ThemeDB.fallback_font
		draw_string(font,Vector2(28,40),"%d PESSOAS NA VILA DE SINTRA"%residents.size(),HORIZONTAL_ALIGNMENT_LEFT,-1,26,Color("254e49"))
		draw_string(font,Vector2(28,64),"Moradores, visitantes e participações fictícias · Personagens e atividades do jogo",HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("657467"))
		for i in residents.size():
			var x := 18+(i%6)*276
			var y := 85+(i/6)*236
			var box := TejoPerson._box(Color("f6f0df"),8)
			box.border_color = Color("c8c4a8")
			box.set_border_width_all(1)
			draw_style_box(box,Rect2(x,y,264,226))
			draw_string(font,Vector2(x+12,y+200),residents[i].entry.name,HORIZONTAL_ALIGNMENT_LEFT,244,15,Color("294f49"))
			draw_string(font,Vector2(x+12,y+218),residents[i].entry.activity,HORIZONTAL_ALIGNMENT_LEFT,244,12,Color("6b7666"))
func _initialize() -> void: call_deferred("run")
func frames(count: int) -> void:
	for i in count: await physics_frame
func capture(name: String, at: Vector2, zoom := 1.0) -> void:
	scene.camera.zoom = Vector2.ONE*zoom
	scene.camera.position = at
	scene.people[0].position = scene.world.population.free_point(at+Vector2(-40,180),true)
	scene.people[1].position = scene.world.population.free_point(scene.people[0].position+Vector2(-120,20),true)
	scene.hud.area_title = scene.world.area_at(scene.people[0].position)
	scene.hud.interaction_prompt = ""
	scene.hud.queue_redraw()
	scene.world.interactions.highlight({})
	await process_frame
	await process_frame
	RenderingServer.force_draw()
	root.get_texture().get_image().save_png("res://output/village-people-"+name+".png")
func run() -> void:
	scene = load("res://scenes/sintra_village.tscn").instantiate()
	root.add_child(scene)
	await frames(4)
	scene.set_process(false)
	for player in scene.people: player.process_mode = Node.PROCESS_MODE_DISABLED
	scene.day_cycle.minutes = 690
	scene.world.population.synchronize(scene.day_cycle,true)
	scene.daylight.set_shader_parameter("daylight",scene.day_cycle.light_color())
	for actor in scene.world.population.residents:
		actor.frame = 0
		actor.art.queue_redraw()
	await capture("palace",Vector2(9800,2330))
	await capture("market",Vector2(11850,7800),.8)
	await capture("families",Vector2(9400,3370))
	await capture("patio",Vector2(18200,12970))
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1680,1516)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.world_2d = World2D.new()
	root.add_child(viewport)
	var gallery := CastGallery.new()
	gallery.residents = scene.world.population.residents
	viewport.add_child(gallery)
	for i in gallery.residents.size():
		var actor: CharacterBody2D = gallery.residents[i]
		actor.facing_left = false
		var art := preload("res://scripts/village_resident_art.gd").new()
		art.resident = actor
		art.position = Vector2(150+(i%6)*276,265+(i/6)*236)
		gallery.add_child(art)
	await process_frame
	await process_frame
	RenderingServer.force_draw()
	viewport.get_texture().get_image().save_png("res://output/village-people-cast.png")
	viewport.queue_free()
	scene.queue_free()
	await frames(2)
	quit()
