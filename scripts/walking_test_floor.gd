extends Node2D
## A neutral floor with a faint distance grid; no scenery or obstacles.
const WORLD_SIZE := Vector2(4800,3600)
const GROUND_COLOR := Color("a7b29b")
var actors: Node2D

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	var ground := Sprite2D.new()
	ground.name = "Ground"
	var paint := GradientTexture2D.new()
	paint.width = 2
	paint.height = 2
	paint.gradient = Gradient.new()
	paint.gradient.colors = PackedColorArray([GROUND_COLOR,GROUND_COLOR])
	ground.texture = paint
	ground.centered = false
	ground.scale = WORLD_SIZE/ground.texture.get_size()
	ground.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	ground.z_index = -50
	add_child(ground)
	actors = Node2D.new()
	actors.name = "Characters"
	actors.y_sort_enabled = true
	add_child(actors)

func is_walkable(point: Vector2, margin := 0.0) -> bool:
	return Rect2(Vector2.ONE*margin,WORLD_SIZE-Vector2.ONE*margin*2).has_point(point)

func can_walk_line(from: Vector2, to: Vector2) -> bool:
	return is_walkable(from) and is_walkable(to)

func find_path(from: Vector2, to: Vector2) -> PackedVector2Array:
	return PackedVector2Array([to]) if can_walk_line(from,to) else PackedVector2Array()

func _draw() -> void:
	# A quiet reference for foot contact and movement distance.
	var grid := Color("718469")
	grid.a = .12
	for x in range(0,int(WORLD_SIZE.x)+1,100):
		draw_line(Vector2(x,0),Vector2(x,WORLD_SIZE.y),grid,1)
	for y in range(0,int(WORLD_SIZE.y)+1,100):
		draw_line(Vector2(0,y),Vector2(WORLD_SIZE.x,y),grid,1)
