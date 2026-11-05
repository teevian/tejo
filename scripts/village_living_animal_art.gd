extends Node2D
## Individual foot depth for the cat and each bird, preserving authored native poses.
var community: Node2D
var bird: Dictionary = {}
var is_cat := false
func _ready() -> void: material = community.director.world.opaque_paint
func _draw() -> void:
	var frame: int = 4+community.cat_frame if is_cat else ((2 if bird.fly>1 else 3) if bird.fly>0 else int(community.clock*2+bird.phase)%2)
	var pose: Dictionary = community.director.ART.data.animals[frame]
	var r: Array = pose.rect
	var source := Rect2(r[0],r[1],r[2],r[3])
	var height: float = 42 if is_cat else (27 if bird.fly<=0 else 45)
	var size := source.size*height/source.size.y
	var lift: float = 0 if is_cat else sin(clampf(bird.fly/4,0,1)*PI)*65
	draw_texture_rect_region(community.director.textures.animals,Rect2(Vector2(-size.x*.5,-size.y-lift),size),source)
