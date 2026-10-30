extends RefCounted
const TILE := 1440.0
const FLOOR: Array[Texture2D] = [preload("res://assets/world/expansion/woodland.png"),preload("res://assets/world/expansion/heath.png"),preload("res://assets/world/expansion/deep_woodland.png"),preload("res://assets/world/expansion/oak_ground.png")]
const SPRING: Texture2D = preload("res://assets/world/expansion/spring.png")
const SPRINGS := [Rect2(5300,2100,900,900),Rect2(8000,5600,900,900),Rect2(1600,5800,900,900),Rect2(2621,4969,900,900)]
const ROUTES: Array[Vector2] = [Vector2(4200,2200),Vector2(5600,2200),Vector2(7000,2100),Vector2(8500,2150),Vector2(10500,2200),Vector2(11300,3500),Vector2(10900,5200),Vector2(10400,6800),Vector2(8250,6600),Vector2(6500,6400),Vector2(4400,6800),Vector2(2300,6650),Vector2(1100,6100),Vector2(1250,4550)]

static func biome(at: Vector2) -> int:
	return 1 if (at.x>9000 or (at.y>6200 and at.x>5400)) else 0

static func build(world: Node2D) -> void:
	# Two coherent ground palettes; independent actors supply the forest's height.
	for row in 6:
		for col in 5:
			var origin := Vector2(4800+col*TILE,row*TILE)
			var extent := Vector2(minf(TILE,world.WORLD_SIZE.x-origin.x),minf(TILE,world.WORLD_SIZE.y-origin.y))
			_add_floor(world,Rect2(origin,extent),row,col)
	for row in 2:
		for col in 4:
			var origin := Vector2(col*TILE,5400+row*TILE)
			var extent := Vector2(minf(TILE,4800-origin.x),minf(TILE,world.WORLD_SIZE.y-origin.y))
			_add_floor(world,Rect2(origin,extent),row+4,col)
	for rect in SPRINGS:
		var sprite := Sprite2D.new()
		sprite.texture = SPRING
		sprite.centered = false
		sprite.position = rect.position
		sprite.scale = rect.size/SPRING.get_size()
		sprite.z_index = -43
		var material := ShaderMaterial.new()
		material.shader = preload("res://shaders/site_ground.gdshader")
		sprite.material = material
		world.add_child(sprite)
		world.terrain_layers.append({"texture":SPRING,"rect":rect,"biome":0})
		var pool := Rect2(rect.position+rect.size*Vector2(.31,.34),rect.size*Vector2(.40,.31))
		world.pool_areas.append(pool)
		var collider := CollisionPolygon2D.new()
		var polygon := PackedVector2Array()
		for i in 32: polygon.append(pool.get_center()+Vector2.from_angle(i*TAU/32)*pool.size*.5)
		collider.polygon = polygon
		var bank := StaticBody2D.new()
		bank.collision_layer = 1
		bank.collision_mask = 2
		bank.add_child(collider)
		world.add_child(bank)
	# Paths connect loops and the six independent approaches. Trees leave corridors.
	world.trail_routes.append_array(ROUTES)
	var rng := RandomNumberGenerator.new()
	rng.seed = 30102688
	var planted: Array[Vector2] = []
	for attempt in 6500:
		if planted.size()>=510:
			break
		var at := Vector2(rng.randf_range(100,world.WORLD_SIZE.x-100),rng.randf_range(150,world.WORLD_SIZE.y-100))
		if at.x<4800 and at.y<5400:
			continue
		if not world.is_walkable(at,55) or world.Heritage.reserved(at,220) or world.Discoveries.reserved(at,80) or _on_route(at,145):
			continue
		var close := false
		for other in planted:
			if at.distance_squared_to(other)<42000:
				close = true
		if close:
			continue
		if biome(at)==1 and rng.randf()<0.58:
			world._add_prop(at,3,rng.randf_range(0.75,1.2))
		else:
			world._add_prop(at,1 if biome(at)==1 else 0,rng.randf_range(0.86,1.15))
		planted.append(at)
	for attempt in 420:
		var at := Vector2(rng.randf_range(80,world.WORLD_SIZE.x-80),rng.randf_range(80,world.WORLD_SIZE.y-80))
		if (at.x<4800 and at.y<5400) or world.Heritage.reserved(at,80) or world.Discoveries.reserved(at,25) or not world.is_walkable(at,20):
			continue
		world.add_low_fern(at,rng.randf_range(40,75),Color.WHITE if biome(at)==0 else Color(0.86,0.91,0.70))
	# Quiet seats and loose objects are small discoveries between monuments.
	for at in [Vector2(5850,2740),Vector2(8500,5680),Vector2(1960,6270),Vector2(11300,3910)]:
		for attempt in 33:
			var candidate: Vector2 = at if attempt==0 else at+Vector2.from_angle(attempt*2.4)*(60+attempt*9)
			if world.is_walkable(candidate,145) and world.is_walkable(candidate+Vector2(-52,22),20) and world.is_walkable(candidate+Vector2(52,22),20):
				world._add_prop(candidate,5,1.0)
				break

static func _on_route(at: Vector2, margin: float) -> bool:
	for i in range(ROUTES.size()-1):
		if at.distance_to(Geometry2D.get_closest_point_to_segment(at,ROUTES[i],ROUTES[i+1]))<margin:
			return true
	for site in preload("res://scripts/sintra_heritage.gd").landmarks():
		if at.distance_to(site.position)<570:
			return true
	return false

static func _add_floor(world: Node2D, rect: Rect2, row: int, col: int) -> void:
	var kind := biome(rect.get_center())
	var variation := posmod(row*13+col*7,9)
	var texture := FLOOR[1 if kind==1 else (2 if variation<4 else (3 if variation<8 else 0))]
	var node := Sprite2D.new()
	node.name = "ExpandedForestFloor"
	node.texture = texture
	node.centered = false
	node.position = rect.position-Vector2(44,44)
	node.region_enabled = true
	node.region_rect = Rect2(Vector2.ZERO,(rect.size+Vector2(88,88))/TILE*texture.get_size())
	node.scale = Vector2.ONE*TILE/texture.get_width()
	node.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	node.z_index = -46
	var material := ShaderMaterial.new()
	material.shader = preload("res://shaders/expansion_ground.gdshader")
	material.set_shader_parameter("mirror_x",(row+col)%2==1)
	material.set_shader_parameter("mirror_y",row%2==1)
	material.set_shader_parameter("uv_extent",(rect.size+Vector2(88,88))/TILE)
	node.material = material
	world.add_child(node)
	world.terrain_layers.append({"texture":texture,"rect":rect,"biome":biome(rect.get_center())})
	world.Scenery.expansion_floor(world,texture,rect,(row+col)%2==1,row%2==1)
