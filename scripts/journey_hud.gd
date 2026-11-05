extends Control
var journey: Node2D
var owner_scene: Node2D
var read_only := false
var more: Button
func _ready() -> void:
	position = Vector2(1007,147 if read_only else 260); size = Vector2(237,211)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	journey.changed.connect(queue_redraw)
	if not read_only:
		more = Button.new(); more.text = "Momentos e desbloqueios"; more.position = Vector2(12,175); more.size = Vector2(213,27)
		more.add_theme_font_size_override("font_size",12)
		more.add_theme_stylebox_override("normal",TejoPerson._box(Color("446054"),5))
		more.add_theme_stylebox_override("hover",TejoPerson._box(Color("617960"),5))
		more.add_theme_color_override("font_color",Color("fff0cd")); more.pressed.connect(journey.open_progress); add_child(more)
func _process(_delta: float) -> void:
	var selected: int = owner_scene.selected
	tooltip_text = "Ligação partilhada. Fome e cansaço pertencem a cada um. Dormir ×1; banco ×0,25."
	visible = not owner_scene.get_tree().paused and (read_only or not journey.scene.exploration_map.visible and not journey.scene.hud.dialogue_active)
	if more!=null: more.disabled = journey.controls_blocked()
	set_meta("selected",selected)
func bar(at: Vector2,width: float,value: float,color: Color) -> void:
	draw_style_box(TejoPerson._box(Color("40594e"),3),Rect2(at,Vector2(width,6)))
	if value>0: draw_style_box(TejoPerson._box(color,3),Rect2(at,Vector2(width*clampf(value/100,0,1),6)))
func _draw() -> void:
	var font := ThemeDB.fallback_font
	var paper := TejoPerson._box(Color(.12,.25,.23,.96),10); paper.border_color = Color("b6bd93"); paper.set_border_width_all(1)
	draw_style_box(paper,Rect2(Vector2.ZERO,Vector2(237,174 if read_only else 211)))
	draw_string(font,Vector2(12,22),"LIGAÇÃO · NÍVEL %d"%journey.level(),HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("e9d2a1"))
	draw_string(font,Vector2(182,22),str(int(journey.bond))+"/100",HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("f3e6c7"))
	bar(Vector2(12,31),213,journey.bond,Color("d7ae76"))
	for i in 2:
		var at := 58+i*47
		draw_string(font,Vector2(12,at),"TE" if i==0 else "JO",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("f2e3c4"))
		for row in 2:
			var key: String = "hunger" if row==0 else "fatigue"
			var y: float = at-8+row*19
			draw_string(font,Vector2(45,y+7),"Fome" if row==0 else "Cansaço",HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("d5dfc9"))
			bar(Vector2(98,y),88,float(journey.needs[i][key]),Color("cb8d66") if row==0 else Color("91a9bc"))
			draw_string(font,Vector2(192,y+7),str(roundi(float(journey.needs[i][key]))),HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("eee3c6"))
	draw_string(font,Vector2(12,161),"CARTEIRA · "+preload("res://scripts/bakery_catalog.gd").euro(journey.coins),HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("e9d2a1"))
