extends SceneTree
var scene: Node2D
var failed := false
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok: failed = true; push_error(message)
func frames(count: int) -> void:
	for i in count: await physics_frame
func walk_vertical(y: float, upwards: bool) -> void:
	var action := "walk_up" if upwards else "walk_down"
	Input.action_press(action)
	for tick in 400:
		await physics_frame
		if (scene.people[0].position.y<y if upwards else scene.people[0].position.y>y): break
	Input.action_release(action)
	await frames(8)
func run() -> void:
	scene = load("res://scenes/sintra_village.tscn").instantiate()
	root.add_child(scene)
	await frames(3)
	scene.set_process(false)
	for player in scene.people: player.idle_delay = 10000
	var world: Node2D = scene.world
	check(world.routes.all(func(route): return route.surface!="steps"),"All old crossing stair textures have been removed")
	check(world.find_children("StoneFlight*","",true,false).is_empty(),"No legacy endlessly tiled stair strips survive")
	var sampled := 0
	for area in world.urban_floor:
		for x in range(int(area.position.x)+64,int(area.end.x)-64,128):
			for y in range(int(area.position.y)+64,int(area.end.y)-64,128):
				var at := Vector2(x,y)
				if world.garden_floor.any(func(garden): return garden.has_point(at)): continue
				check(world._on_ground(at),"Every visibly paved urban courtyard belongs to the walking floor")
				if world.blocked_rects.any(func(rect): return rect.has_point(at)): continue
				if world.circles.any(func(c): return at.distance_to(Vector2(c.x,c.y))<c.z): continue
				check(world.is_walkable(at,0),"Stone cannot block movement merely because it is a different paving texture")
				sampled += 1
	check(sampled>5000,"Walkability audit covers the formerly blocked paved blocks")
	var sides: Array = world.buildings.filter(func(building): return building.has_meta("side_facing"))
	check(sides.size()>100,"The town includes many genuinely side-facing buildings")
	check(sides.any(func(b): return b.get_meta("side_facing")=="left") and sides.any(func(b): return b.get_meta("side_facing")=="right"),"Side buildings face both sides of streets")
	check(sides.any(func(b): return b.label=="Habitação") and sides.any(func(b): return b.label=="Café") and sides.any(func(b): return b.label=="Padaria"),"Side elevations include homes, apartments and shops")
	var specs: Array = world.TERRACES.data.terraces
	check(specs.size()==4,"Exactly four intentional, short stair courts replace the old stair network")
	for spec in specs:
		var platform: Rect2 = world._rect(spec.platform)
		var stairs: Rect2 = world.stair_rect(spec)
		var low := Vector2(stairs.get_center().x,stairs.end.y+60)
		var high := Vector2(stairs.get_center().x,platform.end.y-70)
		check(world.is_walkable(low,14) and world.is_walkable(high,14),"Both landings are usable: "+spec.id)
		check(not world.find_path(low,high).is_empty(),"Real navigation crosses the flight: "+spec.id)
		check(world.elevation_at(low)==0 and world.elevation_at(high)==spec.rise,"Each flight connects two different levels: "+spec.id)
		var previous := 0.0
		for i in range(1,10):
			var at := low.lerp(high,i/10.0)
			var elevation: float = world.elevation_at(at)
			check(elevation>=previous,"Elevation rises continuously through the flight: "+spec.id)
			previous = elevation
		for other in specs:
			if other.id!=spec.id: check(not world.terrace_bounds(spec).intersects(world.terrace_bounds(other)),"New stairs do not cross each other")
		scene.people[0].position = low
		scene.people[1].position = low+Vector2(-85,25)
		for player in scene.people:
			player.stand_up(true)
			player.velocity = Vector2.ZERO
			player.path.clear()
		await walk_vertical(high.y,true)
		check(world.elevation_at(scene.people[0].position)==spec.rise,"Te actually climbs the steps using movement input: "+spec.id)
		await frames(90)
		check(scene.people[1].position.distance_to(scene.people[0].position)<200,"Jo can follow the stair flight: "+spec.id)
		await walk_vertical(low.y,false)
		check(world.elevation_at(scene.people[0].position)==0,"Te can descend to the lower landing: "+spec.id)
	scene.queue_free()
	await frames(3)
	if not failed: print("PASS: all urban stone walkable, %d side-facing buildings, no old stair strips, four bounded non-crossing flights with real ascent/descent and companion access"%sides.size())
	quit(1 if failed else 0)
