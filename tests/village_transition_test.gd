extends SceneTree
var garden: Node2D
var failed := false
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		push_error(message)
func frames(n: int) -> void:
	for i in n: await physics_frame
func run() -> void:
	garden = load("res://scenes/garden.tscn").instantiate()
	root.add_child(garden)
	await frames(3)
	var forest: Node2D = garden.world
	var persons: Array = garden.people.duplicate()
	garden._select_person(1)
	garden.people[0].inventory.try_add(preload("res://scripts/item_art.gd").ITEMS[0])
	garden.dialogue.flags["session_sentinel"] = true
	garden.day_cycle.minutes = 1439
	garden.day_cycle.day = 8
	garden.day_cycle.minutes_per_second = 60
	garden.exploration_map.explored[Vector2i(90,80)] = true
	var forest_pickups: int = forest.interactions.targets.size()
	garden.people[1].position = garden.region_sign.position+Vector2(0,40)
	garden.people[0].position = garden.region_sign.position+Vector2(80,60)
	garden._interact()
	check(garden.region_id=="village","A normal trailhead interaction opens the village")
	var village: Node2D = garden.world
	check(village!=forest and not forest.visible and forest.process_mode==Node.PROCESS_MODE_DISABLED,"Inactive forest is retained and suspended")
	check(garden.people==persons and garden.selected==1,"The exact people and selection cross regions")
	check(garden.people[0].inventory.items.size()==1 and garden.dialogue.flags.session_sentinel,"Bags and narrative effects cross regions")
	await frames(5)
	# Disabled retained regions must leave the shared physics space as well.
	for prop in forest.props.slice(0,12):
		var query := PhysicsPointQueryParameters2D.new()
		query.position = prop.position
		query.collision_mask = 1
		var hits: Array = village.get_world_2d().direct_space_state.intersect_point(query)
		check(not hits.any(func(hit): return forest.is_ancestor_of(hit.collider)),"Inactive forest bases cannot collide inside the town")
	check(garden.day_cycle.day==9 and garden.day_cycle.minutes<100,"The same clock crosses midnight in the village")
	check(garden.hud.region_title=="Vila de Sintra" and garden.scene_id=="sintra_village","HUD and dialogue use the active region")
	# A collected and a dropped item remain in their owning region across revisits.
	var target: Dictionary = village.interactions.targets.filter(func(t): return t.kind=="pickup")[0]
	check(target.item.id.begins_with("village_"),"Town pickup identities have their own namespace")
	target.node.hide()
	village.interactions._discover("village_test_discovery")
	village.interactions.spawn_pickup(preload("res://scripts/item_art.gd").ITEMS[1],village._point(village.LAYOUT.data.earth_test))
	var village_targets: int = village.interactions.targets.size()
	garden.exploration_map.explored[Vector2i(35,38)] = true
	var forest_animal: Vector2 = forest.wildlife.animals[0].position
	await frames(5)
	check(forest.wildlife.animals[0].position==forest_animal,"Inactive forest fauna remain frozen")
	for repeat in 3:
		check(garden._travel_region("forest"),"Return transition succeeds")
		await frames(2)
		check(garden.world==forest and forest.visible and not village.visible,"Return restores the original forest instance")
		check(garden.exploration_map.explored.has(Vector2i(90,80)),"Forest discovery map survives visits")
		check(forest.interactions.targets.size()==forest_pickups,"Forest pickups and encounters are not duplicated")
		for person in garden.people:
			check(forest.is_walkable(person.position,14),"Both return positions are safe in the forest")
		check(garden._travel_region("village"),"Repeated village entrance succeeds")
		await frames(2)
		check(garden.world==village and village.interactions.targets.size()==village_targets and not target.node.visible,"Town items retain their collected/dropped state")
		check(garden.exploration_map.explored.has(Vector2i(35,38)) and garden.dialogue.flags.village_test_discovery,"Town exploration and narrative discoveries survive visits")
		for person in garden.people:
			check(village.is_walkable(person.position,14),"Both return positions are safe in the village")
	check(garden.selected==1 and garden.people[0].inventory.items.size()==1,"Selection and bags survive repeated visits")
	garden._travel_region("forest")
	var before_menu: Vector2 = garden.people[0].position
	garden._toggle_pause()
	check(garden.village_button.visible,"Escape menu exposes village travel")
	garden.village_button.pressed.emit()
	await frames(2)
	check(garden.region_id=="village" and not paused and not garden.village_button.visible,"Menu opens a playable village and dismisses pause")
	garden._toggle_pause()
	check(garden.village_button.text=="Regressar à Serra de Sintra","Village menu offers return to the forest")
	garden.village_button.pressed.emit()
	await frames(2)
	check(garden.region_id=="forest" and not paused and garden.people[0].position.distance_to(before_menu)<30,"Menu return preserves the forest departure position")
	# The original climbing transition still works after multiple region visits.
	garden._enter_climbing()
	check(is_instance_valid(garden.climbing_scene) and not garden.visible,"Climbing still opens from the restored forest")
	garden.climbing_scene.leave()
	await frames(2)
	check(garden.visible and garden.world==forest and garden.camera.is_current(),"Climbing returns to the active forest camera")
	garden.queue_free()
	await frames(3)
	if not failed: print("PASS: normal/repeated travel, same people/bags/selection/director/clock, midnight, independent map/items, suspended fauna, safe returns and climbing")
	quit(1 if failed else 0)
