extends Node2D
const WorldScale = preload("res://scripts/world_scale.gd")
const BENCH: Texture2D = preload("res://assets/world/two-seat-bench.png")
const BENCH_REGION := Rect2(75,121,1619,658)
const WORLD_SIZE := Vector2(4800, 5400)
const CELL := 32.0
const TERRAIN: Array[Texture2D] = [preload("res://assets/world/terrain/sintra-nw.png"),preload("res://assets/world/terrain/sintra-ne.png"),preload("res://assets/world/terrain/sintra-sw-humid.png"),preload("res://assets/world/terrain/sintra-se.png")]
const SOUTH: Texture2D = preload("res://assets/world/terrain/sintra-south.png")
const HUMID_TREES: Texture2D = preload("res://assets/world/sintra-humid-trees.png")
const GROUND: Texture2D = preload("res://assets/world/sintra-overhead-ground-detail.png")
const PROPS: Texture2D = preload("res://assets/world/sintra-overhead-props-cutout.png")
const PaintedOccluder = preload("res://scripts/painted_occluder.gd")
const Prop = preload("res://scripts/open_world_prop.gd")
const PROP_REGIONS: Array[Rect2] = [Rect2(0,0,512,620),Rect2(512,0,555,620),Rect2(1067,60,469,560),Rect2(0,620,565,404),Rect2(565,620,500,404),Rect2(1065,650,471,374)]
const BRIDGES: Array[Vector2] = [Vector2(3070,920),Vector2(2930,2280)]
# Stream centreline traced from the painting; coordinates use the full world size.
const RIVER: Array[Vector2] = [Vector2(2960,0),Vector2(3050,400),Vector2(3070,920),Vector2(3110,1250),Vector2(3140,1800),Vector2(3040,2000),Vector2(2930,2280),Vector2(2860,2700),Vector2(2820,3100),Vector2(2780,3600),Vector2(2800,4050),Vector2(2940,4470),Vector2(2920,4900),Vector2(3080,5400)]
var opaque_paint: ShaderMaterial
var actors: Node2D
var props: Array = []
var circles: Array[Vector3] = []
var blocked_rects: Array[Rect2] = []
var navigation := AStarGrid2D.new()
var people: Array = []
var masonry: Array[Node2D] = []
var low_foliage: Array[Node2D] = []
var boulders: Array[Dictionary] = []
var interactions: Node2D
var wildlife: Node2D
const ARCH_CENTER := Vector2(3985,1360)
var landmarks: Array[Dictionary] = [
	{"id":"trailhead", "name":"Entrada da mata", "position":Vector2(850,2890), "radius":260.0},
	{"id":"old_fountain", "name":"Fonte escondida", "position":Vector2(1620,1100), "radius":200.0},
	{"id":"log_bridge", "name":"Ponte dos eucaliptos", "position":Vector2(3070,920), "radius":270.0},
	{"id":"stone_bridge", "name":"Ponte de pedra", "position":Vector2(2930,2280), "radius":270.0},
	{"id":"chapel_ruins", "name":"Ruínas da capela", "position":Vector2(4170,1460), "radius":270.0},
	{"id":"granite_lookout", "name":"Miradouro do granito", "position":Vector2(4230,390), "radius":250.0},
	{"id":"fern_glade", "name":"Vale dos fetos", "position":Vector2(1650,1870), "radius":370.0},
	{"id":"cork_oak", "name":"Clareira do sobreiro", "position":Vector2(4020,2930), "radius":320.0},
	{"id":"forest_stream", "name":"Margem da ribeira", "position":Vector2(2520,1600), "radius":190.0},
	{"id":"ivy_hollow", "name":"Bosque da hera", "position":Vector2(1200,4200), "radius":350.0},
	{"id":"ravine_bridge", "name":"Passadiço da ravina", "position":Vector2(2940,4470), "radius":300.0},
	{"id":"moss_steps", "name":"Escadaria dos musgos", "position":Vector2(4140,4110), "radius":270.0},
	{"id":"castle_slope", "name":"Encosta da muralha", "position":Vector2(4250,4990), "radius":300.0}]

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	opaque_paint = ShaderMaterial.new()
	opaque_paint.shader = preload("res://shaders/opaque_cutout.gdshader")
	var ground := Sprite2D.new()
	ground.texture = GROUND
	ground.centered = false
	ground.scale = Vector2(4800,3600) / GROUND.get_size()
	ground.z_index = -50
	ground.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(ground)
	_build_terrain()
	var river := preload("res://scripts/living_river.gd").new()
	river.world = self
	add_child(river)
	actors = Node2D.new()
	actors.name = "DepthSortedForest"
	actors.y_sort_enabled = true
	add_child(actors)
	_build_water()
	_build_forest()
	_build_masonry()
	_build_low_foliage()
	_build_southern_forest()
	_build_navigation()
	interactions = preload("res://scripts/world_interactions.gd").new()
	interactions.world = self
	add_child(interactions)
	var atmosphere := preload("res://scripts/forest_depth.gd").new()
	atmosphere.world = self
	add_child(atmosphere)
	wildlife = preload("res://scripts/wildlife.gd").new()
	wildlife.world = self
	add_child(wildlife)

func attach_people(value: Array) -> void:
	people = value

func river_x(y: float) -> float:
	for i in range(RIVER.size()-1):
		if y <= RIVER[i+1].y:
			return lerpf(RIVER[i].x,RIVER[i+1].x,inverse_lerp(RIVER[i].y,RIVER[i+1].y,y))
	return RIVER[-1].x

func in_water(point: Vector2, margin := 0.0) -> bool:
	if point.y > 3600:
		var deck_y := 4470.0 + (point.x-2940.0)*0.24
		if absf(point.y-deck_y) < 105.0-margin:
			return false
		return absf(point.x-river_x(point.y)) < 75.0+margin
	for bridge in BRIDGES:
		if absf(point.y-bridge.y) < 70.0 - margin:
			return false
	return absf(point.x-river_x(point.y)) < 130.0 + margin

func _build_water() -> void:
	# Separate polygons leave genuine physical openings at both painted bridge decks.
	for section in [Vector2(0,850),Vector2(990,2210),Vector2(2350,3600)]:
		var polygon := PackedVector2Array()
		var y: float = section.x
		while y < section.y:
			polygon.append(Vector2(river_x(y)-130,y))
			y += 32
		polygon.append(Vector2(river_x(section.y)-130,section.y))
		y = section.y
		while y > section.x:
			polygon.append(Vector2(river_x(y)+130,y))
			y -= 32
		polygon.append(Vector2(river_x(section.x)+130,section.x))
		var bank := StaticBody2D.new()
		bank.collision_layer = 1
		bank.collision_mask = 2
		var collider := CollisionPolygon2D.new()
		collider.polygon = polygon
		bank.add_child(collider)
		add_child(bank)

func _build_forest() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 291026
	var routes: Array[Vector2] = [Vector2(850,2890),Vector2(650,2300),Vector2(500,1600),Vector2(800,1100),Vector2(1600,820),Vector2(2350,900),Vector2(3300,900),Vector2(4200,650),Vector2(4250,1350),Vector2(4100,2000),Vector2(3500,2300),Vector2(2400,2300),Vector2(1800,2050),Vector2(1400,2450),Vector2(850,2890)]
	var placed: Array[Vector2] = []
	for attempt in 1400:
		if placed.size() >= 165:
			break
		var at := Vector2(rng.randf_range(100,4700),rng.randf_range(130,3500))
		if absf(at.x-river_x(at.y)) < 320:
			continue
		var clear := true
		for place in landmarks:
			if at.distance_to(place.position) < place.radius * 1.20:
				clear = false
		for i in range(routes.size()-1):
			if at.distance_to(Geometry2D.get_closest_point_to_segment(at,routes[i],routes[i+1])) < 110:
				clear = false
		for other in placed:
			if at.distance_to(other) < 180:
				clear = false
		# Keep the initial clearing visible between tall trunks, including crowns south of it.
		if at.x>570 and at.x<1090 and at.y>2890 and at.y<3550:
			clear = false
		if not clear:
			continue
		placed.append(at)
		var kind := rng.randi_range(0,2)
		if at.x > 3200 and rng.randf() < 0.65:
			kind = 1
		elif at.x < 2200 and at.y < 1500 and rng.randf() < 0.65:
			kind = 0
		elif at.y > 1500 and at.y < 2300 and rng.randf() < 0.60:
			kind = 2
		_add_prop(at,kind,rng.randf_range(0.82,1.13))
	# Landmark objects, open approach from multiple sides.
	_add_prop(Vector2(1620,1010),4,1.0)
	_add_prop(Vector2(4100,490),5,1.0)
	_add_prop(Vector2(4100,2840),1,1.5)
	_add_prop(Vector2(1030,2860),5,0.9)
	for at in [Vector2(340,2870),Vector2(2050,640),Vector2(3550,3000),Vector2(4330,2270),Vector2(1800,2900)]:
		_add_prop(at,3,1.0)
	# Large rocks visibly painted into the ground get foot-sized ellipses, not whole foliage blocks.
	for obstacle in [Vector3(1039,726,140),Vector3(2204,165,110),Vector3(285,1077,95),Vector3(2221,1260,90),Vector3(472,2082,150),Vector3(1889,2794,145),Vector3(978,3524,170),Vector3(331,2960,125),Vector3(842,2579,45),Vector3(4422,381,180),Vector3(3477,530,115),Vector3(3428,2629,130)]:
		_add_circle(Vector2(obstacle.x,obstacle.y),obstacle.z)
	# Chapel walls, leaving the central door and the broken south wall open.
	_add_wall(Rect2(3880,1260,38,170))
	_add_wall(Rect2(4110,1120,38,100))
	_add_wall(Rect2(4510,1390,38,160))
	_add_wall(Rect2(4130,1660,175,35))

func _add_prop(at: Vector2, kind: int, variation: float) -> void:
	var prop := Prop.new()
	prop.position = at
	prop.set_meta("kind",kind)
	prop.collision_layer = 1
	prop.collision_mask = 2
	var humid := kind < 2
	var region := BENCH_REGION if kind==5 else (Rect2(kind*512,0,512,1024) if humid else PROP_REGIONS[kind])
	var factor: float = WorldScale.BENCH_WIDTH/region.size.x if kind==5 else WorldScale.PROP_HEIGHTS[kind]*variation/region.size.y
	var sprite := Sprite2D.new()
	sprite.material = opaque_paint
	sprite.texture = BENCH if kind==5 else (HUMID_TREES if humid else PROPS)
	sprite.region_enabled = true
	sprite.region_rect = region
	sprite.region_filter_clip_enabled = true
	sprite.centered = false
	sprite.scale = Vector2.ONE * factor
	sprite.position = Vector2(-region.size.x * factor * 0.5,-region.size.y * factor * (1.0 if kind==5 else 0.95))
	prop.sprite = sprite
	prop.half_width = region.size.x*factor*0.53
	prop.height = region.size.y*factor
	prop.add_child(sprite)
	var collider := CollisionShape2D.new()
	if kind==5:
		var shape := RectangleShape2D.new()
		shape.size = WorldScale.BENCH_FOOTPRINT.size
		collider.shape = shape
		collider.position = WorldScale.BENCH_FOOTPRINT.get_center()
		blocked_rects.append(Rect2(at+WorldScale.BENCH_FOOTPRINT.position,WorldScale.BENCH_FOOTPRINT.size))
		prop.set_meta("radius",WorldScale.BENCH_WIDTH*0.5-12)
		prop.seat_offsets = WorldScale.BENCH_SEATS.duplicate()
	else:
		var radius := 18.0 if kind<3 else 40.0
		var shape := CircleShape2D.new()
		shape.radius = radius*variation
		prop.set_meta("radius",shape.radius)
		collider.shape = shape
		circles.append(Vector3(at.x,at.y,shape.radius))
	prop.add_child(collider)
	actors.add_child(prop)
	props.append(prop)

func _add_circle(at: Vector2, radius: float) -> void:
	var body := StaticBody2D.new()
	body.position = at
	body.collision_layer = 1
	body.collision_mask = 2
	var collider := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = radius
	collider.shape = shape
	body.add_child(collider)
	add_child(body)
	circles.append(Vector3(at.x,at.y,radius))
	boulders.append({"position":at,"radius":radius,"node":body})

func _add_wall(rect: Rect2) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 2
	var collider := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	collider.shape = shape
	collider.position = rect.get_center()
	body.add_child(collider)
	add_child(body)
	blocked_rects.append(rect)

func is_walkable(at: Vector2, margin := 14.0) -> bool:
	if at.x < 32 or at.y < 32 or at.x > WORLD_SIZE.x-32 or at.y > WORLD_SIZE.y-32 or in_water(at,margin):
		return false
	for circle in circles:
		if at.distance_squared_to(Vector2(circle.x,circle.y)) < pow(circle.z+margin,2):
			return false
	for rect in blocked_rects:
		if rect.grow(margin).has_point(at):
			return false
	return true

func _build_navigation() -> void:
	navigation.region = Rect2i(0,0,int(WORLD_SIZE.x/CELL),int(WORLD_SIZE.y/CELL))
	navigation.cell_size = Vector2.ONE*CELL
	navigation.offset = Vector2.ONE*CELL*0.5
	navigation.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	navigation.default_compute_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	navigation.default_estimate_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	navigation.update()
	for x in navigation.region.size.x:
		for y in navigation.region.size.y:
			var id := Vector2i(x,y)
			navigation.set_point_solid(id,not is_walkable(navigation.get_point_position(id),23))

func _nearest_cell(at: Vector2) -> Vector2i:
	var cell := Vector2i(at/CELL).clamp(Vector2i.ZERO,navigation.region.size-Vector2i.ONE)
	if not navigation.is_point_solid(cell):
		return cell
	for radius in range(1,14):
		for x in range(-radius,radius+1):
			for y in range(-radius,radius+1):
				var test := cell+Vector2i(x,y)
				if navigation.region.has_point(test) and not navigation.is_point_solid(test):
					return test
	return cell

func find_path(from: Vector2, to: Vector2) -> PackedVector2Array:
	return navigation.get_point_path(_nearest_cell(from),_nearest_cell(to))

func can_walk_line(from: Vector2, to: Vector2) -> bool:
	var steps := maxi(1,ceili(from.distance_to(to)/16.0))
	for i in range(steps+1):
		if not is_walkable(from.lerp(to,float(i)/steps),16):
			return false
	return true

func area_at(at: Vector2) -> String:
	for place in landmarks:
		if at.distance_to(place.position) < place.radius:
			return place.name
	if at.y > 3600:
		return "Mata húmida da serra"
	if at.x > 3200:
		return "Mata dos sobreiros"
	if at.y < 1400:
		return "Bosque dos eucaliptos"
	return "Interior da serra"

func _build_terrain() -> void:
	# Overscan and feather tile borders while preserving landmark coordinates.
	for index in 4:
		var tile := Polygon2D.new()
		var extent := Vector2(2400,1800)
		var corners := PackedVector2Array([Vector2(-64,-64),Vector2(extent.x+64,-64),extent+Vector2(64,64),Vector2(-64,extent.y+64)])
		tile.polygon = corners
		var uv := PackedVector2Array()
		for corner in corners:
			uv.append(corner/extent*TERRAIN[index].get_size())
		tile.uv = uv
		tile.texture = TERRAIN[index]
		tile.position = Vector2(index%2,floori(index/2.0))*extent
		tile.z_index = -49
		tile.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		var shader := Shader.new()
		shader.code = """shader_type canvas_item;
uniform vec2 tile_origin;
uniform bool southern_stream;
void fragment() {
 vec2 sample_uv = UV;
 if (southern_stream) {
  float bend = 0.055 * (1.0-smoothstep(0.0,0.28,UV.y));
  float bank = smoothstep(0.0,0.12,UV.x)*(1.0-smoothstep(0.60,0.90,UV.x));
  sample_uv.x -= bend*bank;
 }
 vec4 paint = texture(TEXTURE,clamp(sample_uv,vec2(0.0),vec2(1.0)));
 vec2 feather = vec2(64.0/2400.0,64.0/1800.0);
 float a=1.0;
 if (tile_origin.x>0.0) a*=smoothstep(-feather.x,feather.x,UV.x);
 if (tile_origin.x<1.0) a*=1.0-smoothstep(1.0-feather.x,1.0+feather.x,UV.x);
 if (tile_origin.y>0.0) a*=smoothstep(-feather.y,feather.y,UV.y);
 if (tile_origin.y<1.0) a*=1.0-smoothstep(1.0-feather.y,1.0+feather.y,UV.y);
 float damp = tile_origin.x<0.5 && tile_origin.y<0.5 ? 0.26 : 0.0;
 COLOR=vec4(mix(paint.rgb,paint.rgb*vec3(0.73,0.89,0.92),damp),paint.a*a);
}"""
		var material_value := ShaderMaterial.new()
		material_value.shader = shader
		material_value.set_shader_parameter("tile_origin",Vector2(index%2,floori(index/2.0)))
		material_value.set_shader_parameter("southern_stream",index==3)
		tile.material = material_value
		add_child(tile)

	var south := Sprite2D.new()
	south.texture = SOUTH
	south.centered = false
	south.position = Vector2(0,3540)
	south.scale = Vector2(4800,1860)/SOUTH.get_size()
	south.z_index = -48
	var blend := ShaderMaterial.new()
	blend.shader = preload("res://shaders/southern_ground.gdshader")
	south.material = blend
	add_child(south)

func _masonry_part(label: String, points: Array, ground_contact: Vector2) -> void:
	var item := PaintedOccluder.new()
	item.name = label
	item.configure(TERRAIN[1],PackedVector2Array(points),ground_contact,Vector2(2400,0),Vector2(2400,1800)/TERRAIN[1].get_size())
	actors.add_child(item)
	masonry.append(item)

func _build_masonry() -> void:
	# Three separate solid parts leave the doorway genuinely empty between the jambs.
	_masonry_part("ChapelArchLintel",[
		Vector2(900,749),Vector2(913,723),Vector2(936,701),Vector2(957,689),Vector2(980,693),Vector2(998,702),Vector2(1013,718),Vector2(1016,749),
		Vector2(992,764),Vector2(991,746),Vector2(984,731),Vector2(973,726),Vector2(959,729),Vector2(948,739),Vector2(937,756),Vector2(933,777)],Vector2(958,834))
	_masonry_part("ChapelArchLeftJamb",[Vector2(900,749),Vector2(933,777),Vector2(934,816),Vector2(910,831),Vector2(899,823)],Vector2(917,834))
	_masonry_part("ChapelArchRightJamb",[Vector2(992,748),Vector2(1016,733),Vector2(1018,804),Vector2(1000,819),Vector2(987,813)],Vector2(1001,820))
	# Broken walls also have height, rather than being painted floor markings.
	_masonry_part("ChapelWestWall",[Vector2(824,748),Vector2(850,754),Vector2(867,791),Vector2(882,789),Vector2(901,814),Vector2(904,863),Vector2(930,881),Vector2(928,907),Vector2(884,892),Vector2(832,856),Vector2(822,809)],Vector2(870,899))
	_masonry_part("ChapelNorthWall",[Vector2(1027,735),Vector2(1069,700),Vector2(1071,666),Vector2(1095,652),Vector2(1143,668),Vector2(1142,728),Vector2(1160,741),Vector2(1160,774),Vector2(1127,755),Vector2(1116,746),Vector2(1092,748),Vector2(1030,785)],Vector2(1090,784))
	_masonry_part("ChapelBrokenSouthWall",[Vector2(956,882),Vector2(981,888),Vector2(1005,898),Vector2(1015,929),Vector2(1014,978),Vector2(994,971),Vector2(989,948),Vector2(960,936)],Vector2(987,978))
	# Contact footprints, not the lintel, block motion. The central opening stays open.
	_add_wall(Rect2(3895,1320,48,80))
	_add_wall(Rect2(4040,1290,44,65))

func _build_low_foliage() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 69431
	for i in 110:
		var at := Vector2(rng.randf_range(130,4670),rng.randf_range(130,3470))
		if not is_walkable(at,30) or at.distance_to(ARCH_CENTER)<200:
			continue
		var plant := Node2D.new()
		plant.name = "WalkThroughFern"
		plant.position = at
		plant.add_to_group("walkthrough_foliage")
		var sprite := Sprite2D.new()
		sprite.material = opaque_paint
		sprite.texture = PROPS
		sprite.region_enabled = true
		sprite.region_rect = PROP_REGIONS[2]
		sprite.region_filter_clip_enabled = true
		sprite.centered = false
		var height := rng.randf_range(42,64)
		var factor := height/PROP_REGIONS[2].size.y
		sprite.scale = Vector2.ONE*factor
		sprite.position = Vector2(-PROP_REGIONS[2].size.x*factor*0.5,-height*0.95)
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		plant.add_child(sprite)
		actors.add_child(plant)
		low_foliage.append(plant)

func _build_southern_forest() -> void:
	# Water footprints follow the sloping deck, so both banks and the bridge agree.
	for bounds in [Vector2(3600,4365),Vector2(4575,5400)]:
		var outline := PackedVector2Array()
		var steps := 28
		for i in range(steps+1):
			var y := lerpf(bounds.x,bounds.y,float(i)/steps)
			var x := river_x(y)-75
			if (bounds.y==4365 and i==steps) or (bounds.x==4575 and i==0):
				y += (x-2940)*0.24
			outline.append(Vector2(x,y))
		for i in range(steps,-1,-1):
			var y := lerpf(bounds.x,bounds.y,float(i)/steps)
			var x := river_x(y)+75
			if (bounds.y==4365 and i==steps) or (bounds.x==4575 and i==0):
				y += (x-2940)*0.24
			outline.append(Vector2(x,y))
		var bank := StaticBody2D.new()
		bank.collision_layer = 1
		bank.collision_mask = 2
		var collider := CollisionPolygon2D.new()
		collider.polygon = outline
		bank.add_child(collider)
		add_child(bank)
	var rng := RandomNumberGenerator.new()
	rng.seed = 85427
	var placed: Array[Vector2] = []
	for attempt in 650:
		if placed.size() >= 62:
			break
		var at := Vector2(rng.randf_range(100,4700),rng.randf_range(3690,5310))
		if absf(at.x-river_x(at.y))<380:
			continue
		var clear := true
		for landmark in landmarks:
			if at.distance_to(landmark.position)<landmark.radius:
				clear = false
		for other in placed:
			if at.distance_to(other)<220:
				clear = false
		if clear:
			_add_prop(at,rng.randi_range(0,2),rng.randf_range(0.85,1.25))
			placed.append(at)
	# Traced large granite bases. Low ivy remains freely traversable.
	for rock in [Vector3(430,4100,135),Vector3(1740,4650,150),Vector3(530,5040,130),Vector3(3540,4090,120),Vector3(3660,4860,130)]:
		_add_circle(Vector2(rock.x,rock.y),rock.z)
	# Short retaining ledges have gaps at the painted stairs and at either end.
	_add_wall(Rect2(3660,4280,210,30))
	_add_wall(Rect2(4470,4280,160,30))
	_add_wall(Rect2(4440,5280,340,35))
