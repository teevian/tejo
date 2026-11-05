extends RefCounted
const ATLAS: Texture2D = preload("res://assets/items/forest-items.png")
const REGIONS: Array[Rect2] = [Rect2(112,166,284,213),Rect2(586,72,360,376),Rect2(1060,70,442,404),Rect2(93,603,315,306),Rect2(523,551,487,380),Rect2(1079,537,419,412)]
const ITEMS: Array[Dictionary] = [
	{"type":"pebble","name":"Pedrinha","porte":1,"art":0},
	{"type":"pinecone","name":"Pinha","porte":1,"art":1},
	{"type":"twig","name":"Ramo caído","porte":2,"art":2},
	{"type":"shard","name":"Fragmento de cerâmica","porte":1,"art":3},
	{"type":"stone","name":"Pedra com líquenes","porte":3,"art":4},
	{"type":"sticks","name":"Molho de ramos","porte":2,"art":5}]

static func draw_item(canvas: CanvasItem, item: Dictionary, box: Rect2) -> void:
	var chestnut: Dictionary = preload("res://scripts/chestnut_catalog.gd").product(str(item.get("type","")))
	if not chestnut.is_empty():
		var pose: Dictionary = preload("res://data/village/chestnut-art.json").data.food[int(chestnut.art)]
		var source := Rect2(pose.rect[0],pose.rect[1],pose.rect[2],pose.rect[3])
		var factor: float = minf(box.size.x/source.size.x,box.size.y/source.size.y)*.92
		canvas.draw_texture_rect_region(preload("res://assets/items/chestnut-portions.png"),Rect2(box.get_center()-source.size*factor*.5,source.size*factor),source)
		return
	if not preload("res://scripts/bakery_catalog.gd").product(str(item.get("type",""))).is_empty():
		var pose: Dictionary = preload("res://data/village/bakery-art.json").data.food[int(item.art)]
		var source := Rect2(pose.rect[0],pose.rect[1],pose.rect[2],pose.rect[3])
		var factor: float = minf(box.size.x/source.size.x,box.size.y/source.size.y)*.92
		canvas.draw_texture_rect_region(preload("res://assets/items/bakery-food.png"),Rect2(box.get_center()-source.size*factor*.5,source.size*factor),source)
		return
	if item.get("type","")=="neighbour_exam":
		var pose: Dictionary = preload("res://data/village/neighbourhood-art.json").data.props[6]
		var source := Rect2(pose.rect[0],pose.rect[1],pose.rect[2],pose.rect[3])
		var factor: float = minf(box.size.x/source.size.x,box.size.y/source.size.y)*.88
		canvas.draw_texture_rect_region(preload("res://assets/world/village/neighbours-objects.png"),Rect2(box.get_center()-source.size*factor*.5,source.size*factor),source)
		return
	if item.get("type","")=="neighbour_pen":
		var center := box.get_center()
		var size: float = minf(box.size.x,box.size.y)*.34
		canvas.draw_line(center+Vector2(-size,size),center+Vector2(size,-size),Color("39433d"),5,true)
		canvas.draw_line(center+Vector2(-size*.7,size*.7),center+Vector2(size,-size),Color("bd5549"),3,true)
		return
	if str(item.get("type","")).begins_with("living_"):
		var center := box.get_center()
		var size: float = minf(box.size.x,box.size.y)*.35
		var type: String = str(item.type).trim_prefix("living_")
		match type:
			"hat":
				canvas.draw_style_box(TejoPerson._box(Color("bd9c62"),8),Rect2(center-Vector2(size,size*.3),Vector2(size*2,size*.6)))
				canvas.draw_style_box(TejoPerson._box(Color("aa8c55"),5),Rect2(center-Vector2(size*.6,size),Vector2(size*1.2,size)))
			"grain":
				canvas.draw_style_box(TejoPerson._box(Color("b89b6d"),4),Rect2(center-Vector2(size*.65,size),Vector2(size*1.3,size*1.8)))
				for i in 8: canvas.draw_circle(center+Vector2(sin(i*3)*size*.4,cos(i*2)*size*.6),2,Color("e3ce8c"))
			"bottle","water":
				canvas.draw_style_box(TejoPerson._box(Color("92b8ba") if type=="water" else Color("c6d9cf"),4),Rect2(center-Vector2(size*.4,size*.7),Vector2(size*.8,size*1.7)))
				canvas.draw_rect(Rect2(center-Vector2(size*.2,size),Vector2(size*.4,size*.5)),Color("97aaa5"))
			"clock","repaired_clock":
				canvas.draw_circle(center,size,Color("b79c55")); canvas.draw_circle(center,size*.8,Color("e4dbbe")); canvas.draw_line(center,center-Vector2(0,size*.6),Color("4b6053"),2); canvas.draw_line(center,center+Vector2(size*.5,0),Color("4b6053"),2)
			"key": canvas.draw_arc(center-Vector2(size*.4,0),size*.4,0,TAU,14,Color("d3b45e"),3); canvas.draw_line(center,center+Vector2(size,0),Color("d3b45e"),3)
			"cap","button": canvas.draw_circle(center,size*.6,Color("879f92")); canvas.draw_arc(center,size*.4,0,TAU,16,Color("d9c9a2"),1)
			"parcel","box": canvas.draw_style_box(TejoPerson._box(Color("b69568"),3),Rect2(center-Vector2(size,size*.75),Vector2(size*2,size*1.5))); canvas.draw_line(center-Vector2(0,size*.75),center+Vector2(0,size*.75),Color("e2d3a9"),3)
			_:
				canvas.draw_style_box(TejoPerson._box(Color("e8dabc"),2),Rect2(center-Vector2(size,size*.65),Vector2(size*2,size*1.3)))
				canvas.draw_line(center-Vector2(size*.7,0),center+Vector2(size*.7,0),Color("7e9e8b"),2)
		return
	if str(item.get("type","")).begins_with("festival_"):
		var center := box.get_center()
		var size: float = minf(box.size.x,box.size.y)*.32
		match item.type:
			"festival_fruit":
				canvas.draw_circle(center,size,[Color("bd5146"),Color("e7983d"),Color("b4b95e")][int(item.get("variant",0))%3])
				canvas.draw_line(center-Vector2(0,size*.65),center-Vector2(-2,size*1.3),Color("6b633b"),2)
			"festival_sweets":
				canvas.draw_style_box(TejoPerson._box(Color("c38b4c"),5),Rect2(center-Vector2(size,size*.5),Vector2(size*2,size)))
			"festival_flowers":
				canvas.draw_line(center+Vector2(0,size),center-Vector2(0,size),Color("6d8c4b"),2)
				for i in 5: canvas.draw_circle(center-Vector2(0,size*.5)+Vector2.from_angle(i*TAU/5)*size*.4,size*.33,Color("d9859a"))
			"festival_medal":
				canvas.draw_colored_polygon(PackedVector2Array([center+Vector2(-size,-size*1.2),center+Vector2(size,-size*1.2),center+Vector2(0,size*.2)]),Color("6a93b5"))
				canvas.draw_circle(center+Vector2(0,size*.35),size*.7,Color("d6b457"))
		return
	if item.get("type","")=="raffle_ticket":
		var ticket := Rect2(box.get_center()-box.size*Vector2(.42,.3),box.size*Vector2(.84,.6))
		canvas.draw_style_box(TejoPerson._box(Color("e9d594"),3),ticket)
		canvas.draw_line(ticket.position+Vector2(ticket.size.x*.72,3),ticket.end-Vector2(ticket.size.x*.28,3),Color("6a7750"),1)
		canvas.draw_string(ThemeDB.fallback_font,ticket.position+Vector2(4,ticket.size.y*.65),"RIFA",HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("395444"))
		return
	if item.get("type","")=="gelato":
		var center := box.get_center()
		var size := minf(box.size.x,box.size.y)*.38
		canvas.draw_colored_polygon(PackedVector2Array([center+Vector2(-size*.65,0),center+Vector2(size*.65,0),center+Vector2(0,size*1.3)]),Color("c89150"))
		var flavors := [Color("b5c58b"),Color("dfa1a4"),Color("eee2c6")]
		canvas.draw_circle(center-Vector2(0,size*.35),size*.7,flavors[int(item.get("flavor",0))%3])
		return
	if item.get("type","")=="dog_food":
		preload("res://scripts/puppy_art.gd").draw_food(canvas,box)
		return
	var region := REGIONS[int(item.art)]
	var scale_value := minf(box.size.x/region.size.x,box.size.y/region.size.y)
	var extent := region.size*scale_value
	canvas.draw_texture_rect_region(ATLAS,Rect2(box.get_center()-extent*0.5,extent),region)
