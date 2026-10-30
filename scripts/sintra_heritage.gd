extends RefCounted
## Each location has its own native-resolution painting, dispersed across the world.
const SITE_SIZE := Vector2(1600,1600)
const IDS := ["pedras_irmas","mata_reliquia","adrenunes","convento_capuchos","tholos_monge","pedra_amarela"]
const NAMES := ["Pedras Irmãs","Mata Relíquia dos Capuchos","Gruta de Adrenunes","Convento dos Capuchos","Tholos do Monge","Pedra Amarela"]
const ORIGINS := [Vector2(70,0),Vector2(4880,300),Vector2(9680,150),Vector2(6500,3150),Vector2(3440,5500),Vector2(9740,5500)]
const TEXTURES: Array[Texture2D] = [
	preload("res://assets/world/heritage/pedras_irmas.png"),preload("res://assets/world/heritage/mata_reliquia.png"),
	preload("res://assets/world/heritage/adrenunes.png"),preload("res://assets/world/heritage/convento_capuchos.png"),
	preload("res://assets/world/heritage/tholos_monge.png"),preload("res://assets/world/heritage/pedra_amarela.png")]
const APPROACHES := [Vector2(0.50,0.80),Vector2(0.50,0.78),Vector2(0.50,0.80),Vector2(0.50,0.82),Vector2(0.50,0.80),Vector2(0.50,0.80)]
const TREE_MASKS := {
	"RelicOakNorth":preload("res://assets/world/heritage/relic-oak-north-mask.svg"),
	"RelicOakWest":preload("res://assets/world/heritage/relic-oak-west-mask.svg"),
	"RelicOakEast":preload("res://assets/world/heritage/relic-oak-east-mask.svg")
}

static func site_size(index: int) -> Vector2:
	return Vector2(1400,1400) if index==0 else SITE_SIZE

static func site_rect(index: int) -> Rect2:
	return Rect2(ORIGINS[index],site_size(index))

static func reserved(at: Vector2, extra := 0.0) -> bool:
	for i in IDS.size():
		if site_rect(i).grow(extra).has_point(at) or (extra>=150 and site_rect(i).grow(extra).has_point(at-Vector2(0,500))):
			return true
	return false

static func point(index: int, uv: Vector2) -> Vector2:
	return ORIGINS[index]+uv*site_size(index)

static func landmarks() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for i in IDS.size():
		result.append({"id":IDS[i],"name":NAMES[i],"position":point(i,APPROACHES[i]),"radius":490.0})
	return result

static func build(world: Node2D) -> void:
	for i in IDS.size():
		var ground := Sprite2D.new()
		ground.name = "Site_"+IDS[i]
		ground.texture = TEXTURES[i]
		ground.centered = false
		ground.position = ORIGINS[i]
		ground.scale = site_size(i)/TEXTURES[i].get_size()
		ground.z_index = -42
		ground.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		var material := ShaderMaterial.new()
		material.shader = preload("res://shaders/site_ground.gdshader")
		ground.material = material
		world.add_child(ground)
	# Native texture coordinates and footprints are authored after visual review.
	_build_silhouettes(world)
	for i in IDS.size(): world.Scenery.heritage_details(world,i)

static func part(world: Node2D, index: int, label: String, polygon: Array, contact: Vector2, footprint := Rect2()) -> void:
	var texture: Texture2D = TEXTURES[index]
	var source := PackedVector2Array()
	for uv in polygon:
		source.append(uv)
	var bases: Array[PackedVector2Array] = []
	if BASES.has(label):
		bases.append(world.Scenery.polygon(BASES[label]))
	elif footprint.has_area():
		bases.append(world.Scenery.ellipse([footprint.position.x,footprint.position.y,footprint.size.x,footprint.size.y]))
	var mapping := func(uv: Vector2) -> Vector2: return point(index,uv)
	var category := "tree_canopy" if label.begins_with("RelicOak") else ("solid_rock" if label.begins_with("Sister") or label.begins_with("Adrenunes") and not label.ends_with("Lintel") or label=="YellowGranite" or label=="CapuchosGranite" else "masonry")
	var material: ShaderMaterial
	if TREE_MASKS.has(label):
		material = ShaderMaterial.new()
		material.shader = preload("res://shaders/painted_tree_cutout.gdshader")
		material.set_shader_parameter("tree_mask",TREE_MASKS[label])
	var item = world.Scenery.add(world,texture,label,source,contact,bases,mapping,category,material)
	if TREE_MASKS.has(label): item.configure_cutout_mask(TREE_MASKS[label],site_rect(index))

# Ground footprints follow the actual bases. Doorways and gaps are separate empty spaces.
const BASES := {
	"SisterWest":[.09,.43,.42,.43,.49,.50,.46,.55,.32,.58,.13,.56,.07,.50],
	"SisterEast":[.57,.44,.87,.44,.92,.50,.88,.55,.75,.57,.60,.55,.55,.51],
	"RelicOakNorth":[.50,.29,.58,.28,.64,.34,.66,.37,.59,.39,.51,.37,.48,.34],
	"RelicOakWest":[.22,.49,.29,.49,.34,.55,.36,.60,.30,.63,.23,.60,.19,.56],
	"RelicOakEast":[.69,.61,.77,.60,.83,.68,.84,.72,.78,.76,.70,.73,.65,.69],
	"AdrenunesWest":[.10,.43,.19,.40,.40,.40,.46,.47,.43,.52,.30,.55,.12,.53],
	"AdrenunesEast":[.61,.45,.86,.45,.94,.51,.92,.59,.73,.59,.62,.54],
	"AdrenunesForegroundRock":[.35,.56,.43,.54,.56,.54,.63,.58,.61,.62,.54,.64,.38,.62],
	"CapuchosChapel":[.05,.28,.37,.28,.60,.32,.76,.31,.77,.37,.60,.40,.34,.39,.16,.41,.04,.37],
	"CapuchosGranite":[.28,.45,.37,.41,.49,.43,.58,.47,.54,.53,.36,.54,.28,.50],
	"CapuchosPorchBack":[.70,.425,.88,.455,.88,.50,.70,.48],
	"CapuchosPorchWest":[.668,.485,.705,.49,.705,.525,.67,.525],
	"CapuchosPorchEast":[.88,.515,.92,.515,.92,.565,.88,.565],
	"CapuchosGardenWallWest":[.31,.60,.44,.58,.47,.585,.46,.61,.32,.635],
	"CapuchosGardenWallEast":[.44,.58,.64,.54,.65,.56,.46,.61],
	"MongeBack":[.26,.31,.34,.29,.53,.28,.68,.31,.73,.35,.66,.38,.47,.35,.32,.40],
	"MongeWest":[.26,.43,.32,.41,.38,.47,.39,.51,.33,.54,.27,.51],
	"MongeEast":[.68,.43,.76,.42,.79,.46,.77,.51,.71,.55,.64,.51],
	"MongeFrontWest":[.29,.54,.35,.52,.44,.54,.48,.59,.48,.64,.44,.65,.41,.60,.31,.60],
	"MongeFrontEast":[.58,.55,.64,.52,.73,.54,.70,.61,.64,.65,.58,.65],
	"YellowGranite":[.09,.47,.28,.43,.63,.43,.85,.46,.92,.52,.84,.58,.62,.61,.40,.60,.20,.55]
}

static func _build_silhouettes(w: Node2D) -> void:
	part(w,0,"SisterWest",[Vector2(.05,.43),Vector2(.09,.25),Vector2(.23,.13),Vector2(.37,.07),Vector2(.46,.12),Vector2(.49,.37),Vector2(.48,.54),Vector2(.34,.57),Vector2(.16,.56)],Vector2(.30,.55),Rect2(.11,.52,.35,.035))
	part(w,0,"SisterEast",[Vector2(.55,.37),Vector2(.57,.24),Vector2(.69,.18),Vector2(.83,.21),Vector2(.91,.33),Vector2(.93,.47),Vector2(.84,.56),Vector2(.63,.55)],Vector2(.75,.55),Rect2(.58,.52,.29,.04))
	part(w,1,"RelicOakNorth",[Vector2(.30,.0),Vector2(.68,.0),Vector2(.81,.12),Vector2(.66,.21),Vector2(.72,.34),Vector2(.66,.39),Vector2(.57,.40),Vector2(.47,.34),Vector2(.44,.16)],Vector2(.56,.37))
	part(w,1,"RelicOakWest",[Vector2(.0,.24),Vector2(.15,.18),Vector2(.29,.26),Vector2(.34,.44),Vector2(.43,.53),Vector2(.47,.66),Vector2(.33,.63),Vector2(.17,.60),Vector2(.11,.41)],Vector2(.27,.60))
	part(w,1,"RelicOakEast",[Vector2(.66,.38),Vector2(.78,.30),Vector2(.91,.27),Vector2(1,.30),Vector2(.95,.45),Vector2(.84,.55),Vector2(.86,.70),Vector2(.92,.78),Vector2(.78,.76),Vector2(.58,.72),Vector2(.66,.54)],Vector2(.74,.73))
	part(w,2,"AdrenunesWest",[Vector2(.08,.48),Vector2(.11,.31),Vector2(.23,.23),Vector2(.34,.14),Vector2(.44,.15),Vector2(.43,.26),Vector2(.48,.31),Vector2(.46,.43),Vector2(.39,.47),Vector2(.24,.53)],Vector2(.30,.51),Rect2(.12,.48,.34,.035))
	part(w,2,"AdrenunesLintel",[Vector2(.42,.22),Vector2(.46,.21),Vector2(.59,.26),Vector2(.60,.30),Vector2(.49,.28),Vector2(.43,.26)],Vector2(.52,.49))
	part(w,2,"AdrenunesEast",[Vector2(.58,.38),Vector2(.59,.18),Vector2(.66,.12),Vector2(.77,.08),Vector2(.88,.18),Vector2(.91,.36),Vector2(.95,.52),Vector2(.91,.60),Vector2(.72,.58),Vector2(.62,.50)],Vector2(.76,.57),Rect2(.61,.52,.30,.045))
	part(w,2,"AdrenunesForegroundRock",[Vector2(.33,.54),Vector2(.40,.49),Vector2(.52,.48),Vector2(.64,.52),Vector2(.62,.60),Vector2(.56,.63),Vector2(.38,.62)],Vector2(.49,.62),Rect2(.35,.59,.25,.035))
	part(w,3,"CapuchosChapel",[Vector2(.03,.34),Vector2(.04,.23),Vector2(.20,.15),Vector2(.32,.13),Vector2(.32,.08),Vector2(.36,.07),Vector2(.38,.14),Vector2(.49,.14),Vector2(.61,.18),Vector2(.63,.24),Vector2(.77,.27),Vector2(.78,.36),Vector2(.59,.40),Vector2(.37,.38),Vector2(.17,.41)],Vector2(.47,.38),Rect2(.08,.36,.68,.035))
	part(w,3,"CapuchosGranite",[Vector2(.25,.42),Vector2(.28,.35),Vector2(.38,.33),Vector2(.46,.37),Vector2(.54,.39),Vector2(.58,.46),Vector2(.53,.53),Vector2(.33,.52)],Vector2(.43,.52),Rect2(.28,.49,.26,.035))
	part(w,3,"CapuchosPorchRoof",[Vector2(.63,.39),Vector2(.77,.30),Vector2(.96,.34),Vector2(.95,.44),Vector2(.88,.46),Vector2(.66,.41)],Vector2(.80,.54))
	part(w,3,"CapuchosPorchBack",[Vector2(.70,.415),Vector2(.88,.45),Vector2(.88,.50),Vector2(.70,.48)],Vector2(.80,.48))
	part(w,3,"CapuchosPorchWest",[Vector2(.67,.41),Vector2(.70,.42),Vector2(.70,.51),Vector2(.67,.52)],Vector2(.69,.52),Rect2(.67,.50,.03,.025))
	part(w,3,"CapuchosPorchEast",[Vector2(.88,.46),Vector2(.92,.44),Vector2(.92,.55),Vector2(.88,.56)],Vector2(.90,.55),Rect2(.88,.53,.04,.025))
	part(w,3,"CapuchosCross",[Vector2(.24,.49),Vector2(.245,.48),Vector2(.255,.48),Vector2(.258,.49),Vector2(.267,.49),Vector2(.267,.50),Vector2(.257,.505),Vector2(.257,.55),Vector2(.268,.555),Vector2(.267,.58),Vector2(.24,.58),Vector2(.24,.555),Vector2(.247,.55),Vector2(.247,.505),Vector2(.24,.505)],Vector2(.255,.575),Rect2(.24,.56,.03,.025))
	part(w,3,"CapuchosGardenWallWest",[Vector2(.31,.56),Vector2(.43,.55),Vector2(.47,.57),Vector2(.46,.60),Vector2(.32,.625)],Vector2(.39,.61),Rect2(.32,.60,.14,.025))
	part(w,3,"CapuchosGardenWallEast",[Vector2(.43,.55),Vector2(.64,.52),Vector2(.65,.545),Vector2(.46,.60)],Vector2(.55,.575))
	part(w,4,"MongeBack",[Vector2(.25,.35),Vector2(.36,.26),Vector2(.51,.24),Vector2(.65,.27),Vector2(.73,.33),Vector2(.67,.37),Vector2(.47,.33),Vector2(.31,.40)],Vector2(.49,.36),Rect2(.30,.335,.36,.025))
	part(w,4,"MongeWest",[Vector2(.24,.39),Vector2(.29,.33),Vector2(.35,.37),Vector2(.40,.49),Vector2(.36,.53),Vector2(.28,.51)],Vector2(.31,.50),Rect2(.26,.46,.10,.035))
	part(w,4,"MongeEast",[Vector2(.65,.32),Vector2(.76,.31),Vector2(.80,.39),Vector2(.77,.49),Vector2(.71,.54),Vector2(.63,.50),Vector2(.67,.43)],Vector2(.72,.52),Rect2(.68,.47,.09,.045))
	part(w,4,"MongeFrontWest",[Vector2(.29,.52),Vector2(.36,.49),Vector2(.45,.51),Vector2(.48,.59),Vector2(.49,.63),Vector2(.44,.64),Vector2(.43,.58),Vector2(.32,.58)],Vector2(.40,.60),Rect2(.32,.56,.12,.03))
	part(w,4,"MongeFrontEast",[Vector2(.57,.53),Vector2(.64,.50),Vector2(.73,.53),Vector2(.68,.61),Vector2(.63,.65),Vector2(.57,.64)],Vector2(.63,.64),Rect2(.58,.60,.08,.035))
	part(w,4,"MongeEntranceLintel",[Vector2(.45,.505),Vector2(.54,.505),Vector2(.58,.525),Vector2(.58,.548),Vector2(.47,.54)],Vector2(.53,.64))
	part(w,5,"YellowGranite",[Vector2(.08,.47),Vector2(.20,.29),Vector2(.33,.13),Vector2(.39,.06),Vector2(.49,.05),Vector2(.58,.11),Vector2(.67,.23),Vector2(.79,.30),Vector2(.90,.43),Vector2(.92,.51),Vector2(.83,.58),Vector2(.64,.60),Vector2(.41,.60),Vector2(.23,.55)],Vector2(.52,.59),Rect2(.19,.55,.67,.045))
