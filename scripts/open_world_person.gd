extends CharacterBody2D
const Art = preload("res://scripts/open_world_art.gd")
const Body = preload("res://scripts/open_world_body.gd")
const Inventory = preload("res://scripts/inventory.gd")
const WorldScale = preload("res://scripts/world_scale.gd")
const InteractionArt = preload("res://scripts/interaction_art.gd")
const RestArt = preload("res://scripts/rest_art.gd")
var run_input = preload("res://scripts/double_tap_run.gd").new()
var body: Node2D
enum PhoneState { NONE, TAKING_OUT, READING, PUTTING_AWAY }
enum SandState { NONE, APPROACHING, DRAWING }
var idle_delay := randf_range(7.0,10.0)
const JUMP_DURATION := 0.7
var inventory = Inventory.new()
var sand_state := SandState.NONE
var sand_idle_time := 0.0
var sand_time := 0.0
var sand_goal := Vector2.ZERO
var seated := false
var seated_pose := 0
var ground_seated := false
var ground_pose := 0
var ground_rest := false
var ground_waiting := false
var ground_sync := false
var eyes_closed := false
var wake_leader := false
var wake_waiting := false
var rest_gaze = preload("res://scripts/rest_gaze.gd").new()
var rest_posture = preload("res://scripts/rest_posture.gd").new()
var rest_roll_from := 1
var rest_roll_to := 1
var rest_side_row := 0
var rest_side_fraction := 0.0
var rest_transition := ""
var rest_target := ""
var rest_time := 0.0
var rest_duration := 1.0
var rest_reverse_from := 1.0
var rest_from_sand := false
var seating := false
var seat_id := ""
var seat_slot := -1
var seat_goal := Vector2.ZERO
var collecting_time := 0.0
var puppy_recoil := Vector2.ZERO
var puppy_recoil_time := 0.0
var jumping := false
var jump_time := 0.0
var jump_from := Vector2.ZERO
var jump_to := Vector2.ZERO
var queued_jump: Dictionary = {}
var kind := 0
var controlled := false:
	set(value):
		controlled = value
		run_input.reset()
		running = false
		run_distance = 0.0
		cancel_sand_drawing()
		if value:
			queued_jump.clear()
		if value and kind == 1:
			_start_putting_phone_away()
var partner: CharacterBody2D
var world: Node2D
var in_dialogue := false
var map_blocked := false
var facing := Vector2.DOWN
var visual_facing := Vector2.DOWN
var moving := false
var turning := false
var clock := 0.0
var walked := 0.0
var running := false
var run_distance := 0.0
var phone_state := PhoneState.NONE
var phone_idle_time := 0.0
var phone_time := 0.0
var phone_stow_start := 1.0
var football_ball: Node2D
var football_action := ""
var football_variant := 0
var football_time := 0.0
var football_duration := 0.34
var football_facing := 1.0
var path := PackedVector2Array()
var route_time := 0.0
var selected_blend := 0.0

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	var collider := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 12
	collider.shape = shape
	add_child(collider)
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	body = Body.new()
	body.person = self
	add_child(body)

func _physics_process(delta: float) -> void:
	var was_running := running
	running = false
	clock += delta
	selected_blend = move_toward(selected_blend, 1.0 if controlled else 0.0, delta*5)
	if in_dialogue:
		run_input.reset()
		if rest_target=="standing" and not rest_transition.is_empty() and not map_blocked:
			_advance_rest_transition(delta)
			return
		velocity = Vector2.ZERO
		moving = false
		queue_redraw()
		_update_art_motion(delta)
		body.queue_redraw()
		return
	if puppy_recoil_time>0:
		puppy_recoil_time = maxf(0,puppy_recoil_time-delta)
		velocity = puppy_recoil
		if world.is_walkable(position+velocity*delta,14):
			move_and_slide()
		moving = false
		_refresh_art(delta)
		return
	if not football_action.is_empty():
		football_time += delta
		if football_time>=football_duration: football_action = ""
	var input := Input.get_vector("walk_left", "walk_right", "walk_up", "walk_down")
	if controlled: run_input.step(input,delta)
	else: run_input.reset()
	if not rest_transition.is_empty():
		if rest_target=="sand" and (not input.is_zero_approx() or not is_instance_valid(partner) or not partner.controlled or partner.moving):
			cancel_sand_drawing()
		if controlled and not input.is_zero_approx() and rest_target!="standing":
			request_pair_wake()
		_advance_rest_transition(delta)
		return
	if jumping:
		_update_jump(delta)
		return
	if collecting_time>0:
		collecting_time = maxf(0,collecting_time-delta)
		velocity = Vector2.ZERO
		moving = false
		_refresh_art(delta)
		return
	if (wake_waiting or ground_waiting) and rest_transition.is_empty():
		if controlled and not input.is_zero_approx() and not wake_waiting: request_pair_wake()
		if ground_waiting and kind==1: _update_phone(delta,input)
		_refresh_art(delta)
		return
	if seated or ground_seated or seating:
		if controlled and not input.is_zero_approx():
			request_pair_wake()
		elif not controlled and is_instance_valid(partner) and partner.seat_id!=seat_id and position.distance_to(partner.position)>150:
			stand_up()
		elif seated or ground_seated:
			velocity = Vector2.ZERO
			moving = false
			if ground_seated:
				var next_pose: int = rest_posture.step(delta,ground_pose) if is_sleeping() else -1
				if next_pose>=1:
					begin_ground_roll(next_pose)
					_advance_rest_transition(delta)
					return
				var side := 1
				var reciprocal := false
				if is_instance_valid(partner):
					side = 1 if partner.position.x>=position.x else -1
					reciprocal = partner.ground_seated and partner.ground_pose==ground_pose and partner.rest_gaze.target==(0 if side>0 else 4)
				if not eyes_closed: rest_gaze.step(delta,ground_pose,side,reciprocal)
				else: rest_gaze.reset()
			_refresh_art(delta)
			return
	if not rest_transition.is_empty():
		_advance_rest_transition(delta)
		return
	if kind == 1:
		_update_phone(delta, input)
	else:
		_update_sand_drawing(delta,input)
	if not rest_transition.is_empty():
		_advance_rest_transition(delta)
		return
	var direction := Vector2.ZERO
	var speed := 235.0 if kind == 0 else 245.0
	var wants_to_run := false
	if seating:
		if kind==1 and phone_state!=PhoneState.NONE:
			direction = Vector2.ZERO
		elif position.distance_to(seat_goal)<7:
			position = seat_goal
			seating = false
			if ground_rest:
				if ground_sync: ground_waiting = true
				else: _begin_rest_transition("sit","ground",RestArt.SIT_SECONDS)
			else: seated = true
			facing = Vector2.DOWN
			velocity = Vector2.ZERO
		else:
			direction = _steer_towards(seat_goal)
	elif not controlled and not queued_jump.is_empty():
		if position.distance_to(queued_jump.from)<7:
			var landing: Vector2 = queued_jump.to
			position = queued_jump.from
			queued_jump.clear()
			start_jump(landing)
			_update_jump(delta)
			return
		direction = _steer_towards(queued_jump.from)
		speed = 300.0
	elif controlled:
		direction = input
		if is_juggling():
			run_input.reset()
			speed = 190.0
			if football_action=="lift" and football_time<0.42: direction = Vector2.ZERO
		elif run_input.running:
			speed *= 1.42
			wants_to_run = true
	elif sand_state==SandState.APPROACHING:
		if position.distance_to(sand_goal)<6:
			position = sand_goal
			_begin_rest_transition("sit","sand",RestArt.SIT_SECONDS)
			facing = Vector2.DOWN
			sand_time = 0.0
			velocity = Vector2.ZERO
		else:
			direction = _steer_towards(sand_goal)
			speed = 180.0
	elif sand_state==SandState.DRAWING:
		facing = Vector2.DOWN
	elif is_instance_valid(partner) and phone_state != PhoneState.PUTTING_AWAY:
		var gap := position.distance_to(partner.position)
		if partner.is_juggling():
			var spectator: Vector2 = partner.position+Vector2(-135,35)
			if position.distance_to(spectator)>24 and world.is_walkable(spectator,18): direction = _steer_towards(spectator)
			else: facing = position.direction_to(partner.position)
		elif gap > 94:
			speed = 355.0 if gap > 165 else 250.0
			wants_to_run = gap > 165
			direction = _steer_towards(partner.position)
	route_time -= delta
	if world.has_method("walking_multiplier"): speed *= world.walking_multiplier(position)
	velocity = velocity.move_toward(direction * speed, 1600 * delta)
	var previous := position
	move_and_slide()
	position = position.clamp(Vector2(32,32), world.WORLD_SIZE - Vector2(32,32))
	var travelled := position.distance_to(previous)
	moving = travelled > 0.1 and velocity.length() > 10
	if moving:
		facing = velocity.normalized()
		walked += travelled
	running = wants_to_run and moving and velocity.length()>270.0
	if running:
		if not was_running: run_distance = 0.0
		run_distance += travelled
	else:
		run_distance = 0.0
	_refresh_art(delta)

func is_running() -> bool:
	return running and moving and not in_dialogue and not map_blocked and not is_busy() and (not controlled or run_input.running)

func _steer_towards(goal: Vector2) -> Vector2:
	if world.can_walk_line(position,goal):
		path.clear()
		return position.direction_to(goal)
	if route_time<=0 or path.is_empty():
		path = world.find_path(position,goal)
		route_time = 0.3
	while not path.is_empty() and position.distance_to(path[0])<12:
		path.remove_at(0)
	return position.direction_to(path[0]) if not path.is_empty() else Vector2.ZERO

func _refresh_art(delta: float) -> void:
	_update_art_motion(delta)
	if not jumping:
		body.position.y = 0.0
	queue_redraw()
	body.queue_redraw()

func is_busy() -> bool:
	return jumping or seated or ground_seated or seating or ground_waiting or wake_waiting or collecting_time>0 or not rest_transition.is_empty() or is_juggling() or not football_action.is_empty()

func is_juggling() -> bool:
	return is_instance_valid(football_ball) and football_ball.juggling.owner==self

func play_football(action: String, variant: int, duration: float, direction: float) -> void:
	_finish_phone()
	football_action = action
	football_variant = variant
	football_duration = duration
	football_time = 0
	football_facing = direction
	run_input.reset()
	body.queue_redraw()

func cancel_sand_drawing(animated := true) -> void:
	if animated and (sand_state==SandState.DRAWING or rest_target=="sand"):
		stand_up()
	if sand_state!=SandState.NONE:
		path.clear()
	sand_state = SandState.NONE
	sand_idle_time = 0.0
	sand_time = 0.0

func _begin_rest_transition(clip: String, target: String, seconds: float) -> void:
	rest_gaze.reset()
	rest_transition = clip
	rest_target = target
	rest_time = 0
	rest_duration = seconds
	velocity = Vector2.ZERO
	moving = false
	if target!="standing": run_input.reset()

func _advance_rest_transition(delta: float) -> void:
	rest_time = minf(rest_duration,rest_time+delta)
	velocity = Vector2.ZERO
	moving = false
	if rest_time>=rest_duration:
		var target := rest_target
		rest_transition = ""
		rest_target = ""
		rest_from_sand = false
		match target:
			"sand":
				sand_state = SandState.DRAWING
				sand_time = 0
			"ground":
				ground_seated = true
				ground_pose = 0
			"reclined": ground_pose = 4
			"lying": ground_pose = 1
			"rolled": ground_pose = rest_roll_to
			"awake_seated", "partner_ready":
				ground_seated = true
				ground_pose = 0
				if target=="awake_seated": _begin_rest_transition("stretch","stretched",RestArt.STRETCH_SECONDS)
				else:
					stand_up()
					if is_instance_valid(partner): partner.stand_up()
			"stretched": _begin_rest_transition("call","called",RestArt.CALL_SECONDS)
			"called":
				wake_waiting = true
				if is_instance_valid(partner): partner._wake_to_sitting("partner_ready")
				else: stand_up()
	_refresh_art(delta)

func begin_reclining() -> void:
	if ground_seated and ground_pose==0 and rest_transition.is_empty():
		eyes_closed = false
		_begin_rest_transition("recline","reclined",RestArt.RECLINE_SECONDS)

func begin_lying() -> void:
	if ground_seated and ground_pose in [0,4] and rest_transition.is_empty():
		rest_reverse_from = 1
		rest_from_sand = false
		eyes_closed = false
		_begin_rest_transition("lie","lying",RestArt.LIE_SECONDS)

func close_rest_eyes() -> void:
	if ground_seated and ground_pose in [1,2,3] and rest_transition.is_empty():
		eyes_closed = true
		rest_gaze.reset()
		rest_posture.reset()
		if is_instance_valid(body): _refresh_art(0)

func is_sleeping() -> bool:
	return eyes_closed and ground_seated and ground_pose in [1,2,3] and rest_target!="standing"

func request_pair_wake() -> void:
	if wake_leader or wake_waiting or (is_instance_valid(partner) and partner.wake_leader): return
	if ground_rest and ground_seated and is_instance_valid(partner) and partner.ground_rest:
		wake_leader = true
		partner.wake_waiting = true
		_wake_to_sitting("awake_seated")
	else:
		var old_seat := seat_id
		stand_up()
		if is_instance_valid(partner) and partner.seat_id==old_seat: partner.stand_up()

func _wake_to_sitting(target: String) -> void:
	var old_pose := ground_pose
	var clip := rest_transition
	var progress := clampf(rest_time/rest_duration,0,1)
	var side := current_side_roll()
	eyes_closed = false
	wake_waiting = false
	ground_waiting = false
	ground_sync = false
	rest_posture.reset()
	rest_reverse_from = 1
	if old_pose in [1,2,3] or clip in ["lie","roll"]:
		rest_side_row = int(side.x)
		rest_side_fraction = side.y
		rest_reverse_from = progress if clip=="lie" else 1.0
		_begin_rest_transition("sit_up",target,RestArt.ROLL_SECONDS*side.y+RestArt.SIT_UP_SECONDS*rest_reverse_from+RestArt.RECLINE_SECONDS)
	elif old_pose==4 or clip=="recline":
		rest_reverse_from = progress if clip=="recline" else 1.0
		_begin_rest_transition("unrecline",target,maxf(0.1,RestArt.RECLINE_SECONDS*rest_reverse_from))
	else:
		_begin_rest_transition("settle",target,0.2)

func begin_ground_roll(target_pose: int) -> void:
	if not ground_seated or ground_pose not in [1,2,3] or not rest_transition.is_empty() or target_pose==ground_pose or target_pose not in [1,2,3]: return
	rest_roll_from = ground_pose
	rest_roll_to = target_pose
	rest_posture.reset()
	var segments := 2 if ground_pose>=2 and target_pose>=2 else 1
	_begin_rest_transition("roll","rolled",RestArt.ROLL_SECONDS*segments)

func current_side_roll() -> Vector2:
	if rest_transition=="roll":
		if rest_roll_from>=2 and (rest_roll_to==1 or rest_time<RestArt.ROLL_SECONDS):
			return Vector2(rest_roll_from-2,clampf(1-rest_time/RestArt.ROLL_SECONDS,0,1))
		var elapsed := rest_time-(RestArt.ROLL_SECONDS if rest_roll_from>=2 else 0.0)
		return Vector2(rest_roll_to-2,clampf(elapsed/RestArt.ROLL_SECONDS,0,1))
	if ground_pose in [2,3]: return Vector2(ground_pose-2,1)
	return Vector2.ZERO

func _update_sand_drawing(delta: float, input: Vector2) -> void:
	var may_wait := not controlled and not is_busy() and is_instance_valid(partner) and not in_dialogue
	if may_wait:
		may_wait = partner.controlled and not partner.is_busy() and not partner.in_dialogue and partner.velocity.length()<1 and input.is_zero_approx() and not partner.moving
	if not may_wait:
		cancel_sand_drawing()
		return
	if sand_state==SandState.DRAWING:
		sand_time += delta
		return
	if sand_state!=SandState.NONE:
		return
	if velocity.length()>1 or position.distance_to(partner.position)>150:
		sand_idle_time = 0.0
		return
	sand_idle_time += delta
	if sand_idle_time<idle_delay:
		return
	for offset in [Vector2.ZERO,Vector2(-44,24),Vector2(44,24),Vector2(-88,24),Vector2(88,24),Vector2(0,88)]:
		var goal: Vector2 = position+offset
		if goal.distance_to(partner.position)<80:
			continue
		if world.has_method("allows_ground_rest") and not world.allows_ground_rest(goal):
			continue
		# Room for folded legs and the fingertip's small drawing area.
		if not world.is_walkable(goal,46) or not world.is_walkable(goal+Vector2(0,-36),32) or not world.is_walkable(goal+Vector2(30,6),28):
			continue
		if not world.can_walk_line(position,goal) or world.find_path(position,goal).is_empty():
			continue
		sand_goal = goal
		sand_state = SandState.APPROACHING
		sand_time = 0.0
		path.clear()
		return
	sand_idle_time = 5.0

func begin_sitting(id: String, goal: Vector2, slot := 0) -> bool:
	if jumping or not world.is_walkable(goal,14) or world.find_path(position,goal).is_empty():
		return false
	stand_up()
	cancel_sand_drawing(false)
	_start_putting_phone_away()
	queued_jump.clear()
	seating = true
	seat_id = id
	seat_slot = slot
	seat_goal = goal
	path.clear()
	route_time = 0
	return true

func begin_ground_sitting(goal: Vector2, synchronized := false) -> void:
	if jumping or not world.is_walkable(goal,14) or world.find_path(position,goal).is_empty(): return
	ground_waiting = false
	eyes_closed = false
	var already_drawing := sand_state==SandState.DRAWING
	var already_lowering := rest_target=="sand" and rest_transition=="sit"
	if already_lowering and position.distance_to(goal)<7:
		rest_target = "ground"
		cancel_sand_drawing(false)
	elif (already_drawing or already_lowering) and position.distance_to(goal)>=7:
		stand_up()
	else:
		cancel_sand_drawing(false)
	seated = false
	ground_seated = false
	ground_pose = 0
	ground_rest = true
	seat_id = "ground_rest"
	seat_slot = kind
	seat_goal = goal
	seating = true
	queued_jump.clear()
	path.clear()
	route_time = 0
	run_input.reset()
	_start_putting_phone_away()
	ground_sync = synchronized
	if (already_lowering or already_drawing) and position.distance_to(goal)<7:
		seating = false
		if synchronized:
			ground_waiting = true
			rest_transition = ""
			rest_target = ""
		else: _begin_rest_transition("settle","ground",0.28)

func start_ground_settle() -> void:
	ground_waiting = false
	ground_sync = false
	seating = false
	var was_drawing := sand_state==SandState.DRAWING
	cancel_sand_drawing(false)
	_begin_rest_transition("settle" if was_drawing else "sit","ground",RestArt.SIT_SECONDS)

func stand_up(immediate := false) -> void:
	eyes_closed = false
	wake_leader = false
	wake_waiting = false
	ground_waiting = false
	ground_sync = false
	rest_gaze.reset()
	rest_posture.reset()
	var side_now := current_side_roll()
	var was_sand := sand_state==SandState.DRAWING or rest_target=="sand"
	var on_ground := ground_seated or was_sand or rest_target in ["ground","lying"]
	var semi := ground_pose==4 or rest_transition=="recline"
	var lying := ground_pose in [1,2,3] or rest_transition in ["lie","roll"]
	var fraction := 1.0
	if rest_transition in ["sit","lie"]: fraction = clampf(rest_time/rest_duration,0,1)
	var already_rising := rest_target=="standing"
	ground_pose = 0
	ground_seated = false
	ground_rest = false
	seated_pose = 0
	seated = false
	seating = false
	seat_id = ""
	seat_slot = -1
	path.clear()
	sand_state = SandState.NONE
	sand_idle_time = 0
	if immediate:
		rest_transition = ""
		rest_target = ""
		rest_from_sand = false
	elif on_ground and not already_rising:
		rest_from_sand = was_sand
		rest_reverse_from = fraction
		if lying and side_now.y>0:
			rest_side_row = int(side_now.x)
			rest_side_fraction = side_now.y
			rest_reverse_from = 1
			_begin_rest_transition("wake_side","standing",RestArt.ROLL_SECONDS*side_now.y+RestArt.SIT_UP_SECONDS+RestArt.RISE_SECONDS)
		elif semi:
			_begin_rest_transition("wake_reclined","standing",RestArt.RECLINE_SECONDS+RestArt.RISE_SECONDS)
		else:
			_begin_rest_transition("wake" if lying else "stand","standing",RestArt.SIT_UP_SECONDS*fraction+RestArt.RISE_SECONDS if lying else maxf(0.10,RestArt.RISE_SECONDS*fraction))
	if is_instance_valid(body):
		body.position.y = 0

func start_jump(landing: Vector2) -> void:
	stand_up(true)
	cancel_sand_drawing(false)
	_finish_phone()
	jumping = true
	jump_time = 0
	jump_from = position
	jump_to = landing
	facing = position.direction_to(landing)
	velocity = Vector2.ZERO
	path.clear()

func _update_jump(delta: float) -> void:
	jump_time = minf(JUMP_DURATION,jump_time+delta)
	var progress := jump_time/JUMP_DURATION
	position = jump_from.lerp(jump_to,progress)
	body.position.y = -sin(progress*PI)*58.0
	moving = false
	if progress>=1:
		jumping = false
		body.position.y = 0
	_refresh_art(delta)

func _update_art_motion(delta: float) -> void:
	var turn := wrapf(facing.angle()-visual_facing.angle(),-PI,PI)
	var rotation := clampf(turn,-delta*7.0,delta*7.0)
	turning = absf(turn)>0.04 and not jumping and not is_busy()
	visual_facing = Vector2.from_angle(visual_facing.angle()+rotation)
	# A stationary pivot needs footwork too. Moving turns keep the current
	# distance-driven left/right phase instead of restarting on one foot.
	if turning and not moving:
		walked += absf(rotation)*24.0

func _update_phone(delta: float, input: Vector2) -> void:
	if controlled and not input.is_zero_approx():
		_finish_phone()
		return
	var may_wait := not controlled and not is_busy() and velocity.length() < 1 and is_instance_valid(partner)
	if may_wait:
		may_wait = partner.controlled and not partner.is_busy() and partner.velocity.length() < 1 and input.is_zero_approx()
	if may_wait and phone_state == PhoneState.NONE:
		phone_idle_time += delta
		if phone_idle_time >= idle_delay:
			phone_state = PhoneState.TAKING_OUT
			phone_time = 0
	elif not may_wait:
		phone_idle_time = 0
		_start_putting_phone_away()
	match phone_state:
		PhoneState.TAKING_OUT:
			phone_time += delta
			if phone_time >= 0.72:
				phone_state = PhoneState.READING
				phone_time = 0
		PhoneState.READING:
			phone_time += delta
		PhoneState.PUTTING_AWAY:
			phone_time += delta
			if phone_time >= 0.36:
				_finish_phone()

func _start_putting_phone_away() -> void:
	if phone_state in [PhoneState.NONE, PhoneState.PUTTING_AWAY]:
		return
	phone_stow_start = clampf(phone_time / 0.72, 0, 1) if phone_state == PhoneState.TAKING_OUT else 1.0
	phone_state = PhoneState.PUTTING_AWAY
	phone_time = 0

func _finish_phone() -> void:
	phone_state = PhoneState.NONE
	phone_idle_time = 0
	phone_time = 0

func _draw() -> void:
	var recline := (0.6 if ground_pose==4 else 1.0) if ground_seated and ground_pose>=1 else 0.0
	if rest_transition=="lie": recline = clampf(rest_time/rest_duration,0,1)
	elif rest_transition=="wake": recline = maxf(0,rest_reverse_from-rest_time/RestArt.SIT_UP_SECONDS)
	elif rest_transition=="wake_side": recline = maxf(0,1-maxf(0,rest_time-RestArt.ROLL_SECONDS*rest_side_fraction)/RestArt.SIT_UP_SECONDS)
	var drawing := sand_state==SandState.DRAWING
	var side_amount: float = current_side_roll().y if ground_seated or rest_transition=="roll" else 0.0
	if rest_transition=="wake_side": side_amount = maxf(0,rest_side_fraction-rest_time/RestArt.ROLL_SECONDS)
	var shadow_position := Vector2(0,lerpf(-2,-48,recline)).lerp(Vector2(-25 if kind==0 else 0,-34),side_amount)
	var shadow_scale := Vector2(1,0.38).lerp(Vector2(1.05,1.15),recline).lerp(Vector2(1.45,0.65),side_amount)
	draw_set_transform(shadow_position,0,shadow_scale)
	draw_circle(Vector2.ZERO,40 if ground_seated or drawing or recline>0 else 25,Color(0.08,0.16,0.13,0.27))
	draw_set_transform(Vector2(0,-2),0,Vector2(1,0.38))
	if selected_blend > 0.01:
		draw_arc(Vector2.ZERO, 29, 0, TAU, 48, Color(1,0.88,0.6,selected_blend*0.8), 2, true)
	draw_set_transform(Vector2.ZERO)
	if controlled:
		var top: float = InteractionArt.seated_rect(kind,seated_pose).position.y-14 if seated else -Art.HEIGHTS[kind]-18
		if ground_seated:
			top = InteractionArt.GROUND_RECTS[ground_pose][kind].position.y-14
		if jumping:
			top += body.position.y
		var marker_x: float = InteractionArt.SEATED_HEAD_X[seated_pose][kind] if seated else 0.0
		draw_colored_polygon(PackedVector2Array([Vector2(marker_x-5,top),Vector2(marker_x+5,top),Vector2(marker_x,top+6)]),Color("edd8a0"))
