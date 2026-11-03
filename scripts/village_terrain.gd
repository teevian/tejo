extends Node2D
## Urban stone belongs beneath the blocks; woodland is confined to the outskirts.
const WOODLAND = preload("res://assets/world/expansion/deep_woodland.png")
const EARTH = preload("res://assets/world/expansion/woodland.png")
const STAIRS = preload("res://assets/world/village/stone-stairs.png")
const STONE = preload("res://assets/world/village/pavement.png")
const CALCADA = preload("res://assets/world/village/calcada-diamonds.png")
var world: Node2D
var step_sections: Array[Dictionary] = []
var paved_sections: Array[PackedVector2Array] = []
func _quad(rect: Rect2) -> PackedVector2Array:
	return PackedVector2Array([rect.position,rect.position+Vector2(rect.size.x,0),rect.end,rect.position+Vector2(0,rect.size.y)])
func _ready() -> void:
	z_index = -50
	_texture(_quad(Rect2(Vector2.ZERO,world.WORLD_SIZE)),WOODLAND,1,Color("b2bba1"))
	# The private ground between attached houses is mineral courtyard ground.
	# This removes the old strips of forest under every shop facade.
	for data in world.LAYOUT.data.urban_zones:
		_texture(_quad(world._rect(data)),STONE,4.0,Color("b8b2a2"))
	for data in world.LAYOUT.data.garden_zones:
		_texture(_quad(world._rect(data)),WOODLAND,1,Color("b2bba1"))
	for plaza in world.plazas:
		if plaza.get("surface","stone")=="earth": _texture(_quad(plaza.rect),EARTH,1,Color("e3d9ba"))
		else: paved_sections.append(_quad(plaza.rect))
	for route in world.routes:
		for polygon in Geometry2D.offset_polyline(route.points,route.width*.5,Geometry2D.JOIN_ROUND,Geometry2D.END_ROUND):
			if route.surface=="earth": _texture(polygon,EARTH,1,Color("e3d9ba"))
			else: paved_sections.append(polygon)
		if route.surface=="steps": step_sections.append(route)
	# All borders precede all paving. Intersections and squares have no internal seams.
	for points in paved_sections:
		for edge in Geometry2D.offset_polygon(points,14,Geometry2D.JOIN_ROUND):
			_texture(edge,STONE,4.0,Color("d8d3bd"))
	for points in paved_sections: _texture(points,CALCADA,2.8,Color("e7e1d2"))
	_build_stairs()

func _texture(points: PackedVector2Array, texture: Texture2D, scale_uv: float, color: Color) -> void:
	var node := Polygon2D.new()
	node.polygon = points
	var uv := PackedVector2Array()
	for point in points: uv.append(point*scale_uv)
	node.uv = uv
	node.texture = texture
	node.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	node.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	node.color = color
	add_child(node)

func _build_stairs() -> void:
	for route in step_sections:
		for i in range(route.points.size()-1):
			var a: Vector2 = route.points[i]
			var b: Vector2 = route.points[i+1]
			var half: Vector2 = a.direction_to(b).orthogonal()*route.width*.5
			var stair := Polygon2D.new()
			stair.name = "StoneFlight_"+str(get_child_count())
			stair.polygon = PackedVector2Array([a-half,a+half,b+half,b-half])
			var length := a.distance_to(b)/25.0*(STAIRS.get_height()/12.0)
			stair.uv = PackedVector2Array([Vector2.ZERO,Vector2(STAIRS.get_width()*.45,0),Vector2(STAIRS.get_width()*.45,length),Vector2(0,length)])
			stair.texture = STAIRS
			stair.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
			stair.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
			add_child(stair)
