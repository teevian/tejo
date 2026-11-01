extends RefCounted
## The persistent world is X/Y/Z. Physics sees one orthographic X/Y projection.
## A turn changes that projection, never the underlying positions or rope length.
const Route = preload("res://scripts/climbing_route.gd")
const TURN_SECONDS := 0.55
const FACE_NAMES := ["Frente","Direita","Trás","Esquerda"]
var scene: Node2D
var boxes: Array[Dictionary] = []
var actors: Array[Vector3] = []
var view := 0
var angle := 0.0
var rotating := false
var turn_time := 0.0
var turn_start := 0.0
var turn_end := 0.0
var next_view := 0
var turns := 0

func setup() -> void:
	boxes.clear()
	view = 0
	angle = 0
	rotating = false
	turns = 0
	for p in scene.platforms:
		var box := {"id":int(p.id),"left":float(p.x),"right":float(p.end),"back":-80.0,"front":80.0,"y":float(p.y),"slope":float(p.get("slope",0)),"height":minf(230,(float(p.end)-float(p.x))*0.50)}
		if Route.BOUNDS.has(int(p.id)):
			var bounds: Array = Route.BOUNDS[int(p.id)]
			box.left = float(bounds[0]); box.right = float(bounds[1])
			box.back = float(bounds[2]); box.front = float(bounds[3])
		boxes.append(box)
	for edge in scene.links: edge["original_dir"] = int(edge.dir)
	for stone in scene.boulders:
		var box: Dictionary = boxes[stone.parent]
		var original: Dictionary = scene.platforms[stone.parent]
		var t := (float(stone.x)-float(original.x))/(float(original.end)-float(original.x))
		stone["world"] = Vector3(lerpf(box.left,box.right,t),0,float(stone.get("z",(float(box.back)+float(box.front))*0.5)))
		stone["home"] = stone.world
		sync_boulder(stone)
	actors.clear()
	for person in scene.people: actors.append(Vector3(person.position.x,person.position.y,0))
	project_geometry()

func step_person(person, delta: float) -> bool:
	var travel: Dictionary = person.traversal.duplicate()
	var landed: bool = person.step(delta)
	if travel.has("world_path"):
		var path: Array = travel.world_path
		var length := 0.0
		for i in path.size()-1: length += path[i].distance_to(path[i+1])
		var remaining := length*smoothstep(0.0,1.0,person.progress)
		var point: Vector3 = path[-1]
		for i in path.size()-1:
			var segment: float = path[i].distance_to(path[i+1])
			if remaining<=segment:
				point = path[i].lerp(path[i+1],remaining/maxf(1,segment))
				break
			remaining -= segment
		set_world(person,point)
		person.modulate.a = 1.0 if landed else 1.0-sin(PI*person.progress)*0.62
	elif travel.has("world_from"):
		var t := smoothstep(0.0,1.0,person.progress)
		var horizontal := smoothstep(0.20,1.0,person.progress)
		if travel.get("action","")=="descend": horizontal = smoothstep(0.0,0.65,person.progress)
		var point: Vector3 = travel.world_from.lerp(travel.world_to,horizontal)
		point.y = lerpf(travel.world_from.y,travel.world_to.y,t)
		set_world(person,point)
	return landed

func project(point: Vector3, yaw := NAN) -> Vector2:
	var a := angle if is_nan(yaw) else yaw
	return Vector2(640+(point.x-640)*cos(a)+point.z*sin(a),point.y)

func depth(point: Vector3) -> float:
	return -(point.x-640)*sin(angle)+point.z*cos(angle)

func inverse(point: Vector2, distance: float) -> Vector3:
	return Vector3(640+(point.x-640)*cos(angle)-distance*sin(angle),point.y,(point.x-640)*sin(angle)+distance*cos(angle))

func surface_world(box: Dictionary, x: float, z := 0.0) -> float:
	return Route.height_at(int(box.get("id",18)),float(box.left),float(box.right),float(box.y),float(box.slope),x,z)

func point_for(person, at: Vector2, shelf := -2) -> Vector3:
	var previous: Vector3 = actors[person.kind] if actors.size()>person.kind else Vector3(at.x,at.y,0)
	var result := inverse(at,depth(previous))
	var id: int = person.shelf if shelf==-2 and person.grounded else shelf
	if id>=0 and id<boxes.size():
		var box: Dictionary = boxes[id]
		result.x = clampf(result.x,box.left,box.right)
		result.z = clampf(result.z,box.back,box.front)
	return result

func world_point(person) -> Vector3:
	return point_for(person,person.position)

func surface_y(p: Dictionary, x: float, person = null) -> float:
	var box: Dictionary = boxes[p.id]
	var distance := 0.0
	if person!=null and actors.size()>person.kind: distance = depth(actors[person.kind])
	else: distance = depth(Vector3((box.left+box.right)*0.5,box.y,(box.back+box.front)*0.5))
	var point := inverse(Vector2(x,box.y),distance)
	return surface_world(box,clampf(point.x,box.left,box.right),clampf(point.z,box.back,box.front))

func sync_people() -> void:
	if rotating: return
	for person in scene.people: actors[person.kind] = world_point(person)

func corners(box: Dictionary) -> Array[Vector3]:
	var result: Array[Vector3] = []
	for x in [box.left,box.right]:
		for z in [box.back,box.front]: result.append(Vector3(x,surface_world(box,x),z))
	return result

func project_geometry() -> void:
	for i in boxes.size():
		var p: Dictionary = scene.platforms[i]
		var box: Dictionary = boxes[i]
		var lo := INF
		var hi := -INF
		for point in corners(box):
			var u := project(point).x
			lo = minf(lo,u); hi = maxf(hi,u)
		p.x = lo; p.end = hi
		p.y = float(box.y)
		p.slope = float(box.slope)*cos(angle)
	for edge in scene.links:
		var a: Dictionary = scene.platforms[edge.from]
		var b: Dictionary = scene.platforms[edge.to]
		var dx := (float(b.x)+float(b.end)-float(a.x)-float(a.end))*0.5
		edge.dir = int(signf(dx)) if absf(dx)>8 else int(edge.original_dir)*(1 if view in [0,1] else -1)
	for stone in scene.boulders: stone.x = project(stone.world).x

func can_turn() -> bool:
	return not rotating and not scene.get_tree().paused and scene.dialogue_lines.is_empty() and not scene.rock_falling and not scene.people.any(func(person): return person.traversing() or person.jump_buffer>0)

func turn(direction: int) -> bool:
	if not can_turn():
		if scene.people.any(func(person): return person.traversing() or person.jump_buffer>0):
			scene.hud.message("Terminem este apoio antes de rodar o penedo.")
		return false
	sync_people()
	rotating = true
	turn_time = 0
	turn_start = angle
	turn_end = angle+signi(direction)*PI*0.5
	next_view = posmod(view+signi(direction),4)
	for person in scene.people:
		person.jump_buffer = 0
		person.moving = false
		if person.grounded: person.velocity.x = 0
	return true

func step_turn(delta: float) -> void:
	if not rotating: return
	turn_time = minf(TURN_SECONDS,turn_time+delta)
	angle = lerpf(turn_start,turn_end,smoothstep(0.0,1.0,turn_time/TURN_SECONDS))
	for person in scene.people:
		person.position = project(actors[person.kind])
		person.queue_redraw()
	if turn_time<TURN_SECONDS: return
	view = next_view
	angle = view*PI*0.5
	rotating = false
	turns += 1
	project_geometry()
	for person in scene.people:
		person.position = project(actors[person.kind])
		if person.grounded: person.ground_slope = float(scene.platforms[person.shelf].get("slope",0))
		person.blocked_dir = 0

func rope_length() -> float:
	return world_point(scene.people[0]).distance_to(world_point(scene.people[1]))

func rope_allows(person, point: Vector2, target := -2) -> bool:
	var friend = scene.people[1-person.kind]
	var goal := point_for(person,point,target)
	if goal.distance_to(world_point(friend))>Route.ROPE_LENGTH+0.01: return false
	if friend.traversing() and goal.distance_to(point_for(friend,friend.destination,friend.arrival_shelf))>Route.ROPE_LENGTH+0.01: return false
	return true

func set_world(person, point: Vector3) -> void:
	actors[person.kind] = point
	person.position = project(point)

func constrain_rope() -> void:
	var a = scene.people[0]; var b = scene.people[1]
	var pa := world_point(a); var pb := world_point(b)
	var gap := pb-pa
	var length := gap.length()
	if length<=Route.ROPE_LENGTH: return
	scene.rope_taut = true
	var normal := gap/length
	var excess := length-Route.ROPE_LENGTH
	if a.grounded or a.traversing() or not a.anchor.is_empty():
		set_world(b,pb-normal*excess)
		remove_outward(b,normal)
		if not b.grounded: b.hanging = b.position.y>a.position.y+30
	elif b.grounded or b.traversing() or not b.anchor.is_empty():
		set_world(a,pa+normal*excess)
		remove_outward(a,-normal)
		if not a.grounded: a.hanging = a.position.y>b.position.y+30
	else:
		set_world(a,pa+normal*excess*0.5); set_world(b,pb-normal*excess*0.5)
		remove_outward(a,-normal); remove_outward(b,normal)

func remove_outward(person, normal: Vector3) -> void:
	var velocity := Vector3(person.velocity.x*cos(angle),person.velocity.y,person.velocity.x*sin(angle))
	var outward := velocity.dot(normal)
	if outward>0: velocity -= normal*outward
	person.velocity = Vector2(velocity.x*cos(angle)+velocity.z*sin(angle),velocity.y)

func rope_points() -> PackedVector2Array:
	var a: Vector3 = actors[0] if rotating else world_point(scene.people[0])
	var b: Vector3 = actors[1] if rotating else world_point(scene.people[1])
	a.y -= 62; b.y -= 62
	var slack := minf(35,maxf(0,Route.ROPE_LENGTH-a.distance_to(b))*0.20)
	var result := PackedVector2Array()
	for i in 25:
		var t := float(i)/24
		var offset: Vector2 = scene.people[0].view_offset.lerp(scene.people[1].view_offset,t)
		result.append(project(a.lerp(b,t)+Vector3(0,sin(t*PI)*slack,0))+offset)
	return result

func sync_boulder(stone: Dictionary) -> void:
	var parent: Dictionary = boxes[stone.parent]
	var point: Vector3 = stone.world
	point.y = surface_world(parent,point.x,point.z)-float(stone.height)
	stone.world = point
	var r := float(stone.radius)
	boxes[stone.id] = {"id":int(stone.id),"left":point.x-r,"right":point.x+r,"back":point.z-r,"front":point.z+r,"y":point.y,"slope":0.0,"height":float(stone.height)}
	var p: Dictionary = scene.platforms[stone.id]
	p.x = project(point).x-r; p.end = project(point).x+r
	p.y = point.y; p.enabled = scene.platforms[stone.parent].enabled
	stone.x = project(point).x

func move_boulder(stone: Dictionary, amount: float) -> void:
	if stone.locked: return
	var box: Dictionary = boxes[stone.parent]
	var previous: Vector3 = stone.world
	var point := previous+Vector3(cos(angle),0,sin(angle))*amount
	point.x = clampf(point.x,float(box.left)+float(stone.radius)+4,float(box.right)-float(stone.radius)-4)
	point.z = clampf(point.z,float(box.back)+float(stone.radius)+4,float(box.front)-float(stone.radius)-4)
	var shift := point-previous
	for person in scene.people:
		if person.grounded and person.shelf==stone.id and (world_point(person)+shift).distance_to(world_point(scene.people[1-person.kind]))>Route.ROPE_LENGTH: return
	stone.world = point
	if stone.id==Route.KEY_STONE and point.z>=float(box.front)-float(stone.radius)-9:
		stone.locked = true; scene.flags.bridge_braced = true
		scene.flags.bridge_braced_at = scene.clock
		scene.platforms[Route.BRIDGE].enabled = true
		scene.hud.message("A pedra trava a laje entre os penedos. A passagem está segura; atravessem de lado.",6)
	elif stone.id==Route.PUSH_STEP and point.x>=float(box.right)-float(stone.radius)-9:
		stone.locked = true; scene.flags.push_step = true
		scene.hud.message("A pedra ficou presa junto à parede. Cima para subir pelo novo apoio.")
	sync_boulder(stone)
	for person in scene.people:
		if person.grounded and person.shelf==stone.id:
			set_world(person,actors[person.kind]+shift)
			person.position.y = point.y

func prop(shelf: int, x: float, y_offset := 0.0) -> Vector2:
	var box: Dictionary = boxes[shelf]
	var z := (float(box.back)+float(box.front))*0.5
	return project(Vector3(x,surface_world(box,x,z)+y_offset,z))

func prop_near(person, shelf: int, x: float, radius := 100.0) -> bool:
	return person.grounded and person.shelf==shelf and person.position.distance_to(prop(shelf,x))<=radius
