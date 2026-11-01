extends Control

signal person_selected(index: int)
signal debug_time_toggled

const AvatarButton = preload("res://scripts/avatar_button.gd")
var open_world := false
var area_title := "Trilho dos eucaliptos"
var selected := 0
var paused := false
var dialogue_active := false
var avatars: Array[Button] = []
var font: Font = ThemeDB.fallback_font
var day_cycle: RefCounted
var map_open := false
var comment_time := 0.0
var comment_panel: Panel
var comment_label: Label
var debug_time_button: Button

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if day_cycle!=null and OS.is_debug_build():
		debug_time_button = Button.new()
		debug_time_button.name = "DebugDayNight"
		debug_time_button.toggle_mode = true
		debug_time_button.position = Vector2(944,67)
		debug_time_button.size = Vector2(56,26)
		debug_time_button.tooltip_text = "Debug: alternar dia / noite"
		debug_time_button.add_theme_font_size_override("font_size",12)
		debug_time_button.add_theme_color_override("font_color",Color("b9c4ab"))
		debug_time_button.toggled.connect(func(_pressed: bool): debug_time_toggled.emit())
		add_child(debug_time_button)
		_sync_debug_time_button()
	for i in 2:
		var button := AvatarButton.new()
		button.kind = i
		button.position = Vector2(1030+i*110,28)
		button.size = Vector2(96,96)
		button.pressed.connect(func(): person_selected.emit(i))
		add_child(button)
		avatars.append(button)
	select(0)
	comment_panel = Panel.new()
	comment_panel.name = "PathComment"
	comment_panel.position = Vector2(566,578)
	comment_panel.size = Vector2(686,118)
	comment_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	comment_panel.add_theme_stylebox_override("panel",TejoPerson._box(Color("233e3e"),12))
	add_child(comment_panel)
	var title := Label.new()
	title.position = Vector2(18,10)
	title.text = "NOTAS DO CAMINHO"
	title.add_theme_font_size_override("font_size",13)
	title.add_theme_color_override("font_color",Color("ead5a5"))
	comment_panel.add_child(title)
	comment_label = Label.new()
	comment_label.position = Vector2(18,34)
	comment_label.size = Vector2(650,76)
	comment_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	comment_label.add_theme_font_size_override("font_size",18)
	comment_label.add_theme_color_override("font_color",Color("fff4db"))
	comment_panel.add_child(comment_label)
	comment_panel.hide()

func show_comment(value: String) -> void:
	if value.is_empty(): return
	comment_label.text = value
	var height := 52+22*clampi(comment_label.get_line_count(),1,3)
	comment_panel.size.y = height
	comment_panel.position.y = 696-height
	comment_label.size.y = height-38
	comment_time = clampf(value.length()/18.0,4.5,9)
	comment_panel.visible = not paused and not map_open and not dialogue_active

func _process(delta: float) -> void:
	_sync_debug_time_button()
	if not is_instance_valid(comment_panel): return
	comment_panel.visible = comment_time>0 and not paused and not map_open and not dialogue_active
	if comment_panel.visible: comment_time = maxf(0,comment_time-delta)

func _sync_debug_time_button() -> void:
	if debug_time_button==null: return
	var night: bool = day_cycle.minutes<360 or day_cycle.minutes>=1200
	debug_time_button.set_pressed_no_signal(night)
	debug_time_button.text = "Noite" if night else "Dia"

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
		draw_style_box(TejoPerson._box(Color("233e3e"),14),Rect2(758,24,254,118))
		draw_string(font,Vector2(776,51),"Serra de Sintra",HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color("fff4db"))
		draw_circle(Vector2(783,80),11,Color("ead5a5"),false,1.5,true)
		var angle: float = day_cycle.minutes / 720.0 * TAU - PI / 2.0
		draw_line(Vector2(783,80),Vector2(783,80)+Vector2.from_angle(angle)*6,Color("ead5a5"),2,true)
		angle = fmod(day_cycle.minutes,60.0) / 60.0 * TAU - PI / 2.0
		draw_line(Vector2(783,80),Vector2(783,80)+Vector2.from_angle(angle)*9,Color("ead5a5"),1,true)
		draw_string(font,Vector2(806,91),day_cycle.clock_text(),HORIZONTAL_ALIGNMENT_LEFT,-1,30,Color("fff4db"))
		draw_string(font,Vector2(776,123),"%s · Dia %d" % [day_cycle.phase(),day_cycle.day],HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("ead5a5"))
	if not paused:
		return
	draw_rect(Rect2(0,0,1280,720),Color(0.12,0.23,0.20,0.65))
	draw_style_box(TejoPerson._box(Color("f1e6c7"),18),Rect2(415,245 if open_world else 265,450,290 if open_world else 190))
	centered(Vector2(640,320 if open_world else 350),"Em pausa",27,Color("355b50"))
	centered(Vector2(640,370 if open_world else 401),"Esc para continuar",13,Color("7a856b"))
