extends Control

signal person_selected(index: int)
signal pause_requested

const AvatarButton = preload("res://scripts/avatar_button.gd")
var open_world := false
var area_title := "Trilho dos eucaliptos"
var selected := 0
var paused := false
var dialogue_active := false
var avatars: Array[Button] = []
var font: Font = ThemeDB.fallback_font
var pause_button: Button

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for i in 2:
		var button := AvatarButton.new()
		button.kind = i
		button.position = Vector2(1030+i*110,28)
		button.size = Vector2(96,96)
		button.pressed.connect(func(): person_selected.emit(i))
		add_child(button)
		avatars.append(button)
	pause_button = Button.new()
	pause_button.position = Vector2(1197,661)
	pause_button.size = Vector2(45,32)
	pause_button.text = "Ⅱ"
	pause_button.tooltip_text = "Pausa · Esc"
	pause_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	pause_button.add_theme_color_override("font_color",Color("e7dfbf"))
	pause_button.add_theme_font_size_override("font_size",17)
	for state in ["normal", "hover", "pressed", "focus"]:
		var style := TejoPerson._box(Color("34594e") if state == "normal" else Color("527461"),8)
		pause_button.add_theme_stylebox_override(state,style)
	pause_button.pressed.connect(func(): pause_requested.emit())
	add_child(pause_button)
	select(0)

func select(index: int) -> void:
	selected = index
	for i in avatars.size():
		avatars[i].active = i == selected
		avatars[i].queue_redraw()
	queue_redraw()

func label_at(point: Vector2, value: String, size_value: int, color: Color) -> void:
	draw_string(font,point,value,HORIZONTAL_ALIGNMENT_LEFT,-1,size_value,color)

func centered(point: Vector2, value: String, size_value: int, color: Color) -> void:
	var width := font.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,size_value).x
	label_at(point-Vector2(width/2,0),value,size_value,color)

func keycap(point: Vector2, value: String, width: float = 24) -> void:
	var box := TejoPerson._box(Color(0.91,0.91,0.76,0.12),4)
	box.set_border_width_all(1)
	box.border_color = Color(0.88,0.89,0.75,0.24)
	draw_style_box(box,Rect2(point,Vector2(width,22)))
	centered(point+Vector2(width/2,15),value,11,Color("f0e7c8"))

func _draw() -> void:
	var dark := Color("eee4c9")
	# Pale ink keeps the title legible against the forest. A quiet title leaves the entire center of the screen to the scene.
	draw_line(Vector2(37,42),Vector2(44,35),dark,2,true)
	draw_line(Vector2(44,35),Vector2(51,42),dark,2,true)
	draw_line(Vector2(37,51),Vector2(44,44),dark,2,true)
	draw_line(Vector2(44,44),Vector2(51,51),dark,2,true)
	label_at(Vector2(63,53),"tejo",31,dark)
	draw_line(Vector2(143,34),Vector2(143,54),Color("a9b29a"),1,true)
	label_at(Vector2(157,47),"UMA AVENTURA A DOIS",10,Color("d4d4ba"))
	label_at(Vector2(38,84),"DOIS AMIGOS. UM CAMINHO.",10,Color("c0c6ae"))
	if not dialogue_active:
		# Location marker sits below the trail, on the dark painted foliage.
		draw_arc(Vector2(43,606),5,0,TAU,20,Color("d8d9be"),1.2,true)
		draw_circle(Vector2(43,606),1.7,Color("d8d9be"))
		label_at(Vector2(57,610),"SERRA DE SINTRA",11,Color("eee4c9"))
		label_at(Vector2(38,630),"Capítulo 01  /  " + area_title,11,Color("c0c6ae"))
		var who := "Te" if selected == 0 else "Jo"
		var other := "Jo" if selected == 0 else "Te"
		var status := who+" à frente. "+other+" vai contigo."
		var status_width := font.get_string_size(status,HORIZONTAL_ALIGNMENT_LEFT,-1,11).x
		label_at(Vector2(1240-status_width,622),status,11,Color("d8d9be"))
		var tray := TejoPerson._box(Color(0.15,0.29,0.25,0.93),10)
		tray.border_color = Color(0.77,0.82,0.63,0.12)
		tray.set_border_width_all(1)
		if open_world:
			draw_style_box(tray,Rect2(275,655,730,44))
			keycap(Vector2(290,666),"WASD",48)
			label_at(Vector2(347,681),"explorar",11,Color("e0dfbf"))
			keycap(Vector2(419,666),"SHIFT",47)
			label_at(Vector2(475,681),"correr",11,Color("e0dfbf"))
			keycap(Vector2(535,666),"T")
			label_at(Vector2(567,681),"falar",11,Color("e0dfbf"))
			keycap(Vector2(615,666),"M")
			label_at(Vector2(647,681),"mapa",11,Color("e0dfbf"))
			keycap(Vector2(702,666),"TAB",35)
			label_at(Vector2(746,681),"trocar",11,Color("e0dfbf"))
			keycap(Vector2(810,666),"ESC",34)
			label_at(Vector2(853,681),"pausa",11,Color("e0dfbf"))
		else:
			draw_style_box(tray,Rect2(300,655,680,44))
			keycap(Vector2(315,666),"T")
			label_at(Vector2(347,681),"falar",11,Color("e0dfbf"))
			keycap(Vector2(397,666),"A")
			keycap(Vector2(425,666),"D")
			label_at(Vector2(458,681),"mover",11,Color("e0dfbf"))
			draw_line(Vector2(492,668),Vector2(492,686),Color(0.8,0.85,0.7,0.2),1,true)
			keycap(Vector2(508,666),"ESPAÇO",61)
			label_at(Vector2(579,681),"saltar",11,Color("e0dfbf"))
			draw_line(Vector2(628,668),Vector2(628,686),Color(0.8,0.85,0.7,0.2),1,true)
			keycap(Vector2(644,666),"TAB",35)
			label_at(Vector2(688,681),"trocar",11,Color("e0dfbf"))
			draw_line(Vector2(739,668),Vector2(739,686),Color(0.8,0.85,0.7,0.2),1,true)
			keycap(Vector2(755,666),"ESC",34)
			label_at(Vector2(800,681),"pausa",11,Color("e0dfbf"))
	if paused:
		draw_rect(Rect2(0,0,1280,720),Color(0.12,0.23,0.20,0.65))
		var panel := TejoPerson._box(Color("f1e6c7"),18)
		draw_style_box(panel,Rect2(415,265,450,190))
		centered(Vector2(640,309),"SEM PRESSAS",11,Color("8b9679"))
		centered(Vector2(640,359),"Uma pequena pausa.",27,Color("355b50"))
		centered(Vector2(640,401),"Esc ou Ⅱ para continuar",13,Color("7a856b"))

func keycap_light(point: Vector2, value: String, width: float) -> void:
	var box := TejoPerson._box(Color(0.96,0.93,0.78,0.4),4)
	box.set_border_width_all(1)
	box.border_color = Color(0.4,0.5,0.37,0.25)
	draw_style_box(box,Rect2(point,Vector2(width,21)))
	centered(point+Vector2(width/2,14),value,10,Color("627b65"))
