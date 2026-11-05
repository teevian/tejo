extends Node2D
## Original procedural short film projected within the authored blank screen.
var prop: Node2D
func _draw() -> void:
	if not is_instance_valid(prop.director): return
	var director: Node2D = prop.director
	var size: Vector2 = prop.visual_size
	var font := ThemeDB.fallback_font
	if prop.kind=="cinema":
		paint_movie(self,prop.movie_rect,director.minute,director.cinema_open())
		return
	elif prop.kind=="score":
		var at := Vector2(-size.x*.25,-size.y*.82)
		draw_style_box(TejoPerson._box(Color("294b42"),3),Rect2(at,Vector2(size.x*.43,70)))
		draw_string(font,at+Vector2(4,10),"CAMPEONATO",HORIZONTAL_ALIGNMENT_LEFT,-1,7,Color("f2e3b4"))
		draw_string(font,at+Vector2(4,20),"DE TOQUES",HORIZONTAL_ALIGNMENT_LEFT,-1,7,Color("f2e3b4"))
		for i in mini(3,director.ranking.size()):
			var row: Dictionary = director.ranking[i]
			draw_string(font,at+Vector2(4,34+i*12),str(row.name)+"  "+str(row.score),HORIZONTAL_ALIGNMENT_LEFT,-1,8,Color("f2e3b4"))
	elif prop.kind in ["fruit","sweets"]:
		var label: String = "FRUTA DA DONA ANA" if prop.kind=="fruit" else "DOCES DO QUIM"
		draw_style_box(TejoPerson._box(Color("eee0bc"),3),Rect2(-65,-size.y*.33,130,22))
		draw_string(font,Vector2(-59,-size.y*.33+15),label,HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("3c5548"))

static func paint_movie(canvas: CanvasItem, panel: Rect2, minute: float, active: bool) -> void:
	var font := ThemeDB.fallback_font
	canvas.draw_rect(panel,Color("e8dfc3"))
	if not active:
		canvas.draw_string(font,panel.position+Vector2(9,24),"CINEMA NA VILA",HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("3d504b"))
		canvas.draw_string(font,panel.position+Vector2(9,45),"19h30 · 20h30 · 21h30",HORIZONTAL_ALIGNMENT_LEFT,-1,9,Color("596a5e"))
		return
	var t: float = fposmod(minute-1170,60)/24
	var moon: Vector2 = panel.position+panel.size*Vector2(.78,.23)
	canvas.draw_circle(moon,panel.size.y*.09,Color("bda86e"))
	var landscape := PackedVector2Array([panel.position+panel.size*Vector2(0,.8),panel.position+panel.size*Vector2(.2,.38),panel.position+panel.size*Vector2(.41,.82),panel.position+panel.size*Vector2(.65,.52),panel.end,panel.position+Vector2(0,panel.size.y)])
	canvas.draw_colored_polygon(landscape,Color("a3b1a2"))
	var tram: Vector2 = panel.position+panel.size*Vector2(.12+t*.62,.73)
	canvas.draw_style_box(TejoPerson._box(Color("b96b45"),3),Rect2(tram,Vector2(28,16)))
	for x in [5,19]:
		canvas.draw_rect(Rect2(tram+Vector2(x,3),Vector2(5,6)),Color("ead7a4"))
		canvas.draw_circle(tram+Vector2(x,17),2.5,Color("3c514b"))
	canvas.draw_string(font,panel.position+Vector2(8,panel.size.y-5),"O elétrico e a lua",HORIZONTAL_ALIGNMENT_LEFT,-1,9,Color("3f554c"))
