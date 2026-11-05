extends StaticBody2D
const ART = preload("res://data/village/individuality-art.json")
var kind := 0
var painted_height := 90.0
var caption := "Mesa da esplanada"
var lunch := false
var mirrored := false
var visual_shift := Vector2.ZERO
var texture: Texture2D
func setup(world: Node2D,at: Vector2,index: int,height: float) -> void:
	position = at; kind = index; painted_height = height
	if kind in [2,3,7]:
		# Backrests must render behind a person sitting at the same foot anchor.
		position.y -= 24
		visual_shift.y = 24
	material = world.opaque_paint
	collision_layer = 1; collision_mask = 0
	if kind in [0,1]:
		var body := CollisionShape2D.new()
		var shape := RectangleShape2D.new(); shape.size = Vector2(58,28)
		body.shape = shape; body.position.y = -12; add_child(body)
		world.blocked_rects.append(Rect2(at+Vector2(-29,-26),Vector2(58,28)))
	elif kind==4:
		var body := CollisionShape2D.new(); var shape := CircleShape2D.new(); shape.radius = 7
		body.shape = shape; add_child(body); world.circles.append(Vector3(at.x,at.y,7))
	world.actors.add_child(self)
func _draw() -> void:
	if ART.data.props.is_empty(): return
	var pose: Dictionary = ART.data.props[1 if lunch and kind==0 else kind]
	if texture==null: texture = load(pose.path)
	var source := Rect2(pose.rect[0],pose.rect[1],pose.rect[2],pose.rect[3])
	var factor: float = painted_height/source.size.y
	var foot := Vector2(pose.foot[0],pose.foot[1])*factor
	draw_set_transform(visual_shift,0,Vector2(-1 if mirrored else 1,1))
	draw_texture_rect_region(texture,Rect2(-foot,source.size*factor),source)
func available() -> bool: return true
func interaction_prompt() -> String: return caption
func interact(_person: CharacterBody2D) -> String:
	return "As mesas mudam do café e pão para as sopas do almoço. Os moradores chegam a pé e ocupam os seus lugares." if kind==0 else "Um lugar de descanso entre as ruas. Quem está a comer acaba a refeição antes de voltar ao passeio."
