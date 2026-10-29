extends Button
var kind := 0
var active := false
var font: Font = ThemeDB.fallback_font

func _ready() -> void:
	flat = true
	focus_mode = Control.FOCUS_NONE
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	tooltip_text = "Controlar Te" if kind == 0 else "Controlar Jo"
	for state in ["normal","hover","pressed","focus"]:
		add_theme_stylebox_override(state,StyleBoxEmpty.new())
	mouse_entered.connect(queue_redraw)
	mouse_exited.connect(queue_redraw)

func _draw() -> void:
	if active:
		var outline := StyleBoxFlat.new()
		outline.bg_color = Color("eed6a0")
		outline.set_corner_radius_all(16)
		draw_style_box(outline,Rect2(Vector2(-3,-3),size+Vector2(6,6)))
	var box := StyleBoxFlat.new()
	box.bg_color = Color("f7edcf") if active else Color("e5dfc5")
	box.set_corner_radius_all(13)
	box.border_color = Color("365d4b") if active else Color("a4ad91")
	box.set_border_width_all(4 if active else 1)
	box.shadow_color = Color(0.12,0.22,0.17,0.18)
	box.shadow_size = 4
	box.shadow_offset = Vector2(0,3)
	if is_hovered():
		box.bg_color = box.bg_color.lightened(0.06)
	draw_style_box(box,Rect2(Vector2.ZERO,size))
	draw_set_transform(Vector2(48,35),0,Vector2.ONE*1.14)
	TejoPerson.portrait(self,Vector2.ZERO,kind)
	draw_set_transform(Vector2.ZERO)
	var title := "Te" if kind == 0 else "Jo"
	var width := font.get_string_size(title,HORIZONTAL_ALIGNMENT_LEFT,-1,18).x
	draw_string(font,Vector2((size.x-width)/2,82),title,HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("354e46"))
