extends StaticBody2D
## Authored painted cutouts, sharing the same foot-based depth order as the forest.
const ATLAS: Texture2D = preload("res://assets/world/discoveries/forest-discoveries.png")
const DATA = preload("res://assets/world/discoveries/forest-discoveries.json")
var world: Node2D
var kind := 0
var label := ""
var paint_height := 100.0
var labels: Array[String] = []
var sprite: Node2D
var paint_rect: Rect2
var ball_velocity := Vector2.ZERO
var contact_radius := 0.0
var juggling = preload("res://scripts/football_juggling.gd").new()
var ball_accumulator := 0.0
var ball_paint_scale := Vector2.ONE

func _ready() -> void:
	name = "Discovery_"+str(kind)
	collision_layer = 1 if kind in [0,4,6,7] else 0
	collision_mask = 2
	var bounds: Array = DATA.data.regions[kind]
	var source := Rect2(bounds[0],bounds[1],bounds[2],bounds[3])
	var factor := paint_height/source.size.y
	paint_rect = Rect2(-Vector2(source.size.x*.5,source.size.y)*factor,source.size*factor)
	if kind==3:
		juggling.ball = self
		var ball := Sprite2D.new()
		ball.texture = ATLAS
		ball.region_enabled = true
		ball.region_rect = source
		ball.region_filter_clip_enabled = true
		ball.scale = Vector2.ONE*factor
		ball_paint_scale = ball.scale
		ball.position = Vector2(0,-paint_height*.5)
		sprite = ball
	else:
		var paint := Polygon2D.new()
		paint.texture = ATLAS
		var polygon := PackedVector2Array()
		var uv := PackedVector2Array()
		var pivot := source.position+Vector2(source.size.x*.5,source.size.y)
		for point in DATA.data.polygons[kind]:
			var pixel := Vector2(point[0],point[1])
			uv.append(pixel)
			polygon.append((pixel-pivot)*factor)
		paint.polygon = polygon
		paint.uv = uv
		sprite = paint
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	sprite.material = world.opaque_paint
	add_child(sprite)
	if kind==0:
		var lettering := preload("res://scripts/discovery_sign_labels.gd").new()
		lettering.signpost = self
		add_child(lettering)
	if kind==7:
		footprint(Vector2(-paint_rect.size.x*.39,-5),18)
		footprint(Vector2(paint_rect.size.x*.39,-5),18)
	elif kind in [0,4,6]:
		contact_radius = 15.0 if kind!=4 else 42.0
		footprint(Vector2(0,-5),contact_radius)

func footprint(offset: Vector2, radius: float) -> void:
	var collider := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = radius
	collider.shape = shape
	collider.position = offset
	add_child(collider)
	world.circles.append(Vector3(position.x+offset.x,position.y+offset.y,radius))

func _draw() -> void:
	if kind==3:
		draw_set_transform(Vector2(0,1),0,Vector2(1,.35))
		draw_circle(Vector2.ZERO,12+minf(5,juggling.height*0.02),Color(0.06,0.08,0.04,.20/(1+juggling.height*0.005)))
		draw_set_transform(Vector2.ZERO)
		juggling.draw_counter(self)

func draw_sign_labels(canvas: CanvasItem) -> void:
	if labels.size()!=2: return
	var font := ThemeDB.fallback_font
	for i in 2:
		var y := paint_rect.position.y+paint_rect.size.y*(.27 if i==0 else .49)
		var text_width := font.get_string_size(labels[i],HORIZONTAL_ALIGNMENT_LEFT,-1,14).x
		var at := Vector2((12 if i==0 else -14)-text_width*.5,y)
		canvas.draw_string_outline(font,at,labels[i],HORIZONTAL_ALIGNMENT_LEFT,-1,14,2,Color("bfb48d"))
		canvas.draw_string(font,at,labels[i],HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("352e23"))

func kick(person: Node2D) -> void:
	if juggling.height>10: return
	juggling.stop()
	var direction: Vector2 = person.position.direction_to(position)
	if direction.is_zero_approx(): direction = person.facing
	ball_velocity = direction*275

func step_ball(delta: float) -> void:
	if get_tree().paused: return
	if "people" in world and world.people.any(func(person): return person.in_dialogue): return
	# Fixed steps keep timing windows and gravity stable at different display rates.
	ball_accumulator += minf(delta,0.25)
	while ball_accumulator>=1.0/120.0:
		juggling.step(1.0/120.0)
		ball_accumulator -= 1.0/120.0
	if is_instance_valid(sprite):
		sprite.position = Vector2(0,-paint_height*0.5-juggling.height)
		sprite.rotation += juggling.spin*delta
		var pulse: float = juggling.hit_flash/0.12
		sprite.scale = ball_paint_scale*Vector2(1+pulse*0.10,1-pulse*0.08)
	z_index = 1 if juggling.height>0 else 0
	queue_redraw()

func move_ball(delta: float, friction: float) -> void:
	if ball_velocity.length()<2:
		ball_velocity = Vector2.ZERO
		return
	var remaining := ball_velocity.length()*delta
	var direction := ball_velocity.normalized()
	while remaining>0:
		var distance := minf(6,remaining)
		var candidate := position+direction*distance
		if not world.is_walkable(candidate,17):
			ball_velocity *= -.40
			break
		position = candidate
		remaining -= distance
		sprite.rotation += distance/15
	ball_velocity *= exp(-delta*friction)
