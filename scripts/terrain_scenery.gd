extends RefCounted
## Authored 2.5D scenery: silhouette = height; base = occupied ground.
## Coordinates are normalized to the original painting, with no resampled art.
const Painted = preload("res://scripts/painted_occluder.gd")

static func polygon(values: Array) -> PackedVector2Array:
	var result := PackedVector2Array()
	for i in range(0,values.size(),2): result.append(Vector2(values[i],values[i+1]))
	return result

static func ellipse(box: Array) -> PackedVector2Array:
	var result := PackedVector2Array()
	for i in 16:
		result.append(Vector2(box[0]+box[2]*.5,box[1]+box[3]*.5)+Vector2.from_angle(i*TAU/16)*Vector2(box[2],box[3])*.5)
	return result

static func add(world: Node2D, texture: Texture2D, label: String, outline: PackedVector2Array, contact: Vector2, bases: Array[PackedVector2Array], mapping: Callable, category := "solid_rock", material: Material = null):
	var points := PackedVector2Array()
	var uv := PackedVector2Array()
	for point in outline:
		points.append(mapping.call(point))
		uv.append(point*texture.get_size())
	var footprints: Array[PackedVector2Array] = []
	for base in bases:
		var mapped := PackedVector2Array()
		for point in base: mapped.append(mapping.call(point))
		footprints.append(mapped)
	var item := Painted.new()
	item.name = label
	item.configure_mapped(texture,uv,points,mapping.call(contact))
	item.surface.material = material
	world.register_scenery(item,category,footprints)
	if category=="masonry": world.masonry.append(item)
	if category=="solid_rock" and not footprints.is_empty():
		var bounds := Rect2(footprints[0][0],Vector2.ZERO)
		for point in footprints[0]: bounds = bounds.expand(point)
		world.boulders.append({"position":bounds.get_center(),"radius":minf(bounds.size.x,bounds.size.y)*.5,"node":item})
	return item

static func covered(world: Node2D, bounds: Rect2) -> bool:
	for i in world.Heritage.IDS.size():
		if world.Heritage.site_rect(i).grow(35).intersects(bounds): return true
	for rect in world.Discoveries.CLEARINGS:
		if rect.grow(35).intersects(bounds): return true
	for rect in world.Expansion.SPRINGS:
		if rect.grow(35).intersects(bounds): return true
	return false

static func batch(world: Node2D, texture: Texture2D, entries: Array, mapping: Callable, prefix: String, exclude_overlays := false, material: Material = null, clip := Rect2()) -> void:
	for entry in entries:
		var outline := polygon(entry[1])
		var base := ellipse(entry[2])
		var box: Array = entry[2]
		var contact := Vector2(box[0]+box[2]*.5,box[1]+box[3]*.72)
		var bounds := Rect2(mapping.call(outline[0]),Vector2.ZERO)
		for point in outline: bounds = bounds.expand(mapping.call(point))
		if exclude_overlays and covered(world,bounds): continue
		# Partial edge repeats never produce invisible colliders outside the tile.
		if clip.has_area() and not clip.encloses(bounds): continue
		add(world,texture,prefix+entry[0],outline,contact,[base],mapping,"solid_rock",material)

static func build_original(world: Node2D) -> void:
	for index in 4:
		var origin := Vector2(index%2,floori(index/2.0))*Vector2(2400,1800)
		var mapping := func(uv: Vector2) -> Vector2:
			if index==3:
				# Invert the same bend used by the river ground shader.
				var x := uv.x
				for iteration in 8:
					x = uv.x+.055*(1-smoothstep(0,.28,uv.y))*smoothstep(0,.12,x)*(1-smoothstep(.60,.90,x))
				uv.x = x
			return origin+uv*Vector2(2400,1800)
		var shade := world.terrain_materials[index].duplicate() as ShaderMaterial
		shade.set_shader_parameter("scenery_surface",true)
		var first: int = world.scenery_objects.size()
		batch(world,world.TERRAIN[index],ORIGINAL[index],mapping,"Terrain%d_"%index,true,shade)
		if index==3:
			# Sample the curved ground in screen coordinates, using its exact shader.
			# Warping only silhouette vertices would misalign pixels inside triangles.
			for i in range(first,world.scenery_objects.size()):
				var item: Node2D = world.scenery_objects[i]
				var uv := PackedVector2Array()
				for point in item.surface.polygon:
					uv.append((item.position+point-origin)/Vector2(2400,1800)*world.TERRAIN[index].get_size())
				item.surface.uv = uv
	var southern := ShaderMaterial.new()
	southern.shader = preload("res://shaders/southern_ground.gdshader")
	var mapping := func(uv: Vector2) -> Vector2: return Vector2(0,3540)+uv*Vector2(4800,1860)
	batch(world,world.SOUTH,SOUTH,mapping,"Southern_",true,southern)

static func expansion_floor(world: Node2D, texture: Texture2D, rect: Rect2, mirror_x: bool, mirror_y: bool) -> void:
	if texture!=world.Expansion.FLOOR[1]: return # Other floors contain ground cover and small pebbles.
	for repeat_x in 2:
		for repeat_y in 2:
			var mapping := func(uv: Vector2) -> Vector2:
				if mirror_x: uv.x = 1-uv.x
				if mirror_y: uv.y = 1-uv.y
				return rect.position-Vector2(44,44)+(uv+Vector2(repeat_x,repeat_y))*world.Expansion.TILE
			batch(world,texture,HEATH,mapping,"Heath_%d_%d_"%[int(rect.position.x),int(rect.position.y)],true,null,rect.grow(30))

static func clearing(world: Node2D, texture: Texture2D, rect: Rect2, resting: bool, index: int) -> void:
	var mapping := func(uv: Vector2) -> Vector2: return rect.position+uv*rect.size
	batch(world,texture,REST if resting else MEADOW,mapping,"Clearing%d_"%index)

static func heritage_details(world: Node2D, index: int) -> void:
	var mapping := func(uv: Vector2) -> Vector2: return world.Heritage.point(index,uv)
	batch(world,world.Heritage.TEXTURES[index],SITE_DETAILS[index],mapping,"Site%d_"%index)

# Each base occupies the lower volume of its rock, rather than its entire screen silhouette.
const ORIGINAL := [
	[
		["NorthGranite",[.79,.015,.82,0,.88,.015,.92,.07,.91,.11,.85,.13,.80,.09],[.80,.07,.11,.055]],
		["PathWest",[.13,.33,.15,.27,.20,.25,.23,.30,.24,.35,.21,.37,.16,.36],[.14,.31,.095,.055]],
		["PathCenter",[.34,.30,.37,.23,.42,.25,.46,.30,.46,.34,.42,.36,.36,.35],[.35,.31,.11,.045]],
		["FlowerGranite",[.47,.16,.51,.14,.57,.17,.59,.21,.58,.24,.52,.25,.47,.22],[.475,.20,.11,.055]],
		["EastStone",[.69,.25,.71,.21,.75,.21,.78,.25,.78,.29,.75,.30,.70,.29],[.70,.26,.075,.04]],
		["MiddleGranite",[.36,.42,.39,.36,.44,.33,.48,.36,.51,.43,.51,.47,.47,.49,.40,.48],[.37,.43,.14,.065]],
		["WestGranite",[.03,.56,.04,.50,.075,.46,.11,.48,.14,.55,.14,.60,.11,.62,.05,.61],[.035,.56,.10,.065]],
		["Southwest",[.08,.74,.12,.69,.18,.67,.21,.70,.21,.74,.17,.76,.12,.76],[.09,.72,.12,.045]],
		["LowerSmall",[.20,.62,.22,.58,.24,.57,.26,.61,.26,.64,.23,.65],[.205,.62,.055,.03]],
		["LowTrail",[.32,.61,.34,.59,.37,.60,.375,.63,.35,.64,.33,.64],[.325,.615,.05,.027]],
		["SouthCenter",[.37,.72,.40,.68,.45,.68,.48,.72,.47,.75,.43,.76,.38,.75],[.38,.725,.10,.035]],
		["EastGranite",[.69,.60,.73,.55,.81,.55,.85,.59,.85,.62,.81,.65,.75,.65,.70,.63],[.70,.605,.14,.045]],
		["SouthEdge",[.39,.94,.41,.89,.45,.88,.48,.92,.48,.96,.45,.98,.41,.97],[.40,.94,.08,.035]],
		["EastEdge",[.91,.73,.94,.68,.98,.68,1,.73,1,.78,.96,.79,.92,.77],[.92,.75,.08,.035]]
	],
	[
		["Lookout",[.72,.17,.76,.11,.83,.08,.91,.10,.98,.17,1,.24,.99,.36,.93,.39,.83,.35,.77,.29],[.77,.29,.22,.09]],
		["NorthBank",[.01,.11,.04,.09,.09,.11,.12,.16,.16,.16,.19,.20,.25,.22,.27,.29,.24,.32,.14,.28,.07,.23],[.05,.215,.20,.07]],
		["BankMiddle",[.44,.30,.49,.24,.53,.23,.58,.26,.60,.30,.59,.34,.53,.35,.47,.34],[.455,.30,.14,.05]],
		["BridgeEast",[.37,.39,.41,.34,.45,.33,.49,.36,.52,.40,.52,.44,.48,.46,.40,.44],[.38,.40,.14,.055]],
		["RuinsWest",[.38,.67,.41,.62,.45,.60,.49,.61,.51,.66,.50,.71,.47,.75,.41,.75,.38,.71],[.39,.70,.11,.055]],
		["LowerBank",[.36,.83,.39,.78,.43,.77,.46,.79,.48,.83,.47,.86,.42,.89,.38,.88],[.37,.84,.10,.045]],
		["SouthwestBank",[.10,.85,.13,.80,.16,.79,.20,.82,.24,.87,.25,.91,.21,.93,.15,.92],[.12,.88,.12,.045]]
	],
	[
		["UpperWest",[.005,.04,.02,0,.09,0,.14,.04,.14,.10,.09,.13,.02,.11],[.01,.08,.13,.045]],
		["UpperPair",[.075,.20,.10,.13,.17,.09,.22,.10,.26,.15,.29,.23,.28,.29,.23,.32,.14,.29,.09,.26],[.10,.24,.18,.075]],
		["PathPebble",[.31,.26,.33,.235,.35,.24,.38,.27,.38,.30,.34,.31],[.31,.28,.07,.035]],
		["TopCenter",[.38,.16,.41,.12,.46,.12,.49,.15,.50,.18,.47,.20,.41,.20],[.39,.17,.11,.04]],
		["Northeast",[.62,.27,.66,.23,.70,.24,.73,.28,.72,.32,.68,.34,.63,.32],[.63,.29,.10,.045]],
		["FernStone",[.32,.43,.34,.36,.36,.35,.38,.37,.40,.44,.38,.47,.34,.47],[.33,.43,.07,.04]],
		["WestOutcrop",[.06,.70,.08,.63,.12,.59,.15,.59,.21,.63,.22,.69,.19,.73,.12,.75,.07,.73],[.07,.695,.15,.055]],
		["WestRear",[.10,.59,.14,.54,.17,.525,.22,.55,.25,.60,.24,.64,.19,.65],[.13,.61,.11,.04]],
		["CenterSmall",[.36,.56,.38,.53,.41,.525,.44,.55,.43,.58,.39,.59],[.365,.56,.075,.035]],
		["EastOutcrop",[.72,.53,.75,.47,.79,.46,.83,.49,.87,.55,.89,.59,.87,.63,.80,.64,.74,.60],[.74,.58,.14,.06]],
		["EastRear",[.71,.47,.73,.42,.76,.405,.79,.43,.80,.47,.78,.50,.74,.50],[.72,.47,.08,.04]],
		["EasternLow",[.55,.59,.58,.54,.62,.525,.66,.55,.69,.59,.68,.62,.62,.64,.57,.63],[.56,.60,.12,.045]],
		["LowerCenter",[.36,.92,.38,.86,.42,.82,.47,.82,.51,.87,.55,.95,.55,1,.40,1],[.38,.94,.17,.055]],
		["LowerRear",[.23,.91,.26,.84,.30,.81,.35,.82,.38,.88,.36,.92,.30,.94],[.24,.90,.13,.04]],
		["LowerEast",[.70,.87,.72,.82,.77,.79,.81,.80,.87,.86,.88,.91,.83,.94,.76,.93],[.71,.89,.16,.05]]
	],
	[
		["BridgeNorth",[.32,.18,.35,.11,.39,.08,.43,.09,.46,.14,.47,.20,.44,.24,.38,.24,.33,.22],[.33,.20,.13,.055]],
		["BridgeSouth",[.33,.49,.37,.42,.43,.38,.48,.40,.51,.45,.51,.50,.47,.53,.38,.53],[.35,.48,.16,.055]],
		["MiddleBank",[.28,.61,.31,.54,.35,.50,.40,.51,.43,.56,.43,.61,.40,.65,.34,.66,.29,.64],[.29,.61,.14,.055]],
		["LowerBank",[.28,.79,.31,.73,.35,.69,.39,.70,.42,.75,.43,.81,.40,.85,.33,.85,.29,.83],[.29,.80,.14,.055]],
		["SouthBank",[.39,.96,.42,.91,.46,.89,.51,.91,.55,.96,.56,1,.39,1],[.40,.96,.15,.04]]
	]
]
const SOUTH := [
	["Northwest",[.12,.19,.13,.13,.16,.10,.19,.12,.21,.20,.21,.27,.18,.30,.13,.27],[.125,.24,.085,.06]],
	["WestGranite",[.025,.37,.03,.29,.055,.265,.08,.29,.10,.36,.10,.42,.07,.45,.035,.43],[.03,.39,.07,.06]],
	["CentralGranite",[.30,.59,.32,.52,.36,.48,.40,.50,.43,.56,.45,.66,.45,.72,.41,.74,.35,.71,.31,.67],[.31,.66,.14,.08]],
	["WestLow",[0,.85,.015,.77,.04,.72,.07,.72,.09,.78,.095,.87,.075,.93,.025,.94],[.005,.87,.09,.065]],
	["LowerPair",[.13,.79,.15,.72,.18,.70,.21,.73,.22,.80,.21,.86,.17,.88,.14,.85],[.135,.82,.085,.06]],
	["EastBank",[.67,.77,.68,.70,.71,.66,.74,.66,.77,.71,.78,.79,.76,.85,.71,.86,.68,.82],[.68,.80,.10,.06]],
	["StepsGranite",[.70,.29,.71,.23,.74,.22,.77,.26,.78,.33,.76,.38,.72,.38],[.71,.34,.07,.05]],
	["StairEast",[.86,.64,.87,.57,.91,.53,.94,.54,.98,.59,1,.66,.99,.71,.93,.73,.88,.70],[.87,.68,.12,.05]]
]
const HEATH := [
	["Upper",[.37,.14,.40,.12,.44,.12,.46,.15,.45,.18,.41,.19,.38,.18],[.38,.16,.075,.035]],
	["Middle",[.41,.25,.42,.23,.45,.225,.48,.25,.48,.28,.45,.29,.42,.28],[.415,.265,.065,.03]],
	["West",[.03,.43,.045,.40,.065,.40,.085,.43,.085,.45,.06,.47,.035,.46],[.03,.445,.055,.025]],
	["WestMiddle",[.15,.45,.17,.415,.19,.41,.21,.44,.20,.46,.17,.47],[.155,.45,.05,.025]],
	["Center",[.54,.38,.55,.36,.58,.36,.60,.385,.59,.40,.56,.41],[.54,.39,.055,.025]],
	["LowerWest",[.22,.55,.25,.52,.29,.52,.31,.55,.30,.58,.26,.59,.23,.57],[.225,.56,.08,.03]],
	["EastPair",[.855,.48,.875,.455,.91,.455,.94,.48,.945,.52,.92,.55,.88,.54,.86,.52],[.86,.52,.08,.035]],
	["LowerEast",[.74,.62,.76,.60,.78,.61,.795,.64,.78,.66,.75,.65],[.745,.64,.05,.025]],
	["Southwest",[.045,.79,.065,.76,.095,.75,.12,.78,.125,.81,.10,.83,.065,.82],[.05,.80,.075,.035]],
	["SouthPair",[.23,.83,.25,.80,.29,.80,.33,.83,.345,.865,.32,.89,.27,.885,.24,.86],[.235,.855,.11,.035]]
]
const REST := [
	["Northwest",[.055,.14,.07,.10,.12,.075,.17,.085,.20,.12,.195,.17,.15,.185,.09,.18],[.065,.15,.13,.04]],
	["West",[.09,.30,.11,.265,.15,.25,.18,.265,.20,.30,.19,.33,.14,.34,.105,.32],[.10,.31,.095,.035]],
	["Southwest",[.035,.61,.05,.57,.09,.55,.135,.57,.15,.62,.13,.65,.08,.66,.04,.64],[.04,.63,.105,.035]],
	["Southeast",[.76,.62,.78,.59,.83,.59,.86,.63,.86,.66,.82,.68,.77,.66],[.77,.65,.09,.03]],
	["East",[.83,.50,.85,.46,.89,.44,.93,.46,.95,.50,.94,.54,.89,.55,.85,.53],[.84,.52,.105,.035]],
	["RingBack",[.50,.17,.55,.15,.60,.145,.61,.17,.59,.20,.53,.21,.50,.19],[.51,.19,.09,.025]],
	["RingEast",[.65,.17,.68,.145,.72,.16,.75,.185,.74,.21,.69,.22,.66,.20],[.66,.20,.08,.025]],
	["RingRight",[.79,.265,.81,.24,.85,.25,.88,.28,.87,.305,.83,.315,.80,.295],[.80,.295,.07,.025]],
	["RingLowerRight",[.80,.35,.82,.33,.85,.335,.87,.37,.865,.395,.83,.405,.80,.39],[.80,.385,.065,.025]],
	["RingFrontRight",[.72,.435,.75,.41,.79,.405,.82,.43,.80,.455,.75,.47,.72,.46],[.725,.45,.08,.025]],
	["RingFront",[.55,.435,.58,.405,.61,.40,.64,.43,.64,.455,.61,.475,.57,.47],[.555,.455,.08,.025]],
	["RingLeft",[.455,.34,.47,.315,.495,.32,.51,.35,.50,.37,.475,.37],[.46,.355,.045,.02]]
]
const MEADOW := [
	["Northwest",[.035,.12,.05,.07,.10,.04,.13,.05,.16,.09,.17,.14,.15,.17,.09,.18,.05,.16],[.04,.145,.13,.04]],
	["West",[.015,.43,.03,.39,.065,.37,.10,.39,.115,.43,.10,.46,.06,.48,.02,.46],[.02,.45,.09,.035]],
	["Southwest",[.015,.66,.035,.63,.075,.62,.11,.65,.13,.69,.11,.72,.06,.735,.02,.71],[.02,.70,.105,.035]],
	["Southeast",[.77,.80,.80,.75,.84,.74,.88,.76,.905,.81,.90,.85,.86,.87,.81,.85],[.78,.835,.12,.035]],
	["East",[.87,.57,.89,.53,.92,.53,.95,.56,.96,.60,.94,.62,.90,.62,.875,.60],[.875,.60,.08,.035]]
]
const SITE_DETAILS := [
	[
		["Southwest",[.05,.74,.07,.69,.12,.66,.18,.66,.22,.71,.23,.76,.20,.79,.13,.80,.07,.78],[.06,.755,.17,.045]],
		["SouthCenter",[.32,.81,.34,.78,.37,.77,.40,.79,.42,.83,.41,.86,.38,.875,.34,.85],[.33,.84,.085,.035]],
		["EastEdge",[.80,.81,.83,.78,.87,.78,.90,.82,.91,.86,.88,.88,.83,.86],[.805,.85,.10,.035]]
	],
	[
		["Northwest",[.15,.07,.18,.045,.23,.04,.26,.065,.28,.10,.27,.12,.22,.13,.17,.12],[.16,.105,.115,.03]],
		["BetweenRoots",[.42,.485,.44,.455,.47,.445,.50,.47,.53,.50,.52,.52,.47,.53,.43,.515],[.425,.505,.10,.03]],
		["WestEdge",[.01,.77,.025,.735,.06,.715,.10,.73,.12,.77,.115,.80,.08,.81,.035,.80],[.015,.785,.10,.035]],
		["Southwest",[.015,.88,.035,.85,.08,.835,.13,.85,.15,.90,.14,.93,.09,.94,.035,.925],[.02,.915,.125,.03]],
		["Southern",[.33,.89,.35,.86,.39,.86,.425,.89,.435,.92,.405,.94,.36,.93],[.335,.915,.10,.03]]
	],
	[
		["CaveFrontEast",[.55,.61,.58,.58,.61,.56,.65,.57,.69,.61,.71,.65,.69,.68,.64,.68,.58,.66],[.56,.645,.145,.035]],
		["CaveLowerEast",[.60,.70,.63,.675,.68,.66,.73,.69,.74,.72,.70,.75,.65,.75,.61,.73],[.605,.73,.13,.035]],
		["WestEdge",[0,.73,.02,.70,.06,.68,.10,.69,.12,.72,.13,.76,.10,.79,.03,.78,0,.76],[.005,.755,.12,.04]],
		["Southwest",[.005,.86,.015,.83,.05,.81,.08,.83,.09,.87,.08,.90,.04,.91,.01,.89],[.005,.88,.085,.035]]
	],
	[
		["ForecourtWest",[.035,.585,.055,.55,.08,.545,.11,.57,.13,.60,.12,.63,.08,.64,.045,.62],[.04,.61,.085,.035]],
		["Well",[.155,.58,.195,.565,.235,.58,.24,.64,.21,.65,.17,.635],[.16,.615,.08,.035]],
		["Basin",[.23,.585,.29,.575,.32,.60,.32,.63,.28,.65,.235,.64],[.235,.625,.085,.025]],
		["Southwest",[.14,.86,.17,.83,.21,.825,.235,.85,.24,.89,.21,.92,.17,.905],[.145,.885,.095,.035]],
		["SouthwestFront",[.21,.91,.23,.87,.27,.86,.30,.89,.31,.94,.28,.97,.24,.95],[.215,.935,.09,.035]],
		["Southeast",[.81,.91,.84,.875,.89,.86,.94,.88,.97,.93,.96,.97,.91,.99,.85,.96],[.82,.95,.14,.04]]
	],
	[
		["Marker",[.62,.18,.65,.12,.67,.11,.675,.055,.69,.05,.71,.06,.715,.115,.74,.13,.76,.20,.73,.23,.66,.225],[.63,.20,.125,.035]],
		["MarkerBase",[.58,.22,.61,.18,.65,.17,.68,.19,.70,.23,.69,.26,.64,.275,.59,.25],[.585,.245,.11,.035]],
		["WestRing",[.125,.42,.15,.37,.18,.355,.21,.38,.23,.43,.22,.46,.17,.48,.13,.46],[.13,.445,.095,.035]],
		["EastRing",[.76,.44,.79,.42,.85,.41,.90,.43,.93,.47,.91,.50,.84,.51,.78,.49],[.77,.48,.155,.035]],
		["LowerEast",[.64,.59,.68,.565,.73,.56,.78,.59,.81,.63,.80,.66,.73,.68,.66,.65],[.65,.645,.15,.035]],
		["Southwest",[.015,.81,.04,.76,.08,.74,.12,.76,.15,.81,.15,.85,.10,.88,.04,.85],[.02,.835,.13,.04]]
	],
	[
		["Northwest",[.035,.19,.06,.15,.10,.13,.14,.15,.175,.19,.19,.23,.17,.25,.12,.26,.06,.24],[.04,.225,.145,.04]],
		["Southwest",[0,.85,.03,.82,.07,.81,.10,.83,.13,.88,.11,.91,.06,.93,.01,.90],[.005,.895,.12,.035]],
		["Southern",[.21,.93,.24,.89,.28,.875,.32,.89,.35,.93,.35,.97,.31,.99,.25,.97],[.215,.955,.13,.04]],
		["Southeast",[.72,.88,.75,.855,.79,.855,.83,.88,.85,.92,.83,.95,.78,.97,.73,.93],[.725,.925,.12,.04]]
	]
]
