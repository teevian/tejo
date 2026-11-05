extends Node2D
## Measured native props plus small code-native gameplay marks; no new blocking bases.
var director: Node2D
var kind := ""
var key := ""
var label := ""
var resident_owner: CharacterBody2D
var building: Node2D
var contact := Vector2.ZERO
var pane := Rect2()
var state := 0
var clock := 0.0
var mark: Dictionary = {}
var shutter_sources: Array[Dictionary] = []
var shutter_closed := 0.0
func _ready() -> void:
	if kind!="window": material = director.living_paint
func available() -> bool:
	if kind=="window": return is_instance_valid(resident_owner) and (resident_owner.state=="window" or get_meta("peek_visible",false))
	return visible
func interaction_position() -> Vector2: return contact if kind in ["window","bell"] else global_position
func interaction_prompt() -> String:
	return {"feed":"Alimentar os pombos","cat":"Fazer festas ao Sardinha","shop":"Observar a montra de "+label,"window":"Chamar "+(str(resident_owner.entry.name) if is_instance_valid(resident_owner) else "o morador")+" à janela","bell":"Tocar à campainha · "+label,"chalk":"Desenhar no chão com giz","fountain":"Ouvir e usar a fonte","bin":"Examinar o caixote e ajudar a limpar","vending":"Escolher um postal","board":"Consultar o placard da comunidade","barter":"Ver as trocas da Jacinta","chest":"Abrir os achados e perdidos","sound":"Ouvir este som da vila","clue":"Examinar o pormenor do quadro","hat":"Recuperar o chapéu levado pelo vento","box":"Recolher a encomenda caída","pot":"Rodar o vaso para o sol"}.get(kind,"Observar "+label)
func interact(person: CharacterBody2D) -> String:
	if kind=="window" and is_instance_valid(resident_owner):
		if resident_owner.entry.get("neighbour",false): resident_owner.population.open_person(resident_owner); return ""
		if get_meta("ambient_peek",false): return str(resident_owner.entry.name)+", à janela: "+str(resident_owner.entry.greeting)
	director.open_object(self,person)
	return ""
func _draw() -> void:
	if kind=="window": _draw_window(); return
	if kind=="chalk":
		for drawing in director.chalk:
			if Vector2(drawing.at[0],drawing.at[1]).distance_to(global_position)>200: continue
			var center := Vector2(drawing.at[0],drawing.at[1])-global_position
			var color := Color(drawing.color)
			match int(drawing.design):
				0:
					for i in 5: draw_arc(center+Vector2.from_angle(i*TAU/5)*16,11,0,TAU,18,color,2,true)
				1:
					for i in 6: draw_rect(Rect2(center+Vector2((i%2)*25-25,-i/2*26),Vector2(24,25)),color,false,2)
				2:
					draw_string(ThemeDB.fallback_font,center-Vector2(28,0),"Te + Jo",HORIZONTAL_ALIGNMENT_LEFT,-1,17,color)
				3:
					draw_arc(center,27,0,TAU,30,color,2,true); draw_circle(center+Vector2(-9,-5),2,color); draw_circle(center+Vector2(9,-5),2,color); draw_arc(center+Vector2(0,4),12,0,PI,16,color,2,true)
		if director.chalk.is_empty(): draw_arc(Vector2.ZERO,30,0,TAU,25,Color("ddd9be"),1,true)
		return
	if kind=="shop":
		var color := Color("dac690") if director.minute>=540 and director.minute<1110 else Color("988879")
		draw_line(Vector2(-20,-35),Vector2(20,-35),color,3,true)
		if state>0: draw_arc(Vector2(0,-50),20,0,TAU,25,Color("d4e8df"),1.5,true)
		return
	if kind=="feed":
		for i in 8: draw_circle(Vector2(sin(i*3.2)*30,cos(i)*14),2,Color("b9a16c"))
		return
	if kind=="cat": return
	if kind=="sound": draw_arc(Vector2.ZERO,14,-PI*.5,PI*.5,20,Color("b7c5ac"),2,true); return
	if kind=="clue":
		draw_circle(Vector2(0,-14),11,Color("758d5b")); draw_line(Vector2(0,-14),Vector2.ZERO,Color("886844"),3); return
	if kind in ["hat","box"]:
		var item: Dictionary = {"type":"living_"+kind,"porte":1,"art":0}
		preload("res://scripts/item_art.gd").draw_item(self,item,Rect2(-22,-25,44,36))
		return
	if kind=="bell": draw_set_transform(Vector2(40,-75))
	var map: Dictionary = {"bell":0,"chest":1,"board":2,"fountain":3,"bin":4,"vending":5,"pot":6,"barter":7}
	if not map.has(kind): return
	var pose: Dictionary = director.ART.data.objects[int(map[kind])]
	var r: Array = pose.rect
	var source := Rect2(r[0],r[1],r[2],r[3])
	var height: float = {"bell":28,"chest":65,"board":135,"fountain":130,"bin":75,"vending":155,"pot":72,"barter":120}.get(kind,75)
	var size := source.size*(height/source.size.y)
	draw_texture_rect_region(director.textures.objects,Rect2(Vector2(-size.x*.5,-size.y),size),source)
	if kind=="bell":
		var number: String = label.get_slice(",",label.get_slice_count(",")-1).strip_edges()
		draw_style_box(TejoPerson._box(Color("e8dec8"),2),Rect2(18,-29,24,20))
		draw_string(ThemeDB.fallback_font,Vector2(21,-14),number,HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("3a554b"))
	if state>0 and kind in ["fountain","pot"]:
		for i in 7: draw_line(Vector2(-10+i*4,-35),Vector2(-8+i*4,-15+sin(clock+i)*5),Color("9fbfce"),1,true)
func _draw_window() -> void:
	if not available():
		_draw_shutters()
		return
	var pose: Dictionary
	var texture: Texture2D
	var slot: int = int(resident_owner.clock/3)%2
	var individual: Dictionary = preload("res://data/village/individuality-art.json").data.characters
	if resident_owner.entry.get("neighbour",false):
		pose = resident_owner.population.pose_for(resident_owner)
		if pose.is_empty(): return
		texture = load(pose.path)
	elif individual.has(resident_owner.entry.id):
		pose = individual[resident_owner.entry.id].frames[slot]
		texture = load(pose.path)
	else:
		var sheet: Dictionary = director.ART.data.atlases[str(int(resident_owner.entry.living_art))]
		pose = sheet.people[int(resident_owner.entry.column)].frames[slot]
		texture = director.textures[str(int(resident_owner.entry.living_art))]
	var r: Array = pose.rect
	var source := Rect2(r[0]+r[2]*.22,r[1],r[2]*.56,r[3]*.42)
	# Upper body fits the actual native glass; the painted sill and frame remain intact.
	var room := Rect2(pane.position+Vector2(2,2),pane.size-Vector2(4,4))
	var size := source.size*minf(room.size.x/source.size.x,room.size.y/source.size.y)
	var dest := Rect2(Vector2(room.get_center().x-size.x*.5,room.end.y-size.y),size)
	draw_texture_rect_region(texture,dest,source)
	if mark.get("until",0)>clock:
		draw_string(ThemeDB.fallback_font,pane.position-Vector2(10,8),str(mark.text),HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("f1dfb0"))
	_draw_shutters()
	if resident_owner.entry.get("role","")=="plants" and resident_owner.frame==1:
		for i in 4: draw_line(pane.end+Vector2(-i*5,0),pane.end+Vector2(-i*5,22+i*4),Color("9bbbc9"),1,true)

func _draw_shutters() -> void:
	if shutter_closed<=0: return
	for cut in shutter_sources:
		if cut.rect!=pane: continue
		var width: float = pane.size.x*.5*shutter_closed
		draw_texture_rect_region(building.surface.texture,Rect2(pane.position,Vector2(width,pane.size.y)),cut.left)
		draw_texture_rect_region(building.surface.texture,Rect2(Vector2(pane.end.x-width,pane.position.y),Vector2(width,pane.size.y)),cut.right)
