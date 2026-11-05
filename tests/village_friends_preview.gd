extends SceneTree
## Review actual game sprites and the friends in their authored public places.
var scene: Node2D
class FriendsGallery extends Node2D:
	var friends: Array = []
	func _draw() -> void:
		draw_rect(Rect2(0,0,1500,460),Color("e8dfc8"))
		var font := ThemeDB.fallback_font
		draw_string(font,Vector2(26,38),"OS AMIGOS DO TE E DO JO",HORIZONTAL_ALIGNMENT_LEFT,-1,25,Color("254e49"))
		for i in friends.size():
			var x := 14+i*297
			var box := TejoPerson._box(Color("f6f0df"),8)
			box.border_color = Color("c8c4a8")
			box.set_border_width_all(1)
			draw_style_box(box,Rect2(x,62,285,382))
			draw_string(font,Vector2(x+16,405),friends[i].entry.name,HORIZONTAL_ALIGNMENT_LEFT,250,21,Color("294f49"))
			draw_string(font,Vector2(x+16,430),friends[i].entry.activity,HORIZONTAL_ALIGNMENT_LEFT,250,15,Color("6b7666"))

func _initialize() -> void: call_deferred("run")
func frames(count: int) -> void:
	for i in count: await physics_frame
func capture(actor: CharacterBody2D) -> void:
	scene.camera.zoom = Vector2.ONE*1.1
	scene.camera.position = actor.position+Vector2(0,-70)
	var side := 1.0 if actor.entry.id=="martim" else -1.0
	scene.people[0].position = scene.world.population.free_point(actor.position+Vector2(side*120,75),true)
	scene.people[1].position = scene.world.population.free_point(scene.people[0].position+Vector2(side*120,20),true)
	scene.hud.area_title = scene.world.area_at(actor.position)
	scene.hud.interaction_prompt = ""
	scene.hud.queue_redraw()
	scene.world.interactions.highlight({})
	await process_frame
	await process_frame
	RenderingServer.force_draw()
	root.get_texture().get_image().save_png("res://output/village-friends-"+str(actor.entry.id)+".png")
	print(actor.entry.name," home=",actor.home," area=",scene.world.area_at(actor.home))

func run() -> void:
	scene = load("res://scenes/sintra_village.tscn").instantiate()
	root.add_child(scene)
	await frames(4)
	scene.set_process(false)
	for player in scene.people: player.process_mode = Node.PROCESS_MODE_DISABLED
	scene.day_cycle.minutes = 690
	scene.world.population.synchronize(scene.day_cycle,true)
	scene.daylight.set_shader_parameter("daylight",scene.day_cycle.light_color())
	var friends: Array = scene.world.population.residents.filter(func(actor): return actor.entry.has("friend_of"))
	for actor in friends:
		actor.frame = 0
		actor.facing_left = false
		actor.art.queue_redraw()
		await capture(actor)
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1500,460)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.world_2d = World2D.new()
	root.add_child(viewport)
	var gallery := FriendsGallery.new()
	gallery.friends = friends
	viewport.add_child(gallery)
	for i in friends.size():
		var art := preload("res://scripts/village_resident_art.gd").new()
		art.resident = friends[i]
		art.position = Vector2(156+i*297,378)
		art.scale = Vector2.ONE*1.8
		gallery.add_child(art)
	await process_frame
	await process_frame
	RenderingServer.force_draw()
	viewport.get_texture().get_image().save_png("res://output/village-friends-cast.png")
	viewport.queue_free()
	scene.queue_free()
	await frames(2)
	quit()
