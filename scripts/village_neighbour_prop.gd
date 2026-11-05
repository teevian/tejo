extends StaticBody2D
## Native painted objects; only the foosball ball and queue chalk are code-native game marks.
const ART = preload("res://data/village/neighbourhood-art.json")
static var textures: Dictionary = {}
var director: Node2D
var kind := ""
var index := 0
var painted_height := 100.0
var active := true
var born := 0.0
var drift := Vector2.ZERO
var collected := false
var number := 0
func setup(d: Node2D,k: String,at: Vector2,slot: int,height: float) -> void:
	director = d; kind = k; position = at; index = slot; painted_height = height
	if k=="picnic": z_index = -2
	material = d.sprite_paint
	collision_layer = 1; collision_mask = 0
	if k in ["foosball","raffle"]:
		var body := CollisionShape2D.new(); var shape := RectangleShape2D.new()
		shape.size = Vector2(116,45) if k=="foosball" else Vector2(95,32)
		body.shape = shape; body.position.y = -18; add_child(body)
		d.world.blocked_rects.append(Rect2(at-Vector2(shape.size.x*.5,18+shape.size.y*.5),shape.size))
	d.world.actors.add_child(self)
func _draw() -> void:
	if ART.data.props.is_empty() or not active or collected: return
	var pose: Dictionary = ART.data.props[index]
	if not textures.has(pose.path): textures[pose.path] = load(pose.path)
	var source := Rect2(pose.rect[0],pose.rect[1],pose.rect[2],pose.rect[3])
	var scale_factor: float = painted_height/source.size.y
	var foot := Vector2(pose.foot[0],pose.foot[1])*scale_factor
	draw_texture_rect_region(textures[pose.path],Rect2(-foot,source.size*scale_factor),source)
	if kind=="foosball":
		var at: Vector2 = director.episodes.table_ball
		draw_circle(Vector2(at.x*42,-painted_height*.6+at.y*13),3,Color("efe5cc"))
func available() -> bool: return visible and active and not collected
func interaction_position() -> Vector2: return position+Vector2(0,35) if kind in ["foosball","raffle"] else position
func interaction_prompt() -> String:
	return {"picnic":"Conversar com o grupo do piquenique","thermos":"Tentar abrir o termo do Nelson","foosball":"Jogar matraquilhos com o Tóni e a Dora","raffle":"Comprar uma rifa para a atividade de Minecraft","papers":"Ver os testes da professora","paper":"Apanhar o teste levado pelo vento","pigeon":"Ver o correio dos pombos"}.get(kind,"Observar a vida da rua")
func interact(person: CharacterBody2D) -> String:
	if kind=="paper": return director.episodes.collect_paper(self,person)
	director.dialogues.open_scene(kind,person)
	return ""
