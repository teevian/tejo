extends Node2D
## Authored native glass and street lamps respond to the same shared solar clock.
const GLASS = preload("res://data/village/window-glass.json")
const WINDOW_SHADER = preload("res://shaders/village_window_light.gdshader")
const PROPS = preload("res://scripts/village_activity_prop.gd")
var world: Node2D
var lamps: Array[Dictionary] = []
var windows: Array[Dictionary] = []
var glow_texture: GradientTexture2D
var lamp_strength := 0.0
var lit_windows := 0
var last_update := -INF
var emission_layer: CanvasLayer

func _ready() -> void:
	name = "VillageNightLights"
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([Color(1,.72,.32,.48),Color(1,.63,.19,0)])
	glow_texture = GradientTexture2D.new()
	glow_texture.gradient = gradient
	glow_texture.width = 128
	glow_texture.height = 128
	glow_texture.fill = GradientTexture2D.FILL_RADIAL
	glow_texture.fill_from = Vector2(.5,.5)
	glow_texture.fill_to = Vector2(1,.5)
	_place_lamps()
	_add_windows()
	emission_layer = CanvasLayer.new()
	emission_layer.name = "WarmLightsAfterDayGrade"
	emission_layer.layer = 4
	add_child(emission_layer)
	var overlay := preload("res://scripts/village_light_overlay.gd").new()
	overlay.lighting = self
	emission_layer.add_child(overlay)
	world.visibility_changed.connect(func(): emission_layer.visible = world.is_visible_in_tree())

func _place_lamps() -> void:
	var index := 0
	for route in world.routes:
		if route.surface=="earth": continue
		var travelled := 0.0
		for segment in range(route.points.size()-1):
			var a: Vector2 = route.points[segment]
			var b: Vector2 = route.points[segment+1]
			var length := a.distance_to(b)
			var tangent := a.direction_to(b)
			var distance := 280.0+fposmod(-travelled,700)
			while distance<length-150:
				var at: Vector2 = a+tangent*distance+tangent.orthogonal()*(route.width*.5-24)*(1 if index%2 else -1)
				if world.is_walkable(at,35) and not lamps.any(func(l): return l.node.position.distance_to(at)<430): _lamp(at,index)
				distance += 700
				index += 1
			travelled += length
	# Squares keep an evening focal point, even when their streets are very short.
	for at in [Vector2(9160,2520),Vector2(10260,3490),Vector2(11240,7970),Vector2(6530,5080),Vector2(18900,5000),Vector2(18100,12980)]:
		if world.is_walkable(at,35) and not lamps.any(func(l): return l.node.position.distance_to(at)<200): _lamp(at,index); index+=1

func _lamp(at: Vector2, index: int) -> void:
	var source: Array = PROPS.ART.data.props.lamp
	var height := 290.0
	var width: float = height*source[2]/source[3]
	var node := preload("res://scripts/village_architecture.gd").new()
	node.name = "NightStreetLamp_%03d"%lamps.size()
	var base := Rect2(at-Vector2(9,10),Vector2(18,14))
	node.build(PROPS.ATLAS,Rect2(source[0],source[1],source[2],source[3]),at,width,[base],world.opaque_paint)
	world.actors.add_child(node)
	world.blocked_rects.append(base)
	var halo := _glow(node,Vector2(0,-height*.82),Vector2(100,120))
	var pool := _glow(node,Vector2(0,3),Vector2(220,82))
	lamps.append({"node":node,"halo":halo,"pool":pool,"offset":index%21})

func _glow(parent: Node2D, at: Vector2, size: Vector2) -> Sprite2D:
	var node := Sprite2D.new()
	node.texture = glow_texture
	node.position = at
	node.scale = size/128
	var blend := CanvasItemMaterial.new()
	blend.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	node.material = blend
	parent.add_child(node)
	node.hide()
	return node

func _add_windows() -> void:
	var entries: Array = world.architecture_data.duplicate()
	entries.append_array(world.BLOCKS.data.buildings)
	var buildings: Dictionary = {}
	for building in world.buildings: buildings[building.entry_id] = building
	for i in entries.size():
		var entry: Dictionary = entries[i]
		if (i%3==1 and entry.label!="Recanto Lord Byron") or not GLASS.data.has(entry.atlas): continue
		var building: Node2D = buildings[entry.id]
		var source: Rect2 = world._source(entry.atlas,int(entry.type))
		var factor: float = entry.width/source.size.x
		var options: Array = GLASS.data[entry.atlas][int(entry.type)]
		var material := ShaderMaterial.new()
		material.shader = WINDOW_SHADER
		var panes: Array = []
		for k in options.size():
			if (k+i)%3: continue
			var data: Array = options[k]
			var rect := Rect2(data[0],data[1],data[2],data[3])
			var uv := PackedVector2Array([rect.position,Vector2(rect.end.x,rect.position.y),rect.end,Vector2(rect.position.x,rect.end.y)])
			var points := PackedVector2Array()
			for point in uv:
				var p := (point-source.position)*factor-Vector2(building.visual_size.x*.5,building.visual_size.y)
				if entry.get("sprite_mirror",false): p.x = -p.x
				points.append(p)
			var pane := Polygon2D.new()
			pane.polygon = points
			pane.uv = uv
			pane.texture = building.surface.texture
			pane.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
			pane.material = material
			building.add_child(pane)
			panes.append(pane)
		windows.append({"building":building,"material":material,"panes":panes,"on":1100+i%67,"off":(1410+i%180),"overnight":i%19==0})

func step(_delta: float, cycle: RefCounted) -> void:
	if absf(last_update-cycle.minutes)<.2: return
	last_update = cycle.minutes
	var time: float = cycle.minutes
	lamp_strength = night_amount(time)
	for lamp in lamps:
		var level := clampf(lamp_strength*1.5-lamp.offset/50.0,0,1)
		lamp.halo.visible = level>.001
		lamp.pool.visible = level>.001
		lamp.halo.modulate.a = level
		lamp.pool.modulate.a = level*.7
	lit_windows = 0
	for window in windows:
		var night_time := time if time>=720 else time+1440
		var level: float = smoothstep(float(window.on),float(window.on)+25,night_time)*night_amount(time)
		if not window.overnight: level *= 1.0-smoothstep(float(window.off),float(window.off)+35,night_time)
		if window.building.label=="Recanto Lord Byron" and is_instance_valid(world.nightlife):
			level = lamp_strength if world.nightlife.opened else 0.0
		window.material.set_shader_parameter("amount",level*.93)
		window.level = level
		if level>.1: lit_windows += window.panes.size()

static func night_amount(time: float) -> float:
	return smoothstep(1080,1180,time) if time>=720 else 1.0-smoothstep(345,430,time)
