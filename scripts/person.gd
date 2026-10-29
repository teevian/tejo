class_name TejoPerson
extends CharacterBody2D

const JoAppearance = preload("res://scripts/jo_art.gd")
const TeAppearance = preload("res://scripts/te_art.gd")
const PhoneAppearance = preload("res://scripts/jo_phone_art.gd")
const FLOOR_Y := 554.0
const WALK_SPEED := [225.0, 310.0]
const JUMP_SPEED := [-420.0, -455.0]
const COLLISION_HEIGHT := [140.0, 137.0]
const PHONE_IDLE_SECONDS := 7.0
const PHONE_TAKE_SECONDS := 0.72
const PHONE_STOW_SECONDS := 0.36
enum PhoneState { NONE, TAKING_OUT, READING, PUTTING_AWAY }
var walk_min_x := 85.0
var walk_max_x := 1195.0
var in_dialogue := false
var kind := 0
var controlled := false:
	set(value):
		controlled = value
		if value and kind == 1:
			phone_idle_time = 0.0
			_start_putting_phone_away()
var partner: CharacterBody2D
var face := 1.0
var step := 0.0
var clock := 0.0
var moving := false
var selected_blend := 0.0
var phone_state := PhoneState.NONE
var phone_idle_time := 0.0
var phone_time := 0.0
var phone_stow_start := 1.0
var last_leader_position := Vector2.ZERO
var has_leader_position := false

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	var collision := CollisionShape2D.new()
	var shape := CapsuleShape2D.new()
	shape.radius = 21.0 if kind == 0 else 17.0
	shape.height = COLLISION_HEIGHT[kind]
	collision.shape = shape
	collision.position.y = -COLLISION_HEIGHT[kind] * 0.5
	add_child(collision)
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	queue_redraw()

func _physics_process(delta: float) -> void:
	clock += delta
	if in_dialogue:
		queue_redraw()
		return
	if kind == 1:
		_update_phone(delta)
	var direction := 0.0
	if controlled:
		direction = Input.get_axis("walk_left", "walk_right")
		if Input.is_action_just_pressed("jump") and is_on_floor():
			velocity.y = JUMP_SPEED[kind]
	elif is_instance_valid(partner) and phone_state != PhoneState.PUTTING_AWAY:
		var distance: float = partner.position.x - position.x
		if absf(distance) > 89.0:
			direction = signf(distance) * clampf((absf(distance) - 72.0) / 80.0, 0.22, 1.0)
		if partner.position.y < position.y - 44.0 and is_on_floor() and absf(distance) > 65.0:
			velocity.y = JUMP_SPEED[kind]
	if not is_on_floor():
		velocity.y += 1100.0 * delta
	var speed: float = WALK_SPEED[kind] if controlled else 285.0
	velocity.x = move_toward(velocity.x, direction * speed, 1450.0 * delta)
	moving = absf(velocity.x) > 12.0
	if moving:
		face = signf(velocity.x)
		step += delta * absf(velocity.x) * 0.065
	else:
		step = lerpf(step, 0.0, delta * 10.0)
	move_and_slide()
	position.x = clampf(position.x, walk_min_x, walk_max_x)
	selected_blend = move_toward(selected_blend, 1.0 if controlled else 0.0, delta * 5.0)
	z_index = 12 if controlled else 11
	queue_redraw()

func _update_phone(delta: float) -> void:
	# Selection and movement stay responsive even halfway through the pocket gesture.
	if controlled and (not is_zero_approx(Input.get_axis("walk_left", "walk_right")) or Input.is_action_just_pressed("jump")):
		_finish_phone()
		return
	var leader := partner as TejoPerson
	var leader_moved := false
	if is_instance_valid(leader):
		leader_moved = has_leader_position and not leader.position.is_equal_approx(last_leader_position)
		last_leader_position = leader.position
		has_leader_position = true
	var may_wait := not controlled and is_on_floor() and absf(velocity.x) < 1.0 and absf(velocity.y) < 1.0
	may_wait = may_wait and is_instance_valid(leader)
	if may_wait:
		may_wait = leader.kind == 0 and leader.controlled and leader.is_on_floor() and not leader_moved
		may_wait = may_wait and absf(leader.velocity.x) < 1.0 and absf(leader.velocity.y) < 1.0
		# React to the first input, even before Te crosses the companion's follow distance.
		may_wait = may_wait and is_zero_approx(Input.get_axis("walk_left", "walk_right")) and not Input.is_action_just_pressed("jump")
	if may_wait:
		if phone_state == PhoneState.NONE:
			phone_idle_time += delta
			if phone_idle_time >= PHONE_IDLE_SECONDS:
				phone_state = PhoneState.TAKING_OUT
				phone_time = 0.0
	else:
		phone_idle_time = 0.0
		_start_putting_phone_away()
	match phone_state:
		PhoneState.TAKING_OUT:
			phone_time += delta
			if phone_time >= PHONE_TAKE_SECONDS:
				phone_state = PhoneState.READING
				phone_time = 0.0
		PhoneState.READING:
			phone_time += delta
		PhoneState.PUTTING_AWAY:
			phone_time += delta
			if phone_time >= PHONE_STOW_SECONDS:
				_finish_phone()

func _start_putting_phone_away() -> void:
	if phone_state == PhoneState.NONE or phone_state == PhoneState.PUTTING_AWAY:
		return
	phone_stow_start = clampf(phone_time / PHONE_TAKE_SECONDS, 0.0, 1.0) if phone_state == PhoneState.TAKING_OUT else 1.0
	phone_state = PhoneState.PUTTING_AWAY
	phone_time = 0.0

func _finish_phone() -> void:
	phone_state = PhoneState.NONE
	phone_idle_time = 0.0
	phone_time = 0.0

func phone_frame() -> int:
	match phone_state:
		PhoneState.TAKING_OUT:
			return mini(3, int(phone_time / PHONE_TAKE_SECONDS * 4.0))
		PhoneState.READING:
			return 4 + int(phone_time * 2.0) % 4
		PhoneState.PUTTING_AWAY:
			var progress := phone_stow_start * clampf(1.0 - phone_time / PHONE_STOW_SECONDS, 0.0, 1.0)
			return mini(3, int(progress * 4.0))
	return 0

func _draw() -> void:
	# The shadow stays on the forest trail while the character jumps.
	var height := maxf(0.0, FLOOR_Y - position.y)
	draw_set_transform(Vector2(0, height), 0, Vector2(1.0 - height * 0.0018, 0.27))
	var shadow_radius := 40.0 if kind == 0 else 32.0
	draw_circle(Vector2.ZERO, shadow_radius, Color(0.10, 0.21, 0.23, 0.19))
	if selected_blend > 0.01:
		draw_arc(Vector2.ZERO, shadow_radius + 4.0, 0, TAU, 48, Color(1.0, 0.87, 0.57, selected_blend * 0.9), 3.0, true)
	draw_set_transform(Vector2.ZERO)
	if kind == 0:
		_draw_te()
	else:
		_draw_jo()

func _draw_te() -> void:
	var frame := TeAppearance.frame_for(is_on_floor(), moving, velocity.y, step, clock)
	var breath := sin(clock * 1.8) * 0.45 if not moving and is_on_floor() else 0.0
	draw_set_transform(Vector2(0, -breath), 0.0, Vector2(face, 1))
	TeAppearance.draw_pose(self, frame)
	draw_set_transform(Vector2.ZERO)
	if selected_blend > 0.01:
		var marker_y := -TeAppearance.HEIGHT - 13.0 + sin(clock * 3.0) * 2.0
		draw_colored_polygon(PackedVector2Array([Vector2(-4, marker_y), Vector2(4, marker_y), Vector2(0, marker_y + 5)]), Color(1.0, 0.88, 0.63, selected_blend))

func _draw_jo() -> void:
	var frame := JoAppearance.frame_for(is_on_floor(), moving, velocity.y, step, clock)
	var breath := sin(clock * 1.8) * 0.45 if not moving and is_on_floor() else 0.0
	draw_set_transform(Vector2(0, -breath), 0.0, Vector2(face, 1))
	if phone_state != PhoneState.NONE and is_on_floor() and not moving:
		PhoneAppearance.draw_pose(self, phone_frame())
	else:
		JoAppearance.draw_pose(self, frame)
	draw_set_transform(Vector2.ZERO)
	if selected_blend > 0.01:
		var marker_y := -JoAppearance.HEIGHT - 13.0 + sin(clock * 3.0) * 2.0
		draw_colored_polygon(PackedVector2Array([Vector2(-4, marker_y), Vector2(4, marker_y), Vector2(0, marker_y + 5)]), Color(1.0, 0.88, 0.63, selected_blend))

static func _box(color: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	return style

static func portrait(canvas: CanvasItem, center: Vector2, who: int) -> void:
	if who == 0:
		TeAppearance.draw_portrait(canvas, center)
	else:
		JoAppearance.draw_portrait(canvas, center)
