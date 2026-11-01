extends Control
const AvatarButton = preload("res://scripts/avatar_button.gd")
const Route = preload("res://scripts/climbing_route.gd")
var scene: Node2D
var font: Font = ThemeDB.fallback_font
var avatars: Array[Button] = []
var turn_buttons: Array[Button] = []
var note := ""
var note_time := 0.0
var pause_panel: Panel
var arrival_time := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for i in 2:
		var avatar := AvatarButton.new()
		avatar.kind = i
		avatar.position = Vector2(1030+i*110,24)
		avatar.size = Vector2(96,96)
		avatar.pressed.connect(func(): scene._select_person(i))
		add_child(avatar)
		avatars.append(avatar)
	for i in 2:
		var turn := Button.new()
		turn.text = "Q  ↶" if i==0 else "↷  E"
		turn.focus_mode = Control.FOCUS_NONE
		turn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		turn.tooltip_text = "Rodar o penedo um quarto de volta"
		turn.position = Vector2(520+i*188,39)
		turn.size = Vector2(54,46)
		turn.add_theme_font_size_override("font_size",17)
		turn.add_theme_stylebox_override("normal",box(Color("36594c"),8))
		turn.add_theme_stylebox_override("hover",box(Color("537765"),8))
		turn.add_theme_stylebox_override("disabled",box(Color("35443b"),8))
		turn.add_theme_color_override("font_color",Color("f4e7c6"))
		turn.pressed.connect(func(): scene.rotate_world(-1 if i==0 else 1))
		add_child(turn)
		turn_buttons.append(turn)
	pause_panel = Panel.new()
	pause_panel.position = Vector2(395,205)
	pause_panel.size = Vector2(490,320)
	pause_panel.add_theme_stylebox_override("panel",box(Color("eee5cc"),18))
	add_child(pause_panel)
	var title := Label.new()
	title.text = "Uma pausa na subida"
	title.position = Vector2(35,24)
	title.add_theme_font_size_override("font_size",27)
	title.add_theme_color_override("font_color",Color("365247"))
	pause_panel.add_child(title)
	for entry in [["Continuar",func(): scene.get_tree().paused = false; refresh_pause()],["Recomeçar a escalada",scene.restart],["Voltar à floresta",scene.leave]]:
		var button := Button.new()
		button.text = entry[0]
		button.position = Vector2(35,85+pause_panel.get_child_count()*55-55)
		button.size = Vector2(420,44)
		button.add_theme_font_size_override("font_size",18)
		button.add_theme_stylebox_override("normal",box(Color("36594c"),7))
		button.add_theme_stylebox_override("hover",box(Color("537765"),7))
		button.add_theme_color_override("font_color",Color("f4e7c6"))
		button.pressed.connect(entry[1])
		pause_panel.add_child(button)
	pause_panel.hide()

func select(index: int) -> void:
	for i in avatars.size():
		avatars[i].active = i==index
		avatars[i].queue_redraw()

func box(color: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	return style

func message(value: String, seconds := 4.5) -> void:
	note = value
	note_time = maxf(seconds,value.length()/23.0)
	queue_redraw()

func reached_summit() -> void:
	arrival_time = 9

func refresh_pause() -> void:
	pause_panel.visible = scene.get_tree().paused
	refresh_turns()
	queue_redraw()

func refresh_turns() -> void:
	for turn in turn_buttons:
		turn.disabled = not scene.space.can_turn()

func _process(delta: float) -> void:
	refresh_turns()
	if scene.get_tree().paused: return
	if scene.dialogue_lines.is_empty(): note_time = maxf(0,note_time-delta)
	arrival_time = maxf(0,arrival_time-delta)
	queue_redraw()

func centered(value: String, y: float, size_value: int, color: Color) -> void:
	var width := font.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,size_value).x
	draw_string(font,Vector2((1280-width)*0.5,y),value,HORIZONTAL_ALIGNMENT_LEFT,-1,size_value,color)

func _draw() -> void:
	if scene.people.is_empty(): return
	draw_style_box(box(Color(0.12,0.22,0.20,0.92),12),Rect2(26,24,340,132))
	draw_string(font,Vector2(46,51),"SERRA DE SINTRA · ESCALADA",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("d1c7a6"))
	draw_string(font,Vector2(46,81),"Penedo da Amizade",HORIZONTAL_ALIGNMENT_LEFT,-1,24,Color("f5ead0"))
	var feet := maxf(scene.people[0].position.y,scene.people[1].position.y)
	var rise := clampf((Route.START_Y-feet)/(Route.START_Y-1430),0,1)
	draw_rect(Rect2(47,100,240,3),Color("5d7569"))
	draw_rect(Rect2(47,100,240*rise,3),Color("ddc58b"))
	draw_string(font,Vector2(301,106),"%d m"%maxi(0,roundi((Route.START_Y-feet)/80)),HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("e9dcba"))
	var separation: float = scene.rope_separation()
	var tension := clampf(separation/Route.ROPE_LENGTH,0,1)
	var rope_color := Color("e9b67b") if tension>0.92 else Color("c8c8aa")
	draw_string(font,Vector2(47,135),"Corda %.1f / %.0f m"%[separation/80,Route.ROPE_LENGTH/80],HORIZONTAL_ALIGNMENT_LEFT,-1,12,rope_color)
	draw_rect(Rect2(220,127,118,3),Color("5d7569"))
	draw_rect(Rect2(220,127,118*tension,3),rope_color)
	var shelf: int = scene.people[scene.selected].shelf
	if shelf>=0:
		var title: String = scene.platforms[shelf].get("title",Route.TITLES.get(Route.stage(shelf),""))
		if not title.is_empty():
			var title_width := font.get_string_size(title,HORIZONTAL_ALIGNMENT_LEFT,-1,14).x
			draw_style_box(box(Color(0.12,0.22,0.20,0.90),7),Rect2(26,166,title_width+28,32))
			draw_string(font,Vector2(40,187),title,HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("e4d5b4"))
	draw_style_box(box(Color(0.12,0.22,0.20,0.94),12),Rect2(510,24,262,85))
	var face: String = scene.space.FACE_NAMES[scene.space.next_view if scene.space.rotating else scene.space.view]
	var face_width := font.get_string_size(face,HORIZONTAL_ALIGNMENT_LEFT,-1,17).x
	draw_string(font,Vector2(641-face_width*0.5,59),face,HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("f5ead0"))
	for i in 4:
		draw_circle(Vector2(617+i*16,80),3.5,Color("ddc58b") if i==scene.space.view else Color("5d7569"))
	draw_string(font,Vector2(597,99),"RODAR O MUNDO",HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("d1c7a6"))
	if not scene.dialogue_lines.is_empty(): return
	var prompt: String = scene.context_prompt()
	if not prompt.is_empty():
		var width := font.get_string_size(prompt,HORIZONTAL_ALIGNMENT_LEFT,-1,17).x+42
		draw_style_box(box(Color(0.13,0.22,0.20,0.94),10),Rect2((1280-width)*0.5,653,width,43))
		centered(prompt,680,17,Color("f4e6c6"))
	if note_time>0 and not note.is_empty():
		# Wrapped text stays legible on a textured rock face and at smaller windows.
		var paragraph := TextParagraph.new()
		paragraph.add_string(note,font,18)
		paragraph.width = 680
		paragraph.alignment = HORIZONTAL_ALIGNMENT_CENTER
		var height := paragraph.get_size().y+28
		draw_style_box(box(Color(0.13,0.22,0.20,0.94),10),Rect2(286,637-height,708,height))
		paragraph.draw(get_canvas_item(),Vector2(300,650-height),Color("f0e5c9"))
	if arrival_time>0:
		draw_style_box(box(Color(0.13,0.22,0.20,0.94),14),Rect2(390,167,500,100))
		centered("Chegaram os dois.",207,27,Color("f1dfb7"))
		centered("Penedo da Amizade",241,19,Color("c7d3b5"))
	if scene.get_tree().paused: draw_rect(Rect2(0,0,1280,720),Color(0.07,0.15,0.13,0.58))
