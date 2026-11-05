extends StaticBody2D
const ART = preload("res://data/village/nightlife-art.json")
var director: Node2D
var index := 0
var painted_height := 100.0
var texture: Texture2D
func setup(owner_node: Node2D,slot: int,at: Vector2,height: float) -> void:
	director = owner_node; index = slot; position = at; painted_height = height
	material = director.sprite_paint; collision_layer = 1; collision_mask = 0
	var size := Vector2(172,42) if index==0 else (Vector2(54,30) if index==1 else Vector2(24,22))
	var body := CollisionShape2D.new(); var shape := RectangleShape2D.new(); shape.size = size
	body.shape = shape; body.position.y = -12; add_child(body)
	director.world.blocked_rects.append(Rect2(at-Vector2(size.x*.5,12+size.y*.5),size))
	director.world.actors.add_child(self)
func _draw() -> void:
	# Equipment stays visible while closed; its baked footprint must never become an invisible obstacle.
	var pose: Dictionary = ART.data.props[index]
	if texture==null: texture = load(pose.path)
	var source := Rect2(pose.rect[0],pose.rect[1],pose.rect[2],pose.rect[3])
	var factor: float = painted_height/source.size.y
	var foot := Vector2(pose.foot[0],pose.foot[1])*factor
	draw_texture_rect_region(texture,Rect2(-foot,source.size*factor),source)
func available() -> bool: return visible
func interaction_prompt() -> String: return "Entrar na conversa · Lord Byron" if director.opened else "Ver o horário do Lord Byron"
func interact(person: CharacterBody2D) -> String: return director.interact(person)
