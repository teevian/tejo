extends Node2D
## Near branches sit above the actors; ground mist sits below them.
## Parallax follows camera position, never player proximity or opacity.
const BRANCH: Texture2D = preload("res://assets/world/sintra-high-branch-complete.png")
const WorldScale = preload("res://scripts/world_scale.gd")
var world: Node2D
var branches: Array[Dictionary] = []
func _ready() -> void:
	name = "ForestHeightAndFocus"
	var near_focus := ShaderMaterial.new()
	near_focus.shader = preload("res://shaders/near_branch.gdshader")
	var anchors: Array[Vector2] = [Vector2(350,2300),Vector2(1550,2750),Vector2(550,1000),Vector2(1600,1550),Vector2(3600,2100),Vector2(3970,3100),Vector2(400,3890),Vector2(1400,4450),Vector2(3500,3850),Vector2(4100,4780)]
	for i in anchors.size():
		var sprite := Sprite2D.new()
		sprite.texture = BRANCH
		sprite.material = near_focus
		sprite.centered = false
		sprite.scale = Vector2.ONE*WorldScale.NEAR_BRANCH_SCALES[i%2]
		sprite.position = anchors[i]-Vector2(700,1100)*sprite.scale.x
		sprite.flip_h = i%2==1
		sprite.z_index = 8
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		add_child(sprite)
		branches.append({"sprite":sprite,"origin":sprite.position,"anchor":anchors[i]})
	# Mist pools in hollows, under the solid character and tree layer.
	for area in [Rect2(0,1800,2350,1800),Rect2(250,3650,2150,1650),Rect2(2900,3650,1300,1400)]:
		var mist := Polygon2D.new()
		mist.position = area.position
		mist.polygon = PackedVector2Array([Vector2.ZERO,Vector2(area.size.x,0),area.size,Vector2(0,area.size.y)])
		mist.uv = PackedVector2Array([Vector2.ZERO,Vector2(1,0),Vector2.ONE,Vector2(0,1)])
		var material_value := ShaderMaterial.new()
		material_value.shader = preload("res://shaders/forest_mist.gdshader")
		mist.material = material_value
		mist.z_index = -5
		add_child(mist)
func _process(_delta: float) -> void:
	var camera := get_viewport().get_camera_2d()
	if camera == null:
		return
	for branch in branches:
		var offset: Vector2 = (branch.anchor-camera.global_position)*0.085
		branch.sprite.position = branch.origin+offset
