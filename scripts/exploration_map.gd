extends Control
var world: Node2D
var people: Array = []
var explored: Dictionary = {}
var discovered: Dictionary = {}
const TILE := 120.0
const PAPER := Rect2(373,75,534,600)
var selected := 0

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	hide()

func record_positions() -> void:
	for person in people:
		var at: Vector2 = person.position
		var cell := Vector2i(at/TILE)
		for x in range(-3,4):
			for y in range(-3,4):
				var point := cell+Vector2i(x,y)
				if Vector2(x,y).length() < 3.5:
					explored[point] = true
		for place in world.landmarks:
			if at.distance_to(place.position) < place.radius+100:
				discovered[place.id] = true
	if visible:
		queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(0,0,1280,720),Color(0.08,0.17,0.14,0.93))
	var paper := TejoPerson._box(Color("e8ddbb"),12)
	paper.set_border_width_all(2)
	paper.border_color = Color("a8ad85")
	draw_style_box(paper,PAPER.grow(10))
	for index in 4:
		var tile_rect := Rect2(PAPER.position+Vector2(index%2,floori(index/2.0))*Vector2(PAPER.size.x*0.5,PAPER.size.y/3.0),Vector2(PAPER.size.x*0.5,PAPER.size.y/3.0))
		draw_texture_rect(world.TERRAIN[index],tile_rect,false,Color(0.91,0.92,0.79))
	draw_texture_rect(world.SOUTH,Rect2(PAPER.position+Vector2(0,PAPER.size.y*2.0/3.0),Vector2(PAPER.size.x,PAPER.size.y/3.0)),false)
	var cell_size: Vector2 = PAPER.size / (world.WORLD_SIZE/TILE)
	for x in int(world.WORLD_SIZE.x/TILE):
		for y in int(world.WORLD_SIZE.y/TILE):
			if not explored.has(Vector2i(x,y)):
				draw_rect(Rect2(PAPER.position+Vector2(x,y)*cell_size,cell_size+Vector2.ONE),Color("344c3e"))
	var font := ThemeDB.fallback_font
	for place in world.landmarks:
		if not discovered.has(place.id):
			continue
		var point: Vector2 = PAPER.position + place.position/world.WORLD_SIZE*PAPER.size
		draw_circle(point,3,Color("e9d698"))
		var label_position := point+Vector2(6,-6)
		label_position.x = minf(label_position.x,PAPER.end.x-font.get_string_size(place.name,HORIZONTAL_ALIGNMENT_LEFT,-1,12).x-6)
		draw_string_outline(font,label_position,place.name,HORIZONTAL_ALIGNMENT_LEFT,-1,12,3,Color("22392e"))
		draw_string(font,label_position,place.name,HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("fff0c9"))
	for i in people.size():
		var point: Vector2 = PAPER.position + people[i].position/world.WORLD_SIZE*PAPER.size
		draw_circle(point,7 if i==selected else 4,Color("f3dda0") if i==selected else Color("b7c8b8"))
		draw_circle(point,2,Color("324b3c"))
	draw_string(font,Vector2(240,45),"SERRA DE SINTRA  /  O nosso caminho",HORIZONTAL_ALIGNMENT_LEFT,-1,21,Color("e9dfc3"))
	draw_string(font,Vector2(240,706),"O mapa revela-se à medida que exploras.                         M ou Esc · voltar",HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("c5cbb0"))
