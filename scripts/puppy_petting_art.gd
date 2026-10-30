extends RefCounted
const ATLAS: Texture2D = preload("res://assets/puppy/petting-poses.png")
const DATA = preload("res://assets/puppy/petting-poses.json")
static func draw_pose(canvas: CanvasItem, person: Node2D, puppy: Node2D) -> void:
	var frame := int(puppy.state_time*3)%2
	var source: Array = DATA.data.regions[person.kind*2+frame]
	var region := Rect2(source[0],source[1],source[2],source[3])
	var factor: float = 109.0/float(DATA.data.reference_height)
	var side := -1.0 if puppy.position.x<person.position.x else 1.0
	canvas.draw_set_transform(Vector2.ZERO,0,Vector2(side,1))
	# The feet sit left of the reaching hand, in the same world anchor as standing.
	canvas.draw_texture_rect_region(ATLAS,Rect2(Vector2(-region.size.x*.35,-region.size.y)*factor,region.size*factor),region)
	canvas.draw_set_transform(Vector2.ZERO)
