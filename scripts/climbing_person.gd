extends Node2D
## Physics feet stay independent of registered action sprites and paired grips.
const Art = preload("res://scripts/open_world_art.gd")
const Actions = preload("res://scripts/climbing_art.gd")
var kind := 0
var shelf := 0
var controlled := false
var face := 1.0
var moving := false
var distance := 0.0
var clock := 0.0
var blocked_dir := 0
var anchor := ""
var pose := "idle"
var traversal: Dictionary = {}
var progress := 0.0
var duration := 1.0
var start := Vector2.ZERO
var destination := Vector2.ZERO
var arrival_shelf := 0
var grounded := true
var velocity := Vector2.ZERO
var jump_buffer := 0.0
var coyote := 0.0
var ignore_shelf := -1
var ignore_time := 0.0
var hanging := false
var last_shelf := 0
var ground_slope := 0.0
var view_offset := Vector2.ZERO
var choreography_offset := Vector2.ZERO
var assist_action := ""
var assist_progress := -1.0
var air_time := 0.0
var landing_time := 0.0
var landing_soft := false
var hang_time := 0.0
var gesture := ""
var gesture_time := 0.0
var gesture_duration := 1.0

func busy() -> bool:
	return not traversal.is_empty() or not grounded

func traversing() -> bool:
	return not traversal.is_empty()

func travel(target: Vector2, target_shelf: int, action: String, seconds := 1.05) -> void:
	start = position
	destination = target
	arrival_shelf = target_shelf
	pose = action
	progress = 0
	duration = seconds
	traversal = {"action":action}
	grounded = false
	coyote = 0
	hanging = false
	velocity = Vector2.ZERO
	blocked_dir = 0
	moving = false
	landing_time = 0
	gesture_time = 0
	face = signf(target.x-position.x) if absf(target.x-position.x)>1 else face
	queue_redraw()

func step(delta: float) -> bool:
	clock += delta
	air_time = air_time+delta if not grounded else 0
	hang_time = hang_time+delta if hanging else 0
	landing_time = maxf(0,landing_time-delta)
	gesture_time = maxf(0,gesture_time-delta)
	if not traversing():
		queue_redraw()
		return false
	progress = minf(1.0,progress+delta/duration)
	# Hands reach the face first; feet then mantle onto the top. No flying arc.
	var t := smoothstep(0.0,1.0,progress)
	var x_t := smoothstep(0.20,1.0,progress)
	if pose=="descend": x_t = smoothstep(0.0,0.65,progress)
	position = Vector2(lerpf(start.x,destination.x,x_t),lerpf(start.y,destination.y,t))
	if pose=="chimney": position.x += sin(progress*PI*6)*5
	queue_redraw()
	if progress<1.0: return false
	position = destination
	shelf = arrival_shelf
	last_shelf = shelf
	grounded = true
	landing_time = 0.18
	landing_soft = true
	pose = "idle"
	traversal.clear()
	return true

func play_gesture(action: String, seconds: float) -> void:
	gesture = action
	gesture_time = seconds
	gesture_duration = seconds

func animation_state() -> Dictionary:
	var action := ""
	var phase := -1.0
	if traversing():
		action = {"climb":"mantle","descend":"mantle","tunnel":"crawl","pull":"pulled"}.get(pose,pose)
		if action in ["rope","chimney","crawl"]:
			# A final mantle settles onto the destination instead of snapping upright.
			if action=="rope" and progress>0.80:
				action = "mantle"
				phase = lerpf(0.50,0.99,(progress-0.80)/0.20)
		else:
			phase = 1-progress if pose=="descend" else progress
	elif hanging:
		action = "fall" if hang_time<0.12 else "rope"
		phase = 0.99 if hang_time<0.12 else 0.26
	elif not grounded:
		action = "jump" if velocity.y<0 else "fall"
		phase = minf(0.99,air_time/0.30) if action=="jump" else clampf(velocity.y/950,0,0.74)
	elif not assist_action.is_empty():
		action = assist_action
		phase = assist_progress
	elif anchor in ["rope","belay"]:
		action = "belay"
	elif anchor=="balance":
		action = "push"
		phase = 0.60
	elif gesture_time>0:
		action = gesture
		phase = -1 if action=="push" else 1-gesture_time/gesture_duration
	elif landing_time>0 and not moving:
		action = "land"
		phase = lerpf(0.50,0.99,1-landing_time/0.18) if landing_soft else 1-landing_time/0.24
	if not Actions.ACTIONS.has(action): return {"action":"idle","frame":0}
	return {"action":action,"frame":Actions.frame_for(action,phase,clock)}

func contact_point(point: String) -> Vector2:
	var state := animation_state()
	return Actions.contact(kind,state.action,state.frame,point,face)+view_offset+choreography_offset

func rope_grip() -> Vector2:
	var state := animation_state()
	return contact_point("hand" if state.action in ["rope","belay","haul"] else "hip")

func _draw() -> void:
	if grounded:
		draw_set_transform(view_offset,atan(ground_slope),Vector2(1,0.20))
		draw_circle(Vector2.ZERO,33,Color(0.10,0.17,0.15,0.28))
		if controlled: draw_arc(Vector2.ZERO,39,0,TAU,40,Color("e8d3a2"),3,true)
		draw_set_transform(Vector2.ZERO)
	var offset := view_offset+choreography_offset
	var state := animation_state()
	if state.action=="rope":
		# Rope is below the painted fingers and passes through both authored grips.
		draw_line(contact_point("hand"),contact_point("other_hand"),Color("d8b97b"),2,true)
	if state.action!="idle":
		Actions.draw_action(self,kind,state.action,state.frame,offset,face)
	else:
		Art.draw_pose(self,kind,Vector2(face,0),moving,distance,offset)
	# A visible waist harness and the live belay line connect cooperation to bodies.
	var waist := contact_point("hip")
	draw_polyline(PackedVector2Array([waist+Vector2(-15,-1),waist+Vector2(0,4),waist+Vector2(15,-1)]),Color("b78c50"),3,true)
	draw_circle(waist+Vector2(0,6),4,Color("ebd8a8"),false,1.5,true)
	if controlled:
		var y := -170+sin(clock*3)*2
		draw_colored_polygon(PackedVector2Array([offset+Vector2(-4,y),offset+Vector2(4,y),offset+Vector2(0,y+6)]),Color("f1dbac"))
