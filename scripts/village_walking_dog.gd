extends CharacterBody2D
const ART = preload("res://data/village/festival-art.json")
var director: Node2D
var walker: CharacterBody2D
var texture: Texture2D
var route := PackedVector2Array()
var clock := 0.0
var rethink := 0.0
var travelled := 0.0
var frame := 0
var left := false
var pet_until := 0.0
var leash: Node2D
func _ready() -> void:
	name = "BolachaOnAWalk"
	collision_layer = 0
	collision_mask = 1
	texture = load(ART.data.dog.path)
	material = director.world.opaque_paint
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 8
	collision.shape = shape
	add_child(collision)
	leash = preload("res://scripts/village_dog_leash.gd").new()
	add_child(leash)
	synchronize()
func synchronize() -> void:
	var at: Vector2 = director.world.interactions.find_drop_position(walker.position+Vector2(65,30))
	position = walker.position if at==Vector2.INF else at
	route.clear()
	visible = walker.available()
func step(delta: float) -> void:
	clock += delta
	visible = walker.available()
	if not visible: return
	if clock<pet_until: frame = 3; queue_redraw(); return
	rethink -= delta
	if rethink<=0:
		rethink = .8
		_plan_walk()
	var gap := position.distance_to(walker.position)
	var sniff: bool = fposmod(clock,14)<2 and gap<150
	if sniff: frame = 2
	elif gap<65: frame = 3
	else:
		while not route.is_empty() and position.distance_to(route[0])<8: route.remove_at(0)
		var lookahead: int = mini(8,route.size()-1)
		while lookahead>0:
			if position.distance_to(route[lookahead])<320 and _clear_line(position,route[lookahead]):
				for i in lookahead: route.remove_at(0)
				break
			lookahead -= 1
		if not route.is_empty():
			var direction := position.direction_to(route[0])
			var displacement := direction*minf(delta*145,position.distance_to(route[0]))
			if _clear_line(position,position+displacement): move_and_collide(displacement); travelled += displacement.length()
			left = direction.x<0
			frame = int(travelled/18)%2
	queue_redraw()
	leash.queue_redraw()
func _clear_line(a: Vector2,b: Vector2) -> bool:
	var steps := maxi(1,ceili(a.distance_to(b)/2))
	for i in range(steps+1):
		if not director.world.is_walkable(a.lerp(b,float(i)/steps),9): return false
	return true

func _visible_entry(at: Vector2) -> Vector2:
	var cell := Vector2i(at/director.world.CELL)
	for radius in range(0,8):
		var best := Vector2.INF
		var distance := INF
		for dx in range(-radius,radius+1):
			for dy in range(-radius,radius+1):
				var id := cell+Vector2i(dx,dy)
				if not director.world.navigation.region.has_point(id) or director.world.navigation.is_point_solid(id): continue
				var point: Vector2 = director.world.navigation.get_point_position(id)
				if point.distance_squared_to(at)<distance and _clear_line(at,point): best = point; distance = point.distance_squared_to(at)
		if best!=Vector2.INF: return best
	return Vector2.INF

func _plan_walk() -> void:
	var from: Vector2 = _visible_entry(position)
	if from==Vector2.INF: return
	for offset in [Vector2(45,25),Vector2(-45,25),Vector2(0,40),Vector2(0,-40),Vector2.ZERO]:
		var goal: Vector2 = walker.position+offset
		if not director.world.is_walkable(goal,9): continue
		var to: Vector2 = _visible_entry(goal)
		if to==Vector2.INF: continue
		var path: PackedVector2Array = director.world.find_path(from,to)
		if path.is_empty(): continue
		path.append(goal)
		route = path
		return
func available() -> bool: return visible and walker.available()
func interaction_prompt() -> String: return "Fazer festas à Bolacha"
func interact(_player: CharacterBody2D) -> String:
	pet_until = clock+3
	walker.greet_time = 3
	director.world.social_life._say(walker,"A Bolacha já vos adotou para o passeio!","greet")
	return "A Bolacha senta-se, abana a cauda e recebe as festas. A Bea espera por ela antes de continuar."
func _draw() -> void:
	if not visible: return
	var pose: Dictionary = ART.data.dog.frames[frame]
	var r: Array = pose.rect
	var rect := Rect2(r[0],r[1],r[2],r[3])
	var factor := 54.0/rect.size.y
	var foot := Vector2(pose.foot[0],pose.foot[1])*factor
	draw_set_transform(Vector2.ZERO,0,Vector2(-1 if left else 1,1))
	draw_texture_rect_region(texture,Rect2(-foot,rect.size*factor),rect)
	draw_set_transform(Vector2.ZERO)
