extends SceneTree
const Catalog = preload("res://scripts/bakery_catalog.gd")
var failed := false
var scene: Node2D
func _initialize() -> void:
	create_timer(180,true,false,true).timeout.connect(func():push_error("Chestnut test timeout");quit(2))
	call_deferred("run")
func check(ok: bool,message: String) -> void:
	if not ok: failed = true; push_error(message)
func approach() -> void:
	for i in 2: scene.people[i].position = scene.world.population.free_point(scene.world.chestnuts.position+Vector2(-50+i*105,110),true)
func run() -> void:
	scene = load("res://scenes/sintra_village.tscn").instantiate(); root.add_child(scene)
	for i in 4: await physics_frame
	scene.set_process(false)
	for person in scene.people: person.set_physics_process(false); person.inventory.items.clear()
	var j: Node2D = scene.journey; var stall: Node2D = scene.world.chestnuts
	var te: CharacterBody2D = scene.people[0]; var jo: CharacterBody2D = scene.people[1]
	check(not j.storage_enabled,"Never touch the player's saved game")
	check(stall.position.distance_to(scene.world.bakery.position)>3000,"Chestnut stall belongs to a different part of town")
	check(not scene.world.is_walkable(stall.position-Vector2(0,20),1),"Cart has a real obstacle baked into navigation")
	check(scene.world.landmarks.any(func(p):return p.id=="chestnuts_parque"),"Stall can be discovered on the map")
	approach(); scene.day_cycle.minutes = 960; j.coins = 2400
	for p in scene.people:
		check(p.position.distance_to(stall.position)<185 and scene.world.is_walkable(p.position,18),"Both buyers can stand on clear accessible ground")
		check(scene.world.interactions._reachable(p,{"position":stall.position,"radius":0.0,"kind":"street_scene","node":stall}),"Stall can be reached without buying through walls")
	var path: PackedVector2Array = scene.world.find_path(te.position,scene.world.population.free_point(stall.position+Vector2(0,380),true))
	check(not path.is_empty(),"The cart leaves an actual navigable approach through the park")
	stall.interact(te); check(j.panel.opened and te.in_dialogue,"Actual world interaction opens the choice menu")
	j.panel.choose(0)
	check(te.inventory.items.size()==1 and te.inventory.items[0].type=="chestnuts_roasted" and j.coins==2150,"Buying plain chestnuts through the real menu debits exactly 2.50 euros")
	check(not j.panel.opened and not te.in_dialogue,"Buying returns control to the player")
	check(Catalog.food(te.inventory.items[0]) and Catalog.nutrition(te.inventory.items[0])==28,"Plain chestnuts use the shared food system")
	var id: String = te.inventory.items[0].id
	for i in 4: te.inventory.try_add({"type":"pebble","name":"Pedrinha","porte":1,"art":0})
	stall.interact(te); j.panel.choose(2)
	check(te.inventory.items.size()==5 and te.inventory.items[0].butter and te.inventory.items[0].id==id and j.coins==2120,"Butter upgrades an existing portion, even with a full bag, for exactly 30 cents")
	stall.add_butter(j,0,id); check(j.coins==2120,"The same portion cannot be buttered and charged twice")
	stall.buy(j,0,false); check(j.coins==2120 and te.inventory.items.size()==5,"Full bag prevents a purchase without charging")
	te.inventory.items.clear(); stall.interact(jo); j.panel.choose(1)
	check(jo.inventory.items.size()==1 and jo.inventory.items[0].type=="chestnuts_butter" and j.coins==1840,"Jo can buy the buttered variant directly for 2.80 euros")
	j.needs[0].hunger = 60; j.needs[1].hunger = 80; j.bond = 0; j.awarded.clear(); j.daily.clear()
	j.consume(1,0,2)
	check(jo.inventory.items.is_empty() and j.needs[0].hunger==44 and j.needs[1].hunger==64 and j.bond==2,"Sharing consumes one buttered portion, feeds both and increases bonding")
	stall.buy(j,0,false); j.consume(0,0,0)
	check(te.inventory.items.is_empty() and j.needs[0].hunger==16,"Eating plain chestnuts only feeds the eater")
	j.coins = 0; stall.buy(j,0,true)
	check(j.coins==0 and te.inventory.items.is_empty(),"Insufficient funds cannot produce a free portion")
	j.coins = 1000; stall.buy(j,0,false); id = te.inventory.items[0].id; j.coins = 29
	stall.add_butter(j,0,id)
	check(j.coins==29 and not te.inventory.items[0].butter,"Insufficient funds cannot add free butter")
	j.coins = 1000; stall.interact(te); scene.day_cycle.minutes = 1320; j.panel.choose(1)
	check(j.coins==1000 and te.inventory.items.size()==1,"Closing time is rechecked after the menu was opened")
	stall.step(0,scene.day_cycle); check(stall.frame==2,"Closed stall shows the covered cart without a vendor or lit brazier")
	stall.add_butter(j,0,id); check(j.coins==1000 and not te.inventory.items[0].butter,"Butter is unavailable after closing too")
	scene.day_cycle.minutes = 960; te.position += Vector2(1800,0)
	stall.buy(j,0,true); stall.add_butter(j,0,id)
	check(j.coins==1000 and te.inventory.items.size()==1 and not te.inventory.items[0].butter,"Old menus cannot buy or add butter remotely")
	approach(); stall.add_butter(j,0,id)
	var data: Dictionary = JSON.parse_string(JSON.stringify(j.snapshot()))
	te.inventory.items.clear(); j.restore(data)
	check(te.inventory.items.size()==1 and te.inventory.items[0].butter and te.inventory.items[0].id==id and Catalog.nutrition(te.inventory.items[0])==32,"Saving and restoring preserves the butter variant, identity and satiety")
	stall.step(0,scene.day_cycle); check(stall.frame==1,"Actual purchases switch the vendor into the serving pose")
	stall.step(4,scene.day_cycle); check(stall.frame in [0,1],"Open cart resumes its roasting and serving poses")
	print("Chestnut stall position: ",stall.position)
	scene.queue_free()
	for i in 8: await physics_frame
	if not failed: print("PASS: park access, real menu purchases, butter upgrade, atomic pricing, food/sharing, opening hours and saved portions")
	quit(1 if failed else 0)
