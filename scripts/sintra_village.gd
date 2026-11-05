extends Node2D
## Data-authored urban neighbourhoods, public squares and the two hillside gardens.
const WORLD_SIZE := Vector2(22400,16000)
const CELL := 32.0
const WorldScale = preload("res://scripts/world_scale.gd")
const Navigation = preload("res://scripts/exploration_navigation.gd")
const Props = preload("res://scripts/exploration_props.gd")
const Architecture = preload("res://scripts/village_architecture.gd")
const Detail = preload("res://scripts/village_street_detail.gd")
const LAYOUT = preload("res://data/village/layout.json")
const REGIONS = preload("res://data/village/art-regions.json")
const TERRACES = preload("res://data/village/terraces.json")
const BLOCKS = preload("res://data/village/block-infill.json")
const TEXTURES := {
	"palace":preload("res://assets/world/village/national-palace.png"),
	"landmarks":preload("res://assets/world/village/landmarks.png"),
	"urban":preload("res://assets/world/village/urban-frontages.png"),
	"side":preload("res://assets/world/village/side-frontages.png"),
	"market":preload("res://assets/world/village/street-market.png")}
var region_title := "Vila de Sintra"
var actors: Node2D
var people: Array = []
var props: Array = []
var circles: Array[Vector3] = []
var blocked_rects: Array[Rect2] = []
var boulders: Array[Dictionary] = []
var scenery_props: Array[StaticBody2D] = []
var scenery_objects: Array[StaticBody2D] = []
var interactions: Node2D
var population: Node2D
var street_life: Node2D
var social_life: Node2D
var living_life: Node2D
var dining: Node2D
var neighbourhood: Node2D
var passers: Node2D
var nightlife: Node2D
var bakery: Node2D
var chestnuts: Node2D
var manual_street_rest := false
var festival_life: Node2D
var festival_props: Array[Node2D] = []
var lighting: Node2D
var activity_props: Array[Node2D] = []
var wildlife: Node2D
var puppy: Node2D
var opaque_paint: ShaderMaterial
var navigation := AStarGrid2D.new()
var routes: Array[Dictionary] = []
var plazas: Array[Dictionary] = []
var landmarks: Array[Dictionary] = []
var buildings: Array[StaticBody2D] = []
var ground_buckets: Dictionary = {}
var plaza_buckets: Dictionary = {}
var ground_segments: Array[Dictionary] = []
var solid_buckets: Dictionary = {}
var circle_buckets: Dictionary = {}
var indexed_rects := 0
var indexed_circles := 0
var floor_cells: Dictionary = {}
var urban_floor: Array[Rect2] = []
var garden_floor: Array[Rect2] = []
var architecture_data: Array = []
var neighbour_cells: Dictionary = {}
var neighbour_clock := 0.0
var ambient_time := 0.0
var menu_spawn := Vector2.ZERO
var forest_access := Vector2.ZERO
var arcade_floor := Rect2()

func _ready() -> void:
	name = "HistoricVillageWorld"
	process_mode = Node.PROCESS_MODE_PAUSABLE
	opaque_paint = ShaderMaterial.new()
	opaque_paint.shader = preload("res://shaders/opaque_cutout.gdshader")
	_read_layout()
	var terrain := preload("res://scripts/village_terrain.gd").new()
	terrain.name = "PaintedTerrainAndStreets"
	terrain.world = self
	add_child(terrain)
	actors = Node2D.new()
	actors.name = "DepthSortedVillage"
	actors.y_sort_enabled = true
	add_child(actors)
	_build_architecture()
	for spec in TERRACES.data.terraces:
		var terrace := preload("res://scripts/village_terrace.gd").new()
		terrace.world = self
		terrace.spec = spec
		add_child(terrace)
	_build_street_life()
	for spec in TERRACES.data.terraces:
		var platform := _rect(spec.platform)
		for side in [-1,1]: _detail("pot",Vector2(platform.get_center().x+side*110,platform.position.y+30))
	_build_gardens()
	for spec in preload("res://data/village/street-life.json").data.props:
		var object := preload("res://scripts/village_activity_prop.gd").new()
		object.setup(self,spec)
		activity_props.append(object)
	_build_festival_equipment()
	dining = preload("res://scripts/village_dining.gd").new()
	dining.world = self
	add_child(dining)
	neighbourhood = preload("res://scripts/village_neighbourhood.gd").new()
	neighbourhood.world = self
	neighbourhood.build_equipment()
	nightlife = preload("res://scripts/village_nightlife.gd").new()
	nightlife.world = self
	nightlife.build_equipment()
	bakery = preload("res://scripts/village_bakery.gd").new()
	bakery.build(self)
	chestnuts = preload("res://scripts/village_chestnuts.gd").new()
	chestnuts.build(self)
	lighting = preload("res://scripts/village_lighting.gd").new()
	lighting.world = self
	add_child(lighting)
	_bake_navigation_and_boundary()
	interactions = preload("res://scripts/world_interactions.gd").new()
	interactions.world = self
	interactions.include_forest_content = false
	interactions.id_prefix = "village_"
	interactions.authored_targets.assign(_observations())
	for entry in LAYOUT.data.pickups:
		interactions.pickup_placements.append({"item":preload("res://scripts/item_art.gd").ITEMS[int(entry.item)],"position":_point(entry.at)})
	add_child(interactions)
	for place in landmarks:
		var approach: Vector2 = interactions.find_drop_position(place.position)
		if approach!=Vector2.INF: place.position = approach
	population = preload("res://scripts/village_population.gd").new()
	population.world = self
	add_child(population)
	street_life = preload("res://scripts/village_street_life.gd").new()
	street_life.world = self
	add_child(street_life)
	festival_life = preload("res://scripts/village_festival_life.gd").new()
	festival_life.world = self
	add_child(festival_life)
	living_life = preload("res://scripts/village_living_life.gd").new()
	living_life.world = self
	add_child(living_life)
	add_child(neighbourhood)
	social_life = preload("res://scripts/village_social_life.gd").new()
	social_life.world = self
	add_child(social_life)
	dining.bind()
	neighbourhood.bind()
	passers = preload("res://scripts/village_passers.gd").new()
	passers.world = self
	add_child(passers)
	add_child(nightlife)
	bakery.bind()
	chestnuts.bind()

func _build_festival_equipment() -> void:
	var specs: Array = [["cinema",Vector2(5530,9950),285.0],["fruit",Vector2(18060,12850),200.0],["sweets",Vector2(12950,12380),250.0],["chess",Vector2(18500,7820),120.0],["flowers",Vector2(18900,4770),150.0],["score",Vector2(13000,12500),160.0],["poetry",Vector2(15670,5310),135.0],["bicycle",Vector2(18450,7490),155.0]]
	for spec in specs:
		var at: Vector2 = _event_space(spec[1],float(spec[2]))
		var object := preload("res://scripts/village_festival_prop.gd").new()
		object.setup(self,spec[0],at,float(spec[2]))
		festival_props.append(object)

func _event_space(preferred: Vector2, width: float) -> Vector2:
	for radius in range(0,673,32):
		for i in (1 if radius==0 else 16):
			var at: Vector2 = preferred+Vector2.from_angle(i*TAU/16)*radius
			if not is_walkable(at,maxf(30,width*.38)): continue
			var covered := false
			for building in buildings:
				if building.position.y<at.y: continue
				if building.screen_bounds.has_point(at-Vector2(0,60)) or building.screen_bounds.has_point(at-Vector2(0,160)): covered = true; break
			if not covered: return at
	return preferred

func _point(data: Array) -> Vector2: return Vector2(data[0],data[1])
func _rect(data: Array) -> Rect2: return Rect2(data[0],data[1],data[2],data[3])
func _index_bounds(table: Dictionary, bounds: Rect2, index: int, size := 256.0) -> void:
	var first := Vector2i((bounds.position/size).floor())
	var last := Vector2i((bounds.end/size).floor())
	for x in range(first.x,last.x+1):
		for y in range(first.y,last.y+1):
			var key := Vector2i(x,y)
			if not table.has(key): table[key] = []
			table[key].append(index)

func _read_layout() -> void:
	for data in LAYOUT.data.urban_zones: urban_floor.append(_rect(data))
	for data in LAYOUT.data.garden_zones: garden_floor.append(_rect(data))
	menu_spawn = _point(LAYOUT.data.menu_spawn)
	forest_access = _point(LAYOUT.data.forest_access)
	arcade_floor = _rect(LAYOUT.data.arcade_floor)
	for entry in LAYOUT.data.routes:
		var route: Dictionary = entry.duplicate(true)
		var points := PackedVector2Array()
		for point in entry.points: points.append(_point(point))
		route.points = points
		routes.append(route)
		for i in range(points.size()-1):
			var bounds := Rect2(points[i],Vector2.ZERO).expand(points[i+1]).grow(route.width*.5+150)
			var index := ground_segments.size()
			ground_segments.append({"a":points[i],"b":points[i+1],"radius":route.width*.5,"surface":route.surface})
			_index_bounds(ground_buckets,bounds,index)
	for entry in LAYOUT.data.plazas:
		var plaza: Dictionary = entry.duplicate(true)
		plaza.rect = _rect(entry.rect)
		_index_bounds(plaza_buckets,plaza.rect.grow(150),plazas.size())
		plazas.append(plaza)
	# Treat the arcade as another piece of public floor, including its real openings.
	_index_bounds(plaza_buckets,arcade_floor.grow(150),plazas.size())
	plazas.append({"id":"palace_arcade","name":"Arcadas do Palácio","rect":arcade_floor,"surface":"stone"})
	for entry in LAYOUT.data.landmarks:
		var place: Dictionary = entry.duplicate(true)
		place.position = _point(entry.position)
		landmarks.append(place)

func _source(atlas: String, index: int) -> Rect2:
	return Rect2(20,26,1500,970) if atlas=="palace" else _rect(REGIONS.data[atlas][index])

func _building(entry: Dictionary) -> void:
	var building := Architecture.new()
	building.name = entry.id
	building.entry_id = entry.id
	building.label = entry.label
	building.add_to_group("village_architecture")
	var bases: Array = []
	for base in entry.bases: bases.append(_rect(base))
	building.build(TEXTURES[entry.atlas],_source(entry.atlas,int(entry.type)),_point(entry.at),entry.width,bases,opaque_paint,entry.get("sprite_mirror",false))
	if entry.has("side_facing"):
		building.entry_position = _point(entry.at)+Vector2((1 if entry.side_facing=="right" else -1)*(entry.width*.5+32),-70)
		building.set_meta("side_facing",entry.side_facing)
	actors.add_child(building)
	buildings.append(building)
	scenery_objects.append(building)
	for base: Rect2 in bases: blocked_rects.append(base)

func _build_architecture() -> void:
	for entry in LAYOUT.data.monuments: _building(entry)
	architecture_data = preload("res://data/village/frontages.json").data.buildings
	for i in architecture_data.size():
		_building(architecture_data[i])
		if i%6==0: _attach_lantern(buildings.back())
	for entry in BLOCKS.data.buildings: _building(entry)

func _attach_lantern(building: StaticBody2D) -> void:
	var source := _source("market",11)
	var lamp := Sprite2D.new()
	lamp.name = "HangingIronLantern"
	lamp.texture = TEXTURES.market
	lamp.material = opaque_paint
	lamp.region_enabled = true
	lamp.region_rect = source
	lamp.region_filter_clip_enabled = true
	lamp.centered = false
	lamp.scale = Vector2.ONE*110/source.size.x
	lamp.position = Vector2(building.visual_size.x*.36,-215-source.size.y*lamp.scale.y)
	building.add_child(lamp)

func _build_street_life() -> void:
	for entry in LAYOUT.data.street_objects:
		var at := _point(entry.at)
		var width: float = entry.width
		var kind := int(entry.kind)
		var depth := 90.0 if kind in [7,8] else 32.0
		# Keep a continuous walking lane around the stalls and cafe terraces.
		if not is_walkable(at,14): continue
		var base := Rect2(at-Vector2(width*.38,depth),Vector2(width*.76,depth))
		if TERRACES.data.terraces.any(func(spec): return terrace_bounds(spec).grow(35).intersects(base)): continue
		if entry.solid and (not is_walkable(base.position,14) or not is_walkable(base.end,14)): continue
		var object := Architecture.new()
		object.name = "StreetObject_%03d_%d"%[actors.get_child_count(),kind]
		object.build(TEXTURES.market,_source("market",kind),at,width,[base] if entry.solid else [],opaque_paint)
		object.set_meta("street_kind",kind)
		actors.add_child(object)
		if entry.solid: blocked_rects.append(base)
	for at in LAYOUT.data.benches: Props.add(self,_point(at),5,1.0)
	for entry in LAYOUT.data.plaques:
		var at := _point(entry.at)
		# Ceramic plaques sit beside the walkway, rather than occupying its centre.
		var width := ThemeDB.fallback_font.get_string_size(entry.text,HORIZONTAL_ALIGNMENT_LEFT,-1,15).x+24
		_detail("plaque",at+Vector2(-160,-125),entry.text,width)
	for entry in LAYOUT.data.bunting:
		var flags := preload("res://scripts/village_bunting.gd").new()
		flags.position = _point(entry.a)
		flags.span = _point(entry.b)-flags.position
		flags.z_index = 5
		add_child(flags)

func _detail(kind: String, at: Vector2, text := "", width := 180.0) -> void:
	var detail := Detail.new()
	detail.name = kind+"_"+str(actors.get_child_count())
	detail.kind = kind
	detail.position = at
	detail.text = text
	detail.width = width
	actors.add_child(detail)

func _build_gardens() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 311026
	# Vegetation belongs to the two gardens and the outside edge of the town.
	for zone_data in LAYOUT.data.garden_zones:
		var zone := _rect(zone_data)
		for i in 130:
			var at := zone.position+Vector2(rng.randf(),rng.randf())*zone.size
			if _on_ground(at,-135): continue
			if buildings.any(func(b): return b.screen_bounds.grow(60).has_point(at)): continue
			Props.add(self,at,i%2,rng.randf_range(.7,1.05))
		for i in 50:
			var at := zone.position+Vector2(rng.randf(),rng.randf())*zone.size
			if not _on_ground(at,-50): Props.add(self,at,2,rng.randf_range(.55,.9))
	for i in 110:
		var at := Vector2(rng.randf_range(350,WORLD_SIZE.x-350),rng.randf_range(800,WORLD_SIZE.y-350))
		if _on_ground(at,-200): continue
		var urban := false
		for zone in LAYOUT.data.urban_zones:
			if _rect(zone).grow(250).has_point(at): urban = true; break
		if not urban: Props.add(self,at,i%2,rng.randf_range(.8,1.15))

func _index_new_solids() -> void:
	while indexed_rects<blocked_rects.size():
		_index_bounds(solid_buckets,blocked_rects[indexed_rects].grow(160),indexed_rects)
		indexed_rects += 1
	while indexed_circles<circles.size():
		var circle := circles[indexed_circles]
		var radius := circle.z+160
		_index_bounds(circle_buckets,Rect2(Vector2(circle.x,circle.y)-Vector2.ONE*radius,Vector2.ONE*radius*2),indexed_circles)
		indexed_circles += 1

func _on_ground(at: Vector2, margin := 0.0, earth_only := false) -> bool:
	if margin>0:
		if not _on_ground(at,0,earth_only): return false
		for i in 8:
			if not _on_ground(at+Vector2.from_angle(i*TAU/8)*margin,0,earth_only): return false
		return true
	var key := Vector2i((at/256).floor())
	for index in plaza_buckets.get(key,[]):
		var plaza: Dictionary = plazas[index]
		if earth_only and plaza.get("surface","")!="earth": continue
		if plaza.rect.grow(-margin).has_point(at): return true
	for index in ground_buckets.get(key,[]):
		var segment: Dictionary = ground_segments[index]
		if earth_only and segment.surface!="earth": continue
		var radius: float = segment.radius-margin
		if radius>0 and at.distance_squared_to(Geometry2D.get_closest_point_to_segment(at,segment.a,segment.b))<radius*radius: return true
	# The broad mineral courtyards are visibly paved too. The painted gardens
	# override these rectangles; their paths and earth squares were handled above.
	if not earth_only and not garden_floor.any(func(rect): return rect.has_point(at)):
		for rect in urban_floor:
			if rect.grow(-margin).has_point(at): return true
	return false

func is_walkable(at: Vector2, margin := 14.0) -> bool:
	if at.x<32 or at.y<32 or at.x>WORLD_SIZE.x-32 or at.y>WORLD_SIZE.y-32 or not _on_ground(at,margin): return false
	_index_new_solids()
	var key := Vector2i((at/256).floor())
	for index in circle_buckets.get(key,[]):
		var circle := circles[index]
		if at.distance_squared_to(Vector2(circle.x,circle.y))<pow(circle.z+margin,2): return false
	for index in solid_buckets.get(key,[]):
		if blocked_rects[index].grow(margin).has_point(at): return false
	return true

func _raster_floor(bounds: Rect2, segment: Dictionary = {}) -> void:
	var first := Vector2i((bounds.position/CELL).floor()).max(Vector2i.ZERO)
	var last := Vector2i((bounds.end/CELL).ceil()).min(Vector2i(WORLD_SIZE/CELL)-Vector2i.ONE)
	for x in range(first.x,last.x+1):
		for y in range(first.y,last.y+1):
			var key := Vector2i(x,y)
			if floor_cells.has(key): continue
			var at := (Vector2(key)+Vector2.ONE*.5)*CELL
			if segment.is_empty():
				if bounds.has_point(at): floor_cells[key] = true
			elif at.distance_squared_to(Geometry2D.get_closest_point_to_segment(at,segment.a,segment.b))<segment.radius*segment.radius: floor_cells[key] = true

func _bake_navigation_and_boundary() -> void:
	# Rasterize only public floor, not every building against all 350,000 grid cells.
	navigation.region = Rect2i(Vector2i.ZERO,Vector2i(WORLD_SIZE/CELL))
	navigation.cell_size = Vector2.ONE*CELL
	navigation.offset = Vector2.ONE*CELL*.5
	navigation.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	navigation.default_compute_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	navigation.default_estimate_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	navigation.update()
	navigation.fill_solid_region(navigation.region,true)
	for rect in urban_floor: _raster_floor(rect)
	for plaza in plazas: _raster_floor(plaza.rect)
	for segment in ground_segments:
		_raster_floor(Rect2(segment.a,Vector2.ZERO).expand(segment.b).grow(segment.radius),segment)
	for cell: Vector2i in floor_cells.keys():
		if not _on_ground(navigation.get_point_position(cell)):
			floor_cells.erase(cell)
	for cell: Vector2i in floor_cells:
		if is_walkable(navigation.get_point_position(cell),23): navigation.set_point_solid(cell,false)
	# Keep the coarse outer collider outside the analytic public floor. A raw
	# stair-step raster edge could block a body even when its A* route was clear.
	var boundary_floor: Dictionary = floor_cells.duplicate()
	for cell: Vector2i in floor_cells:
		for dx in range(-1,2):
			for dy in range(-1,2): boundary_floor[cell+Vector2i(dx,dy)] = true
	var segments := PackedVector2Array()
	var edges := [[Vector2i(-1,0),Vector2.ZERO,Vector2(0,CELL)],[Vector2i(1,0),Vector2(CELL,0),Vector2(CELL,CELL)],[Vector2i(0,-1),Vector2.ZERO,Vector2(CELL,0)],[Vector2i(0,1),Vector2(0,CELL),Vector2(CELL,CELL)]]
	for cell: Vector2i in boundary_floor:
		var origin := Vector2(cell)*CELL
		for edge in edges:
			if not boundary_floor.has(cell+edge[0]):
				segments.append(origin+edge[1])
				segments.append(origin+edge[2])
	var boundary := StaticBody2D.new()
	boundary.name = "PublicStreetPerimeter"
	var shape := ConcavePolygonShape2D.new()
	shape.segments = segments
	var collision := CollisionShape2D.new()
	collision.shape = shape
	boundary.add_child(collision)
	add_child(boundary)

func _observations() -> Array:
	var result: Array = []
	for entry in LAYOUT.data.observations:
		var target: Dictionary = entry.duplicate(true)
		target.position = _point(entry.position)
		# Move a plaque's interaction point onto its nearest clear public approach.
		var preferred: Vector2 = target.position
		if not is_walkable(preferred,16):
			for radius in range(32,416,32):
				var found := false
				for i in 16:
					var candidate := preferred+Vector2.from_angle(i*TAU/16)*radius
					if is_walkable(candidate,16): target.position = candidate; found = true; break
				if found: break
		result.append(target)
	for spec in TERRACES.data.terraces:
		result.append({"id":"terrace_"+str(spec.id),"kind":"observation","label":spec.name,"position":_rect(spec.platform).get_center(),"reach":115.0,"radius":0.0,"text":"Um lanço de degraus liga a rua a este pequeno patamar. Entre os vasos e o muro de pedra, vemos os telhados de outro ângulo."})
	return result

func attach_people(value: Array) -> void: people = value
func find_path(from: Vector2, to: Vector2) -> PackedVector2Array: return Navigation.find_path(self,from,to)
func can_walk_line(from: Vector2, to: Vector2) -> bool:
	# Sampling alone can miss the very tip of a house corner, causing a smoothed
	# route to stop there forever. Test solid geometry continuously as well.
	_index_new_solids()
	var rectangles: Dictionary = {}
	var round_solids: Dictionary = {}
	var clearance := 24.0 if from.distance_to(to)>64 else 16.0
	var samples := maxi(1,ceili(from.distance_to(to)/128.0))
	for i in range(samples+1):
		var key := Vector2i((from.lerp(to,float(i)/samples)/256).floor())
		for index in solid_buckets.get(key,[]): rectangles[index] = true
		for index in circle_buckets.get(key,[]): round_solids[index] = true
	for index in rectangles:
		if _segment_hits_rect(from,to,blocked_rects[index].grow(clearance)): return false
	for index in round_solids:
		var circle := circles[index]
		var center := Vector2(circle.x,circle.y)
		if center.distance_to(Geometry2D.get_closest_point_to_segment(center,from,to))<circle.z+clearance: return false
	var floor_samples := maxi(1,ceili(from.distance_to(to)/(8.0 if clearance>16 else 4.0)))
	for i in range(floor_samples+1):
		if not _on_ground(from.lerp(to,float(i)/floor_samples),clearance): return false
	return true
func _segment_hits_rect(from: Vector2, to: Vector2, rect: Rect2) -> bool:
	var first := 0.0
	var last := 1.0
	var vector := to-from
	for axis in 2:
		if absf(vector[axis])<.00001:
			if from[axis]<rect.position[axis] or from[axis]>rect.end[axis]: return false
		else:
			var a: float = (rect.position[axis]-from[axis])/vector[axis]
			var b: float = (rect.end[axis]-from[axis])/vector[axis]
			first = maxf(first,minf(a,b))
			last = minf(last,maxf(a,b))
			if first>last: return false
	return true
func river_x(_y: float) -> float: return -1000.0
func in_water(_at: Vector2, _margin := 0.0) -> bool: return false
func allows_ground_rest(at: Vector2) -> bool:
	if manual_street_rest:
		# Explicit sleep is allowed on a clear stretch of paving too. Passive
		# daytime idling still prefers the gardens, rather than lying across a street.
		if not is_walkable(at,100): return false
		return not buildings.any(func(b):return b.position.y>=at.y and (b.screen_bounds.has_point(at-Vector2(0,70)) or b.screen_bounds.has_point(at-Vector2(0,150))))
	if not _on_ground(at,75,true): return false
	var key := Vector2i((at/256).floor())
	for index in ground_buckets.get(key,[]):
		var segment: Dictionary = ground_segments[index]
		if segment.surface!="earth" and at.distance_to(Geometry2D.get_closest_point_to_segment(at,segment.a,segment.b))<segment.radius+55: return false
	for index in plaza_buckets.get(key,[]):
		var plaza: Dictionary = plazas[index]
		if plaza.get("surface","")!="earth" and plaza.rect.grow(55).has_point(at): return false
	return true
func step_environment(delta: float, cycle: RefCounted) -> void:
	ambient_time += delta
	if is_instance_valid(nightlife): nightlife.prepare(cycle)
	neighbour_clock -= delta
	if neighbour_clock<=0:
		neighbour_clock = .15
		neighbour_cells.clear()
		if is_instance_valid(social_life):
			for a in social_life.actors:
				if not a.visible: continue
				var cell := Vector2i((a.position/128).floor())
				if not neighbour_cells.has(cell): neighbour_cells[cell] = []
				neighbour_cells[cell].append(a)
	if is_instance_valid(population): population.step(delta,cycle)
	if is_instance_valid(street_life): street_life.step(delta,cycle)
	if is_instance_valid(festival_life): festival_life.step(delta,cycle)
	if is_instance_valid(living_life): living_life.step(delta,cycle)
	if is_instance_valid(neighbourhood): neighbourhood.step(delta,cycle)
	if is_instance_valid(passers): passers.step(delta,cycle)
	if is_instance_valid(social_life): social_life.step(delta,cycle)
	if is_instance_valid(dining): dining.step(delta,cycle)
	if is_instance_valid(nightlife): nightlife.step(delta,cycle)
	if is_instance_valid(chestnuts): chestnuts.step(delta,cycle)
	if is_instance_valid(lighting): lighting.step(delta,cycle)

func synchronize_clock(cycle: RefCounted, force := false) -> void:
	if is_instance_valid(nightlife): nightlife.release_all()
	if is_instance_valid(social_life): social_life.reset(cycle)
	population.synchronize(cycle,force)
	street_life.synchronize(cycle,force)
	festival_life.synchronize(cycle,force)
	living_life.synchronize(cycle,force)
	neighbourhood.synchronize(cycle,force)
	passers.synchronize(cycle,force)
	nightlife.synchronize(cycle)
	chestnuts.step(0,cycle)
	lighting.step(0,cycle)
func terrace_bounds(spec: Dictionary) -> Rect2:
	var platform := _rect(spec.platform)
	return Rect2(platform.position,platform.size+Vector2(0,float(spec.run)+float(spec.landing)))
func stair_rect(spec: Dictionary) -> Rect2:
	var platform := _rect(spec.platform)
	return Rect2(platform.get_center().x-spec.stair_width*.5,platform.end.y,spec.stair_width,spec.run)
func elevation_at(at: Vector2) -> float:
	for spec in TERRACES.data.terraces:
		if _rect(spec.platform).has_point(at): return spec.rise
		var stairs := stair_rect(spec)
		if stairs.has_point(at): return (1.0-(at.y-stairs.position.y)/stairs.size.y)*float(spec.rise)
	return 0
func walking_multiplier(at: Vector2) -> float:
	for spec in TERRACES.data.terraces:
		if stair_rect(spec).has_point(at): return .74
	return 1
func area_at(at: Vector2) -> String:
	for spec in TERRACES.data.terraces:
		if _rect(spec.platform).has_point(at): return spec.name
		if stair_rect(spec).has_point(at): return "Escadas · "+str(spec.name)
	var result := "Ruas da Vila Velha"
	for district in LAYOUT.data.districts:
		if _rect(district.rect).has_point(at): result = district.name; break
	var distance := INF
	for place in landmarks:
		var gap := at.distance_to(place.position)
		if gap<place.radius and gap<distance: result = place.name; distance = gap
	return result

func draw_exploration_map(canvas: Control, paper: Rect2) -> void:
	var factor := paper.size/WORLD_SIZE
	canvas.draw_rect(paper,Color("647b59"))
	for zone in LAYOUT.data.urban_zones:
		var bounds := _rect(zone)
		canvas.draw_rect(Rect2(paper.position+bounds.position*factor,bounds.size*factor),Color("aaa18a"))
	for route in routes:
		var points := PackedVector2Array()
		for point in route.points: points.append(paper.position+point*factor)
		canvas.draw_polyline(points,Color("c4b78e") if route.surface=="earth" else Color("ece0bd"),maxf(2,route.width*factor.x),true)
	for plaza in plazas: canvas.draw_rect(Rect2(paper.position+plaza.rect.position*factor,plaza.rect.size*factor),Color("e6d9b7"))
	for building in buildings:
		var bounds: Rect2 = building.ground_bounds
		canvas.draw_rect(Rect2(paper.position+bounds.position*factor,bounds.size*factor),Color("9e654e"))

	if is_instance_valid(living_life): living_life.draw_map(canvas,paper)

func nearby_people(at: Vector2) -> Array:
	var result: Array = []
	var cell := Vector2i((at/128).floor())
	for x in range(-1,2):
		for y in range(-1,2): result.append_array(neighbour_cells.get(cell+Vector2i(x,y),[]))
	return result
