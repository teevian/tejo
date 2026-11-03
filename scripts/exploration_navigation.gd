extends RefCounted
## Shared path queries and clearance policy; the village rasterizes its public floor separately.
static func bake(world: Node2D) -> void:
	var navigation: AStarGrid2D = world.navigation
	var CELL: float = world.CELL
	var WORLD_SIZE: Vector2 = world.WORLD_SIZE
	navigation.region = Rect2i(0,0,int(WORLD_SIZE.x/CELL),int(WORLD_SIZE.y/CELL))
	navigation.cell_size = Vector2.ONE*CELL
	navigation.offset = Vector2.ONE*CELL*0.5
	navigation.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	navigation.default_compute_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	navigation.default_estimate_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	navigation.update()
	for x in navigation.region.size.x:
		for y in navigation.region.size.y:
			var id := Vector2i(x,y)
			navigation.set_point_solid(id,not world.is_walkable(navigation.get_point_position(id),23))

static func nearest(world: Node2D, at: Vector2) -> Vector2i:
	var navigation: AStarGrid2D = world.navigation
	var CELL: float = world.CELL
	var cell := Vector2i(at/CELL).clamp(Vector2i.ZERO,navigation.region.size-Vector2i.ONE)
	if not navigation.is_point_solid(cell):
		return cell
	for radius in range(1,14):
		for x in range(-radius,radius+1):
			for y in range(-radius,radius+1):
				var test := cell+Vector2i(x,y)
				if navigation.region.has_point(test) and not navigation.is_point_solid(test):
					return test
	return cell

static func find_path(world: Node2D, from: Vector2, to: Vector2) -> PackedVector2Array:
	return world.navigation.get_point_path(nearest(world,from),nearest(world,to))

static func can_walk_line(world: Node2D, from: Vector2, to: Vector2) -> bool:
	var steps := maxi(1,ceili(from.distance_to(to)/16.0))
	for i in range(steps+1):
		if not world.is_walkable(from.lerp(to,float(i)/steps),16):
			return false
	return true

