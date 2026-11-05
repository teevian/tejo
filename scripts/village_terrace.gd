extends Node2D
## One short, bounded flight joins a lower landing to a raised stone court.
const STONE = preload("res://assets/world/village/pavement.png")
const STAIR_STONE = preload("res://assets/world/village/stone-stairs.png")
const Terrain = preload("res://scripts/village_terrain.gd")
var world: Node2D
var spec: Dictionary
var platform := Rect2()
var flight := Rect2()
var walls: Array[Rect2] = []

func _ready() -> void:
	z_index = -40
	platform = world._rect(spec.platform)
	flight = Rect2(platform.get_center().x-spec.stair_width*.5,platform.end.y,spec.stair_width,spec.run)
	var lip := 14.0
	walls = [Rect2(platform.position,Vector2(platform.size.x,lip)),Rect2(platform.position,Vector2(lip,platform.size.y)),Rect2(platform.end.x-lip,platform.position.y,lip,platform.size.y)]
	for side in [-1,1]:
		var x: float = platform.position.x if side<0 else flight.end.x
		var width: float = flight.position.x-platform.position.x
		walls.append(Rect2(x,platform.end.y,width,spec.rise))
		walls.append(Rect2(flight.position.x-lip if side<0 else flight.end.x,flight.position.y,lip,flight.size.y))
	for rect in walls:
		world.blocked_rects.append(rect)
		var body := StaticBody2D.new()
		body.name = "TerraceWall_"+spec.id
		var shape := CollisionShape2D.new()
		var bounds := RectangleShape2D.new()
		bounds.size = rect.size
		shape.shape = bounds
		shape.position = rect.get_center()
		body.add_child(shape)
		add_child(body)
	_surface(platform.grow(-lip),STONE,Color.WHITE,1)
	_surface(Rect2(flight.position+Vector2(0,flight.size.y),Vector2(flight.size.x,spec.landing)),STONE,Color.WHITE,1)

func _surface(rect: Rect2, texture: Texture2D, tint: Color, uv_scale: float) -> void:
	var node := Polygon2D.new()
	node.polygon = PackedVector2Array([rect.position,Vector2(rect.end.x,rect.position.y),rect.end,Vector2(rect.position.x,rect.end.y)])
	var uv := PackedVector2Array()
	for point in node.polygon: uv.append(point*uv_scale)
	node.uv = uv
	node.texture = texture
	node.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	node.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	node.color = tint
	node.material = Terrain.paving_material(Color("c8c3b0"),Color("928f7f"),Vector2(12,11))
	add_child(node)

func _draw() -> void:
	for rect in walls:
		draw_rect(rect,Color("777b74"))
		for row in range(0,int(rect.size.y),18):
			for col in range(0,int(rect.size.x),38):
				var block := Rect2(rect.position+Vector2(col+1,row+1),Vector2(minf(35,rect.size.x-col-1),minf(15,rect.size.y-row-1)))
				if block.size.x>0 and block.size.y>0: draw_rect(block,Color("a7a79a") if (row/18+col/38)%2 else Color("b8b5a5"))
		draw_line(rect.position,rect.position+Vector2(rect.size.x,0),Color("ded9c6"),4,true)
	# One finite granite flight, with native tread noses and shaded risers. No
	# repeated UVs and no stretching a strip along an entire winding street.
	draw_texture_rect_region(STAIR_STONE,flight,Rect2(0,0,STAIR_STONE.get_width(),STAIR_STONE.get_height()*9.0/11.0))
