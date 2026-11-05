extends CharacterBody2D
## Slow real tours, a dedicated wide-road grid, pedestrian yielding and a chatty driver.
const ART = preload("res://data/village/festival-art.json")
const GRID := 64.0
var director: Node2D
var driver: CharacterBody2D
var kind := ""
var boarded := false
var navigation: AStarGrid2D
var path := PackedVector2Array()
var stops: Array[Vector2] = []
var stop_index := 0
var facing := Vector2.RIGHT
var elapsed := 0.0
var wait := 0.0
var contact_cooldown := 0.0
var conversation_count := 0
var target_player: CharacterBody2D
var seeking_player := false
var yielded := 0.0
var distance_travelled := 0.0
var margin := 62.0
var texture: Texture2D
var poses: Array = []
var moving_now := false
var community_hub := Vector2.INF

func _ready() -> void:
	name = "Tour_"+kind
	collision_layer = 0
	collision_mask = 0
	margin = 110 if kind=="carriage" else 85
	material = director.world.opaque_paint
	var spec: Dictionary = ART.data.vehicles[kind]
	texture = load(spec.path)
	poses = spec.frames
	if not director.traffic_grids.has(margin): director.traffic_grids[margin] = _build_grid()
	navigation = director.traffic_grids[margin]
	position = _nearest(position)
	if position==Vector2.INF: position = _nearest(director.world.menu_spawn)
	var authored: Array = [Vector2(18000,7560),Vector2(19000,7650),Vector2(18850,8040),Vector2(18100,8010)] if kind=="carriage" else ([Vector2(9800,2390),Vector2(9600,3350),Vector2(9900,4800),Vector2(11500,7850),Vector2(13700,6500),Vector2(15500,5200)] if kind=="tuk_green" else [Vector2(15500,5200),Vector2(18700,4700),Vector2(18500,7750),Vector2(13800,6600)])
	for point in authored:
		var at: Vector2 = _nearest(point)
		if at!=Vector2.INF: stops.append(at)
	# The palace's pedestrian exits can be too narrow for a tuk-tuk. Keep real
	# local tour stops as well, rather than repeatedly requesting an impossible exit.
	if kind=="tuk_green":
		for point in [Vector2(9000,2250),Vector2(10550,2250),Vector2(10300,2500),Vector2(9500,2150)]:
			var at: Vector2 = _nearest(point)
			if at!=Vector2.INF and not stops.has(at): stops.append(at)
		_reachable_circuit()
	hide()

func _component(at: Vector2) -> Dictionary:
	var start := Vector2i(at/GRID)
	var reached := {start:true}
	var queue: Array[Vector2i] = [start]
	var head := 0
	while head<queue.size():
		var cell: Vector2i = queue[head]
		head += 1
		for offset in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
			var next: Vector2i = cell+offset
			if not navigation.region.has_point(next) or navigation.is_point_solid(next) or reached.has(next): continue
			reached[next] = true
			queue.append(next)
	return reached

func _reachable_circuit() -> void:
	var reached: Dictionary = _component(position)
	if reached.size()<64:
		var checked: Dictionary = reached.duplicate()
		var found := false
		for radius in range(1,13):
			for i in 16:
				var candidate: Vector2 = _nearest(position+Vector2.from_angle(i*TAU/16)*radius*GRID)
				if candidate==Vector2.INF or checked.has(Vector2i(candidate/GRID)): continue
				var component: Dictionary = _component(candidate)
				checked.merge(component)
				if component.size()>=64:
					position = candidate
					reached = component
					found = true
					break
			if found: break
	var connected: Array[Vector2] = []
	for point in stops:
		if reached.has(Vector2i(point/GRID)): connected.append(point)
	for direction in [Vector2(1,1),Vector2(-1,1),Vector2(-1,-1),Vector2(1,-1)]:
		var best := position
		var score := -INF
		for cell in reached:
			var point: Vector2 = navigation.get_point_position(cell)
			if point.dot(direction)>score: best = point; score = point.dot(direction)
		if not connected.has(best): connected.append(best)
	stops = connected

func _on_road(at: Vector2) -> bool:
	var world: Node2D = director.world
	var key := Vector2i((at/256).floor())
	for index in world.plaza_buckets.get(key,[]):
		var plaza: Dictionary = world.plazas[index]
		if plaza.rect.grow(-margin).has_point(at): return true
	for index in world.ground_buckets.get(key,[]):
		var road: Dictionary = world.ground_segments[index]
		if road.surface=="earth" and kind!="carriage": continue
		if at.distance_to(Geometry2D.get_closest_point_to_segment(at,road.a,road.b))<float(road.radius)*.70: return true
	return false

func _build_grid() -> AStarGrid2D:
	var grid := AStarGrid2D.new()
	grid.region = Rect2i(Vector2i.ZERO,Vector2i(director.world.WORLD_SIZE/GRID))
	grid.cell_size = Vector2.ONE*GRID
	grid.offset = Vector2.ONE*GRID*.5
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	grid.update()
	for x in grid.region.size.x:
		for y in grid.region.size.y:
			var cell := Vector2i(x,y)
			var at: Vector2 = grid.get_point_position(cell)
			grid.set_point_solid(cell,not (_on_road(at) and director.world.is_walkable(at,margin+12) and director.world.elevation_at(at)==0))
	return grid

func _nearest(at: Vector2) -> Vector2:
	var cell := Vector2i(at/GRID)
	for radius in range(0,14):
		var best := Vector2.INF
		var distance := INF
		for dx in range(-radius,radius+1):
			for dy in range(-radius,radius+1):
				var id := cell+Vector2i(dx,dy)
				if not navigation.region.has_point(id) or navigation.is_point_solid(id): continue
				var candidate: Vector2 = navigation.get_point_position(id)
				if candidate.distance_squared_to(at)<distance: best = candidate; distance = candidate.distance_squared_to(at)
		if best!=Vector2.INF: return best
	return Vector2.INF

func _safe_line(a: Vector2,b: Vector2) -> bool:
	var samples := maxi(1,ceili(a.distance_to(b)/20))
	for i in range(samples+1):
		var at := a.lerp(b,float(i)/samples)
		if not director.world.is_walkable(at,margin) or director.world.elevation_at(at)!=0: return false
	return true

func _route(to: Vector2, avoid: Array = []) -> bool:
	var changed: Array[Vector2i] = []
	for person in avoid:
		if person==driver or not person.visible: continue
		var center := Vector2i(person.position/GRID)
		for dx in range(-2,3):
			for dy in range(-2,3):
				var cell := center+Vector2i(dx,dy)
				if not navigation.region.has_point(cell) or navigation.is_point_solid(cell): continue
				var at: Vector2 = navigation.get_point_position(cell)
				if at.distance_to(person.position)<90 and at.distance_to(position)>80:
					navigation.set_point_solid(cell,true)
					changed.append(cell)
	var end: Vector2 = _nearest(to)
	var start := Vector2.INF
	var start_distance := INF
	var around := Vector2i(position/GRID)
	for dx in range(-3,4):
		for dy in range(-3,4):
			var cell := around+Vector2i(dx,dy)
			if not navigation.region.has_point(cell) or navigation.is_point_solid(cell): continue
			var candidate: Vector2 = navigation.get_point_position(cell)
			if candidate.distance_squared_to(position)<start_distance and _safe_line(position,candidate): start = candidate; start_distance = candidate.distance_squared_to(position)
	var result := PackedVector2Array()
	if end!=Vector2.INF and start!=Vector2.INF: result = navigation.get_point_path(Vector2i(start/GRID),Vector2i(end/GRID))
	for cell in changed: navigation.set_point_solid(cell,false)
	if result.is_empty(): return false
	path = result
	return true

func board() -> void:
	boarded = true
	driver._cancel_encounter()
	driver.state = "riding"
	driver.route.clear()
	driver.collision_layer = 0
	driver.collision_mask = 0
	driver.art.hide()
	driver.position = position
	driver.show()
	show()

func disembark() -> void:
	if not boarded: return
	boarded = false
	seeking_player = false
	target_player = null
	path.clear()
	driver._outside()
	driver.art.show()
	driver.state = "activity"
	for block in driver.schedule:
		if block.mode!="inside": block.destination = position
	hide()

func synchronize(cycle: RefCounted) -> void:
	contact_cooldown = 0
	wait = 0
	seeking_player = false
	path.clear()
	if driver.appointment.mode=="inside": disembark(); hide(); return
	var at: Vector2 = _nearest(driver.position if community_hub==Vector2.INF else community_hub)
	if at!=Vector2.INF: position = at
	board()
	stop_index = posmod(int(cycle.minutes/40),maxi(1,stops.size()))
	for block in driver.schedule:
		if block.mode!="inside": block.destination = position
	if not stops.is_empty(): _route(stops[stop_index])

func available() -> bool: return boarded and visible
func interaction_prompt() -> String: return "Ouvir o Tó · mais uma história da vila" if kind=="tuk_green" else ("Conhecer o Castanho e a carroça" if kind=="carriage" else "Pedir o roteiro do tuk-tuk")
func interact(_player: CharacterBody2D) -> String:
	if is_instance_valid(director.world.get("living_life")) and _player!=null and kind!="carriage":
		director.world.living_life.guide_choice(self,_player)
		return ""
	wait = 5
	conversation_count += 1
	var lines: Array = ["Ó Te! Ó Jo! Então, já vos falei desta curva?","Vocês andam depressa, mas eu tenho histórias para todas as paragens!","Só para dizer olá. Pronto, e para perguntar se já provaram as queijadas."] if kind=="tuk_green" else driver.motion.personality.lines
	var line: String = lines[(conversation_count-1)%lines.size()]
	director.world.social_life._say(driver,line,"speak")
	return driver.entry.name+": "+line

func _spot_player() -> void:
	if kind!="tuk_green" or contact_cooldown>0 or seeking_player: return
	for person in director.world.people:
		if not person.controlled or not person.moving or person.position.distance_to(position)>850: continue
		var ray := PhysicsRayQueryParameters2D.create(position,person.position,1)
		if not get_world_2d().direct_space_state.intersect_ray(ray).is_empty(): continue
		for offset in [Vector2(190,10),Vector2(-190,10),Vector2(0,190),Vector2(0,-190)]:
			var point: Vector2 = _nearest(person.position+offset)
			if point==Vector2.INF or point.distance_to(person.position)<120 or point.distance_to(person.position)>290: continue
			if not _route(point): continue
			target_player = person
			seeking_player = true
			contact_cooldown = 40
			return

func step(delta: float, cycle: RefCounted) -> void:
	moving_now = false
	elapsed += delta
	contact_cooldown = maxf(0,contact_cooldown-delta)
	if driver.appointment.mode=="inside": disembark(); return
	if not boarded:
		if driver.available() and driver.state=="activity" and driver.position.distance_to(position)<45: board()
		else: return
	if wait>0:
		wait -= delta
		driver.position = position
		queue_redraw()
		return
	if is_instance_valid(director.world.get("living_life")) and director.world.living_life.park_guide(self):
		driver.position = position
		queue_redraw()
		return
	_spot_player()
	if seeking_player and is_instance_valid(target_player) and position.distance_to(target_player.position)<290:
		path.clear()
		seeking_player = false
		interact(null)
		return
	if path.is_empty():
		seeking_player = false
		if stops.is_empty(): return
		stop_index = (stop_index+1)%stops.size()
		if not _route(stops[stop_index]): wait = 3; return
		wait = 3.5 if kind!="carriage" else 7
		if kind=="carriage": director.world.social_life._say(driver,"Pausa para o Castanho descansar. O passeio não tem pressa.","listen")
		return
	while not path.is_empty() and position.distance_to(path[0])<5: path.remove_at(0)
	if path.is_empty(): return
	var direction: Vector2 = position.direction_to(path[0])
	var ahead: Vector2 = position+direction*(130 if kind=="carriage" else 110)
	var crowd: Array = director.world.social_life.actors+director.world.people
	var blocked: bool = crowd.any(func(a): return a!=driver and a.visible and a.position.distance_to(ahead)<70)
	if blocked:
		yielded += delta
		if yielded>7:
			_route(path[-1],crowd)
			yielded = 0
			return
		if yielded>4:
			for sign in [-1,1]:
				var aside: Vector2 = position+direction.rotated(PI*.5)*sign*80+direction*65
				if _on_road(aside) and _safe_line(position,aside) and not crowd.any(func(a): return a!=driver and a.visible and a.position.distance_to(aside)<90): path.insert(0,aside); yielded = 0; break
		return
	yielded = 0
	var speed := 68.0 if kind=="carriage" else 100.0
	if seeking_player: speed = 290
	var displacement := direction*minf(speed*delta,position.distance_to(path[0]))
	if _safe_line(position,position+displacement):
		moving_now = true
		position += displacement
		facing = direction
		distance_travelled += displacement.length()
	else: path.clear()
	driver.position = position
	driver.travelled += displacement.length()
	queue_redraw()

func _draw() -> void:
	if poses.is_empty(): return
	var frame: int = int(elapsed*4)%2 if moving_now else 0
	if absf(facing.y)>absf(facing.x)*1.1: frame = 2 if facing.y>0 else 3
	var pose: Dictionary = poses[frame]
	var r: Array = pose.rect
	var rect := Rect2(r[0],r[1],r[2],r[3])
	var scale_value: float = (220 if kind=="carriage" else 190)/rect.size.y
	var foot := Vector2(pose.foot[0],pose.foot[1])*scale_value
	draw_set_transform(Vector2.ZERO,0,Vector2(-1 if facing.x<0 else 1,1))
	draw_texture_rect_region(texture,Rect2(-foot,rect.size*scale_value),rect)
	draw_set_transform(Vector2.ZERO)
