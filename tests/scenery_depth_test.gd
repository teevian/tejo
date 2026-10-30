extends SceneTree
var failed := false
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		push_error(message)
func run() -> void:
	var scene = load("res://scenes/garden.tscn").instantiate()
	root.add_child(scene)
	await physics_frame
	scene.set_process(false)
	for person in scene.people: person.in_dialogue = true
	var world = scene.world
	check(world.scenery_objects.size()>150,"Painted scenery is separated across the original and expanded map")
	var categories := {}
	var checked := 0
	for object in world.scenery_objects:
		categories[object.scenery_kind] = true
		check(object.get_parent()==world.actors and object.z_index==0,"Scenery shares foot sorting with characters: "+object.name)
		for polygon in object.footprints:
			var center := Vector2.ZERO
			for point in polygon: center += point/polygon.size()
			if not Geometry2D.is_point_in_polygon(center,polygon): continue
			check(not world.is_walkable(center,0),"Occupied ground blocks navigation: "+object.name)
			var query := PhysicsPointQueryParameters2D.new()
			query.position = center
			query.collision_mask = 1
			var hits: Array[Dictionary] = world.get_world_2d().direct_space_state.intersect_point(query,32)
			check(hits.any(func(hit): return hit.collider==object),"The same polygon blocks real physics: "+object.name)
			var cell := Vector2i(center/world.CELL)
			if world.navigation.region.has_point(cell):
				var grid_point: Vector2 = world.navigation.get_point_position(cell)
				check(world.navigation.is_point_solid(cell)==not world.is_walkable(grid_point,23),"Navigation matches the physical footprint: "+object.name)
			checked += 1
	check(checked>140 and categories.has("solid_rock") and categories.has("tree_canopy") and categories.has("masonry"),"Rocks, trees and architecture have solid ground volumes")
	# A full player motion must stop at a rock; routing must go around its sides.
	for name_value in ["Terrain2_UpperPair","SisterWest","YellowGranite","CapuchosChapel"]:
		var object: Node2D = world.actors.get_node(name_value)
		var polygon: PackedVector2Array = object.footprints[0]
		var bounds := Rect2(polygon[0],Vector2.ZERO)
		for point in polygon: bounds = bounds.expand(point)
		var start := Vector2(bounds.get_center().x,bounds.end.y+45)
		var goal := Vector2(bounds.get_center().x,bounds.position.y-45)
		var person: CharacterBody2D = scene.people[0]
		person.position = start
		check(person.test_move(person.transform,goal-start),"Actual character cannot cross "+name_value)
		var route: PackedVector2Array = world.find_path(start,goal)
		check(not route.is_empty(),"Companion can route around "+name_value)
		for i in range(1,route.size()): check(world.can_walk_line(route[i-1],route[i]),"Route never cuts a solid corner: "+name_value)
	for entry in [[0,Vector2(.52,.51)],[2,Vector2(.52,.44)],[3,Vector2(.80,.53)],[4,Vector2(.53,.61)]]:
		check(world.is_walkable(world.Heritage.point(entry[0],entry[1]),14),"Authored monument openings stay physically open")
	# Exercise the real follower, including acceleration, steering and move_and_slide.
	var leader: CharacterBody2D = scene.people[0]
	var follower: CharacterBody2D = scene.people[1]
	var route: PackedVector2Array = world.find_path(Vector2(456,2420),Vector2(456,2180))
	check(not route.is_empty(),"Boulder detour has usable endpoints")
	if not route.is_empty():
		leader.position = route[-1]
		follower.position = route[0]
		follower.in_dialogue = false
		follower._finish_phone()
		follower.path.clear()
		follower.route_time = 0
		for i in 420:
			await physics_frame
			if world.scenery_blocks(follower.position,10):
				check(false,"Moving companion never enters a solid footprint")
				break
		check(follower.position.distance_to(leader.position)<125,"Real companion completes the boulder detour")
		follower.in_dialogue = true
	var ponds_before: int = world.wildlife.ponds.size()
	var children_before: int = world.get_child_count()
	for i in 8: world.wildlife._covered_at(Vector2(850,2890),Vector2(850,2780))
	check(world.wildlife.ponds.size()==ponds_before and world.get_child_count()==children_before,"Visibility queries do not create scenery or habitat duplicates")
	if not failed: print("PASS: %d shared physical/navigation footprints, depth categories, solid player motion, companion detours and open monument passages"%checked)
	quit(1 if failed else 0)
