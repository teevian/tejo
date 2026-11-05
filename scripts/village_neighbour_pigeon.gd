extends Node2D
## A single recognisable courier; letter arrival requires the painted bird's real flight.
const ART = preload("res://data/village/neighbourhood-art.json")
var director: Node2D
var busy := false
var returning := false
var from := Vector2.ZERO
var to := Vector2.ZERO
var flight := 0.0
var clock := 0.0
var delivered := false
var texture: Texture2D
func _ready() -> void:
	material = director.sprite_paint
	reset()
func reset() -> void:
	busy = false; delivered = false
	position = director.by_id.ernesto_pombos.position+Vector2(40,0)
func deliver(start: Vector2,finish: Vector2,receipt: bool) -> void:
	from = start; to = finish; returning = receipt; flight = 0; busy = true; delivered = false
	position = start
func step(delta: float) -> void:
	clock += delta
	visible = not director.episodes.ready_cast("pigeon",2).is_empty()
	if not visible and busy: busy = false
	if busy:
		flight += delta
		var duration: float = maxf(3,from.distance_to(to)/110)
		var t: float = clampf(flight/duration,0,1)
		position = from.lerp(to,t)-Vector2(0,sin(t*PI)*48)
		if t>=1:
			busy = false; delivered = true
			director.episodes.pigeon_arrived(returning)
	queue_redraw()
func _draw() -> void:
	if ART.data.pigeon.is_empty(): return
	var i: int = (4 if returning else 2)+int(clock*7)%2 if busy else (6 if delivered else int(clock/2)%2)
	var pose: Dictionary = ART.data.pigeon[i]
	if texture==null: texture = load(pose.path)
	var r := Rect2(pose.rect[0],pose.rect[1],pose.rect[2],pose.rect[3])
	var factor: float = (31 if busy else 25)/r.size.y
	draw_set_transform(Vector2.ZERO,0,Vector2(-1 if to.x<from.x else 1,1))
	draw_texture_rect_region(texture,Rect2(Vector2(-r.size.x*.5,-r.size.y)*factor,r.size*factor),r)
