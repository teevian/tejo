extends Node2D
var kind := "leaf"
var offset := Vector2.ZERO
func _draw() -> void:
	if kind=="hollow":
		draw_set_transform(offset,0,Vector2(0.72,1))
		draw_circle(Vector2.ZERO,11,Color("65533d"))
		draw_circle(Vector2(0,1),8,Color("2c3024"))
		draw_arc(Vector2.ZERO,10,0.2,2.8,18,Color("90714c"),1.4,true)
	elif kind=="flowers":
		for i in 5:
			var stem := Vector2(sin(i*12.3)*18,cos(i*7.1)*8)
			var tip := stem+Vector2(sin(i*3.5)*4,-10-i%3*3)
			draw_line(stem,tip,Color("657b46"),0.85,true)
			for petal in 5:
				draw_circle(tip+Vector2.from_angle(petal*TAU/5)*1.7,1.4,Color("c9bc9a") if i%2 else Color("b5a4bb"))
			draw_circle(tip,0.8,Color("b49e57"))
	else:
		for at in [Vector2.ZERO,Vector2(24,17),Vector2(-18,25)]:
			draw_set_transform(at+Vector2(1,3),0,Vector2(1,0.52))
			draw_circle(Vector2.ZERO,16,Color(0.1,0.19,0.15,0.3))
			draw_set_transform(at,0.2,Vector2(1,0.55))
			var points := PackedVector2Array([Vector2.ZERO])
			for i in range(1,28):
				var angle := lerpf(0.15,TAU-0.15,float(i)/28)
				points.append(Vector2.from_angle(angle)*15)
			draw_colored_polygon(points,Color("527a4a"))
			draw_arc(Vector2.ZERO,14,0.3,5.9,24,Color("759451"),1,true)
			for i in 5:
				draw_line(Vector2.ZERO,Vector2.from_angle(i*1.2+0.5)*12,Color("6a8a4c"),0.7,true)
	draw_set_transform(Vector2.ZERO)
