extends Node2D
var highlighted := false
var font: Font = ThemeDB.fallback_font

func _draw() -> void:
	draw_line(Vector2(0,0),Vector2(0,-125),Color("72634b"),10,true)
	var wood := StyleBoxFlat.new()
	wood.bg_color = Color("435d47")
	wood.border_color = Color("e0c78d") if highlighted else Color("a7ac86")
	wood.set_border_width_all(3 if highlighted else 1)
	wood.set_corner_radius_all(5)
	draw_style_box(wood,Rect2(-107,-144,214,77))
	draw_string(font,Vector2(-88,-116),"↑ Penedo da Amizade",HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("f6e9c7"))
	draw_string(font,Vector2(-88,-88),"Escalada a dois · Espaço",HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("ddd3ad"))
