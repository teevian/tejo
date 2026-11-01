extends Node2D
## Existing painted poses, with airborne movement and short contextual mantles.
const Art = preload("res://scripts/open_world_art.gd")
const Te = preload("res://scripts/te_art.gd")
const Jo = preload("res://scripts/jo_art.gd")
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
	face = signf(target.x-position.x) if absf(target.x-position.x)>1 else face
	queue_redraw()

func step(delta: float) -> bool:
	clock += delta
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
	pose = "idle"
	traversal.clear()
	return true

func _draw() -> void:
	if grounded:
		draw_set_transform(view_offset,atan(ground_slope),Vector2(1,0.20))
		draw_circle(Vector2.ZERO,33,Color(0.10,0.17,0.15,0.28))
		if controlled: draw_arc(Vector2.ZERO,39,0,TAU,40,Color("e8d3a2"),3,true)
		draw_set_transform(Vector2.ZERO)
	var offset := view_offset
	if busy():
		# Reuse the original painted scrambling poses, retaining each identity.
		draw_set_transform(offset+Vector2(0,-3),-face*0.12,Vector2(face,1)*0.85)
		var rising := progress<0.58 if traversing() else velocity.y<0 or hanging
		if kind==0: Te.draw_pose(self,10 if rising else 11)
		else: Jo.draw_pose(self,10 if rising else 11)
		draw_set_transform(Vector2.ZERO)
	elif pose=="support":
		draw_set_transform(offset,0,Vector2(face,1)*0.85)
		if kind==0: Te.draw_pose(self,9)
		else: Jo.draw_pose(self,9)
		draw_set_transform(Vector2.ZERO)
	else:
		Art.draw_pose(self,kind,Vector2(face,0),moving,distance,offset)
	# A visible waist harness and the live belay line connect cooperation to bodies.
	var waist := Vector2(0,-67)+offset
	draw_polyline(PackedVector2Array([waist+Vector2(-15,-1),waist+Vector2(0,4),waist+Vector2(15,-1)]),Color("b78c50"),3,true)
	draw_circle(waist+Vector2(0,6),4,Color("ebd8a8"),false,1.5,true)
	if controlled:
		var y := -170+sin(clock*3)*2
		draw_colored_polygon(PackedVector2Array([offset+Vector2(-4,y),offset+Vector2(4,y),offset+Vector2(0,y+6)]),Color("f1dbac"))
