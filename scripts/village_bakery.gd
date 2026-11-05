extends StaticBody2D
const Catalog = preload("res://scripts/bakery_catalog.gd")
const ART = preload("res://data/village/bakery-art.json")
var world: Node2D
var building: Node2D
var texture: Texture2D
var painted_height := 175.0
func build(owner_world: Node2D) -> void:
	world = owner_world; name = "PastelariaDoLargo"
	var choices: Array = world.buildings.filter(func(b):return b.label=="Padaria")
	choices.sort_custom(func(a,b):return a.entry_position.distance_squared_to(Vector2(10100,4450))<b.entry_position.distance_squared_to(Vector2(10100,4450)))
	assert(not choices.is_empty(),"The bakery belongs to an actual bakery frontage")
	building = choices[0]
	position = world._event_space(building.entry_position+Vector2(0,145),260)
	var paint := ShaderMaterial.new(); paint.shader = preload("res://shaders/village_neighbour_cutout.gdshader"); material = paint
	collision_layer = 1; collision_mask = 0
	var body := CollisionShape2D.new(); var shape := RectangleShape2D.new(); shape.size = Vector2(240,48)
	body.shape = shape; body.position.y = -20; add_child(body)
	world.blocked_rects.append(Rect2(position-Vector2(120,44),shape.size))
	world.actors.add_child(self)
func bind() -> void:
	world.interactions.targets.append({"id":"bakery_largo","kind":"street_scene","node":self,"label":"Pastelaria do Largo","position":position,"reach":185.0,"radius":0.0})
	world.landmarks.append({"id":"bakery_largo","name":"Pastelaria do Largo","position":position+Vector2(0,90),"radius":250.0})
	var baker: CharacterBody2D = world.population.by_id.luis
	var work: Vector2 = baker.population.routines.clear_destination(position+Vector2(-185,-10),[])
	for block in baker.schedule:
		if block.place=="regular": block.destination = work; block.activity = "a preparar pão e a atender a pastelaria"
func opened(at: float) -> bool: return at>=420 and at<1290
func available() -> bool: return visible
func interaction_prompt() -> String: return "Comprar bolos e bebidas · Pastelaria do Largo"
func interact(person: CharacterBody2D) -> String:
	var journey: Node2D = world.get_parent().get("journey")
	if journey==null: return "Pastelaria do Largo · 07:00–21:30."
	if not opened(journey.scene.day_cycle.minutes): return "A pastelaria abre das 07:00 às 21:30. O horário fica na montra."
	journey.shop_panel.open(self,person)
	return ""
func buy(journey: Node2D,owner: int,index: int) -> String:
	if owner<0 or owner>1 or index<0 or index>=Catalog.PRODUCTS.size(): return "Escolha inválida."
	if not world.is_visible_in_tree() or journey.world!=world or not opened(journey.scene.day_cycle.minutes): return "A pastelaria está fechada. Volta entre as 07:00 e as 21:30."
	var person: CharacterBody2D = journey.scene.people[owner]
	if person.position.distance_to(position)>240: return "Aproxima-te do balcão para comprar."
	if not world.interactions._reachable(person,{"position":position,"radius":0.0,"kind":"street_scene","node":self}): return "Aproxima-te pela frente do balcão."
	var item: Dictionary = Catalog.item(index)
	if journey.coins<int(item.price): return "Não há dinheiro suficiente. Os resultados dos jogos e as ajudas pela vila dão dinheiro para o lanche."
	if not person.inventory.can_add(item): return "A bolsa de "+person.name+" está cheia. Come, partilha ou pousa um objeto antes de comprar."
	journey.serial += 1; item.id = "bakery_"+str(journey.serial)
	if not person.inventory.try_add(item): return "A compra não foi concluída; o dinheiro fica na carteira."
	journey.coins -= int(item.price); journey.dirty = true; journey.changed.emit()
	return person.name+" guardou "+item.name.to_lower()+". Clica no produto na bolsa para comer, dar ou partilhar."
func _draw() -> void:
	var pose: Dictionary = ART.data.counter
	if texture==null: texture = load(pose.path)
	var source := Rect2(pose.rect[0],pose.rect[1],pose.rect[2],pose.rect[3])
	var factor: float = painted_height/source.size.y
	var foot := Vector2(pose.foot[0],pose.foot[1])*factor
	draw_texture_rect_region(texture,Rect2(-foot,source.size*factor),source)
