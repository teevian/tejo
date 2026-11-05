extends CharacterBody2D
## Persistent person: appointments, actual journeys, indoor meals/sleep and local life.
const Art = preload("res://scripts/village_resident_art.gd")
const CharacterMotion = preload("res://scripts/village_character_motion.gd")
var motion := CharacterMotion.new()
var gait := preload("res://scripts/village_gait.gd").new()
var travel_direction := Vector2.RIGHT
var meal_seated := false
var meal_frame := 0
var encounter_id := -1
var social_lock := false
var social_pose := ""
var social_line := ""
var speech_until := 0.0
var flash_until := 0.0
var snack_until := 0.0
var memory: Dictionary = {}
var event_busy := false
var population: Node2D
var entry: Dictionary = {}
var profile: Dictionary = {}
var schedule: Array = []
var appointment: Dictionary = {}
var routine_index := -1
var dependants: Array = []
var ordinal := 0
var home := Vector2.ZERO
var anchor := Vector2.ZERO
var stroll: Array[Vector2] = []
var stroll_index := 0
var route := PackedVector2Array()
var state := "activity"
var clock := 0.0
var dwell := 0.0
var greet_time := 0.0
var yield_cooldown := 0.0
var distance_walked := 0.0
var greetings := 0
var facing_left := false
var art: Node2D
var frame := 0
var travelled := 0.0
var goal := Vector2.ZERO
var enter_time := 0.0
var retry_time := 0.0
var stuck_time := 0.0
var escort_time := 0.0

func _ready() -> void:
	entry = entry.duplicate(true)
	add_to_group("village_resident")
	collision_layer = 4
	collision_mask = 3
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 16 if entry.id=="duarte" else 11
	collision.shape = shape
	add_child(collision)
	clock = ordinal*.61
	dwell = 4.0+ordinal%7
	facing_left = entry.mirror
	motion.configure(entry)
	gait.configure(self)
	art = Art.new()
	art.resident = self
	add_child(art)

func prepare_stroll() -> void:
	stroll.clear()
	stroll_index = 0
	stroll.append(anchor)
	if not appointment.is_empty() and not appointment.stroll: return
	var offsets: Array = entry.route_offsets
	if offsets.is_empty() and not appointment.is_empty(): offsets = [[-85,0],[85,0]]
	for offset in offsets:
		var at: Vector2 = population.clear_stroll_point(self,anchor+Vector2(offset[0],offset[1]))
		if at!=Vector2.INF: stroll.append(at)
	if not offsets.is_empty() and stroll.size()==1:
		for direction in [Vector2.RIGHT,Vector2.LEFT,Vector2.DOWN,Vector2.UP]:
			var at: Vector2 = population.clear_stroll_point(self,anchor+direction*90)
			if at!=Vector2.INF: stroll.append(at); break

func _outside() -> void:
	show()
	modulate.a = 1
	collision_layer = 4
	collision_mask = 3
	enter_time = 0

func _inside() -> void:
	state = "inside"
	route.clear()
	velocity = Vector2.ZERO
	collision_layer = 0
	collision_mask = 0
	hide()

func begin_appointment(index: int) -> void:
	meal_seated = false
	_cancel_encounter()
	routine_index = index
	appointment = schedule[index]
	anchor = appointment.destination
	prepare_stroll()
	route.clear()
	retry_time = 0
	stuck_time = 0
	if state=="inside" and position.distance_to(anchor)<20 and appointment.mode=="inside": return
	_outside()
	if position.distance_to(anchor)<20: _arrive()
	else:
		state = "commuting"
		if not _begin_walk(anchor,"commuting"): retry_time = 1

func seek_day(minutes: float) -> void:
	meal_seated = false
	# Only first entry, hours skipped by sleep/debug, or a return after time away.
	# Ordinary clock boundaries always walk from the person's actual position.
	_cancel_encounter()
	var index: int = population.routines.index_at(self,minutes)
	routine_index = index
	appointment = schedule[index]
	anchor = appointment.destination
	prepare_stroll()
	var previous: Dictionary = schedule[posmod(index-1,schedule.size())]
	var start: Vector2 = previous.destination
	var path := PackedVector2Array()
	# An unchanged overnight address is already reached. Projecting that same
	# narrow doorway onto the coarse grid can otherwise place its sleeper outside.
	if start.distance_to(anchor)>8: path = population.world.find_path(start,anchor)
	if not path.is_empty():
		path.insert(0,start)
		if population.world.can_walk_line(path[-1],anchor): path.append(anchor)
	var distance: float = maxf(0,minutes-float(appointment.minute))*gait.commute_speed*(.6 if gait.kind=="cane" else 1.0)
	position = start if path.is_empty() else population.routines.advance_on_path(path,distance)
	_outside()
	state = "commuting"
	route.clear()
	retry_time = 0
	stuck_time = 0
	if position.distance_to(anchor)<20:
		if appointment.mode=="inside": _inside()
		else: _arrive()
	else: _begin_walk(anchor,"commuting")
	queue_redraw()
	art.queue_redraw()

func _arrive() -> void:
	if position.distance_to(anchor)>arrival_radius():
		state = "commuting"
		if not _begin_walk(anchor,"commuting"): retry_time = 2
		return
	state = "entering" if appointment.get("mode","")=="inside" else "activity"
	enter_time = .8 if state=="entering" else 0.0
	dwell = _idle_duration()
	velocity = Vector2.ZERO
	frame = 0

func _begin_walk(to: Vector2, next_state := "walking") -> bool:
	if to==Vector2.INF or position.distance_to(to)<8: return false
	route = population.world.find_path(position,to)
	if route.is_empty(): return false
	if not population.world.can_walk_line(position,route[0]):
		# Nearest by grid distance can be across the corner of a house. Pick a
		# grid entry that this body can actually reach before asking A* to continue.
		var found := false
		var cell := Vector2i(position/population.world.CELL)
		for radius in range(1,5):
			for dx in range(-radius,radius+1):
				for dy in range(-radius,radius+1):
					var candidate := cell+Vector2i(dx,dy)
					if not population.world.navigation.region.has_point(candidate) or population.world.navigation.is_point_solid(candidate): continue
					var at: Vector2 = population.world.navigation.get_point_position(candidate)
					if not population.world.can_walk_line(position,at): continue
					var continuation: PackedVector2Array = population.world.find_path(at,to)
					if continuation.is_empty(): continue
					route = continuation
					found = true
					break
				if found: break
			if found: break
		if not found: return false
	if population.world.can_walk_line(route[-1],to): route.append(to)
	goal = to
	state = next_state
	return true

func arrival_radius() -> float:
	if appointment.get("mode","")=="outdoor_meal": return 8.0
	return 44.0 if appointment.get("mode","")=="inside" else 32.0

func available() -> bool: return visible and state not in ["inside","entering"]
func activity_label() -> String:
	if encounter_id>=0:
		return {"offer":"a atender um vizinho","capture":"a tirar uma fotografia","clap":"a aplaudir o concerto","listen":"a ouvir outra pessoa","speak":"a conversar"}.get(social_pose,"num encontro com outras pessoas")
	if appointment.is_empty(): return entry.activity
	if state=="commuting":
		if appointment.place in ["residence","home"]: return "a regressar ao alojamento" if profile.residence=="hotel" else "a regressar a casa"
		var location: String = appointment.location
		if location.begins_with("encontro "): return "a caminho do "+location
		if location.begins_with("Casas "): return "a caminho das "+location
		if location.begins_with("Jardins "): return "a caminho dos "+location
		if location.begins_with("Praça ") or location.begins_with("Rua ") or location.begins_with("Fonte "): return "a caminho da "+location
		return "a caminho do "+location
	return appointment.activity

func step(delta: float, _cycle: RefCounted) -> void:
	clock += delta
	yield_cooldown = maxf(0,yield_cooldown-delta)
	greet_time = maxf(0,greet_time-delta)
	retry_time = maxf(0,retry_time-delta)
	escort_time = maxf(0,escort_time-delta)
	if state=="inside": return
	if state=="entering":
		enter_time = maxf(0,enter_time-delta)
		modulate.a = enter_time/.8
		if enter_time<=0: _inside()
		return
	if meal_seated:
		velocity = Vector2.ZERO
		art.queue_redraw()
		return
	if event_busy or social_lock or greet_time>0 or population.waiting_for_child(self):
		velocity = Vector2.ZERO
		motion.step(self,delta,0)
		queue_redraw()
		art.queue_redraw()
		return
	if state=="commuting" and profile.has("guardian") and escort_time<=0:
		var adult: CharacterBody2D = population.by_id[profile.guardian]
		if adult.available() and adult.state=="commuting" and adult.position.distance_to(adult.anchor)>150 and position.distance_to(adult.position)>145:
			_begin_walk(adult.position,"commuting")
			escort_time = 1.0
		elif adult.position.distance_to(adult.anchor)<=150 and goal!=anchor:
			_begin_walk(anchor,"commuting")
	# Keep a purposeful route when passing the player. Steering and swept
	# collisions still give way, without replacing an errand with an idle detour.
	var errand_mode: Variant = get("delivery_mode")
	var purposeful: bool = (errand_mode is String and not str(errand_mode).is_empty()) or get_meta("seeking_bench",false)
	if encounter_id<0 and state!="commuting" and not purposeful and yield_cooldown<=0:
		var aside: Vector2 = population.yield_goal(self)
		if aside!=Vector2.INF and _begin_walk(aside,"yielding"): yield_cooldown = 3.0
	var old_position := position
	if state in ["commuting","walking","yielding","returning"]:
		while not route.is_empty() and position.distance_to(route[0])<7: route.remove_at(0)
		var lookahead := mini(route.size()-1,8)
		while lookahead>0:
			if position.distance_to(route[lookahead])>384:
				lookahead -= 1
				continue
			if population.world.can_walk_line(position,route[lookahead]):
				for i in lookahead: route.remove_at(0)
				break
			lookahead -= 1
		if route.is_empty():
			if state=="commuting":
				if position.distance_to(anchor)<arrival_radius(): _arrive()
				elif retry_time<=0:
					_begin_walk(anchor,"commuting")
					retry_time = 2
			else:
				state = "activity"
				dwell = _idle_duration()
			velocity = Vector2.ZERO
		else:
			var direction := position.direction_to(route[0])
			var speed: float = gait.speed(self)
			speed *= population.world.walking_multiplier(position)
			var separation: Vector2 = population.neighbouring_velocity(self)
			velocity = (direction*speed+separation).limit_length(speed*1.15)
			var displacement := velocity*delta
			if displacement.length()>position.distance_to(route[0]): displacement = direction*position.distance_to(route[0])
			if not population.world.can_walk_line(position,position+displacement) or (separation.length_squared()>1 and not population.world.can_walk_line(position+displacement,route[0])):
				# Neighbour avoidance must never push someone into a building edge.
				displacement = direction*minf(speed*delta,position.distance_to(route[0]))
			if population.world.can_walk_line(position,position+displacement) or _clear_body_step(position,position+displacement):
				move_and_collide(displacement)
			elif not population.world.is_walkable(position,26): _recover_clearance(speed*delta)
			if absf(direction.x)>.12: facing_left = direction.x<0
			stuck_time = stuck_time+delta if position.distance_to(old_position)<.02 else 0.0
			if stuck_time>1.5:
				var resume_state := state
				_begin_walk(goal,resume_state)
				stuck_time = 0
	else:
		velocity = Vector2.ZERO
		dwell -= delta
		if dwell<=0:
			if position.distance_to(anchor)>45 and stroll.size()==1: _begin_walk(anchor,"returning")
			elif stroll.size()>1:
				stroll_index = (stroll_index+motion.rng.randi_range(1,stroll.size()-1))%stroll.size()
				if not _begin_walk(stroll[stroll_index]): dwell = 3.0
			else: dwell = _idle_duration()
	var walked := position.distance_to(old_position)
	if walked>.02: travel_direction = position-old_position
	distance_walked += walked
	travelled += walked
	motion.step(self,delta,walked)
	queue_redraw()
	art.queue_redraw()

func _clear_body_step(from: Vector2, to: Vector2) -> bool:
	# Coarse route smoothing keeps generous space. At a paving junction that
	# margin can reject a tiny step although this eleven-pixel body fits safely.
	# Test the actual body clearance densely and keep swept physics for walls.
	var steps := maxi(1,ceili(from.distance_to(to)/2))
	var clearance := 17.0 if entry.id=="duarte" else 12.0
	for i in range(steps+1):
		if not population.world.is_walkable(from.lerp(to,float(i)/steps),clearance): return false
	return true

func _recover_clearance(distance: float) -> void:
	for radius in [12.0,24.0,40.0]:
		for i in 16:
			var motion: Vector2 = Vector2.from_angle(i*TAU/16)*radius
			if population.world.is_walkable(position+motion,26) and not test_move(global_transform,motion):
				move_and_collide(motion.limit_length(distance))
				return

func _idle_duration() -> float:
	return float(entry.wait_seconds)*motion.rng.randf_range(.65,1.6)*(1.25-float(motion.personality.restlessness)*.5)

func _cancel_encounter() -> void:
	if is_instance_valid(population.world.social_life): population.world.social_life.cancel_for(self)

func greet() -> String:
	_cancel_encounter()
	if appointment.get("place","")=="nightlife" and is_instance_valid(population.world.nightlife):
		return population.world.nightlife.greet(self)
	var reply: String = _greeting()
	if is_instance_valid(population.world.social_life): reply += population.world.social_life.memory_line(self)
	return reply

func _greeting() -> String:
	greetings += 1
	greet_time = 3.2
	velocity = Vector2.ZERO
	if state=="commuting": return "%s cumprimenta o Te e o Jo. Está %s; à chegada, vai %s."%[entry.name,activity_label(),str(appointment.activity).trim_prefix("a ")]
	if appointment.get("place","")=="regular" and appointment.get("activity","")==entry.activity: return entry.greeting
	if appointment.get("place","")=="friends":
		var others: Array = population.residents.filter(func(actor): return actor!=self and actor.available() and actor.entry.has("friend_of") and actor.position.distance_to(position)<400)
		if others.is_empty(): return "%s cumprimenta o Te e o Jo. Chegou ao ponto de encontro e espera pelos amigos."%entry.name
	return "%s cumprimenta o Te e o Jo. Está %s — %s."%[entry.name,activity_label(),appointment.location]

func _draw() -> void:
	draw_set_transform(Vector2(0,2),0,Vector2(1,.32))
	draw_circle(Vector2.ZERO,28 if entry.id=="duarte" else (13 if entry.age<13 else 19),Color(0.07,.08,.06,.18))
	draw_set_transform(Vector2.ZERO)
	if entry.id=="matilde" and state=="activity":
		for i in 5:
			var at := anchor-position+Vector2(-36 if i%3==1 else 0,16+i*19)
			draw_rect(Rect2(at-Vector2(15,0),Vector2(29,18)),Color(.91,.86,.71,.65),false,1.1)
	if entry.id=="aisha" and frame<2 and state=="activity":
		for i in 5:
			var t := fposmod(clock*.24+i*.21,1.0)
			var at := Vector2(12+t*38+sin(t*7+i)*8,-70-t*110)
			draw_arc(at,3+t*4,0,TAU,20,Color(.82,.9,.94,(1-t)*.5),1,true)
	if flash_until>clock:
		draw_circle(Vector2(21,-float(entry.height)*.69),8,Color(1,.97,.82,.9))
