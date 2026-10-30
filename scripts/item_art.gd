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
	var region := REGIONS[int(item.art)]
	var scale_value := minf(box.size.x/region.size.x,box.size.y/region.size.y)
	var extent := region.size*scale_value
	canvas.draw_texture_rect_region(ATLAS,Rect2(box.get_center()-extent*0.5,extent),region)
