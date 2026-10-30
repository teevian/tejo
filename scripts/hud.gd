extends Control

signal person_selected(index: int)

const AvatarButton = preload("res://scripts/avatar_button.gd")
var open_world := false
var area_title := "Trilho dos eucaliptos"
var selected := 0
var paused := false
var dialogue_active := false
var avatars: Array[Button] = []
var font: Font = ThemeDB.fallback_font
var day_cycle: RefCounted

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
	select(0)

func select(index: int) -> void:
	selected = index
	for i in avatars.size():
		avatars[i].active = i == selected
		avatars[i].queue_redraw()
	queue_redraw()

func centered(point: Vector2, value: String, size_value: int, color: Color) -> void:
	var width := font.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,size_value).x
	draw_string(font,point-Vector2(width/2,0),value,HORIZONTAL_ALIGNMENT_LEFT,-1,size_value,color)

func _draw() -> void:
	if day_cycle != null:
		draw_style_box(TejoPerson._box(Color("233e3e"),14),Rect2(24,24,222,94))
		draw_circle(Vector2(49,52),11,Color("ead5a5"),false,1.5,true)
		var angle: float = day_cycle.minutes / 720.0 * TAU - PI / 2.0
		draw_line(Vector2(49,52),Vector2(49,52)+Vector2.from_angle(angle)*6,Color("ead5a5"),2,true)
		angle = fmod(day_cycle.minutes,60.0) / 60.0 * TAU - PI / 2.0
		draw_line(Vector2(49,52),Vector2(49,52)+Vector2.from_angle(angle)*9,Color("ead5a5"),1,true)
		draw_string(font,Vector2(72,63),day_cycle.clock_text(),HORIZONTAL_ALIGNMENT_LEFT,-1,30,Color("fff4db"))
		draw_string(font,Vector2(40,97),"%s · Dia %d" % [day_cycle.phase(),day_cycle.day],HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("ead5a5"))
	if not paused:
		return
	draw_rect(Rect2(0,0,1280,720),Color(0.12,0.23,0.20,0.65))
	draw_style_box(TejoPerson._box(Color("f1e6c7"),18),Rect2(415,265,450,190))
	centered(Vector2(640,350),"Em pausa",27,Color("355b50"))
	centered(Vector2(640,401),"Esc para continuar",13,Color("7a856b"))
