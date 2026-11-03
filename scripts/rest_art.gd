extends RefCounted
const Art = preload("res://scripts/open_world_art.gd")
const Interaction = preload("res://scripts/interaction_art.gd")
const ATLASES := [preload("res://assets/characters/interactions/te-rest-transitions.png"),preload("res://assets/characters/interactions/jo-rest-transitions.png")]
const SIDE_ATLASES := [preload("res://assets/characters/interactions/te-rest-side.png"),preload("res://assets/characters/interactions/jo-rest-side.png")]
const NEW_ATLASES := Interaction.REST_SEQUENCE_ATLASES
const RECLINE_SECONDS := 0.90
const STRETCH_SECONDS := 1.60
const CALL_SECONDS := 1.05
const CELL := Vector2(480,560)
const ANCHOR := Vector2(240,520)
const SIT_SECONDS := 0.64
const LIE_SECONDS := 0.80
const RISE_SECONDS := 0.56
const SIT_UP_SECONDS := 0.48
const ROLL_SECONDS := 0.84

static func draw_side(canvas: CanvasItem, kind: int, row: int, frame: int, sleeping := false) -> void:
	var scale_value: float = Art.HEIGHTS[kind]/438.0
	var atlas: Texture2D = preload("res://scripts/sleep_art.gd").ROLLS[kind] if sleeping else SIDE_ATLASES[kind]
	canvas.draw_texture_rect_region(atlas,Rect2(Vector2(-320,-520)*scale_value,Vector2(640,560)*scale_value),Rect2(clampi(frame,0,3)*640,clampi(row,0,1)*560,640,560))

static func draw_pose(canvas: CanvasItem, kind: int, row: int, frame: int) -> void:
	var scale_value: float = Art.HEIGHTS[kind]/438.0
	canvas.draw_texture_rect_region(ATLASES[kind],Rect2(-ANCHOR*scale_value,CELL*scale_value),Rect2(Vector2(frame*CELL.x,row*CELL.y),CELL))

static func draw_new(canvas: CanvasItem, kind: int, row: int, frame: int) -> void:
	var factor: float = Art.HEIGHTS[kind]/438.0
	canvas.draw_texture_rect_region(NEW_ATLASES[kind],Rect2(-ANCHOR*factor,CELL*factor),Rect2(Vector2(clampi(frame,0,4)*CELL.x,row*CELL.y),CELL))

static func draw_transition(canvas: CanvasItem, person) -> void:
	var clip: String = person.rest_transition
	var progress: float = clampf(person.rest_time/person.rest_duration,0,0.999)
	if clip in ["recline","unrecline","wake_reclined"]:
		var fraction: float = progress if clip=="recline" else person.rest_reverse_from*(1-progress)
		if clip=="wake_reclined": fraction = 1-person.rest_time/RECLINE_SECONDS
		if fraction>=0: draw_new(canvas,person.kind,1,clampi(int(fraction*5),0,4))
		else: draw_pose(canvas,person.kind,0,clampi(int((1-(person.rest_time-RECLINE_SECONDS)/RISE_SECONDS)*4),0,3))
		return
	if clip in ["stretch","call"]:
		var keys: Array = [0,1,2,3,3,2,4,0] if clip=="stretch" else [0,1,2,2,3,4]
		draw_new(canvas,person.kind,2 if clip=="stretch" else 3,keys[mini(int(progress*keys.size()),keys.size()-1)])
		return
	if clip=="sit_up":
		var time: float = person.rest_time
		var roll: float = ROLL_SECONDS*person.rest_side_fraction
		var sit_up: float = SIT_UP_SECONDS*person.rest_reverse_from
		if time<roll:
			draw_side(canvas,person.kind,person.rest_side_row,clampi(int((person.rest_side_fraction-time/ROLL_SECONDS)*4),0,3))
		elif time<roll+sit_up:
			var fraction: float = person.rest_reverse_from-(time-roll)/SIT_UP_SECONDS
			draw_pose(canvas,person.kind,1,clampi(1+int(fraction*3),1,3))
		else:
			draw_new(canvas,person.kind,1,clampi(int((1-(time-roll-sit_up)/RECLINE_SECONDS)*5),0,4))
		return
	if clip=="lie":
		draw_pose(canvas,person.kind,1,clampi(1+int(progress*3),1,3))
		return
	if person.rest_transition=="roll":
		var side: Vector2 = person.current_side_roll()
		draw_side(canvas,person.kind,int(side.x),clampi(int(side.y*4),0,3),person.is_sleeping())
		return
	var elapsed: float = person.rest_time
	if person.rest_transition=="wake_side":
		var roll_seconds: float = ROLL_SECONDS*person.rest_side_fraction
		if elapsed<roll_seconds:
			var amount: float = person.rest_side_fraction-elapsed/ROLL_SECONDS
			draw_side(canvas,person.kind,person.rest_side_row,clampi(int(amount*4),0,3))
			return
		elapsed -= roll_seconds
	var phase := clampf(person.rest_time/person.rest_duration,0,0.999)
	var row := 0
	var fraction: float = phase
	match person.rest_transition:
		"stand": fraction = person.rest_reverse_from*(1-phase)
		"wake", "wake_side":
			var sit_up: float = SIT_UP_SECONDS*person.rest_reverse_from
			if elapsed<sit_up:
				row = 1
				fraction = person.rest_reverse_from*(1-elapsed/maxf(0.01,sit_up))
			else:
				fraction = 1-(elapsed-sit_up)/RISE_SECONDS
		"settle": fraction = lerpf(0.5,0.999,phase)
	var frame := clampi(int(fraction*4),0,3)
	if row==0 and frame==3 and person.kind==0 and (person.rest_target=="sand" or person.rest_from_sand):
		Interaction.draw_sand(canvas,person.sand_time)
	else:
		draw_pose(canvas,person.kind,row,frame)
