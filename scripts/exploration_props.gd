extends RefCounted
## Shared painted furniture and vegetation, measured against the approved characters.
const WorldScale = preload("res://scripts/world_scale.gd")
const Prop = preload("res://scripts/open_world_prop.gd")
const BENCH = preload("res://assets/world/two-seat-bench.png")
const BENCH_REGION := Rect2(75,121,1619,658)
const HUMID_TREES = preload("res://assets/world/sintra-humid-trees.png")
const PROPS = preload("res://assets/world/sintra-overhead-props-cutout.png")
const PROP_REGIONS: Array[Rect2] = [Rect2(0,0,512,620),Rect2(512,0,555,620),Rect2(1067,60,469,560),Rect2(0,620,565,404),Rect2(565,620,500,404),Rect2(1065,650,471,374)]

static func add(world: Node2D, at: Vector2, kind: int, variation: float) -> void:
	if kind==5:
		for attempt in 48:
			var candidate := at if attempt==0 else at+Vector2.from_angle(attempt*2.4)*(55+attempt*8)
			if world.is_walkable(candidate,120) and world.is_walkable(candidate+Vector2(-52,22),20) and world.is_walkable(candidate+Vector2(52,22),20):
				at = candidate
				break
	var prop := Prop.new()
	prop.position = at
	prop.set_meta("kind",kind)
	prop.add_to_group("tree_canopy" if kind<2 else ("solid_rock" if kind==3 else "scenery_prop"))
	prop.collision_layer = 1
	prop.collision_mask = 2
	var humid := kind < 2
	var region := BENCH_REGION if kind==5 else (Rect2(kind*512,0,512,1024) if humid else PROP_REGIONS[kind])
	var factor: float = WorldScale.BENCH_WIDTH/region.size.x if kind==5 else WorldScale.PROP_HEIGHTS[kind]*variation/region.size.y
	var sprite := Sprite2D.new()
	sprite.material = world.opaque_paint
	sprite.texture = BENCH if kind==5 else (HUMID_TREES if humid else PROPS)
	sprite.region_enabled = true
	sprite.region_rect = region
	sprite.region_filter_clip_enabled = true
	sprite.centered = false
	sprite.scale = Vector2.ONE * factor
	sprite.position = Vector2(-region.size.x * factor * 0.5,-region.size.y * factor * (1.0 if kind==5 else 0.95))
	prop.sprite = sprite
	prop.half_width = region.size.x*factor*0.53
	prop.height = region.size.y*factor
	prop.add_child(sprite)
	var collider := CollisionShape2D.new()
	if kind==5:
		var shape := RectangleShape2D.new()
		shape.size = WorldScale.BENCH_FOOTPRINT.size
		collider.shape = shape
		collider.position = WorldScale.BENCH_FOOTPRINT.get_center()
		world.blocked_rects.append(Rect2(at+WorldScale.BENCH_FOOTPRINT.position,WorldScale.BENCH_FOOTPRINT.size))
		prop.set_meta("radius",WorldScale.BENCH_WIDTH*0.5-12)
		prop.seat_offsets = WorldScale.BENCH_SEATS.duplicate()
	else:
		var radius := 18.0 if kind<3 else 40.0
		var shape := CircleShape2D.new()
		shape.radius = radius*variation
		prop.set_meta("radius",shape.radius)
		collider.shape = shape
		world.circles.append(Vector3(at.x,at.y,shape.radius))
	prop.add_child(collider)
	world.actors.add_child(prop)
	world.props.append(prop)

