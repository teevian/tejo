extends Node2D
## A reactive flock and one opportunistic neighbourhood cat; local, sparse decisions.
var director: Node2D
var flock: Array[Dictionary] = []
var cat := Vector2.ZERO
var cat_goal := Vector2.ZERO
var cat_frame := 0
var cat_house := 0
var clock := 0.0
var home := Vector2.ZERO
var feed := Vector2.INF
var food_until := 0.0
var frightened := 0
var cat_visits := 0
var rethink := 0.0
var accumulated := 0.0
var painters: Array[Node2D] = []
var cat_painter: Node2D
func _ready() -> void:
	material = director.world.opaque_paint
	for i in 28:
		var at: Vector2 = director.routines.clear_destination(home+Vector2.from_angle(i*2.4)*(35+i%6*24),[])
		flock.append({"at":at,"home":at,"goal":at,"fly":0.0,"phase":float(i),"follow":false})
		var painter := preload("res://scripts/village_living_animal_art.gd").new()
		painter.community = self
		painter.bird = flock[-1]
		painter.position = at
		director.world.actors.add_child(painter)
		painters.append(painter)
	cat = director.by_id.dario.home
	cat_goal = cat
	cat_painter = preload("res://scripts/village_living_animal_art.gd").new()
	cat_painter.community = self
	cat_painter.is_cat = true
	cat_painter.position = cat
	director.world.actors.add_child(cat_painter)
func step(delta: float) -> void:
	clock += delta
	accumulated += delta
	rethink -= delta
	var local: bool = director.world.people.any(func(p):return p.position.distance_to(home)<1400 or p.position.distance_to(cat)<900)
	if not local and rethink>0: return
	delta = accumulated
	accumulated = 0
	if rethink<=0:
		rethink = .7
		var scared := Vector2.INF
		for p in director.world.people:
			if p.moving and p.velocity.length()>180:
				for bird in flock:
					if p.position.distance_to(bird.at)<100: scared = p.position; break
		for a in [director.by_id.dinis]:
			if a.available() and a.velocity.length()>150 and a.position.distance_to(home)<350: scared = a.position
		for i in flock.size():
			var bird: Dictionary = flock[i]
			if scared!=Vector2.INF and bird.at.distance_to(scared)<280:
				bird.fly = 3.5+float(i%4)*.35
				var away: Vector2 = scared.direction_to(bird.at)
				var safe: Vector2 = director.free_point(bird.at+away*180)
				if safe!=Vector2.INF: bird.goal = safe
				frightened += 1
			elif clock>food_until:
				bird.goal = bird.home+Vector2(sin(clock*.13+i),cos(clock*.11+i))*25
			else:
				bird.goal = feed+Vector2.from_angle(i*2.4)*(12+i%5*12)
			if bird.follow and clock<food_until:
				var p: CharacterBody2D = director.player()
				if is_instance_valid(p): bird.goal = p.position+Vector2(-45,25)
		var previous_house := cat_house
		cat_house = int(clock/60)%3
		if cat_house!=previous_house: remove_meta("cat_route")
		cat_goal = [director.by_id.dario.home,director.by_id.lurdes_sardinha.home,home+Vector2(220,0)][cat_house]
		if cat.distance_to(cat_goal)<25: cat_frame = int(clock/8)%2
	for bird in flock:
		bird.fly = maxf(0,bird.fly-delta)
		var next: Vector2 = bird.at.move_toward(bird.goal,delta*(125 if bird.fly>0 else 22))
		if director.world.is_walkable(next,3): bird.at = next
	if cat.distance_to(cat_goal)>25:
		# The cat uses the same clear routes as residents, not a line through houses.
		if not has_meta("cat_route") or get_meta("cat_route").is_empty(): set_meta("cat_route",director.world.find_path(cat,cat_goal))
		var path: PackedVector2Array = get_meta("cat_route")
		if not path.is_empty():
			var next := cat.move_toward(path[0],delta*65)
			if director.world.is_walkable(next,6): cat = next
			if cat.distance_to(path[0])<8: path.remove_at(0)
			set_meta("cat_route",path)
		cat_frame = 2+int(clock*5)%2
		if cat.distance_to(cat_goal)<30: cat_visits += 1
	for i in flock.size():
		painters[i].position = flock[i].at
		if local: painters[i].queue_redraw()
	cat_painter.position = cat
	if local: cat_painter.queue_redraw()
func feed_at(at: Vector2, follow := true) -> void:
	feed = at
	food_until = clock+65
	flock[0].follow = follow
