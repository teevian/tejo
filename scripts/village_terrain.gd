extends Node2D
## Continuous limestone walks surround a connected, directionally laid granite lane.
const WOODLAND = preload("res://assets/world/expansion/deep_woodland.png")
const EARTH = preload("res://assets/world/expansion/woodland.png")
const STONE = preload("res://assets/world/village/pavement.png")
const CALCADA = preload("res://assets/world/village/calcada-diamonds.png")
const PAVING = preload("res://shaders/village_paving.gdshader")
var world: Node2D
var streets: Array[Dictionary] = []
var courts: Array[Rect2] = []
var pavement: ShaderMaterial
var carriageway: ShaderMaterial
var court_paving: ShaderMaterial

static func paving_material(face: Color, joint: Color, size: Vector2) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = PAVING
	material.set_shader_parameter("stone_color",face)
	material.set_shader_parameter("joint_color",joint)
	material.set_shader_parameter("block_size",size)
	return material

func _quad(rect: Rect2) -> PackedVector2Array:
	return PackedVector2Array([rect.position,rect.position+Vector2(rect.size.x,0),rect.end,rect.position+Vector2(0,rect.size.y)])

func _ready() -> void:
	z_index = -50
	pavement = paving_material(Color("c8c3b0"),Color("928f7f"),Vector2(12,11))
	carriageway = paving_material(Color("888a82"),Color("5d615a"),Vector2(20,16))
	court_paving = paving_material(Color("a8a99c"),Color("777c70"),Vector2(17,15))
	_texture(_quad(Rect2(Vector2.ZERO,world.WORLD_SIZE)),WOODLAND,1,Color("b2bba1"))
	# The pale walks continue to the plinths. Visible backcourts stay traversable.
	for data in world.LAYOUT.data.urban_zones:
		_paved(_quad(world._rect(data)),pavement)
	for data in world.LAYOUT.data.garden_zones:
		_texture(_quad(world._rect(data)),WOODLAND,1,Color("b2bba1"))
	for plaza in world.plazas:
		if plaza.get("surface","stone")=="earth":
			_texture(_quad(plaza.rect),EARTH,1,Color("e3d9ba"))
		else:
			_paved(_quad(plaza.rect),pavement)
			courts.append(plaza.rect.grow(-minf(62,plaza.rect.size.y*.14)))
	for route in world.routes:
		var outlines := Geometry2D.offset_polyline(route.points,route.width*.5,Geometry2D.JOIN_ROUND,Geometry2D.END_ROUND)
		for polygon in outlines:
			if route.surface=="earth": _texture(polygon,EARTH,1,Color("e3d9ba"))
			else: _paved(polygon,pavement)
		if route.surface=="earth": continue
		var half_width: float = route.width*.31
		var course := rounded_course(route.points,minf(48,route.width*.16))
		streets.append({"id":route.id,"points":course,"half_width":half_width,"polygons":Geometry2D.offset_polyline(course,half_width,Geometry2D.JOIN_ROUND,Geometry2D.END_ROUND)})
	# Every kerb precedes every lane and court. Junction paving covers internal
	# kerbs, leaving only the outside edge of the connected street network.
	for street in streets:
		for polygon in street.polygons: _kerb(polygon)
	for court in courts: _kerb(_quad(court))
	for street in streets: _lane(street.points,street.half_width)
	for court in courts: _paved(_quad(court),court_paving)
	# Decorative diamonds now belong to two framed panels, not the entire town.
	_inlay(Rect2(9320,3195,540,180))
	_inlay(Rect2(9496,2150,800,230))

func _kerb(points: PackedVector2Array) -> void:
	for polygon in Geometry2D.offset_polygon(points,8,Geometry2D.JOIN_ROUND):
		_flat(polygon,Color("72766d"))
	for polygon in Geometry2D.offset_polygon(points,5,Geometry2D.JOIN_ROUND):
		_paved(polygon,pavement)

static func rounded_course(points: PackedVector2Array, radius: float) -> PackedVector2Array:
	var result := PackedVector2Array([points[0]])
	for i in range(1,points.size()-1):
		var corner := points[i]
		var before := corner.move_toward(points[i-1],minf(radius,corner.distance_to(points[i-1])*.2))
		var after := corner.move_toward(points[i+1],minf(radius,corner.distance_to(points[i+1])*.2))
		result.append(before)
		for step in range(1,9):
			var t := step/8.0
			result.append(before.lerp(corner,t).lerp(corner.lerp(after,t),t))
	result.append(points[-1])
	return result

func _lane(course: PackedVector2Array, half_width: float) -> void:
	var points := PackedVector2Array()
	# Stations keep the local stone courses aligned through every bend.
	for i in range(course.size()-1):
		var count := maxi(1,ceili(course[i].distance_to(course[i+1])/56))
		for step in count: points.append(course[i].lerp(course[i+1],float(step)/count))
	points.append(course[-1])
	var vertices := PackedVector2Array()
	var uv := PackedVector2Array()
	var quads: Array[PackedInt32Array] = []
	var distance := 0.0
	for i in points.size():
		if i>0: distance += points[i-1].distance_to(points[i])
		var incoming := (points[i]-points[maxi(0,i-1)]).normalized()
		var outgoing := (points[mini(points.size()-1,i+1)]-points[i]).normalized()
		if i==0: incoming = outgoing
		if i==points.size()-1: outgoing = incoming
		var tangent := (incoming+outgoing).normalized()
		var normal := tangent.orthogonal()
		var extent := half_width/maxf(.8,normal.dot(incoming.orthogonal()))
		vertices.append(points[i]-normal*extent)
		vertices.append(points[i]+normal*extent)
		uv.append(Vector2(0,distance))
		uv.append(Vector2(half_width*2,distance))
		if i>0: quads.append(PackedInt32Array([(i-1)*2,(i-1)*2+1,i*2+1,i*2]))
	var ribbon := _paved(vertices,carriageway,uv)
	ribbon.polygons = quads
	_cap(points[0],(points[1]-points[0]).normalized(),half_width,0,true)
	_cap(points[-1],(points[-1]-points[-2]).normalized(),half_width,distance,false)

func _cap(at: Vector2, tangent: Vector2, radius: float, distance: float, start: bool) -> void:
	var vertices := PackedVector2Array([at])
	var uv := PackedVector2Array([Vector2(radius,distance)])
	var normal := tangent.orthogonal()
	for step in range(17):
		var angle := PI*step/16
		var local := normal*cos(angle)*radius+tangent*sin(angle)*radius*(-1 if start else 1)
		vertices.append(at+local)
		uv.append(Vector2(radius+local.dot(normal),distance+local.dot(tangent)))
	_paved(vertices,carriageway,uv)

func _inlay(rect: Rect2) -> void:
	_flat(_quad(rect.grow(9)),Color("777d70"))
	_paved(_quad(rect.grow(6)),pavement)
	_texture(_quad(rect),CALCADA,4.3,Color("dddaca"))

func _flat(points: PackedVector2Array, color: Color) -> Polygon2D:
	var node := Polygon2D.new()
	node.polygon = points
	node.color = color
	add_child(node)
	return node

func _paved(points: PackedVector2Array, material: ShaderMaterial, uv := PackedVector2Array()) -> Polygon2D:
	var node := _texture(points,STONE,1,Color.WHITE)
	if not uv.is_empty(): node.uv = uv
	node.material = material
	return node

func _texture(points: PackedVector2Array, texture: Texture2D, scale_uv: float, color: Color) -> Polygon2D:
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
	return node
