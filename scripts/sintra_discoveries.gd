extends RefCounted
## Authored encounters interrupt the repeating ground between the main landmarks.
const Art = preload("res://scripts/discovery_prop.gd")
const CLEARING: Texture2D = preload("res://assets/world/discoveries/football_clearing.png")
const REST: Texture2D = preload("res://assets/world/discoveries/rest_clearing.png")
const CLEARINGS := [Rect2(10100,2470,1300,1040),Rect2(6220,5510,1280,1050),Rect2(7850,660,1180,980)]
const GROUND: Array[Texture2D] = [CLEARING,REST,REST]
const PLANTS := [Vector2(5530,3700),Vector2(8350,1700),Vector2(11030,5140)]
const SIGNS := [Vector2(5010,2190),Vector2(8240,2300),Vector2(9400,4820),Vector2(5450,6690),Vector2(9230,6840),Vector2(7580,5080)]
const SIGN_LABELS := [["Capuchos","Fonte"],["Adrenunes","Mata Relíquia"],["Pedra Amarela","Capuchos"],["Pedra Amarela","Monge"],["Pedra Amarela","Monge"],["Pedra Amarela","Capuchos"]]
const EXTRAS := [Vector2(8650,4720),Vector2(5430,2850),Vector2(6000,6750),Vector2(8910,3880),Vector2(11530,5900),Vector2(1960,6990)]
const BENCHES := [Vector2(6520,6130),Vector2(7130,5990),Vector2(8120,1260),Vector2(8720,1160),Vector2(11200,3390),Vector2(11350,5530)]

static func landmarks() -> Array[Dictionary]:
	return [
		{"id":"football_clearing","name":"Descampado da bola","position":Vector2(10750,3240),"radius":350.0},
		{"id":"rest_clearing","name":"Clareira dos bancos","position":Vector2(6800,6200),"radius":340.0},
		{"id":"old_stones","name":"Recanto das pedras redondas","position":Vector2(8450,1320),"radius":330.0},
		{"id":"white_bells","name":"Recanto das flores brancas","position":Vector2(5530,3810),"radius":240.0},
		{"id":"forgotten_gate","name":"Portão esquecido","position":Vector2(8910,4000),"radius":220.0}]

static func reserved(at: Vector2, extra := 0.0) -> bool:
	for rect in CLEARINGS:
		if rect.grow(extra).has_point(at) or rect.grow(extra).has_point(at-Vector2(0,510)):
			return true
	for center in PLANTS+SIGNS+EXTRAS+BENCHES:
		if at.distance_to(center)<extra+135 or (at-Vector2(0,420)).distance_to(center)<extra+200:
			return true
	return false

static func build(world: Node2D) -> void:
	for i in CLEARINGS.size():
		var rect: Rect2 = CLEARINGS[i]
		var texture: Texture2D = GROUND[i]
		var ground := Sprite2D.new()
		ground.name = "DistinctClearing_"+str(i)
		ground.texture = texture
		ground.centered = false
		ground.position = rect.position
		ground.scale = rect.size/texture.get_size()
		ground.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		ground.z_index = -41
		var blend := ShaderMaterial.new()
		blend.shader = preload("res://shaders/site_ground.gdshader")
		ground.material = blend
		world.add_child(ground)
		world.terrain_layers.append({"texture":texture,"rect":rect,"biome":0})
		world.Scenery.clearing(world,texture,rect,i>0,i)
	for i in SIGNS.size():
		var sign = add(world,SIGNS[i],0,"Placa de madeira antiga",225)
		sign.labels.assign(SIGN_LABELS[i])
	for i in PLANTS.size():
		var plant = add(world,PLANTS[i],1 if i<2 else 2,"Flores brancas" if i<2 else "Planta de folhas prateadas",180 if i<2 else 110)
		world.discovery_flowers.append(plant.position+Vector2(20,15))
	add(world,Vector2(10720,3150),3,"Bola de futebol esquecida",31)
	add(world,EXTRAS[0],4,"Tronco oco com cogumelos",145)
	add(world,EXTRAS[1],5,"Regador enferrujado",53)
	add(world,EXTRAS[2],6,"Abrigo de insetos",165)
	add(world,EXTRAS[3],7,"Portão antigo",210)
	add(world,EXTRAS[4],2,"Folhas prateadas entre as urzes",115)
	add(world,EXTRAS[5],4,"Tronco coberto de musgo",135)
	for at in BENCHES:
		for attempt in 25:
			var candidate: Vector2 = at if attempt==0 else at+Vector2.from_angle(attempt*2.4)*(45+attempt*8)
			if world.is_walkable(candidate,150) and world.is_walkable(candidate+Vector2(-52,22),20) and world.is_walkable(candidate+Vector2(52,22),20):
				world._add_prop(candidate,5,1.0)
				break
	world.landmarks.append_array(landmarks())

static func add(world: Node2D, at: Vector2, kind: int, label: String, height: float):
	var object = Art.new()
	object.world = world
	object.position = at
	object.kind = kind
	object.label = label
	object.paint_height = height
	world.actors.add_child(object)
	world.scenery_props.append(object)
	return object

static func step(world: Node2D, delta: float) -> void:
	for object in world.scenery_props:
		if object.kind==3: object.step_ball(delta)
