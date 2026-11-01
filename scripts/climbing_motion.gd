extends RefCounted
## Swept feet/surface contacts keep slopes, jumps, loose blocks and belays in one
## simulation. Only the authored cooperative moves use short scripted mantles.
const Route = preload("res://scripts/climbing_route.gd")
const SPEED := 245.0
const GRAVITY := 1750.0
const JUMP := 655.0
const RADIUS := 22.0
var scene: Node2D

func advance(person, direction: float, delta: float) -> void:
	person.jump_buffer = maxf(0,person.jump_buffer-delta)
	person.ignore_time = maxf(0,person.ignore_time-delta)
	if person.traversing(): return
	if person.grounded and (person.shelf<0 or not scene.platforms[person.shelf].enabled):
		depart(person)
	if not person.anchor.is_empty() and person.grounded:
		person.velocity = Vector2.ZERO
		person.moving = false
		return
	if person.grounded: person.coyote = 0.12
	else: person.coyote = maxf(0,person.coyote-delta)
	var previous: Vector2 = person.position
	walk(person,direction,delta)
	if person.grounded:
		var shelf: Dictionary = scene.platforms[person.shelf]
		if person.position.x<float(shelf.x)-2 or person.position.x>float(shelf.end)+2:
			depart(person)
		else:
			person.position.y = scene.surface_y(shelf,person.position.x,person)
			person.ground_slope = float(shelf.get("slope",0))
	if not person.grounded:
		person.velocity.y = minf(950,person.velocity.y+GRAVITY*delta)
		person.position.y += person.velocity.y*delta
		if person.velocity.y>=0:
			var best := INF
			var ground := -1
			for shelf in scene.platforms:
				if not shelf.enabled or (shelf.id==person.ignore_shelf and person.ignore_time>0): continue
				if not scene.platform_visible(int(shelf.id)): continue
				if person.position.x<float(shelf.x)-2 or person.position.x>float(shelf.end)+2: continue
				var y: float = scene.surface_y(shelf,person.position.x,person)
				if previous.y<=y+4 and person.position.y>=y and y<best:
					best = y
					ground = shelf.id
			if ground>=0:
				person.position.y = best
				person.shelf = ground
				person.last_shelf = ground
				person.grounded = true
				person.hanging = false
				person.velocity.y = 0
				person.ground_slope = float(scene.platforms[ground].get("slope",0))
	person.queue_redraw()

func depart(person) -> void:
	person.last_shelf = person.shelf if person.shelf>=0 else person.last_shelf
	person.grounded = false
	person.shelf = -1
	person.anchor = ""
	person.pose = "idle"

func jump(person) -> void:
	if person.traversing() or (not person.grounded and person.coyote<=0): return
	depart(person)
	person.velocity.y = -JUMP
	person.coyote = 0
	person.jump_buffer = 0
	person.hanging = false

func walk(person, direction: float, delta: float) -> void:
	if person.traversing(): return
	var previous: float = person.position.x
	var slope: float = person.ground_slope if person.grounded else 0.0
	var speed := SPEED*(1.0-maxf(0,-direction*slope)*0.6)
	var target_speed := direction*speed
	if absf(slope)>0.20: target_speed += signf(slope)*29
	person.velocity.x = move_toward(person.velocity.x,target_speed,(1800.0 if person.grounded else 950.0)*delta)
	var next_x := clampf(previous+person.velocity.x*delta,-640,1920)
	if absf(direction)>0.1: person.face = signf(direction)
	if person.grounded:
		var edge: Dictionary = scene.edge_for(person,int(signf(person.velocity.x)))
		if not edge.is_empty():
			var high: Dictionary = scene.platforms[edge.to]
			var wall: float = scene.edge_x(person,int(edge.dir))
			var rise: float = person.position.y-scene.surface_y(high,wall+edge.dir*RADIUS,person)
			if rise>45:
				if edge.dir>0 and previous<=wall+1 and next_x>wall: next_x = wall
				if edge.dir<0 and previous>=wall-1 and next_x<wall: next_x = wall
	for stone in scene.boulders:
		if not scene.platforms[stone.id].enabled: continue
		var top := float(scene.platforms[stone.id].y)
		if person.position.y<=top+8 or person.position.y>top+float(stone.height)+25: continue
		var side := signf(previous-float(stone.x))
		var contact := float(stone.x)+side*(float(stone.radius)+RADIUS)
		if (side>0 and next_x<contact and previous>=contact-2) or (side<0 and next_x>contact and previous<=contact+2):
			if person.grounded and person.shelf==stone.parent and absf(direction)>0.1:
				move_boulder(stone,direction*112*delta)
			next_x = float(stone.x)+side*(float(stone.radius)+RADIUS)
	var proposed := Vector2(next_x,person.position.y)
	if person.grounded: proposed.y = scene.surface_y(scene.platforms[person.shelf],next_x,person)
	if not scene.rope_allows(person,proposed):
		next_x = previous
		scene.rope_taut = true
	person.position.x = next_x
	person.distance += absf(next_x-previous)
	person.moving = absf(next_x-previous)>0.05
	if not person.moving and absf(direction)>0.1:
		person.blocked_dir = int(signf(direction))
		person.velocity.x = 0
	else: person.blocked_dir = 0

func move_boulder(stone: Dictionary, amount: float) -> void:
	scene.space.move_boulder(stone,amount)

func _sync_boulder(stone: Dictionary) -> void:
	scene.space.sync_boulder(stone)

func step_boulders(delta: float) -> void:
	for stone in scene.boulders:
		var parent: Dictionary = scene.platforms[stone.parent]
		if not parent.enabled:
			_sync_boulder(stone)
			continue
		if not stone.locked and absf(float(parent.get("slope",0)))>0.16:
			stone.velocity = clampf(float(stone.velocity)+float(parent.slope)*150*delta,-75,75)
			move_boulder(stone,float(stone.velocity)*delta)
		_sync_boulder(stone)

func step_crumbles(delta: float) -> void:
	for shelf in scene.platforms:
		var life := float(shelf.get("fragile",0))
		if life<=0: continue
		if shelf.enabled:
			var occupants: int = scene.people.filter(func(person): return person.grounded and person.shelf==shelf.id).size()
			var occupied := occupants>0
			if float(shelf.timer)<0 and occupied: shelf.timer = life
			if occupants>int(shelf.get("capacity",2)): shelf.timer = minf(float(shelf.timer),0.12)
			if float(shelf.timer)>=0:
				shelf.timer = maxf(0,float(shelf.timer)-delta)
				if shelf.timer<=0:
					shelf.enabled = false
					shelf.reset = 5.5
					for person in scene.people:
						if person.shelf==shelf.id or (person.traversing() and person.arrival_shelf==shelf.id):
							person.traversal.clear()
							depart(person)
		else:
			shelf.fall = float(shelf.fall)+delta
			shelf.reset = float(shelf.reset)-delta
			if shelf.reset<=0:
				shelf.enabled = true
				shelf.timer = -1.0
				shelf.fall = 0.0
				for stone in scene.boulders:
					if stone.parent==shelf.id:
						stone.world = stone.home
						stone.velocity = 0

func constrain_rope() -> void:
	scene.space.constrain_rope()
