extends Node2D
## A ribbon over the painted river samples its existing colours, leaving bridges dry.
var world: Node2D
var water_material: ShaderMaterial
var elapsed := 0.0
func _ready() -> void:
	name = "LivingRiver"
	z_index = -40
	water_material = ShaderMaterial.new()
	water_material.shader = preload("res://shaders/river_flow.gdshader")
	var vertices := PackedVector3Array()
	var coordinates := PackedVector2Array()
	var indices := PackedInt32Array()
	var steps := int(world.WORLD_SIZE.y/24.0)
	for i in range(steps+1):
		var y := float(i)*24.0
		var width := lerpf(122.0,70.0,smoothstep(3500.0,3700.0,y))
		var center: float = world.river_x(y)
		vertices.append(Vector3(center-width,y,0))
		vertices.append(Vector3(center+width,y,0))
		coordinates.append(Vector2(-1,y))
		coordinates.append(Vector2(1,y))
		if i<steps:
			var a := i*2
			indices.append_array(PackedInt32Array([a,a+1,a+2,a+1,a+3,a+2]))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_TEX_UV] = coordinates
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	var surface := MeshInstance2D.new()
	surface.mesh = mesh
	surface.material = water_material
	add_child(surface)
func _process(delta: float) -> void:
	elapsed += delta
	water_material.set_shader_parameter("flow_time",elapsed)
