extends SceneTree
const Inventory = preload("res://scripts/inventory.gd")
const ItemArt = preload("res://scripts/item_art.gd")
const Art = preload("res://scripts/open_world_art.gd")
const InteractionArt = preload("res://scripts/interaction_art.gd")
var scene: Node2D
var te: CharacterBody2D
var jo: CharacterBody2D
var failed := false

class ErrorLog:
	extends Logger
	var errors: Array[String] = []
	func _log_error(_function: String, file: String, line: int, code: String, _rationale: String, _editor_notify: bool, _error_type: int, _backtraces: Array[ScriptBacktrace]) -> void:
		errors.append("%s:%d %s"%[file,line,code])

func _initialize() -> void:
	call_deferred("run")
	create_timer(40.0,true,false,true).timeout.connect(func():
		push_error("Interaction checks timed out")
		quit(1))

func check(value: bool, message: String) -> void:
	if not value:
		failed = true
		push_error(message)

func frames(count: int) -> void:
	for i in count:
		await physics_frame

func space() -> void:
	var event := InputEventKey.new()
	event.physical_keycode = KEY_SPACE
	event.pressed = true
	root.push_input(event)
	event = event.duplicate()
	event.pressed = false
	root.push_input(event)

func place(a: Vector2, b: Vector2) -> void:
	for person in scene.people:
		person.stand_up()
		person.cancel_shoulder()
		person._finish_phone()
		person.collecting_time = 0
		person.queued_jump.clear()
		person.velocity = Vector2.ZERO
		person.moving = false
		person.path.clear()
		person.in_dialogue = false
	te.position = a
	jo.position = b

func approach(kind: String) -> Dictionary:
	for target in scene.world.interactions.targets:
		if target.kind!=kind:
			continue
		for step in 12:
			var at: Vector2 = target.position+Vector2.from_angle(float(step)*TAU/12.0)*(float(target.radius)+45)
			if not scene.world.is_walkable(at,14):
				continue
			place(at,at+Vector2(-80,60))
			te.facing = at.direction_to(target.position)
			await frames(2)
			var nearest: Dictionary = scene.world.interactions.nearest(te)
			if nearest.get("id")==target.id:
				return target
	check(false,"Could not approach a reachable "+kind)
	return {}

func run() -> void:
	var logger := ErrorLog.new()
	OS.add_logger(logger)
	for weights in [[1,1,1,1,1],[2,2,1],[3,2],[3,1,1]]:
		var inventory := Inventory.new()
		for porte in weights:
			check(inventory.try_add({"name":"Test","porte":porte}),"A legal load must fit")
		check(inventory.used_porte()==5,"Capacity is the sum of porte, not a four-slot limit")
		check(not inventory.try_add({"porte":1}),"A full inventory must reject another object")
		check(not inventory.try_add({"porte":0}) and not inventory.try_add({"porte":4}),"Item porte must be between one and three")
		inventory.take(0)
		check(inventory.used_porte()<5,"Removing an object must release capacity")
	scene = load("res://scenes/garden.tscn").instantiate()
	root.add_child(scene)
	te = scene.people[0]
	jo = scene.people[1]
	await frames(3)
	var manager = scene.world.interactions
	check(scene.inventory_panel.entries.slice(0,5).all(func(entry):return entry.visible) and scene.inventory_panel.entries.slice(5,10).all(func(entry):return not entry.visible),"Only Te's selected inventory must be visible")
	for target in manager.targets:
		if target.kind=="bench":
			var width: float = target.node.sprite.region_rect.size.x*target.node.sprite.scale.x
			var body_width: float = Art.TE[0].size.x/Art.TE[0].size.y*Art.HEIGHTS[0]
			check(width>body_width*2+30,"The bench must be wide enough for two adult bodies and space between them")
			check(target.node.seat_offsets.size()==2,"Every bench must expose exactly two places")
			for slot in 2:
				check(scene.world.is_walkable(target.node.seat_position(slot),14),"Both places on every bench must be clear of rocks and collisions")
	for prop in scene.world.props:
		var kind: int = prop.get_meta("kind")
		if kind<2:
			check(prop.height>Art.HEIGHTS[0]*3 and prop.height<Art.HEIGHTS[0]*8,"Trees must follow a consistent scale relative to people")
		elif kind==2:
			check(prop.height<Art.HEIGHTS[0]*0.9,"Low vegetation must not be taller than a character")
	var pickup: Dictionary = manager.targets.filter(func(t):return t.kind=="pickup")[0]
	place(pickup.position+Vector2(-30,0),pickup.position+Vector2(-100,15))
	await frames(2)
	space()
	check(te.inventory.items.size()==1 and jo.inventory.items.is_empty(),"Space must put an object only in the selected character's bag")
	check(not pickup.node.visible,"A collected object must disappear from the ground")
	space()
	check(te.inventory.items.size()==1,"Repeated input must not duplicate a pickup")
	await frames(40)
	var item_id: String = te.inventory.items[0].id
	scene.inventory_panel.entries[0].pressed.emit()
	check(te.inventory.items.is_empty(),"Clicking a bag item must drop it")
	var dropped: Dictionary = manager.targets[-1]
	check(dropped.node.visible and dropped.item.id==item_id,"Dropped objects retain their identity and can be found again")
	scene._select_person(1)
	check(scene.inventory_panel.entries.slice(0,5).all(func(entry):return not entry.visible) and scene.inventory_panel.entries.slice(5,10).all(func(entry):return entry.visible),"Switching to Jo must replace Te's inventory with Jo's")
	place(dropped.position+Vector2(-100,20),dropped.position+Vector2(-25,0))
	await frames(2)
	space()
	check(jo.inventory.items.size()==1 and jo.inventory.items[0].id==item_id and te.inventory.items.is_empty(),"The other character can pick up a dropped object")
	await frames(40)
	scene.inventory_panel.entries[5].pressed.emit()
	check(jo.inventory.items.is_empty() and te.inventory.items.is_empty(),"Jo's inventory buttons must address Jo's bag")
	scene._select_person(0)
	te.inventory.try_add(ItemArt.ITEMS[4])
	te.inventory.try_add(ItemArt.ITEMS[2])
	var extra: Dictionary = manager.spawn_pickup(ItemArt.ITEMS[0],Vector2(850,3000))
	place(Vector2(820,3000),Vector2(740,3020))
	await frames(2)
	space()
	check(te.inventory.used_porte()==5 and extra.node.visible,"Full bags must leave the object in the world")
	te.inventory.take(1)
	space()
	check(te.inventory.used_porte()==4 and not extra.node.visible,"Freeing capacity allows the pickup")
	await frames(40)
	for target in manager.targets:
		if target.kind=="pickup":
			target.node.hide()
	for kind in ["tree","rock","fern","fountain","ruin"]:
		var target: Dictionary = await approach(kind)
		if target.is_empty():
			continue
		space()
		var flag: String = {"tree":"examined_tree","rock":"examined_rock","fern":"examined_ferns","fountain":"fountain_water","ruin":"ruins_examined"}[kind]
		check(scene.dialogue.flags.get(flag,false),"Interaction must register discovery: "+kind)
		if kind=="tree":
			check(target.get("gift_given",false) and manager.targets[-1].kind=="pickup","Examining a tree reveals a collectible pine cone")
			manager.targets[-1].node.hide()
			var count: int = manager.targets.size()
			space()
			check(manager.targets.size()==count,"A tree must not create infinite objects")
		await frames(45)
	var bench: Dictionary = await approach("bench")
	jo.position = manager.find_drop_position(bench.position+Vector2(-330,140))
	space()
	check(scene._camera_target().distance_to(te.position-Vector2(0,Art.HEIGHTS[0]*0.52))<150,"The camera must stay with the player while a distant companion approaches the bench")
	await frames(300)
	check(te.seated and jo.seated and te.seat_id==bench.get("id") and jo.seat_id==bench.get("id"),"Both characters must walk to the same bench and sit")
	check(te.seat_slot!=jo.seat_slot and te.position.distance_to(jo.position)>85,"A bench must provide two distinct places without overlap")
	check(scene.world.is_walkable(te.position,12),"Seating must leave the feet on clear ground")
	check(scene.world.is_walkable(jo.position,12),"The second seat must also leave feet on clear ground")
	for person in scene.people:
		var effective_height: float = InteractionArt.SEATED[person.kind].size.y*InteractionArt.SCALE-person.body.position.y
		check(effective_height<Art.HEIGHTS[person.kind]*0.9,"Sitting must lower the head relative to standing")
	scene._select_person(1)
	check(te.seated and jo.seated,"Switching selection must preserve both seats")
	space()
	check(not te.seated and not jo.seated and not te.seating and not jo.seating,"Space must stand both characters up")
	scene._select_person(0)
	space()
	await frames(120)
	check(te.seated and jo.seated,"The two places can be used again")
	space()
	check(not te.seated and not te.seating and not jo.seated and not jo.seating,"Space must stand the pair up again")
	space()
	await frames(120)
	Input.action_press("walk_left")
	await frames(4)
	Input.action_release("walk_left")
	check(not te.seated and not te.seating and not jo.seated and not jo.seating,"Movement must stand both up and respond immediately")
	# Idle behaviour mirrors Jo's seven-second phone delay.
	place(Vector2(770,2920),Vector2(850,2890))
	scene._select_person(1)
	await frames(540)
	check(te.shoulder_state==te.ShoulderState.TOUCHING,"Te must approach idle Jo and put a hand on his shoulder")
	check(te.position.distance_to(te.shoulder_goal)<7 and not te.moving,"The shoulder gesture must settle at contact")
	check(jo.phone_state==jo.PhoneState.NONE,"Selected Jo must not use his phone during the gesture")
	scene._toggle_pause()
	var held := te.position
	await frames(15)
	check(te.position==held,"Pause must freeze the shoulder gesture")
	scene._toggle_pause()
	Input.action_press("walk_up")
	await frames(3)
	Input.action_release("walk_up")
	check(te.shoulder_state==te.ShoulderState.NONE,"Jo's movement must cancel the gesture")
	place(Vector2(770,2920),Vector2(850,2890))
	te.shoulder_idle_time = 7
	await frames(100)
	check(te.shoulder_state==te.ShoulderState.TOUCHING,"The gesture can restart after another quiet wait")
	scene._select_person(0)
	check(te.shoulder_state==te.ShoulderState.NONE,"Selecting Te must cancel the idle gesture")
	# Broad water is inspected; only the narrow southern stream can be jumped.
	var center: float = scene.world.river_x(1700)
	place(Vector2(center-165,1700),Vector2(center-245,1700))
	await frames(3)
	space()
	check(not te.jumping,"Wide river sections must not be jumpable")
	center = scene.world.river_x(3900)
	place(Vector2(center-190,3900),Vector2(center-270,3900))
	await frames(3)
	check(not manager.river_target(te).get("can_jump",false),"A narrow stream must still require a nearby launch point")
	place(Vector2(center-110,3900),Vector2(center-190,3900))
	await frames(3)
	check(manager.nearest(te).get("kind")=="river","The narrow bank must offer a river interaction")
	var landing: Vector2 = manager.river_target(te).landing
	scene.world.blocked_rects.append(Rect2(landing-Vector2(25,25),Vector2(50,50)))
	space()
	check(not te.jumping,"A blocked landing must reject the jump")
	scene.world.blocked_rects.pop_back()
	space()
	check(te.jumping,"Space must start a narrow-river jump")
	await frames(22)
	check(te.jumping and te.body.position.y < -30,"The jump must visibly rise above the water")
	await frames(28)
	check(not te.jumping and te.position.x>center and not scene.world.in_water(te.position,12),"A jump must land on a clear opposite bank")
	await frames(180)
	check(not jo.jumping and jo.position.x>center and not scene.world.in_water(jo.position,12),"The companion must follow the same crossing")
	check(te.position.distance_to(jo.position)>35,"Companions must not stack on the same landing point")
	scene._select_person(1)
	jo.facing = Vector2.LEFT
	space()
	check(jo.jumping,"Jo must be able to lead a jump in the opposite direction")
	await frames(240)
	check(not jo.jumping and jo.position.x<scene.world.river_x(jo.position.y) and not scene.world.in_water(jo.position,12),"Jo's return jump must land on the other bank")
	check(not te.jumping and te.position.x<scene.world.river_x(te.position.y) and not scene.world.in_water(te.position,12),"Te must follow Jo's return jump")
	scene._select_person(0)
	# Paused, map and dialogue inputs cannot mutate inventories or start actions.
	var size_before: int = te.inventory.items.size()
	scene._toggle_pause()
	space()
	scene.inventory_panel.entries[0].pressed.emit()
	check(te.inventory.items.size()==size_before,"Paused input must not drop or collect objects")
	scene._toggle_pause()
	scene._toggle_map()
	space()
	check(te.inventory.items.size()==size_before and not te.jumping,"Map input must not trigger world interactions")
	scene._toggle_map()
	scene._talk()
	space()
	check(te.inventory.items.size()==size_before and scene.dialogue.is_active(),"Dialogue must block world interactions")
	scene.dialogue.cancel()
	OS.remove_logger(logger)
	check(logger.errors.is_empty(),"Runtime errors: "+str(logger.errors))
	if not failed:
		print("PASS: coherent scales, two-seat benches and paired approach/stand, distant companion/camera, inventory, world interactions, shoulder idle, safe jumps, modal input blocking")
	quit(1 if failed else 0)
