extends Node2D
const Art = preload("res://scripts/wildlife_art.gd")
var ecosystem: Node2D
var species := "bird"
var state := "idle"
var state_time := 0.0
var timer := 0.0
var think_in := 0.0
var phase := 0.0
var variant := 0
var flock := -1
var flock_slot := 0
var home: Dictionary = {}
var pond: Dictionary = {}
var anchor := Vector2.ZERO
var target := Vector2.ZERO
var route := PackedVector2Array()
var velocity := Vector2.ZERO
var facing := Vector2.RIGHT
var altitude := 0.0
var thirst := 0.0
var hunger := 0.55
var cooldown := 0.0
var quarry: Node2D
var flight_height := 100.0
var jump_from := Vector2.ZERO
var jump_to := Vector2.ZERO
var jump_next := "bank"
var ripple := 0.0
var art: Node2D
const FOX_RUN_SPEED := 530.0
const FOX_CHASE_SPEED := 465.0
const FOX_ACCELERATION := 2300.0
const FOX_BOUND_SECONDS := 0.28
const SQUIRREL_RUN_SPEED := 490.0
var ground_speed := 0.0
var gait_distance := 0.0
var turn_from := Vector2.RIGHT
var run_next := "flee"
var run_duration := 0.0
var curiosity_cooldown := 0.0
var watched_person: Node2D
var repath_in := 0.0
var panic_time := 0.0

func _ready() -> void:
	name = species.capitalize()
	art = Art.new()
	art.animal = self
	add_child(art)

func set_state(value: String, duration := 0.0) -> void:
	state = value
	state_time = 0.0
	timer = duration
	velocity = Vector2.ZERO
	if art!=null: art.visible = state not in ["hidden","submerged","shelter"]

func step(delta: float) -> void:
	state_time += delta
	timer -= delta
	cooldown = maxf(0,cooldown-delta)
	curiosity_cooldown = maxf(0,curiosity_cooldown-delta)
	repath_in = maxf(0,repath_in-delta)
	panic_time = maxf(0,panic_time-delta)
	ripple = maxf(0,ripple-delta)
	think_in -= delta
	if think_in<=0:
		think_in = (0.09 if species in ["fox","squirrel"] else 0.24)+ecosystem.rng.randf_range(0,0.04)
		think()
	move(delta)
	if velocity.length_squared()>1 and state not in ["bound","startled"]:
		facing = velocity.normalized()
	gait_distance += velocity.length()*delta
	art.position = Vector2(0,-altitude)
	art.visible = state not in ["hidden","submerged","shelter"]
	z_index = 5 if (species=="bird" and state=="fly") or (species in ["bat","owl"] and state in ["fly","cruise","hunt","swoop","evade","return","emerge"]) else 0
	queue_redraw()
	art.queue_redraw()

func think() -> void:
	match species:
		"bird": _bird_think()
		"squirrel": _squirrel_think()
		"fox": _fox_think()
		"frog": _frog_think()
		"butterfly": _butterfly_think()

func move(delta: float) -> void:
	match species:
		"bird": _bird_move(delta)
		"squirrel": _squirrel_move(delta)
		"fox": _fox_move(delta)
		"frog": _frog_move(delta)
		"butterfly": _butterfly_move(delta)

func _draw() -> void:
	if state in ["hidden","shelter"] or species=="firefly":
		return
	if state!="submerged" and altitude<180 and state not in ["perch","roost","watch","climb","descend"]:
		var radius := 17.0 if species=="fox" else (8.0 if species=="squirrel" else 5.0)
		draw_set_transform(Vector2(0,2),0,Vector2(1,0.35))
		draw_circle(Vector2.ZERO,radius,Color(0.04,0.07,0.04,0.22*(1-altitude/240)))
		draw_set_transform(Vector2.ZERO)
	if ripple>0:
		draw_set_transform(Vector2.ZERO,0,Vector2(1,0.42))
		draw_arc(Vector2.ZERO,(1.5-ripple)*26+10,0,TAU,28,Color(0.78,0.88,0.78,ripple*0.3),1.2,true)
		draw_set_transform(Vector2.ZERO)

func go_land(point: Vector2) -> bool:
	target = point
	if ecosystem.world.can_walk_line(position,point):
		route = PackedVector2Array([point])
		return true
	route = ecosystem.world.find_path(position,point)
	if not route.is_empty():
		# Stop beside a trunk or the water, not in the centre of a blocked cell.
		if ecosystem.world.can_walk_line(route[-1],point):
			route.append(point)
	# String-pull grid paths into clear corridors: running should not zigzag at cells.
	if species in ["fox","squirrel"] and route.size()>2:
		var smooth := PackedVector2Array()
		var from := position
		var index := 0
		while index<route.size():
			var furthest := index
			for next in range(index+1,mini(index+14,route.size())):
				if ecosystem.world.can_walk_line(from,route[next]):
					furthest = next
			smooth.append(route[furthest])
			from = route[furthest]
			index = furthest+1
		route = smooth
	return not route.is_empty()

func walk(delta: float, speed: float) -> void:
	velocity = Vector2.ZERO
	var remaining := speed*delta
	while remaining>0 and not route.is_empty():
		var next := route[0]
		var distance := position.distance_to(next)
		if distance<2:
			route.remove_at(0)
			continue
		var direction := position.direction_to(next)
		var travel := minf(distance,minf(remaining,8.0))
		var candidate := position+direction*travel
		if not ecosystem.world.is_walkable(candidate,6):
			route.clear()
			return
		velocity = direction*speed
		position = candidate
		remaining -= travel
		if travel>=distance:
			route.remove_at(0)

# Birds share takeoff/landing destinations, but steer and flap individually.
func launch(destination: Dictionary, alarm := false, group := true) -> void:
	home = destination
	target = home.foot+Vector2(home.perch.x+(flock_slot-1.5)*38,0)
	flight_height = maxf(110,-float(home.perch.y)+42)
	set_state("fly",ecosystem.rng.randf_range(4,8))
	ecosystem.note("flights")
	if group and flock>=0:
		for other in ecosystem.animals:
			if other!=self and other.species=="bird" and other.flock==flock:
				other.launch(destination,alarm,false)
	if alarm:
		cooldown = 8

func _bird_think() -> void:
	var danger = ecosystem.threat(position,145)
	var owl = ecosystem.nearby_animal(position,["owl"],170,self)
	if owl!=null and absf(owl.altitude-altitude)<100: danger = owl
	if danger!=null and state in ["forage","perch","roost"] and cooldown<=0:
		var away: Vector2 = danger.position.direction_to(position)
		launch(ecosystem.nearest_tree(position+away*600),true)
		return
	if state=="fly":
		return
	if not ecosystem.is_day():
		if state not in ["perch","roost"]:
			launch(ecosystem.nearest_tree(position))
		else:
			set_state("roost",8)
		return
	if state=="roost":
		set_state("perch",ecosystem.rng.randf_range(2,10))
	if timer>0:
		return
	if state=="forage" or ecosystem.rng.randf()<0.7:
		launch(ecosystem.nearest_tree(position+Vector2.from_angle(ecosystem.rng.randf()*TAU)*ecosystem.rng.randf_range(350,850)))
	else:
		target = ecosystem.land_point(home.foot,170)
		set_state("land",3)

func _bird_move(delta: float) -> void:
	if state=="fly":
		var desired := position.direction_to(target)*105
		var separation := Vector2.ZERO
		for other in ecosystem.animals:
			if other==self or other.species!="bird" or other.state!="fly":
				continue
			var offset: Vector2 = position-other.position
			if offset.length_squared()<1600 and offset.length_squared()>0.01:
				separation += offset.normalized()*(40-offset.length())*1.5
		velocity = velocity.lerp(desired+separation,minf(1,delta*3))
		if position.distance_to(target)>12:
			position += velocity*delta
		altitude = move_toward(altitude,flight_height,delta*90)
		if position.distance_to(target)<20 and absf(altitude-flight_height)<5:
			position = target
			altitude = flight_height
			set_state("perch",ecosystem.rng.randf_range(8,24))
	elif state=="land":
		var previous := position
		position = position.move_toward(target,delta*65)
		velocity = (position-previous)/maxf(delta,0.001)
		altitude = move_toward(altitude,0,delta*90)
		if altitude==0 and position.distance_to(target)<2:
			set_state("forage",ecosystem.rng.randf_range(3,8))
	elif state=="forage":
		altitude = maxf(0,sin(state_time*8))*2

func _squirrel_think() -> void:
	var danger = ecosystem.threat(position,240)
	if state=="hidden":
		if timer<=0 and danger==null and ecosystem.is_day():
			set_state("descend",2)
		return
	if state in ["climb","descend","startled"]:
		return
	if state=="flee":
		if position.distance_to(home.foot)<48:
			position = home.foot
			set_state("climb",1.8)
		elif route.is_empty() or timer<=0:
			go_land(home.foot)
			timer = 5
		return
	if danger!=null:
		home = ecosystem.nearest_tree(position)
		ecosystem.ensure_hollow(home)
		go_land(home.foot)
		facing = danger.position.direction_to(position)
		set_state("startled",0.24)
		ecosystem.note("startles")
		ecosystem.note("escapes")
		return
	if not ecosystem.is_day():
		go_land(home.foot)
		set_state("flee",8)
		return
	if state=="wander" and route.is_empty():
		set_state("forage",ecosystem.rng.randf_range(2,7))
	if timer>0:
		return
	if ecosystem.rng.randf()<0.25:
		go_land(home.foot)
		set_state("flee",8)
	else:
		go_land(ecosystem.land_point(home.foot,300))
		set_state("wander",ecosystem.rng.randf_range(5,12))

func _squirrel_move(delta: float) -> void:
	if state=="startled":
		altitude = sin(clampf(state_time/0.24,0,1)*PI)*16
		if state_time>=0.24:
			altitude = 0
			set_state("flee",5)
	elif state in ["wander","flee"]:
		ground_speed = move_toward(ground_speed,SQUIRREL_RUN_SPEED if state=="flee" else 105.0,delta*2600)
		walk(delta,ground_speed)
		altitude = absf(sin(gait_distance/18))*5 if velocity.length()>1 else 0
	elif state=="climb":
		altitude = move_toward(altitude,120,delta*80)
		if altitude>=120:
			set_state("hidden",ecosystem.rng.randf_range(8,22))
			ecosystem.note("hides")
	elif state=="descend":
		altitude = move_toward(altitude,0,delta*65)
		if altitude==0:
			go_land(ecosystem.land_point(home.foot,160))
			set_state("wander",4)

func begin_run(next_state: String, duration: float) -> void:
	var was_still := velocity.length()<15 and ground_speed<30
	if state=="bound":
		run_next = next_state
		run_duration = duration
		return
	if was_still:
		turn_from = facing
		run_next = next_state
		run_duration = duration
		set_state("bound",FOX_BOUND_SECONDS)
		ecosystem.note("fox_bounds")
	else:
		var momentum := velocity
		set_state(next_state,duration)
		velocity = momentum

func flee_from(danger: Node2D) -> void:
	var goal: Vector2 = ecosystem.escape_point(self,danger)
	go_land(goal)
	begin_run("flee",2.8)
	panic_time = 5
	curiosity_cooldown = ecosystem.rng.randf_range(24,50)
	repath_in = 0.45
	ecosystem.note("escapes")

func _fox_move(delta: float) -> void:
	thirst = minf(1,thirst+delta*0.003)
	hunger = minf(1,hunger+delta*0.002)
	if state=="bound":
		var desired := position.direction_to(target)
		if not route.is_empty():
			desired = position.direction_to(route[0])
		var progress := clampf(state_time/FOX_BOUND_SECONDS,0,1)
		facing = Vector2.from_angle(lerp_angle(turn_from.angle(),desired.angle(),smoothstep(0,0.7,progress)))
		altitude = sin(progress*PI)*21
		walk(delta,90+progress*110)
		if progress>=1:
			altitude = 0
			ground_speed = 200
			set_state(run_next,run_duration)
		return
	altitude = 0
	if state in ["wander","chase","flee","to_water","to_den","approach_watch","dash"]:
		var running := state in ["chase","flee","dash"]
		var speed := (FOX_CHASE_SPEED if state=="chase" else FOX_RUN_SPEED) if running else (92.0 if state=="approach_watch" else 120.0)
		ground_speed = move_toward(ground_speed,speed,FOX_ACCELERATION*delta)
		walk(delta,ground_speed)
		altitude = absf(sin(gait_distance/34))*6 if running and not velocity.is_zero_approx() else 0
	else:
		ground_speed = move_toward(ground_speed,0,FOX_ACCELERATION*delta)
		velocity = Vector2.ZERO

func _fox_think() -> void:
	var person = ecosystem.nearest_person(position,850)
	var danger = ecosystem.threat(position,300,false)
	# Human proximity always overrides curiosity, thirst and hunting.
	if danger!=null:
		if state=="bound":
			if run_next!="flee":
				flee_from(danger)
		elif state!="flee" or ((route.is_empty() or timer<=0) and repath_in<=0):
			flee_from(danger)
		return
	if state=="bound":
		return
	if state=="flee":
		if not route.is_empty() and timer>0:
			return
		if person!=null and position.distance_to(person.position)<550:
			flee_from(person)
			return
		set_state("listen",ecosystem.rng.randf_range(2,4))
		return
	if state=="chase":
		if not is_instance_valid(quarry) or quarry.state in ["hidden","climb","descend"] or state_time>9:
			cooldown = 2
			set_state("sniff",2)
			return
		if position.distance_to(quarry.position)<26:
			set_state("pounce",0.45)
			cooldown = 2
			return
		if repath_in<=0:
			# Lead the prey slightly; update quickly as it changes direction.
			var intercept: Vector2 = quarry.position+quarry.velocity*0.12
			go_land(intercept if ecosystem.world.is_walkable(intercept,12) else quarry.position)
			repath_in = 0.22
		return
	if state=="pounce":
		if timer<=0:
			set_state("sniff",1)
		return
	# Visible prey triggers an immediate run, even during a quiet watching spell.
	if cooldown<=0:
		quarry = ecosystem.prey(position,720)
		if quarry!=null:
			go_land(quarry.position)
			begin_run("chase",9)
			repath_in = 0.22
			ecosystem.note("hunts")
			return
	if state=="watch":
		if is_instance_valid(watched_person):
			facing = position.direction_to(watched_person.position)
		if timer<=0 or not ecosystem.at_view_edge(position):
			if is_instance_valid(watched_person):
				flee_from(watched_person)
			else:
				set_state("listen",2)
		return
	if state=="approach_watch":
		if position.distance_to(target)<25 and ecosystem.at_view_edge(position):
			set_state("watch",ecosystem.rng.randf_range(3,6))
			ecosystem.note("watches")
		elif timer<=0 or route.is_empty():
			curiosity_cooldown = 10
			set_state("listen",2)
		return
	if state=="drink":
		thirst = maxf(0,thirst-0.03)
		if timer<=0:
			set_state("listen",2)
		return
	if state=="to_water":
		if position.distance_to(pond.bank)<45:
			facing = position.direction_to(pond.leaf)
			set_state("drink",7)
			ecosystem.note("drinks")
		elif route.is_empty() or timer<=0:
			set_state("listen",3)
		return
	if thirst>0.72:
		pond = ecosystem.nearest_pond(position)
		go_land(pond.bank)
		set_state("to_water",60)
		return
	if person!=null and curiosity_cooldown<=0 and panic_time<=0:
		var point: Dictionary = ecosystem.observation_point(self,person)
		curiosity_cooldown = 8 if point.is_empty() else ecosystem.rng.randf_range(35,65)
		if not point.is_empty() and go_land(point.position):
			watched_person = person
			set_state("approach_watch",8)
			return
	if state=="sleep":
		if ecosystem.is_twilight() or not ecosystem.is_day() or hunger>0.8:
			set_state("listen",2)
		return
	if timer>0 and not (state in ["wander","dash","to_den"] and route.is_empty()):
		return
	if state=="to_den":
		set_state("sleep",20)
	elif ecosystem.is_day() and not ecosystem.is_twilight() and ecosystem.rng.randf()<0.2:
		go_land(home.foot+Vector2(60,35))
		set_state("to_den",20)
	elif ecosystem.rng.randf()<0.25:
		hunger = maxf(0,hunger-0.12)
		set_state("sniff",ecosystem.rng.randf_range(2,4))
	else:
		go_land(ecosystem.land_point(position,650))
		begin_run("dash",ecosystem.rng.randf_range(1.5,3))

func hop(destination: Vector2, next_state: String) -> void:
	jump_from = position
	jump_to = destination
	jump_next = next_state
	set_state("hop",0.55)

func _frog_think() -> void:
	if state=="hop":
		return
	var danger = ecosystem.threat(position,180)
	if state=="submerged":
		if timer<=0 and danger==null:
			position = pond.leaf
			ripple = 1.5
			set_state("surface",3)
			ecosystem.note("emerges")
		return
	if danger!=null and state!="submerged":
		hop(pond.leaf+Vector2(0,24),"submerged")
		ecosystem.note("dives")
		return
	# Passing insects make the frog turn and snap; butterflies veer away.
	for other in ecosystem.animals:
		if other.species in ["butterfly","firefly"] and position.distance_to(other.position)<60 and other.altitude<45 and other.state in ["flutter","glimmer"] and cooldown<=0:
			facing = position.direction_to(other.position)
			other.startle(position)
			set_state("snap",0.5)
			cooldown = 2
			if other.species=="firefly": ecosystem.note("insect_escapes")
			return
	if timer>0:
		return
	match state:
		"surface": hop(pond.leaf,"leaf")
		"leaf":
			if ecosystem.rng.randf()<0.55:
				hop(pond.leaf+[Vector2.ZERO,Vector2(24,17),Vector2(-18,25)][ecosystem.rng.randi_range(0,2)],"leaf")
			else:
				hop(pond.bank,"bank")
		"bank": hop(pond.leaf,"leaf")
		_: set_state("bank",2)

func _frog_move(_delta: float) -> void:
	if state=="hop":
		var t := clampf(state_time/0.55,0,1)
		position = jump_from.lerp(jump_to,t)
		facing = jump_from.direction_to(jump_to)
		altitude = sin(t*PI)*24
		if t>=1:
			altitude = 0
			set_state(jump_next,ecosystem.rng.randf_range(6,16) if ecosystem.is_day() else ecosystem.rng.randf_range(2,6))
			if jump_next in ["submerged","leaf"]:
				ripple = 1.5
	elif state=="leaf":
		altitude = 2+sin(ecosystem.elapsed*1.7+pond.leaf.y)*0.8

func startle(from: Vector2) -> void:
	target = position+from.direction_to(position)*110+Vector2(20,-30)
	set_state("evade",2)
	cooldown = 3

func _butterfly_think() -> void:
	var danger = ecosystem.threat(position,100)
	if danger!=null and cooldown<=0:
		startle(danger.position)
		return
	if state=="evade" and timer>0:
		return
	if not ecosystem.is_day():
		set_state("rest",5)
		return
	if timer>0 and state!="rest":
		return
	if state=="nectar":
		anchor = ecosystem.flowers[ecosystem.rng.randi_range(0,ecosystem.flowers.size()-1)] if ecosystem.rng.randf()<0.12 else anchor
		set_state("flutter",ecosystem.rng.randf_range(4,10))
	elif state=="flutter":
		set_state("nectar",ecosystem.rng.randf_range(3,7))
	else:
		set_state("flutter",5)

func _butterfly_move(delta: float) -> void:
	var previous := position
	if state=="flutter":
		var t: float = ecosystem.elapsed+phase*4
		target = anchor+Vector2(sin(t*0.65+phase)*65,cos(t*0.43)*45)
		position = position.move_toward(target,delta*35)
		altitude = 18+sin(t*2.3)*8
	elif state=="evade":
		position = position.move_toward(target,delta*95)
		altitude = move_toward(altitude,40,delta*30)
	else:
		position = position.move_toward(anchor,delta*32)
		altitude = move_toward(altitude,8,delta*20)
	velocity = (position-previous)/maxf(delta,0.001)
