extends RefCounted
## Tilted capstones, side boulders and dark open mouths shelter real 3D paths.
const Route = preload("res://scripts/climbing_route.gd")
const Geology = preload("res://scripts/climbing_geology.gd")

static func build(renderer: Node2D) -> void:
	var caves := Node3D.new()
	caves.name = "RockPassages"
	renderer.root_3d.add_child(caves)
	for t in Route.TUNNELS.size():
		var path: Array = Route.TUNNELS[t].path
		var chamber := Node3D.new()
		chamber.name = "RootsDolmen" if t==0 else "FernTunnel"
		caves.add_child(chamber)
		for end in [0,path.size()-1]:
			var point: Vector3 = path[end]
			var inward: Vector3 = (path[1]-point if end==0 else path[-2]-point).normalized()
			inward.y = 0
			var across := Vector3(inward.z,0,-inward.x)
			var origin := Vector3(point.x,-point.y,point.z)
			for side in [-1,1]:
				var stone: MeshInstance3D = renderer.add_rock(Geology.boulder_mesh(Vector3(94,142,115),800+t*20+end+side,true),renderer.granite_material(Vector3(0.80,0.85,0.78),810+t),chamber)
				stone.position = origin+across*side*187+Vector3.UP*97
				stone.rotation = Vector3(0.08*side,atan2(inward.x,inward.z),0.10*side)
			var lintel: MeshInstance3D = renderer.add_rock(Geology.boulder_mesh(Vector3(285,104,192),830+t*10+end,true),renderer.granite_material(Vector3(0.87,0.90,0.84),820+t),chamber)
			lintel.position = origin+Vector3.UP*267
			lintel.rotation = Vector3(0.07,atan2(inward.x,inward.z),-0.13)
			var mouth := MeshInstance3D.new()
			var opening := QuadMesh.new()
			opening.size = Vector2(265,188)
			mouth.mesh = opening
			var shade := StandardMaterial3D.new()
			shade.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			shade.albedo_color = Color("18251e")
			shade.cull_mode = BaseMaterial3D.CULL_DISABLED
			mouth.material_override = shade
			mouth.layers = 2
			mouth.basis = Basis(across,Vector3.UP,across.cross(Vector3.UP))
			mouth.position = origin+Vector3.UP*96+inward*28
			chamber.add_child(mouth)
		# A continuous leaning roof joins both entrances, rather than two portals
		# standing in empty air. It remains below the adjacent higher terraces.
		for i in range(1,path.size()-1):
			var point: Vector3 = path[i]
			var slab: MeshInstance3D = renderer.add_rock(Geology.boulder_mesh(Vector3(250,96,220),860+t*10+i,true),renderer.granite_material(Vector3(0.82,0.87,0.80),860+t),chamber,2)
			slab.position = Vector3(point.x,-point.y+270,point.z)
			slab.rotation = Vector3(-0.10,0.31*i,0.15)
