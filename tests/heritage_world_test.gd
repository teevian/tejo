extends SceneTree
var failed := false
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		push_error(message)
func run() -> void:
	var scene = load("res://scenes/garden.tscn").instantiate()
	root.add_child(scene)
	await physics_frame
	scene.set_process(false)
	var world = scene.world
	check(world.WORLD_SIZE.x*world.WORLD_SIZE.y==8400*5400*2,"Exactly twice the previous map area")
	var sites: Array[Dictionary] = world.Heritage.landmarks()
	for i in sites.size():
		var place: Dictionary = sites[i]
		for j in range(i+1,sites.size()):
			check(place.position.distance_to(sites[j].position)>2400,"Sites are separated by substantial exploration: "+place.id)
		check(world.is_walkable(place.position,23),"Walkable approach: "+place.id)
		var path: PackedVector2Array = world.find_path(Vector2(850,2890),place.position)
		check(not path.is_empty(),"Reachable from original entrance: "+place.id)
		for step in path: check(world.is_walkable(step,23),"No collision in route: "+place.id)
		var density: Vector2 = world.Heritage.TEXTURES[i].get_size()/world.Heritage.site_size(i)
		check(density.x>=.60 and density.y>=.60,"Native painted detail matches original 1448/2400 density: "+place.id)
		scene.people[0].position = place.position
		scene.people[1].position = place.position+Vector2(60,0)
		scene.exploration_map.record_positions()
		check(scene.exploration_map.discovered.has(place.id),"Discovery: "+place.id)
		scene._talk()
		check(scene.dialogue.active_topic.id==place.id+"_heritage","Local conversation: "+place.id)
		scene.dialogue.cancel()
	for column in [5500,7800,10400]:
		var resident := 0
		var flora := 0
		for animal in world.wildlife.animals:
			if absf(animal.position.x-column)<1600: resident += 1
		for prop in world.props:
			if absf(prop.position.x-column)<1600: flora += 1
		check(resident>8 and flora>30,"New regions have resident fauna and flora")
	for pool in world.pool_areas:
		check(world.in_water(pool.get_center()),"Painted pools block navigation")
	check(world.find_path(Vector2(850,2890),Vector2(11000,7300)).size()>0,"Far southeast remains reachable")
	check(world.is_walkable(world.Heritage.point(0,Vector2(.52,.51))),"Gap between sister rocks stays open")
	check(world.is_walkable(world.Heritage.point(2,Vector2(.52,.44))),"Adrenunes passage stays open")
	check(world.is_walkable(world.Heritage.point(3,Vector2(.80,.53))),"Capuchos porch stays open")
	check(world.is_walkable(world.Heritage.point(4,Vector2(.53,.61))),"Monge entrance stays open")
	if not failed: print("PASS: doubled area, dispersed sites, native density, resident wildlife/flora, safe routes, discovery and open entrances")
	quit(1 if failed else 0)
