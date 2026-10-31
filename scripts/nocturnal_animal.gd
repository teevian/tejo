extends "res://scripts/wildlife_animal.gd"
## Night residents use the same simulation clock, depth and persistent population.
const NightArt = preload("res://scripts/nocturnal_art.gd")
var outing_time := 0.0
var head_yaw := 0.0
var head_target := 0.0
var glow := 0.0
var glow_visible := false
var pulse_rate := 1.0
var eye_open := 1.0
var blink_in := 2.5
var blink_time := -1.0
var blink_duration := 0.22
var eye_glint := 0.0
var glint_cooldown := 0.0

func _ready() -> void:
	name = species.capitalize()
	blink_in = 1.5+phase
	art = NightArt.new()
	art.animal = self
	add_child(art)
	art.visible = state!="shelter"

func think() -> void:
	match species:
		"bat": _bat_think()
		"owl": _owl_think()
		"firefly": _firefly_think()
		"snake": _snake_think()

func move(delta: float) -> void:
	match species:
		"bat": _bat_move(delta)
		"owl":
			_owl_eyes(delta)
			_owl_move(delta)
		"firefly": _firefly_move(delta)
		"snake": _snake_move(delta)

func startle(from: Vector2) -> void:
	if species=="firefly":
		# Ground lights never take flight, even when disturbed.
		cooldown = 2.8
		return
	var away := from.direction_to(position)
	if away.is_zero_approx(): away = Vector2.from_angle(phase)
	target = position+away*(190 if species=="bat" else 65)
	set_state("evade",1.5)
	cooldown = 2.8

func _bat_think() -> void:
	if state=="shelter": return
	if not ecosystem.nocturnal_active() or outing_time<=0:
		if state!="return":
			target = home.foot
			set_state("return")
		return
	if state=="return": return
	if state=="emerge":
		if timer<=0: set_state("cruise")
		return
	var owl = ecosystem.nearby_animal(position,["owl"],190,self)
	if owl!=null and absf(owl.altitude-altitude)<130 and cooldown<=0:
		startle(owl.position)
		ecosystem.note("aerial_escapes")
		return
	if state=="evade":
		if timer>0: return
		set_state("cruise")
	if cooldown<=0:
		quarry = ecosystem.nearby_animal(position,["butterfly"],150,self)
		if quarry!=null:
			if state!="hunt":
				set_state("hunt")
				ecosystem.note("bat_hunts")
			if position.distance_to(quarry.position)<24 and absf(altitude-quarry.altitude)<35:
				quarry.startle(position)
				ecosystem.note("insect_escapes")
				quarry = null
				cooldown = 3
				set_state("cruise")
			return
	if state=="hunt": set_state("cruise")

func _bat_move(delta: float) -> void:
	if state=="shelter" or (state=="emerge" and timer>0): return
	outing_time -= delta
	if state=="return":
		var previous := position
		position = position.move_toward(target,185*delta)
		velocity = (position-previous)/maxf(delta,0.001)
		altitude = move_toward(altitude,120,delta*90)
		if position.distance_to(target)<2 and absf(altitude-120)<2:
			position = target
			set_state("shelter")
		return
	var flight_altitude := 70.0+sin(ecosystem.elapsed*2.1+phase)*14
	if state=="hunt" and is_instance_valid(quarry):
		target = quarry.position+quarry.velocity*0.15
		flight_altitude = quarry.altitude+12
	elif state!="evade":
		var t: float = ecosystem.elapsed*0.9+phase
		target = anchor+Vector2(sin(t)*150,cos(t*0.73)*95)
		# Different slots and phases keep a departing group from becoming one sprite.
		target += Vector2.from_angle(phase+flock_slot)*28
	var desired := position.direction_to(target)*(245.0 if state=="evade" else 165.0)
	var separation := Vector2.ZERO
	for other in ecosystem.colonies[flock].members:
		if other==self or other.state=="shelter": continue
		var offset: Vector2 = position-other.position
		if offset.length_squared()>0.1 and offset.length_squared()<900:
			separation += offset.normalized()*(30-offset.length())*4
	velocity = velocity.lerp(desired+separation,minf(1,delta*5))
	position += velocity*delta
	position = position.clamp(Vector2.ONE*16,ecosystem.world.WORLD_SIZE-Vector2.ONE*16)
	altitude = move_toward(altitude,flight_altitude,delta*75)

func owl_flight(destination: Dictionary, next_state := "fly") -> void:
	home = destination
	target = home.foot+Vector2(home.owl_perch.x,0)
	flight_height = -home.owl_perch.y+42
	set_state(next_state)
	ecosystem.note("owl_flights")

func _owl_think() -> void:
	if not ecosystem.nocturnal_active():
		if state=="watch":
			set_state("shelter")
		elif state not in ["shelter","return"]:
			owl_flight(home,"return")
		return
	if state=="shelter":
		facing = Vector2.DOWN
		set_state("watch",ecosystem.rng.randf_range(12,24))
		return
	if state in ["fly","return"]: return
	if state=="swoop":
		if not is_instance_valid(quarry) or quarry.state in ["shelter","submerged","hidden","return"] or state_time>2.5 or position.distance_to(quarry.position)<45:
			if is_instance_valid(quarry) and quarry.species=="bat":
				quarry.startle(position)
				ecosystem.note("aerial_escapes")
			quarry = null
			cooldown = 14
			owl_flight(home)
		return
	var person = ecosystem.nearest_person(position,600)
	if person!=null and (position.distance_to(person.position)<75 or (person.velocity.length()>290 and position.distance_to(person.position)<230)):
		var away: Vector2 = person.position.direction_to(position)
		var refuge: Dictionary = ecosystem.next_owl_tree(self,position+away*500)
		if not refuge.is_empty(): owl_flight(refuge)
		return
	if timer>0: return
	quarry = ecosystem.nearby_animal(position,["bat","frog","snake"],440,self) if cooldown<=0 and person==null else null
	var toward: Vector2 = quarry.position if quarry!=null else position+Vector2.from_angle(ecosystem.rng.randf()*TAU)*550
	var destination: Dictionary = ecosystem.next_owl_tree(self,toward)
	if destination.is_empty():
		timer = 5
		return
	if quarry!=null:
		home = destination
		target = home.foot+Vector2(home.owl_perch.x,0)
		flight_height = -home.owl_perch.y+42
		set_state("swoop")
		ecosystem.note("owl_hunts")
	else:
		owl_flight(destination)

func _owl_eyes(delta: float) -> void:
	eye_glint = move_toward(eye_glint,0,delta*2.7)
	glint_cooldown = maxf(0,glint_cooldown-delta)
	if state=="shelter":
		eye_open = 0.0
	else:
		blink_in -= delta
		if blink_in<=0 and blink_time<0:
			blink_time = 0
			blink_duration = ecosystem.rng.randf_range(0.18,0.26)
			if state=="watch" and ecosystem.rng.randf()<0.15:
				blink_duration = ecosystem.rng.randf_range(0.7,1.3)
			blink_in = ecosystem.rng.randf_range(3,8)
		if blink_time>=0:
			blink_time += delta
			eye_open = 1.0-smoothstep(0,0.07,blink_time)*(1.0-smoothstep(blink_duration-0.09,blink_duration,blink_time))
			if blink_time>=blink_duration: blink_time = -1
		else:
			eye_open = 1.0
	art.material.set_shader_parameter("eye_open",eye_open)

func _owl_move(delta: float) -> void:
	if state in ["shelter","watch"]:
		# Feet, torso and facing never turn on the branch. Only the separate head does.
		velocity = Vector2.ZERO
		var person = ecosystem.nearest_person(position,650) if state=="watch" else null
		head_target = clampf(Vector2.DOWN.angle_to(position.direction_to(person.position)),-PI,PI) if person!=null else sin(ecosystem.elapsed*0.25+phase)*0.6
		var previous_yaw := head_yaw
		head_yaw = move_toward(head_yaw,head_target,delta*1.65)
		var reflection_angle := sin(phase)*0.48
		var crosses_light := (previous_yaw-reflection_angle)*(head_yaw-reflection_angle)<=0
		if state=="watch" and eye_open>0.85 and glint_cooldown<=0 and absf(head_yaw-previous_yaw)>0.001 and crosses_light:
			eye_glint = 1.0
			glint_cooldown = ecosystem.rng.randf_range(9,18)
			ecosystem.note("owl_glints")
		return
	var destination := target
	var desired_altitude := flight_height
	if state=="swoop" and is_instance_valid(quarry):
		destination = quarry.position+quarry.velocity*0.12
		desired_altitude = quarry.altitude+25
	var previous := position
	position = position.move_toward(destination,delta*(195 if state=="swoop" else 125))
	velocity = (position-previous)/maxf(delta,0.001)
	altitude = move_toward(altitude,desired_altitude,delta*85)
	head_yaw = move_toward(head_yaw,0,delta*2)
	if state!="swoop" and position.distance_to(target)<1 and absf(altitude-flight_height)<1:
		position = target
		altitude = flight_height
		facing = Vector2.DOWN
		set_state("watch" if ecosystem.nocturnal_active() else "shelter",ecosystem.rng.randf_range(14,30))

func _firefly_think() -> void:
	var point := anchor
	glow_visible = ecosystem.view_rect().grow(40).has_point(point) and not ecosystem._covered_at(position,point)
	if not ecosystem.nocturnal_active():
		if state!="shelter": set_state("settle")
		return
	if state in ["shelter","settle"]: set_state("glimmer")
	if cooldown<=0:
		var person = ecosystem.nearest_person(position,65)
		if person!=null: startle(person.position)

func light_strength() -> float:
	var pulse := pow(maxf(0,sin(ecosystem.elapsed*pulse_rate+phase)),3)
	return glow*(0.06+pulse*0.94)

func _firefly_move(delta: float) -> void:
	position = anchor
	altitude = 0
	velocity = Vector2.ZERO
	var strength: float = ecosystem.nocturnal_activity() if state not in ["shelter","settle"] else 0.0
	if cooldown>0: strength *= 0.35
	glow = move_toward(glow,strength,delta*0.8)
	if state=="settle" and glow<=0:
		set_state("shelter")

func _snake_think() -> void:
	if not ecosystem.nocturnal_active():
		if state=="shelter": return
		if position.distance_to(anchor)<12 or (state=="return" and (route.is_empty() or timer<=0)):
			set_state("shelter")
		elif state!="return":
			go_land(anchor)
			set_state("return",8)
		return
	if state=="shelter":
		if timer>0 or ecosystem.threat(position,180,true,self)!=null: return
		set_state("coil",ecosystem.rng.randf_range(1,3))
		return
	var danger = ecosystem.threat(position,180,true,self)
	if danger!=null:
		if state!="retreat" or timer<=0 or route.is_empty():
			var away: Vector2 = danger.position.direction_to(position)
			var destination := anchor+(position+away*150-anchor).limit_length(240)
			if ecosystem.world.is_walkable(destination,8) and ecosystem.world.can_walk_line(position,destination):
				go_land(destination)
				set_state("retreat",3)
				ecosystem.note("snake_escapes")
			else:
				set_state("shelter",3)
		return
	if state=="stalk":
		if not is_instance_valid(quarry) or quarry.state not in ["bank","snap"] or state_time>4:
			set_state("coil",3)
			cooldown = 7
		elif position.distance_to(quarry.position)<48:
			quarry.hop(quarry.pond.leaf+Vector2(0,24),"submerged")
			ecosystem.note("dives")
			set_state("coil",3)
			cooldown = 7
		return
	if state=="retreat" and route.is_empty():
		set_state("coil",3)
	if cooldown<=0:
		quarry = ecosystem.river_prey(position,anchor,160)
		if quarry!=null:
			go_land(quarry.position)
			set_state("stalk",4)
			ecosystem.note("snake_hunts")
			return
	if timer>0 and (state=="coil" or not route.is_empty()): return
	for attempt in 12:
		var destination: Vector2 = anchor+Vector2.from_angle(ecosystem.rng.randf()*TAU)*ecosystem.rng.randf_range(35,180)
		if ecosystem.world.is_walkable(destination,8) and ecosystem.world.can_walk_line(position,destination):
			go_land(destination)
			set_state("slither",ecosystem.rng.randf_range(3,6))
			return
	set_state("coil",3)

func _snake_move(delta: float) -> void:
	altitude = 0
	if state not in ["slither","retreat","stalk","return"]: return
	var previous := position
	walk(delta,100 if state=="retreat" else 58)
	if position.distance_to(anchor)>270:
		position = previous
		route.clear()
		set_state("coil",2)
