extends RefCounted
## Ball height is independent of its ground position; contact is tested in 3D.
const Art = preload("res://scripts/football_art.gd")
const GRAVITY := 430.0
const RELEASE_TIME := 0.28
const TOUCH_DELAY := 0.065
const COOLDOWN := 0.25
var ball: Node2D
var owner: CharacterBody2D
var height := 0.0
var vertical_speed := 0.0
var lifting := false
var lift_time := 0.0
var lift_from := Vector2.ZERO
var cooldown := 0.0
var pending := {}
var count := 0
var best := 0
var last_count := 0
var attempts := 0
var hit_flash := 0.0
var spin := 0.0
var last_contact := ""
var last_quality := 0.0
var variants := {"foot":[0,0,0],"knee":[0,0,0],"head":[0,0,0]}
var rng := RandomNumberGenerator.new()
var last_direction := Vector2.ZERO

func _init() -> void:
	rng.randomize()

func _te_drift(min_speed: float, max_speed: float) -> Vector2:
	var direction := Vector2.from_angle(rng.randf_range(0,TAU))
	# Every flick changes direction by at least sixty degrees, including new rounds.
	for attempt in 12:
		if last_direction.is_zero_approx() or direction.dot(last_direction)<=0.5: break
		direction = Vector2.from_angle(rng.randf_range(0,TAU))
	if not last_direction.is_zero_approx() and direction.dot(last_direction)>0.5:
		direction = last_direction.rotated(PI*0.5)
	last_direction = direction
	return direction*rng.randf_range(min_speed,max_speed)

func _te_shot() -> void:
	var direction := Vector2.ZERO
	for attempt in 12:
		direction = Vector2(-1 if rng.randf()<0.5 else 1,rng.randf_range(-0.4,0.4)).normalized()
		if direction.dot(last_direction)<=0.5: break
	if direction.dot(last_direction)>0.5:
		direction = Vector2(-1 if last_direction.x>=0 else 1,rng.randf_range(-0.4,0.4)).normalized()
	last_direction = direction
	# A fast low sideways shot, rather than another high juggling arc.
	ball.ball_velocity = direction*rng.randf_range(680,840)
	vertical_speed = rng.randf_range(125,175)

func active() -> bool:
	return is_instance_valid(owner)

func start(person: CharacterBody2D) -> bool:
	if person.is_busy() or height>10 or person.position.distance_to(ball.position)>68 or not ball.world.can_walk_line(person.position,ball.position): return false
	stop()
	owner = person
	owner.football_ball = ball
	owner.play_football("lift",0,0.56,1.0 if ball.position.x>=person.position.x else -1.0)
	lift_from = ball.position
	lifting = true
	lift_time = 0
	height = 0
	vertical_speed = 0
	ball.ball_velocity = Vector2.ZERO
	count = 0
	attempts = 0
	cooldown = 0
	pending.clear()
	return true

func stop() -> void:
	if active() and owner.football_ball==ball: owner.football_ball = null
	last_count = count
	best = maxi(best,count)
	owner = null
	lifting = false
	pending.clear()
	cooldown = 0

func candidate(delay := 0.0) -> Dictionary:
	if not active(): return {}
	var ball_ground: Vector2 = ball.position+ball.ball_velocity*delay
	var actor_ground: Vector2 = owner.position+owner.velocity*delay
	var altitude := maxf(0,height+vertical_speed*delay-GRAVITY*delay*delay*0.5)
	var best_score := INF
	var result := {}
	for action in (["foot"] if owner.kind==0 else ["foot","knee","head"]):
		for variant in (2 if owner.kind==0 else 3):
			for sign_value in [1.0,-1.0]:
				var contact: Vector2 = Art.contact(action,variant,sign_value,owner.kind)
				var ground_error := ball_ground-actor_ground-Vector2(contact.x,0)
				var error := Vector3(ground_error.x,ground_error.y*1.5,altitude+contact.y).length()
				var score: float = error+float(variants[action][variant]%3)*0.8
				if score<best_score:
					best_score = score
					result = {"action":action,"variant":variant,"facing":sign_value,"error":error,"point":contact}
	return result

func request_touch() -> bool:
	if not active() or lifting or cooldown>0 or not pending.is_empty(): return false
	var contact := candidate(TOUCH_DELAY)
	if contact.is_empty(): return false
	attempts += 1
	cooldown = COOLDOWN
	pending = contact
	pending.delay = TOUCH_DELAY
	owner.play_football(str(contact.action),int(contact.variant),0.34,float(contact.facing))
	return true

func _touch() -> void:
	if not active() or pending.is_empty():
		pending.clear()
		return
	var action: String = pending.action
	var point: Vector2 = Art.contact(action,int(pending.variant),float(pending.facing),owner.kind)
	var offset: Vector2 = ball.position-owner.position-Vector2(point.x,0)
	var error := Vector3(offset.x,offset.y*1.5,height+point.y).length()
	var window: float = ball.paint_height*0.5+(10.0 if action=="head" else 8.0)
	if error<=window and vertical_speed<150 and height>1:
		last_quality = clampf(1-error/window,0,1)
		var apex := minf(315,maxf(height+75,205+last_quality*65+(-point.y)*0.18))
		vertical_speed = sqrt(2*GRAVITY*(apex-height))
		var input := Input.get_vector("walk_left","walk_right","walk_up","walk_down")
		var drift := offset*1.7+input*38+owner.velocity*0.10
		# Contact direction and off-centre errors are visible and recoverable with the arrows.
		drift.x += float([8,-10,13][count%3])*(1-last_quality*0.5)
		ball.ball_velocity = drift.limit_length(115)
		var te: bool = owner.kind==0
		if te:
			if count==0: ball.ball_velocity = _te_drift(22,42)
			else: _te_shot()
		count += 1
		best = maxi(best,count)
		variants[action][int(pending.variant)] += 1
		last_contact = action
		hit_flash = 0.12
		spin = clampf(ball.ball_velocity.x*0.04+float(pending.facing)*2,-7,7)
		if te and count>=2: stop()
	pending.clear()

func step(delta: float) -> void:
	if active() and (not owner.controlled or owner.jumping or owner.puppy_recoil_time>0): stop()
	cooldown = maxf(0,cooldown-delta)
	hit_flash = maxf(0,hit_flash-delta)
	if lifting and active():
		lift_time += delta
		var point: Vector2 = Art.lift_contact(owner.football_facing,owner.kind)
		var fraction := clampf(lift_time/RELEASE_TIME,0,1)
		ball.position = lift_from.lerp(owner.position+Vector2(point.x,0),smoothstep(0,1,fraction))
		height = maxf(0,-point.y)*smoothstep(0.45,1,fraction)
		if lift_time>=RELEASE_TIME:
			lifting = false
			vertical_speed = sqrt(2*GRAVITY*maxf(40,190-height))
			ball.ball_velocity = Vector2(owner.football_facing*10,0)
			if owner.kind==0: ball.ball_velocity = _te_drift(15,28)
			spin = owner.football_facing*2
		return
	if height>0 or vertical_speed>0:
		height += vertical_speed*delta-GRAVITY*delta*delta*0.5
		vertical_speed -= GRAVITY*delta
		ball.move_ball(delta,0.14)
		if height<=0:
			height = 0
			if active(): stop()
			vertical_speed = -vertical_speed*0.28 if vertical_speed < -85 else 0.0
	else:
		ball.move_ball(delta,1.45)
		spin *= exp(-delta*4)
	if not pending.is_empty():
		pending.delay -= delta
		if float(pending.delay)<=0: _touch()
	if active() and owner.position.distance_to(ball.position)>300: stop()

func draw_counter(canvas: CanvasItem) -> void:
	if not active() or count==0: return
	var at: Vector2 = owner.position-ball.position+Vector2(-8,-180)
	canvas.draw_string_outline(ThemeDB.fallback_font,at,str(count),HORIZONTAL_ALIGNMENT_LEFT,-1,18,3,Color("344034"))
	canvas.draw_string(ThemeDB.fallback_font,at,str(count),HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("f1e5c7"))
