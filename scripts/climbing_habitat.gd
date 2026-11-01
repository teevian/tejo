extends Node3D
## Real world-space roots sampled on the mountain; cutout crowns stay readable
## as the camera orbits, while the vegetation keeps its place on the rock.
const Geology = preload("res://scripts/climbing_geology.gd")
const ATLAS_PATH := "res://assets/climbing/sintra-botany-atlas.png"
const SURFACE_MASK := 16
var renderer: Node2D
var plants: Array[MeshInstance3D] = []
var roots: Array[Dictionary] = []
var materials: Array[StandardMaterial3D] = []
var regions: Array[Rect2i] = []
var colliders: Array[StaticBody3D] = []
var ready_for_review := false
var shared_quad: QuadMesh
var atlas: Texture2D
var pocket_meshes: Array[ArrayMesh] = []
var pocket_material: ShaderMaterial

func _ready() -> void:
	name = "SintraVegetation"
	atlas = load(ATLAS_PATH)
	prepare_materials()
	prepare_surfaces()
	# Let the dedicated 3D world's broad phase register the static rock geometry.
	await get_tree().physics_frame
	await get_tree().physics_frame
	populate()
	ready_for_review = true
	update_view(renderer.scene.space.angle)

func prepare_materials() -> void:
	shared_quad = QuadMesh.new()
	shared_quad.size = Vector2.ONE
	var pixels := atlas.get_image()
	var size := pixels.get_size()
	# The generated specimens have unequal silhouettes; keep roots and fine
	# branches within their own measured regions rather than cropping a tree.
	var cells := [Rect2(0,0,0.505,0.55),Rect2(0.505,0,0.495,0.55),Rect2(0,0.55,0.565,0.45),Rect2(0.565,0.55,0.435,0.45)]
	for i in 4:
		var bounds: Rect2 = cells[i]
		var cell := Rect2i(Vector2i(bounds.position*Vector2(size)),Vector2i(bounds.size*Vector2(size)))
		var used := pixels.get_region(cell).get_used_rect()
		var region := Rect2i(cell.position+used.position,used.size)
		regions.append(region)
		var paint := StandardMaterial3D.new()
		paint.albedo_texture = atlas
		paint.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_DEPTH_PRE_PASS
		paint.alpha_scissor_threshold = 0.30
		paint.no_depth_test = true
		paint.render_priority = 10
		paint.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		paint.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
		paint.billboard_keep_scale = true
		paint.cull_mode = BaseMaterial3D.CULL_DISABLED
		paint.roughness = 1
		paint.metallic_specular = 0.08
		paint.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
		paint.uv1_scale = Vector3(float(region.size.x)/size.x,float(region.size.y)/size.y,1)
		paint.uv1_offset = Vector3(float(region.position.x)/size.x,float(region.position.y)/size.y,0)
		paint.albedo_color = Color(0.94,0.98,0.92)
		materials.append(paint)
	for i in 6: pocket_meshes.append(Geology.boulder_mesh(Vector3(72,32,61),500+i,true))
	pocket_material = renderer.granite_material(Vector3(0.91,0.94,0.86),500)

func prepare_surfaces() -> void:
	for rock in renderer.root_3d.get_node("Mountain").get_children():
		if not rock is MeshInstance3D: continue
		var body := StaticBody3D.new()
		body.collision_layer = SURFACE_MASK
		body.collision_mask = 0
		var shape := CollisionShape3D.new()
		shape.shape = rock.mesh.create_trimesh_shape()
		body.add_child(shape)
		rock.add_child(body)
		colliders.append(body)

func sample_surface(y: float, angle: float) -> Dictionary:
	var radial := Vector3(cos(angle),0,sin(angle))
	var center := Vector3(640,-y,0)
	var query := PhysicsRayQueryParameters3D.create(center+radial*1200,center,SURFACE_MASK)
	return get_world_3d().direct_space_state.intersect_ray(query)

func add_plant(kind: int, y: float, angle: float, width: float, seed: int) -> void:
	var hit := sample_surface(y,angle)
	if hit.is_empty(): return
	var contact: Vector3 = hit.position
	var normal: Vector3 = hit.normal
	var root := contact+normal*4+Vector3.UP*5
	if kind==3: root = contact+normal*4
	else:
		# Small, partly buried boulders form pockets of soil under the roots.
		var pocket: MeshInstance3D = renderer.add_rock(pocket_meshes[seed%6],pocket_material,self,2)
		var scale_value := 0.72+0.24*(0.5+0.5*sin(seed*1.7))
		pocket.scale = Vector3.ONE*scale_value
		pocket.rotation.y = angle
		pocket.position = root-Vector3.UP*32*scale_value-normal*8
	var region: Rect2i = regions[kind]
	var height := width*float(region.size.y)/maxi(1,region.size.x)
	var plant := MeshInstance3D.new()
	plant.name = ["MaritimePine","EvergreenScrub","HeatherAndFerns","TrailingIvy"][kind]+"_"+str(seed)
	plant.mesh = shared_quad
	plant.material_override = materials[kind]
	plant.layers = 2
	plant.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	plant.scale = Vector3(width,height,1)
	plant.position = root+Vector3.UP*height*( -0.5 if kind==3 else 0.5)
	add_child(plant)
	plants.append(plant)
	roots.append({"kind":kind,"root":root,"contact":contact,"normal":normal,"width":width,"height":height,"node":plant})

func populate() -> void:
	# Vegetated joints all the way up the crag, denser around the lower boulders.
	for level in 15:
		var y := 1500.0+level*207
		for side in 8:
			var seed := level*8+side
			var angle := TAU*side/8+level*0.37
			var kind := 3 if side%3==0 else (1 if (side+level)%2==0 else 2)
			var width := 135+35*sin(seed*1.9)
			if kind==1: width += 75
			add_plant(kind,y+sin(seed*1.3)*38,angle,width,seed)
		# A few broad, woody shrubs make the greenery read as a hillside habitat.
		for side in 2:
			var seed := 200+level*2+side
			add_plant(1,y+87,side*PI+level*0.63,240+sin(seed)*35,seed)
	for level in 7:
		for side in 2:
			var seed := 300+level*2+side
			add_plant(0,2150+level*340+sin(seed)*40,side*PI+level*0.56+0.14,340+35*sin(seed*1.3),seed)

func update_view(yaw: float) -> void:
	var toward_camera := Vector3(-sin(yaw),0,cos(yaw))
	for entry in roots:
		var radial: Vector3 = (entry.contact-Vector3(640,entry.contact.y,0)).normalized()
		entry.node.visible = radial.dot(toward_camera)>-0.08
