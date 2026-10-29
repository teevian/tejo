extends CharacterBody2D
const Art = preload("res://scripts/open_world_art.gd")
const Body = preload("res://scripts/open_world_body.gd")
var body: Node2D
enum PhoneState { NONE, TAKING_OUT, READING, PUTTING_AWAY }
const PHONE_IDLE_SECONDS := 7.0
var kind := 0
var controlled := false:
	set(value):
		controlled = value
		if value and kind == 1:
			_start_putting_phone_away()
var partner: CharacterBody2D
var world: Node2D
var in_dialogue := false
var facing := Vector2.DOWN
var visual_facing := Vector2.DOWN
var gait_weight := 0.0
var moving := false
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
	if kind == 1:
		_update_phone(delta, input)
	var direction := Vector2.ZERO
	var speed := 235.0 if kind == 0 else 245.0
	if controlled:
		direction = input
		if Input.is_action_pressed("sprint"):
			speed *= 1.42
	elif is_instance_valid(partner) and phone_state != PhoneState.PUTTING_AWAY:
		var gap := position.distance_to(partner.position)
		if gap > 94:
			speed = 355.0 if gap > 165 else 250.0
			if world.can_walk_line(position, partner.position):
				direction = position.direction_to(partner.position)
				path.clear()
			else:
				route_time -= delta
				if route_time <= 0 or path.is_empty():
					path = world.find_path(position, partner.position)
					route_time = 0.3
				while not path.is_empty() and position.distance_to(path[0]) < 18:
					path.remove_at(0)
				if not path.is_empty():
					direction = position.direction_to(path[0])
	velocity = velocity.move_toward(direction * speed, 1600 * delta)
	var previous := position
	move_and_slide()
	position = position.clamp(Vector2(32,32), world.WORLD_SIZE - Vector2(32,32))
	var travelled := position.distance_to(previous)
	moving = travelled > 0.1 and velocity.length() > 10
	if moving:
		facing = velocity.normalized()
		walked += travelled
	_update_art_motion(delta)
	queue_redraw()
	body.queue_redraw()

func _update_art_motion(delta: float) -> void:
	var turn := wrapf(facing.angle()-visual_facing.angle(),-PI,PI)
	visual_facing = Vector2.from_angle(visual_facing.angle()+clampf(turn,-delta*12.0,delta*12.0))
	gait_weight = move_toward(gait_weight,1.0 if moving else 0.0,delta*7.0)

func _update_phone(delta: float, input: Vector2) -> void:
	if controlled and not input.is_zero_approx():
		_finish_phone()
		return
	var may_wait := not controlled and velocity.length() < 1 and is_instance_valid(partner)
	if may_wait:
		may_wait = partner.controlled and partner.velocity.length() < 1 and input.is_zero_approx()
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
	draw_circle(Vector2.ZERO, 32, Color(0.08,0.16,0.13,0.27))
	if selected_blend > 0.01:
		draw_arc(Vector2.ZERO, 36, 0, TAU, 48, Color(1,0.88,0.6,selected_blend*0.8), 2, true)
	draw_set_transform(Vector2.ZERO)
	if controlled:
		draw_colored_polygon(PackedVector2Array([Vector2(-5,-211),Vector2(5,-211),Vector2(0,-205)]),Color("edd8a0"))
