extends RefCounted
const ATLAS: Texture2D = preload("res://assets/characters/football/jo-football.png")
const Walk = preload("res://scripts/open_world_art.gd")
const DATA = preload("res://assets/characters/football/animations.json")
const TE_ATLAS: Texture2D = preload("res://assets/characters/football/te-football.png")
const TE_DATA = preload("res://assets/characters/football/te-animations.json")
const CELL := Vector2(576,560)
const ANCHOR := Vector2(288,520)
const ROWS := {"lift":0,"foot":1,"knee":2,"head":3}

static func contact(action: String, variant: int, facing := 1.0, kind := 1) -> Vector2:
	var xy: Array = TE_DATA.data.contacts[clampi(variant,0,1)] if kind==0 else DATA.data.contacts[action][clampi(variant,0,2)]
	var point := (Vector2(xy[0],xy[1])-ANCHOR)*Walk.HEIGHTS[kind]/438.0
	point.x *= facing
	return point

static func lift_contact(facing := 1.0, kind := 1) -> Vector2:
	var xy: Array = TE_DATA.data.contacts[0] if kind==0 else DATA.data.lift
	var point := (Vector2(xy[0],xy[1])-ANCHOR)*Walk.HEIGHTS[kind]/438.0
	point.x *= facing
	return point

static func draw_key(canvas: CanvasItem, action: String, key: int, facing := 1.0, kind := 1) -> void:
	var scale_value: float = Walk.HEIGHTS[kind]/438.0
	canvas.draw_set_transform(Vector2.ZERO,0,Vector2(facing,1))
	if kind==0:
		var column: int = [0,1,1,0][clampi(key,0,3)] if action=="lift" else (key+1 if key<2 else 0)
		canvas.draw_texture_rect_region(TE_ATLAS,Rect2(-ANCHOR*scale_value,CELL*scale_value),Rect2(column*CELL.x,0,CELL.x,CELL.y))
	else:
		canvas.draw_texture_rect_region(ATLAS,Rect2(-ANCHOR*scale_value,CELL*scale_value),Rect2(clampi(key,0,3)*CELL.x,int(ROWS[action])*CELL.y,CELL.x,CELL.y))
	canvas.draw_set_transform(Vector2.ZERO)

static func draw_person(canvas: CanvasItem, person) -> void:
	var key := 3
	if person.football_action=="lift": key = clampi(int(person.football_time/person.football_duration*4),0,3)
	elif person.football_time>=0.06 and person.football_time<0.23: key = person.football_variant
	draw_key(canvas,person.football_action,key,person.football_facing,person.kind)
