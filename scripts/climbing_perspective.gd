extends Node2D
## An actual 3D scene rendered with an orbiting orthographic camera. Characters
## remain the approved 2D paintings, projected at their persistent 3D positions.
const Geology = preload("res://scripts/climbing_geology.gd")
const GRANITE = preload("res://assets/climbing/granite-surface.png")
var scene: Node2D
var viewport: SubViewport
var camera_3d: Camera3D
var core_camera: Camera3D
var core_plane: Sprite2D
var image_plane: Sprite2D
var meshes: Array[MeshInstance3D] = []
var materials: Array[ShaderMaterial] = []
var stone_tints: Array[Vector3] = []
var root_3d: Node3D
var supports: Array[MeshInstance3D] = []
var props: Dictionary = {}
var habitat: Node3D

func _ready() -> void:
	z_index = -10
	viewport = SubViewport.new()
	viewport.name = "GraniteWorld3D"
	viewport.size = Vector2i(1280,720)
	viewport.own_world_3d = true
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
	viewport.msaa_3d = Viewport.MSAA_2X
	add_child(viewport)
	root_3d = Node3D.new()
	viewport.add_child(root_3d)
	var environment := WorldEnvironment.new()
	var light := Environment.new()
	light.background_mode = Environment.BG_CLEAR_COLOR
	light.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	light.ambient_light_color = Color("eee9d9")
	light.ambient_light_energy = 0.62
	environment.environment = light
	root_3d.add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-36,-28,0)
	sun.light_color = Color("fff9ef")
	sun.light_energy = 0.90
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 6000
	root_3d.add_child(sun)
	camera_3d = Camera3D.new()
	camera_3d.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera_3d.keep_aspect = Camera3D.KEEP_HEIGHT
	camera_3d.near = 1
	camera_3d.far = 9000
	camera_3d.cull_mask = 1
	root_3d.add_child(camera_3d)
	camera_3d.make_current()
	# A separate background pass keeps the decorative cliff from hiding playable
	# shelves on the rear face, matching the flattened collision projection.
	var core_viewport := SubViewport.new()
	core_viewport.name = "CliffBackground3D"
	core_viewport.size = viewport.size
	core_viewport.world_3d = viewport.find_world_3d()
	core_viewport.transparent_bg = true
	core_viewport.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
	core_viewport.msaa_3d = Viewport.MSAA_2X
	add_child(core_viewport)
	core_camera = Camera3D.new()
	core_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	core_camera.keep_aspect = Camera3D.KEEP_HEIGHT
	core_camera.near = 1
	core_camera.far = 9000
	core_camera.cull_mask = 2
	core_viewport.add_child(core_camera)
	core_camera.make_current()
	core_plane = Sprite2D.new()
	core_plane.centered = false
	core_plane.texture = core_viewport.get_texture()
	core_plane.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(core_plane)
	image_plane = Sprite2D.new()
	image_plane.centered = false
	image_plane.texture = viewport.get_texture()
	image_plane.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(image_plane)
	rebuild()
	habitat = preload("res://scripts/climbing_habitat.gd").new()
	habitat.renderer = self
	root_3d.add_child(habitat)
	update_view()

func granite_material(tint: Vector3, seed := 0) -> ShaderMaterial:
	var result := ShaderMaterial.new()
	result.shader = preload("res://shaders/climbing_granite_3d.gdshader")
	result.set_shader_parameter("granite",GRANITE)
	result.set_shader_parameter("tint",tint)
	result.set_shader_parameter("seed",float(seed)*1.731)
	return result

func add_rock(mesh: ArrayMesh, paint: ShaderMaterial, parent: Node3D, layer := 1) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = paint
	instance.layers = layer
	parent.add_child(instance)
	return instance

func rebuild() -> void:
	for mesh in meshes: mesh.queue_free()
	for support in supports: support.queue_free()
	meshes.clear(); materials.clear(); supports.clear(); stone_tints.clear()
	for p in scene.platforms:
		var box: Dictionary = scene.space.boxes[p.id]
		var fragile := float(p.get("fragile",0))>0
		var mesh: ArrayMesh
		if p.get("boulder",false):
			mesh = Geology.boulder_mesh(Vector3((float(box.right)-float(box.left))*0.5,float(box.height)*0.5,(float(box.front)-float(box.back))*0.5),int(p.id))
		else: mesh = Geology.ledge_mesh(box,int(p.id),false)
		var tint: Vector3 = [Vector3(0.90,0.92,0.86),Vector3(0.99,0.94,0.84),Vector3(0.94,0.97,0.93),Vector3(0.89,0.91,0.86)][int(p.id)%4]
		var paint := granite_material(tint,int(p.id))
		paint.set_shader_parameter("fragility",1.0 if fragile else 0.0)
		var instance := add_rock(mesh,paint,root_3d)
		instance.name = "Outcrop_"+str(p.id)
		meshes.append(instance); materials.append(paint)
		stone_tints.append(tint)
		# Exfoliating plates rest on permanent buttresses; only the loose plate falls.
		if not p.get("boulder",false) and p.id not in [18,19,29]:
			var base: Dictionary = box.duplicate()
			var inset := (float(box.right)-float(box.left))*0.07
			base.left += inset; base.right -= inset
			base.y += 78.0 if fragile else 38.0
			base.height = 245.0
			var support := add_rock(Geology.ledge_mesh(base,int(p.id)+80,true),granite_material(Vector3(0.90,0.93,0.89),int(p.id)),root_3d,2)
			support.name = "Root_"+str(p.id)
			support.set_meta("base",base)
			support.set_meta("fragile",fragile)
			support.set_meta("shelf",int(p.id))
			supports.append(support)
	if not root_3d.has_node("Mountain"):
		build_mountain()
		build_props()
		preload("res://scripts/climbing_caverns.gd").build(self)

func build_mountain() -> void:
	var mountain := Node3D.new()
	mountain.name = "Mountain"
	root_3d.add_child(mountain)
	var core := add_rock(Geology.mountain_mesh(),granite_material(Vector3(0.92,0.94,0.90),31),mountain,2)
	core.name = "ContinuousGranite"
	core.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Uneven, partly buried boulders share the central body. Their axes follow
	# shallow geological joints instead of the old horizontal block stack.
	for level in 9:
		for side in 3:
			var seed := 37+level*3+side
			var angle := side*TAU/3+level*1.31
			var y := 1570.0+level*345+sin(seed*2.1)*55
			var center := Geology.mountain_center(y)
			var r := 350.0+sin(seed*1.7)*28
			var radius := Vector3(260+sin(seed)*35,270+cos(seed*1.4)*55,240+cos(seed*1.9)*30)
			var stone := add_rock(Geology.boulder_mesh(radius,seed,true),granite_material(Vector3(0.94,0.95,0.90),seed),mountain,2)
			stone.position = Vector3(center.x+cos(angle)*r,-y,center.y+sin(angle)*r)
			stone.rotation = Vector3(sin(seed)*0.10,angle+0.2,cos(seed)*0.11)
			stone.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Broad buttresses anchor the galleries and the two sheltered crossings.
	for spec in [[Vector3(1080,-3600,-30),Vector3(360,380,510)], [Vector3(440,-2070,-350),Vector3(310,330,420)], [Vector3(1090,-2700,-300),Vector3(300,310,350)]]:
		var stone := add_rock(Geology.boulder_mesh(spec[1],96+mountain.get_child_count(),true),granite_material(Vector3(0.87,0.92,0.85),96),mountain,2)
		stone.position = spec[0]
		stone.rotation.z = 0.16

func prop_rock(key: String, size: Vector3, seed: int) -> MeshInstance3D:
	var result := add_rock(Geology.boulder_mesh(size,seed),granite_material(Vector3(1.01,1.0,0.94),seed),root_3d)
	props[key] = result
	return result

func build_props() -> void:
	prop_rock("loose",Vector3(64,34,56),102)
	prop_rock("hinge",Vector3(112,29,58),103)
	prop_rock("wedge",Vector3(29,21,24),104)
	prop_rock("horn",Vector3(31,39,29),105)
	prop_rock("scout_horn",Vector3(34,38,30),114)
	for i in 4: prop_rock("cairn_"+str(i),Vector3(28-i*5,11,23-i*4),106+i)

func prop_position(shelf: int, x: float, height_above := 0.0) -> Vector3:
	var box: Dictionary = scene.space.boxes[shelf]
	var z := (float(box.back)+float(box.front))*0.5
	return Vector3(x,-scene.space.surface_world(box,x,z)+height_above,z)

func update_props() -> void:
	var loose: MeshInstance3D = props.loose
	loose.visible = not scene.flags.get("rock_step",false)
	var t := clampf((scene.rock_time-0.85)/0.65,0,1) if scene.rock_falling else 0.0
	loose.position = prop_position(4,511,34).lerp(prop_position(3,630,34),t*t)
	loose.rotation = Vector3(t*0.7,0,t*1.5)
	props.hinge.position = prop_position(6,283,10)
	props.hinge.rotation.z = -0.06 if scene.platforms[19].enabled else 0.06
	props.wedge.position = prop_position(7,750,21)
	props.wedge.rotation.z = 0.18 if scene.flags.get("balance_locked",false) else -0.07
	props.horn.position = prop_position(13,820,39)
	props.scout_horn.position = prop_position(28,650,38)
	for i in 4: props["cairn_"+str(i)].position = prop_position(17,1000,11+i*18)

func update_view() -> void:
	if not is_instance_valid(scene.camera): return
	var yaw: float = scene.space.angle
	var camera_point: Vector3 = scene.space.inverse(scene.camera.position,0)
	var target := Vector3(camera_point.x,-camera_point.y,camera_point.z)
	camera_3d.position = target+Vector3(-sin(yaw)*3200,0,cos(yaw)*3200)
	camera_3d.look_at(target,Vector3.UP)
	camera_3d.size = 720.0/scene.camera.zoom.y
	core_camera.transform = camera_3d.transform
	core_camera.size = camera_3d.size
	var size: Vector2 = Vector2(1280,720)/scene.camera.zoom
	image_plane.position = scene.camera.position-size*0.5
	image_plane.scale = size/Vector2(1280,720)
	core_plane.position = image_plane.position
	core_plane.scale = image_plane.scale
	for i in meshes.size():
		var p: Dictionary = scene.platforms[i]
		var instance: MeshInstance3D = meshes[i]
		var fall := float(p.get("fall",0))
		instance.visible = (p.enabled or (fall>0 and fall<1.4)) and scene.platform_visible(i)
		if p.get("boulder",false):
			var box: Dictionary = scene.space.boxes[i]
			instance.position = Vector3((box.left+box.right)*0.5,-float(box.y)-float(box.height)*0.5,(box.back+box.front)*0.5)
		else:
			instance.position.y = -700*fall*fall if not p.enabled else 0.0
			var life := float(p.get("fragile",0))
			var timer := float(p.get("timer",-1))
			var warning := 1-timer/life if life>0 and timer>=0 else 0.0
			instance.position.x = sin(scene.clock*73)*warning*3
			materials[i].set_shader_parameter("tint",stone_tints[i]*Vector3(1,1-warning*0.09,1-warning*0.13))
		if i==29:
			# The unsafe slab already exists. The depth stone seats it gradually;
			# solving the puzzle never conjures a new rock out of empty space.
			instance.visible = true
			var settled := smoothstep(0.0,0.75,scene.clock-float(scene.flags.get("bridge_braced_at",scene.clock))) if scene.flags.get("bridge_braced",false) else 0.0
			var tilt := Basis(Vector3.RIGHT,0.32*(1-settled))
			var box: Dictionary = scene.space.boxes[29]
			var pivot := Vector3((box.left+box.right)*0.5,-float(box.y),(box.back+box.front)*0.5)
			instance.transform = Transform3D(tilt,pivot-tilt*pivot)
	for support in supports: support.visible = scene.platform_visible(int(support.get_meta("shelf")))
	update_props()
	if is_instance_valid(habitat) and habitat.ready_for_review: habitat.update_view(yaw)
