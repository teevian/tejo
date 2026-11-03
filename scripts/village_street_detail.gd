extends Node2D
## Low stonework, a readable street plaque and lanterns are separate depth objects.
var kind := "plaque"
var text := ""
var width := 180.0
func _draw() -> void:
	var font := ThemeDB.fallback_font
	if kind=="plaque":
		var box := TejoPerson._box(Color("e4dfc9"),4)
		box.border_color = Color("526e80")
		box.set_border_width_all(3)
		draw_style_box(box,Rect2(-width/2,-49,width,43))
		draw_string(font,Vector2(-width/2+10,-23),text,HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("344c5b"))
	elif kind=="wall":
		draw_texture_rect(preload("res://assets/world/village/pavement.png"),Rect2(-width/2,-60,width,60),false,Color("a5ad9b"))
		for row in 3:
			for col in ceili(width/48):
				var x := -width/2+col*48+(24 if row%2 else 0)
				draw_rect(Rect2(x,-60+row*19,44,16),Color(0.28,0.33,0.27,0.13) if (col+row)%3 else Color(0.45,0.51,0.34,0.2))
		draw_line(Vector2(-width/2,-61),Vector2(width/2,-61),Color("d9cfb4"),7,true)
	elif kind=="lamp":
		draw_line(Vector2.ZERO,Vector2(0,-178),Color("3d4942"),6,true)
		draw_arc(Vector2(12,-174),12,PI,TAU,12,Color("3d4942"),4,true)
		draw_colored_polygon(PackedVector2Array([Vector2(12,-173),Vector2(34,-173),Vector2(30,-145),Vector2(16,-145)]),Color("e2cf8f"))
		draw_line(Vector2(10,-175),Vector2(35,-175),Color("424f46"),6,true)
	else:
		# Terracotta pot with an irregular hand-sized cluster of leaves.
		draw_colored_polygon(PackedVector2Array([Vector2(-18,-28),Vector2(18,-28),Vector2(12,0),Vector2(-12,0)]),Color("a76342"))
		draw_line(Vector2(-20,-29),Vector2(20,-29),Color("c58d64"),6,true)
		for i in 17:
			var point := Vector2(sin(i*2.4)*22,-40+cos(i*1.8)*13)
			draw_circle(point,7,Color("596e42") if i%2 else Color("758357"))
