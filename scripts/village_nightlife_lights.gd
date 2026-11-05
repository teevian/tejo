extends Node2D
## Small warm sources and a pool of light follow the camera after the shared night grade.
var director: Node2D
func _draw() -> void:
	if not director.opened or not director.world.is_visible_in_tree(): return
	var transform: Transform2D = director.world.get_canvas_transform()
	var zoom: float = transform.get_scale().x
	var origin: Vector2 = director.counter.position
	var texture: Texture2D = director.world.lighting.glow_texture
	var bulbs := [Vector2(-205,-190),Vector2(0,-180),Vector2(210,-185)]
	for i in range(2):
		draw_line(transform*(origin+bulbs[i]),transform*(origin+bulbs[i+1]),Color("3e3931"),1.5*zoom,true)
	for offset in bulbs:
		var point: Vector2 = transform*(origin+offset)
		var radius := Vector2(55,65)*zoom
		draw_texture_rect(texture,Rect2(point-radius,radius*2),false,Color(1,.82,.47,.64))
		draw_circle(point,3*zoom,Color(1,.88,.57,.92))
	var floor_at: Vector2 = transform*(director.center+Vector2(0,75))
	var pool := Vector2(420,265)*zoom
	draw_texture_rect(texture,Rect2(floor_at-pool,pool*2),false,Color(1,.75,.38,.19))
