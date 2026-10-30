extends Control
signal drop_requested(owner: int, index: int)
const ItemArt = preload("res://scripts/item_art.gd")
var people: Array = []
var selected := 0
var entries: Array[Button] = []

class Entry:
	extends Button
	var item: Dictionary = {}
	func _ready() -> void:
		focus_mode = Control.FOCUS_NONE
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		for state in ["normal","hover","pressed","focus","disabled"]:
			add_theme_stylebox_override(state,StyleBoxEmpty.new())
		mouse_entered.connect(queue_redraw)
		mouse_exited.connect(queue_redraw)
	func _draw() -> void:
		var paper := TejoPerson._box(Color("d9d6b9") if not item.is_empty() else Color("3d5848"),6)
		paper.border_color = Color("e0c88e") if is_hovered() and not item.is_empty() else Color("73846b")
		paper.set_border_width_all(1)
		draw_style_box(paper,Rect2(Vector2.ZERO,size))
		if item.is_empty():
			draw_circle(size*0.5,1.5,Color("7d8c71"))
		else:
			ItemArt.draw_item(self,item,Rect2(3,2,size.x-6,size.y-9))
			draw_string(ThemeDB.fallback_font,Vector2(size.x-11,size.y-3),str(item.porte),HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("304c3e"))

func _ready() -> void:
	position = Vector2(1007,147)
	size = Vector2(237,99)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for owner in 2:
		people[owner].inventory.changed.connect(refresh)
		for index in 5:
			var entry := Entry.new()
			entry.position = Vector2(12+index*44,32)
			entry.size = Vector2(38,40)
			entry.pressed.connect(func():drop_requested.emit(owner,index))
			add_child(entry)
			entries.append(entry)
	refresh()

func refresh() -> void:
	for owner in 2:
		for index in 5:
			var entry = entries[owner*5+index]
			entry.item = people[owner].inventory.items[index] if index<people[owner].inventory.items.size() else {}
			entry.disabled = entry.item.is_empty()
			entry.visible = owner==selected
			entry.tooltip_text = "" if entry.item.is_empty() else "%s · porte %d\nBolsa de %s · clicar para pousar no chão"%[entry.item.name,entry.item.porte,people[owner].name]
			entry.queue_redraw()
	queue_redraw()

func _draw() -> void:
	var font := ThemeDB.fallback_font
	var owner := selected
	var y := 0.0
	var paper := TejoPerson._box(Color(0.15,0.29,0.24,0.95),10)
	paper.border_color = Color("dbc58e")
	paper.set_border_width_all(2)
	draw_style_box(paper,Rect2(0,y,237,99))
	draw_string(font,Vector2(13,y+21),"BOLSA DE "+str(people[owner].name).to_upper(),HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("eee4c9"))
	var used: int = people[owner].inventory.used_porte()
	draw_string(font,Vector2(161,y+21),"porte %d/5"%used,HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("e3d3aa"))
	for segment in 5:
		draw_style_box(TejoPerson._box(Color("d7c28c") if segment<used else Color("526b51"),2),Rect2(13+segment*43,y+82,37,4))
