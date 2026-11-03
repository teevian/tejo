extends Node2D
## A footpath marker shared by the two ends of the compressed journey.
var highlighted := false
var to_village := true
func _draw() -> void:
	var font := ThemeDB.fallback_font
	draw_line(Vector2.ZERO,Vector2(0,-135),Color("75664d"),11,true)
	draw_line(Vector2(3,-3),Vector2(3,-133),Color("9c8c68"),3,true)
	var face := StyleBoxFlat.new()
	face.bg_color = Color("3c5b4a")
	face.border_color = Color("eddaa5") if highlighted else Color("929978")
	face.set_border_width_all(3 if highlighted else 2)
	face.set_corner_radius_all(4)
	draw_style_box(face,Rect2(-135,-162,270,85))
	draw_string(font,Vector2(-119,-135),"↓ Vila de Sintra" if to_village else "↑ Serra de Sintra",HORIZONTAL_ALIGNMENT_LEFT,-1,23,Color("f4e9ce"))
	draw_string(font,Vector2(-119,-109),"Pela Vila Sassetti" if to_village else "Pelos caminhos da encosta",HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("ded3b2"))
	if highlighted:
		draw_string_outline(font,Vector2(-118,-57),"Espaço · seguir juntos",HORIZONTAL_ALIGNMENT_LEFT,-1,17,4,Color("243b31"))
		draw_string(font,Vector2(-118,-57),"Espaço · seguir juntos",HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("f4e9ce"))
