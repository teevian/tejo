extends Node2D
## A bounded, persistent population. Decisions are staggered; animation stays smooth.
const Animal = preload("res://scripts/wildlife_animal.gd")
const HabitatArt = preload("res://scripts/wildlife_habitat.gd")
const NocturnalAnimal = preload("res://scripts/nocturnal_animal.gd")
var world: Node2D
var day_cycle: RefCounted
var animals: Array = []
var trees: Array[Dictionary] = []
var ponds: Array[Dictionary] = []
var flowers: Array[Vector2] = []
var rng := RandomNumberGenerator.new()
var elapsed := 0.0
var hollows: Dictionary = {}
var occlusion_images: Dictionary = {}
var colonies: Array[Dictionary] = []
var firefly_patches: Array[Dictionary] = []
var night_glow: Node2D
var events := {"flights":0,"escapes":0,"hunts":0,"drinks":0,"dives":0,"emerges":0,"hides":0,"fox_bounds":0,"watches":0,"startles":0,"bat_groups":0,"bat_hunts":0,"owl_flights":0,"owl_hunts":0,"aerial_escapes":0,"insect_escapes":0,"owl_glints":0,"snake_hunts":0,"snake_escapes":0}

func _ready() -> void:
	name = "WildlifeEcosystem"
	rng.seed = 29102673
	for prop in world.props:
		if int(prop.get_meta("kind")) > 1:
			continue
		var foot: Vector2 = prop.position + Vector2(0,42)
		if not world.is_walkable(foot,8):
			continue
		# Owl talons sit on authored wood pixels, rather than an approximate canopy height.
		var branch_pixel := Vector2(305,468) if int(prop.get_meta("kind"))==0 else Vector2(340,265)
		var owl_perch: Vector2 = prop.sprite.position+branch_pixel*prop.sprite.scale
		trees.append({"node":prop,"foot":foot,"perch":Vector2(28,-prop.height*0.58),"owl_perch":owl_perch,"hollow":Vector2(0,-78)})
	# Quiet river edges, away from bridge decks. Leaves sit in the actual water.
	for y in [510.0,1360.0,1680.0,1960.0,2640.0,3030.0,3330.0,3910.0,4700.0,5070.0]:
		for side in [-1.0,1.0]:
			var width := 75.0 if y>3600 else 130.0
			var bank := Vector2(world.river_x(y)+side*(width+28),y)
			if not world.is_walkable(bank,8):
				continue
			var leaf := Vector2(world.river_x(y)+side*(width-55),y+12)
			ponds.append({"bank":bank,"leaf":leaf})
			flowers.append(bank+Vector2(side*25,40))
			var patch := HabitatArt.new()
			patch.kind = "leaf"
			patch.position = leaf
			patch.z_index = -6
			world.add_child(patch)
	for pool in world.pool_areas:
		for side in [-1.0,1.0]:
			var bank: Vector2 = pool.get_center()+Vector2(side*(pool.size.x*.5+34),0)
			var leaf: Vector2 = pool.get_center()+Vector2(side*(pool.size.x*.5-45),0)
			if not world.is_walkable(bank,10): continue
			ponds.append({"bank":bank,"leaf":leaf})
			flowers.append(bank+Vector2(0,65))
			var patch := HabitatArt.new()
			patch.position = leaf
			patch.z_index = -6
			world.add_child(patch)
	for plant in world.low_foliage:
		if rng.randf()<0.35:
			flowers.append(plant.position)
	# Ensure the first clearing already has a small, unforced community.
	flowers.append_array([Vector2(680,2820),Vector2(1170,3030),Vector2(920,2640)])
	flowers.append_array(world.discovery_flowers)
	for at in flowers:
		var bloom := HabitatArt.new()
		bloom.kind = "flowers"
		bloom.position = at
		world.actors.add_child(bloom)
	for i in 32:
		var home := nearest_tree(Vector2(850,2890)) if i<4 else trees[((i/4)*19)%trees.size()]
		if i>=24:
			home = trees[rng.randi_range(0,trees.size()-1)]
		var bird = spawn("bird",home.foot,home)
		bird.flock = i/4 if i<24 else -1
		bird.flock_slot = i%4
		bird.set_state("perch",rng.randf_range(2,12))
		bird.altitude = -home.perch.y+42
		bird.position = home.foot+Vector2(home.perch.x+(bird.flock_slot-1.5)*38,0)
	for i in 22:
		var home := nearest_tree(Vector2(850+i*140,2820)) if i<3 else trees[(i*7)%trees.size()]
		ensure_hollow(home)
		var squirrel = spawn("squirrel",land_point(home.foot,190),home)
		squirrel.set_state("forage",rng.randf_range(2,6))
	for at in [Vector2(1450,2840),Vector2(2580,1500),Vector2(3470,4100)]:
		var fox = spawn("fox",land_point(at,140),nearest_tree(at))
		fox.thirst = rng.randf_range(0.3,0.8)
		fox.curiosity_cooldown = rng.randf_range(8,20)
		fox.set_state("wander",rng.randf_range(1,4))
	for pond in ponds:
		for i in 2:
			var frog = spawn("frog",pond.bank+Vector2(0,i*18),{})
			frog.pond = pond
			frog.set_state("bank",rng.randf_range(1,7))
	for i in 38:
		var flower: Vector2 = flowers[flowers.size()-1-i%3] if i<5 else flowers[rng.randi_range(0,flowers.size()-1)]
		var butterfly = spawn("butterfly",flower+Vector2(rng.randf_range(-70,70),rng.randf_range(-70,70)),{})
		butterfly.anchor = flower
		butterfly.altitude = rng.randf_range(14,32)
		butterfly.set_state("flutter",rng.randf_range(2,8))

	# Additional resident communities live in the expansion, including beyond the old boundary.
	var outer_trees: Array[Dictionary] = []
	for tree in trees:
		if tree.foot.x>4900 or tree.foot.y>5500: outer_trees.append(tree)
	for i in 28:
		var home: Dictionary = outer_trees[(i*11)%outer_trees.size()]
		var bird = spawn("bird",home.foot,home)
		bird.flock = 6+i/4
		bird.flock_slot = i%4
		bird.altitude = -home.perch.y+42
		bird.set_state("perch",rng.randf_range(3,18))
	for i in 18:
		var home: Dictionary = outer_trees[(i*13)%outer_trees.size()]
		ensure_hollow(home)
		var squirrel = spawn("squirrel",land_point(home.foot,140),home)
		squirrel.set_state("forage",rng.randf_range(3,8))
	for at in [Vector2(5700,3600),Vector2(10200,3100),Vector2(7200,6650)]:
		var fox = spawn("fox",land_point(at,160),nearest_tree(at))
		fox.set_state("wander",3)
		fox.curiosity_cooldown = rng.randf_range(12,30)
	var outer_flowers: Array[Vector2] = []
	for flower in flowers:
		if flower.x>4800 or flower.y>5400: outer_flowers.append(flower)
	for i in 24:
		var flower: Vector2 = outer_flowers[(i*7)%outer_flowers.size()]
		var butterfly = spawn("butterfly",flower,{})
		butterfly.anchor = flower
		butterfly.set_state("flutter",rng.randf_range(3,10))
	_build_nocturnal_community()

func _build_nocturnal_community() -> void:
	# Resident colonies share real hollows; they never spawn/despawn with the camera.
	for at in [Vector2(920,2820),Vector2(1700,1700),Vector2(4000,4200),Vector2(5800,3500),Vector2(7700,1800),Vector2(10300,3500),Vector2(7200,6400)]:
		var home := nearest_tree(at)
		ensure_hollow(home)
		var colony := {"home":home,"members":[],"timer":rng.randf_range(3,14)}
		for slot in 4:
			var bat = spawn("bat",home.foot,home)
			bat.flock = colonies.size()
			bat.flock_slot = slot
			bat.altitude = 120
			bat.set_state("shelter")
			colony.members.append(bat)
		colonies.append(colony)
	for at in [Vector2(960,2800),Vector2(1650,1800),Vector2(3900,2900),Vector2(1400,4400),Vector2(4300,4800),Vector2(5600,3400),Vector2(7600,1600),Vector2(10200,3400),Vector2(6800,6500),Vector2(10500,6400),Vector2(600,2500),Vector2(2350,1600),Vector2(3050,4500),Vector2(9200,5400)]:
		var home := nearest_tree(at)
		var owl = spawn("owl",home.foot+Vector2(home.owl_perch.x,0),home)
		owl.altitude = -home.owl_perch.y+42
		owl.facing = Vector2.DOWN
		owl.set_state("shelter")
	# Include the entrance and distribute the remaining patches across the whole forest.
	for i in 20:
		var at: Vector2 = flowers[(i*flowers.size()/20)%flowers.size()]
		if i==0: at = nearest_flower(Vector2(850,2890))
		var patch := {"anchor":at,"members":[]}
		for slot in 4:
			var insect = spawn("firefly",at+Vector2(rng.randf_range(-45,45),rng.randf_range(-32,32)),{})
			insect.anchor = insect.position
			insect.altitude = 0
			insect.pulse_rate = rng.randf_range(0.65,2.15)
			insect.set_state("shelter")
			patch.members.append(insect)
		firefly_patches.append(patch)
	# A few snakes occupy alternating banks along the real river, rather than pools.
	for i in 8:
		var pond: Dictionary = ponds[mini(i*2+i%2,ponds.size()-1)]
		var at := land_point(pond.bank+Vector2(30 if i%2==0 else -30,25),60)
		var snake = spawn("snake",at,{})
		snake.pond = pond
		snake.anchor = at
		snake.set_state("shelter")
	# Emission sits above the night grade and below the HUD, using the same camera.
	var glow_layer := CanvasLayer.new()
	glow_layer.name = "FireflyEmission"
	glow_layer.layer = 4
	glow_layer.follow_viewport_enabled = true
	add_child(glow_layer)
	night_glow = preload("res://scripts/firefly_glow.gd").new()
	night_glow.ecosystem = self
	glow_layer.add_child(night_glow)

func spawn(species: String, at: Vector2, home: Dictionary):
	var animal = NocturnalAnimal.new() if species in ["bat","owl","firefly","snake"] else Animal.new()
	animal.ecosystem = self
	animal.species = species
	animal.position = at
	animal.home = home
	animal.anchor = at
	animal.phase = rng.randf()*TAU
	animal.think_in = rng.randf_range(0,0.3)
	animal.variant = animals.size()%3
	world.actors.add_child(animal)
	animals.append(animal)
	return animal

func step(delta: float) -> void:
	elapsed += delta
	for colony in colonies:
		if not nocturnal_active():
			continue
		colony.timer -= delta
		if colony.timer<=0:
			release_colony(colony)
			colony.timer = rng.randf_range(32,60)
	for animal in animals:
		animal.step(delta)
	if night_glow!=null: night_glow.queue_redraw()

func release_colony(colony: Dictionary) -> void:
	var patch := nearest_flower(colony.home.foot)
	var released := 0
	for bat in colony.members:
		if bat.state=="shelter":
			bat.anchor = patch
			bat.outing_time = rng.randf_range(16,25)
			bat.set_state("emerge",bat.flock_slot*0.22)
			released += 1
	if released>1: note("bat_groups")

func sync_debug_time() -> void:
	# Debug jumps settle residents immediately, without advancing or resetting the game.
	var night := not is_day()
	for animal in animals:
		animal.think_in = 0
		match animal.species:
			"bird":
				animal.position = animal.home.foot+Vector2(animal.home.perch.x+(animal.flock_slot-1.5)*38,0)
				animal.altitude = -animal.home.perch.y+42
				animal.set_state("roost" if night else "perch",rng.randf_range(2,8))
			"squirrel":
				animal.route.clear()
				animal.position = animal.home.foot if night else land_point(animal.home.foot,160)
				animal.altitude = 120 if night else 0
				animal.set_state("hidden" if night else "forage",rng.randf_range(2,6))
			"butterfly":
				animal.position = animal.anchor
				animal.altitude = 8 if night else 24
				animal.set_state("rest" if night else "flutter",4)
			"bat":
				animal.position = animal.home.foot
				animal.altitude = 120
				animal.set_state("shelter")
			"owl":
				animal.position = animal.home.foot+Vector2(animal.home.owl_perch.x,0)
				animal.altitude = -animal.home.owl_perch.y+42
				animal.facing = Vector2.DOWN
				animal.head_yaw = 0
				animal.eye_glint = 0
				animal.eye_open = 1.0 if night else 0.0
				animal.art.material.set_shader_parameter("eye_open",animal.eye_open)
				animal.set_state("watch" if night else "shelter",rng.randf_range(12,24))
			"firefly":
				animal.position = animal.anchor
				animal.altitude = 0
				animal.glow = 1.0 if night else 0.0
				animal.cooldown = 0
				animal.set_state("glimmer" if night else "shelter")
				animal._firefly_think()
			"snake":
				animal.position = animal.anchor
				animal.altitude = 0
				animal.route.clear()
				animal.set_state("coil" if night else "shelter",2)
			"fox":
				if night and animal.state in ["sleep","to_den"]: animal.set_state("listen",2)
		animal.art.position = Vector2(0,-animal.altitude)
		animal.z_index = 0
		animal.art.queue_redraw()
		animal.queue_redraw()
	for colony in colonies:
		colony.timer = rng.randf_range(32,60) if night else rng.randf_range(3,14)
		if night: release_colony(colony)
	if night_glow!=null: night_glow.queue_redraw()

func nocturnal_activity() -> float:
	if day_cycle==null: return 0.0
	var hour: float = day_cycle.minutes/60.0
	return smoothstep(18.5,20.0,hour) if hour>=12 else 1.0-smoothstep(5.0,6.0,hour)

func nocturnal_active() -> bool:
	return nocturnal_activity()>0.12

func nearest_flower(at: Vector2) -> Vector2:
	var best: Vector2 = flowers[0]
	var distance := INF
	for flower in flowers:
		var d: float = at.distance_squared_to(flower)
		if d<distance:
			distance = d
			best = flower
	return best

func next_owl_tree(owl: Node2D, toward: Vector2) -> Dictionary:
	var best: Dictionary = {}
	var score := INF
	for tree in trees:
		var distance: float = owl.position.distance_to(tree.foot)
		if tree==owl.home or distance<150 or distance>1000: continue
		var occupied := false
		for animal in animals:
			if animal!=owl and animal.species=="owl" and animal.home==tree:
				occupied = true
				break
		if occupied: continue
		var candidate: float = tree.foot.distance_squared_to(toward)
		if candidate<score:
			score = candidate
			best = tree
	return best

func nearby_animal(at: Vector2, species_list: Array, radius: float, except: Node2D = null):
	var closest = null
	var distance := radius*radius
	for animal in animals:
		if animal==except or animal.species not in species_list or animal.state in ["hidden","shelter","submerged","roost","rest","climb","descend","return","emerge"]: continue
		var d: float = at.distance_squared_to(animal.position)
		if d<distance:
			distance = d
			closest = animal
	return closest

func river_prey(at: Vector2, territory: Vector2, radius: float):
	var closest = null
	var distance := radius*radius
	for animal in animals:
		if animal.species!="frog" or animal.state not in ["bank","snap"] or animal.position.distance_to(territory)>230: continue
		var d: float = at.distance_squared_to(animal.position)
		if d<distance and world.can_walk_line(at,animal.position):
			distance = d
			closest = animal
	return closest

func is_day() -> bool:
	return day_cycle == null or (day_cycle.minutes>=360 and day_cycle.minutes<1200)

func is_twilight() -> bool:
	if day_cycle == null:
		return false
	var hour: float = day_cycle.minutes/60.0
	return (hour>=5 and hour<8) or (hour>=18 and hour<22)

func nearest_tree(at: Vector2) -> Dictionary:
	var best: Dictionary = trees[0]
	var distance := INF
	for tree in trees:
		var d: float = at.distance_squared_to(tree.foot)
		if d<distance:
			distance = d
			best = tree
	return best

func nearest_pond(at: Vector2) -> Dictionary:
	var best: Dictionary = ponds[0]
	var distance := INF
	for pond in ponds:
		var d: float = at.distance_squared_to(pond.bank)
		if d<distance:
			distance = d
			best = pond
	return best

func land_point(at: Vector2, radius: float) -> Vector2:
	for attempt in 24:
		var point := at+Vector2.from_angle(rng.randf()*TAU)*rng.randf_range(32,radius)
		if world.is_walkable(point,12):
			return point
	if world.is_walkable(at,8):
		return at
	return world.navigation.get_point_position(world._nearest_cell(at))

func threat(at: Vector2, radius: float, include_predators := true, except: Node2D = null):
	var closest = null
	var distance := radius*radius
	for person in world.people:
		# Running carries farther than standing quietly.
		var d: float = at.distance_squared_to(person.position)
		var reach := 1.45 if person.velocity.length()>290 else 1.0
		if d<distance*reach*reach:
			distance = d
			closest = person
	if include_predators:
		for animal in animals:
			if animal==except: continue
			if (animal.species=="fox" and animal.state!="sleep") or (animal.species=="owl" and animal.state=="swoop" and animal.altitude<100) or (animal.species=="snake" and animal.state=="stalk"):
				var d: float = at.distance_squared_to(animal.position)
				if d<distance:
					distance = d
					closest = animal
	return closest

func prey(at: Vector2, radius: float):
	var closest = null
	var distance := radius*radius
	for animal in animals:
		if animal.species!="squirrel" or animal.state in ["hidden","climb","descend"]:
			continue
		var d: float = at.distance_squared_to(animal.position)
		if d<distance and world.can_walk_line(at,animal.position):
			distance = d
			closest = animal
	return closest

func note(event: String) -> void:
	events[event] += 1

func ensure_hollow(tree: Dictionary) -> void:
	var key: Vector2 = tree.foot
	if hollows.has(key):
		return
	var hollow := HabitatArt.new()
	hollow.kind = "hollow"
	hollow.position = tree.node.position+Vector2(0,2)
	hollow.offset = tree.hollow
	world.actors.add_child(hollow)
	hollows[key] = hollow

func nearest_person(at: Vector2, radius: float):
	var closest = null
	var distance := radius*radius
	for person in world.people:
		var d: float = at.distance_squared_to(person.position)
		if d<distance:
			distance = d
			closest = person
	return closest

func view_rect() -> Rect2:
	var camera := get_viewport().get_camera_2d()
	if camera==null:
		return Rect2()
	var size: Vector2 = get_viewport_rect().size/camera.zoom
	return Rect2(camera.get_screen_center_position()-size*0.5,size)

func at_view_edge(at: Vector2) -> bool:
	var rect := view_rect()
	return rect.grow(-28).has_point(at) and not rect.grow(-145).has_point(at)

func observation_point(fox: Node2D, person: Node2D) -> Dictionary:
	var rect := view_rect()
	if rect.size==Vector2.ZERO:
		return {}
	var best: Dictionary = {}
	var score := INF
	# Inset corners keep the whole animal on screen without drawing over the HUD.
	for uv in [Vector2(0.10,0.82),Vector2(0.90,0.82),Vector2(0.08,0.55),Vector2(0.92,0.55),Vector2(0.10,0.40),Vector2(0.90,0.46),Vector2(0.22,0.86),Vector2(0.78,0.86),Vector2(0.08,0.70),Vector2(0.92,0.70)]:
		var at: Vector2 = rect.position+rect.size*uv
		for offset in [Vector2.ZERO,Vector2(0,32),Vector2(0,-32),Vector2(32,0),Vector2(-32,0)]:
			var candidate: Vector2 = at+offset
			if not at_view_edge(candidate) or not world.is_walkable(candidate,18):
				continue
			if candidate.distance_to(person.position)<340 or candidate.distance_to(fox.position)>800:
				continue
			if not world.can_walk_line(candidate,person.position):
				continue
			if not visible_watch_point(candidate):
				continue
			var distance: float = fox.position.distance_squared_to(candidate)
			if distance<score:
				score = distance
				best = {"position":candidate}
	return best

func escape_point(fox: Node2D, danger: Node2D) -> Vector2:
	var away: Vector2 = danger.position.direction_to(fox.position)
	if away.is_zero_approx():
		away = Vector2.LEFT
	var best: Vector2 = fox.position
	var best_score := -INF
	# Prefer short, unobstructed escape corridors; never route back past the player.
	for distance in [650.0,420.0,240.0]:
		for angle in [0.0,-0.45,0.45,-0.85,0.85,-1.2,1.2]:
			var candidate: Vector2 = fox.position+away.rotated(angle)*distance
			if not world.is_walkable(candidate,12):
				continue
			if not world.can_walk_line(fox.position,candidate):
				continue
			var score: float = candidate.distance_to(danger.position)-absf(angle)*90
			if score>best_score:
				best_score = score
				best = candidate
	if best_score>-INF:
		return best
	# Dense woods: choose a reachable endpoint whose initial route leads away.
	for attempt in 12:
		var candidate := land_point(fox.position+away*450,240)
		var path: PackedVector2Array = world.find_path(fox.position,candidate)
		if path.size()<2 or candidate.distance_to(danger.position)<fox.position.distance_to(danger.position)+100:
			continue
		var first: Vector2 = fox.position.direction_to(path[mini(2,path.size()-1)])
		if first.dot(away)>-0.1:
			return candidate
	return fox.position

func _sprite_covers(sprite: Sprite2D, point: Vector2) -> bool:
	var local: Vector2 = sprite.to_local(point)
	var rect := sprite.get_rect()
	if not rect.has_point(local):
		return false
	var key: int = sprite.texture.get_instance_id()
	if not occlusion_images.has(key):
		var image: Image = sprite.texture.get_image()
		if image.is_compressed(): image.decompress()
		occlusion_images[key] = image
	var image: Image = occlusion_images[key]
	local -= rect.position
	if sprite.flip_h: local.x = rect.size.x-local.x-1
	if sprite.flip_v: local.y = rect.size.y-local.y-1
	if sprite.region_enabled: local += sprite.region_rect.position
	var pixel := Vector2i(local).clamp(Vector2i.ZERO,image.get_size()-Vector2i.ONE)
	return image.get_pixelv(pixel).a>0.12

func _covered_at(at: Vector2, point: Vector2) -> bool:
	for prop in world.props:
		if prop.position.y>at.y and _sprite_covers(prop.sprite,point):
			return true
	for object in world.scenery_objects:
		if object.position.y>at.y and object.covers_point(point):
			return true
	for plant in world.low_foliage:
		if plant.position.y>at.y and _sprite_covers(plant.get_child(0),point):
			return true
	var atmosphere := world.get_node_or_null("ForestHeightAndFocus")
	if atmosphere!=null:
		for branch in atmosphere.branches:
			if _sprite_covers(branch.sprite,point):
				return true
	return false

func visible_watch_point(at: Vector2) -> bool:
	# Check the head in the actual watching direction, not only a visible tail.
	var person = nearest_person(at,1200)
	var facing: Vector2 = at.direction_to(person.position) if person!=null else Vector2.LEFT
	var direction := posmod(roundi((facing.angle()+PI/2)/(PI/4)),8)
	var head_offsets := [Vector2(0,-48),Vector2(20,-43),Vector2(27,-35),Vector2(20,-30),Vector2(0,-26),Vector2(-20,-30),Vector2(-27,-35),Vector2(-20,-43)]
	var head: Vector2 = head_offsets[direction]
	var visible_head := 0
	for dx in [-6,0,6]:
		if not _covered_at(at,at+head+Vector2(dx,0)):
			visible_head += 1
	if visible_head<3:
		return false
	var clear := 0
	for offset in [Vector2(-22,-18),Vector2(0,-18),Vector2(22,-18),Vector2(-16,-37),Vector2(0,-37),Vector2(16,-37)]:
		if not _covered_at(at,at+offset): clear += 1
	return clear>=6
