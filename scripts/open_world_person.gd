extends CharacterBody2D
const Art = preload("res://scripts/open_world_art.gd")
const Body = preload("res://scripts/open_world_body.gd")
const Inventory = preload("res://scripts/inventory.gd")
const WorldScale = preload("res://scripts/world_scale.gd")
const InteractionArt = preload("res://scripts/interaction_art.gd")
var body: Node2D
enum PhoneState { NONE, TAKING_OUT, READING, PUTTING_AWAY }
enum ShoulderState { NONE, APPROACHING, TOUCHING }
const PHONE_IDLE_SECONDS := 7.0
const JUMP_DURATION := 0.7
var inventory = Inventory.new()
var shoulder_state := ShoulderState.NONE
var shoulder_idle_time := 0.0
var shoulder_side := 1.0
var shoulder_goal := Vector2.ZERO
var seated := false
var seating := false
var seat_id := ""
var seat_slot := -1
var seat_goal := Vector2.ZERO
var collecting_time := 0.0
var jumping := false
var jump_time := 0.0
var jump_from := Vector2.ZERO
var jump_to := Vector2.ZERO
var queued_jump: Dictionary = {}
var kind := 0
var controlled := false:
	set(value):
		controlled = value
		cancel_shoulder()
		if value:
			queued_jump.clear()
		if value and kind == 1:
			_start_putting_phone_away()
var partner: CharacterBody2D
var world: Node2D
var in_dialogue := false
var facing := Vector2.DOWN
var visual_facing := Vector2.DOWN
var moving := false
var turning := false
var clock := 0.0
var walked := 0.0
var phone_state := PhoneState.NONE
var phone_idle_time := 0.0
var phone_time := 0.0
var phone_stow_start := 1.0
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
	clock += delta
	selected_blend = move_toward(selected_blend, 1.0 if controlled else 0.0, delta*5)
	if in_dialogue:
		velocity = Vector2.ZERO
		moving = false
		queue_redraw()
		_update_art_motion(delta)
		body.queue_redraw()
		return
	var input := Input.get_vector("walk_left", "walk_right", "walk_up", "walk_down")
	if jumping:
		_update_jump(delta)
		return
	if collecting_time>0:
		collecting_time = maxf(0,collecting_time-delta)
		velocity = Vector2.ZERO
		moving = false
		_refresh_art(delta)
		return
	if seated or seating:
		if controlled and not input.is_zero_approx():
			var old_seat := seat_id
			stand_up()
			if is_instance_valid(partner) and partner.seat_id==old_seat:
				partner.stand_up()
		elif not controlled and is_instance_valid(partner) and partner.seat_id!=seat_id and position.distance_to(partner.position)>150:
			stand_up()
		elif seated:
			velocity = Vector2.ZERO
			moving = false
			_refresh_art(delta)
			return
	if kind == 1:
		_update_phone(delta, input)
	else:
		_update_shoulder(delta,input)
	var direction := Vector2.ZERO
	var speed := 235.0 if kind == 0 else 245.0
	if seating:
		if position.distance_to(seat_goal)<7:
			position = seat_goal
			seating = false
			seated = true
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
		if Input.is_action_pressed("sprint"):
			speed *= 1.42
	elif shoulder_state==ShoulderState.APPROACHING:
		if position.distance_to(shoulder_goal)<6:
			position = shoulder_goal
			shoulder_state = ShoulderState.TOUCHING
			facing = Vector2.DOWN
			partner.facing = Vector2.DOWN
			velocity = Vector2.ZERO
		else:
			direction = _steer_towards(shoulder_goal)
			speed = 180.0
	elif shoulder_state==ShoulderState.TOUCHING:
		facing = Vector2.DOWN
	elif is_instance_valid(partner) and phone_state != PhoneState.PUTTING_AWAY:
		var gap := position.distance_to(partner.position)
		if gap > 94:
			speed = 355.0 if gap > 165 else 250.0
			direction = _steer_towards(partner.position)
	route_time -= delta
	velocity = velocity.move_toward(direction * speed, 1600 * delta)
	var previous := position
	move_and_slide()
	position = position.clamp(Vector2(32,32), world.WORLD_SIZE - Vector2(32,32))
	var travelled := position.distance_to(previous)
	moving = travelled > 0.1 and velocity.length() > 10
	if moving:
		facing = velocity.normalized()
		walked += travelled
	_refresh_art(delta)

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
	return jumping or seated or seating or collecting_time>0

func cancel_shoulder() -> void:
	if shoulder_state!=ShoulderState.NONE:
		path.clear()
	shoulder_state = ShoulderState.NONE
	shoulder_idle_time = 0

func _update_shoulder(delta: float, input: Vector2) -> void:
	var may_wait := not controlled and not is_busy() and is_instance_valid(partner) and not in_dialogue
	if may_wait:
		may_wait = partner.controlled and not partner.is_busy() and not partner.in_dialogue and partner.velocity.length()<1 and input.is_zero_approx() and not partner.moving
	if not may_wait:
		cancel_shoulder()
		return
	if shoulder_state==ShoulderState.NONE:
		if velocity.length()>1 or position.distance_to(partner.position)>150:
			shoulder_idle_time = 0
			return
		shoulder_idle_time += delta
		if shoulder_idle_time<PHONE_IDLE_SECONDS:
			return
		for side in [1.0,-1.0]:
			var goal: Vector2 = partner.position+WorldScale.SHOULDER_OFFSET*Vector2(-side,1)
			if world.is_walkable(goal,18) and not world.find_path(position,goal).is_empty():
				shoulder_side = side
				shoulder_goal = goal
				shoulder_state = ShoulderState.APPROACHING
				path.clear()
				return
		shoulder_idle_time = 5.0

func begin_sitting(id: String, goal: Vector2, slot := 0) -> bool:
	if jumping or not world.is_walkable(goal,14) or world.find_path(position,goal).is_empty():
		return false
	stand_up()
	cancel_shoulder()
	_finish_phone()
	queued_jump.clear()
	seating = true
	seat_id = id
	seat_slot = slot
	seat_goal = goal
	path.clear()
	route_time = 0
	return true

func stand_up() -> void:
	seated = false
	seating = false
	seat_id = ""
	seat_slot = -1
	path.clear()
	if is_instance_valid(body):
		body.position.y = 0

func start_jump(landing: Vector2) -> void:
	stand_up()
	cancel_shoulder()
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
		if phone_idle_time >= PHONE_IDLE_SECONDS:
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
	draw_set_transform(Vector2(0,-2), 0, Vector2(1,0.38))
	draw_circle(Vector2.ZERO, 25, Color(0.08,0.16,0.13,0.27))
	if selected_blend > 0.01:
		draw_arc(Vector2.ZERO, 29, 0, TAU, 48, Color(1,0.88,0.6,selected_blend*0.8), 2, true)
	draw_set_transform(Vector2.ZERO)
	if controlled:
		var top: float = -InteractionArt.SEATED[kind].size.y*InteractionArt.SCALE-14 if seated else -Art.HEIGHTS[kind]-18
		if jumping:
			top += body.position.y
		draw_colored_polygon(PackedVector2Array([Vector2(-5,top),Vector2(5,top),Vector2(0,top+6)]),Color("edd8a0"))
