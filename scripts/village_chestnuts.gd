extends StaticBody2D
## A staffed chestnut cart by the park, with atomic purchases and an optional topping.
const Catalog = preload("res://scripts/chestnut_catalog.gd")
const Money = preload("res://scripts/bakery_catalog.gd")
const ART = preload("res://data/village/chestnut-art.json")
var world: Node2D
var frame := 0
var serving := 0.0
var texture: Texture2D
func build(owner_world: Node2D) -> void:
	world = owner_world; name = "CastanhasDoParque"
	position = _site(Vector2(18200,6000))
	var paint := ShaderMaterial.new(); paint.shader = preload("res://shaders/village_neighbour_cutout.gdshader"); material = paint
	collision_layer = 1; collision_mask = 0
	var body := CollisionShape2D.new(); var shape := RectangleShape2D.new(); shape.size = Vector2(210,52)
	body.shape = shape; body.position.y = -22; add_child(body)
	world.blocked_rects.append(Rect2(position-Vector2(105,48),shape.size))
	world.actors.add_child(self)
func _site(preferred: Vector2) -> Vector2:
	# Reserve the counter and its customers together; a free cart alone can leave
	# the buyers behind a foreground roof or squeezed against a house corner.
	for radius in range(0,1025,32):
		for i in (1 if radius==0 else 24):
			var at: Vector2 = preferred+Vector2.from_angle(i*TAU/24)*radius
			if not world.is_walkable(at,105): continue
			var clear := true
			for offset in [Vector2.ZERO,Vector2(-50,110),Vector2(55,110),Vector2(0,220)]:
				var feet: Vector2 = at+offset
				if not world.is_walkable(feet,30): clear = false; break
				if world.buildings.any(func(b):return b.position.y>=feet.y and (b.screen_bounds.has_point(feet-Vector2(0,60)) or b.screen_bounds.has_point(feet-Vector2(0,160)))): clear = false; break
			if clear: return at
	return world._event_space(preferred,300)
func bind() -> void:
	world.interactions.targets.append({"id":"chestnuts_parque","kind":"street_scene","node":self,"label":"Castanhas do Parque","position":position,"reach":185.0,"radius":0.0})
	world.landmarks.append({"id":"chestnuts_parque","name":"Castanhas do Parque","position":position+Vector2(0,100),"radius":250.0})
	step(0,world.get_parent().day_cycle)
func opened(at: float) -> bool: return at>=600 and at<1320
func available() -> bool: return visible
func interaction_prompt() -> String: return "Castanhas do Parque · fechado · 10:00–22:00" if frame==2 else "Comprar castanhas · simples ou com manteiga"
func step(delta: float,cycle: RefCounted) -> void:
	serving = maxf(0,serving-delta)
	var next := (1 if serving>0 or fmod(world.ambient_time,8.0)>5.0 else 0) if opened(cycle.minutes) else 2
	if next!=frame: frame = next; queue_redraw()
func interact(person: CharacterBody2D) -> String:
	var journey: Node2D = world.get_parent().get("journey")
	if journey==null or not opened(journey.scene.day_cycle.minutes): return "Castanhas do Parque · 10:00–22:00. A banca está tapada; volta durante o horário de atendimento."
	if journey.controls_blocked(): return ""
	var owner: int = journey.scene.people.find(person)
	if owner<0: return ""
	var choices: Array = ["Castanhas assadas · 2,50 €", "Castanhas com manteiga · 2,80 €"]
	var plain_id := ""
	for item in person.inventory.items:
		if item.get("type","")=="chestnuts_roasted": plain_id = str(item.get("id","")); break
	if not plain_id.is_empty(): choices.append("Juntar manteiga às castanhas da bolsa · +0,30 €")
	journey.panel.show_choices("Castanhas do Parque · Sr. Amílcar", "«Quentes e boas! A manteiga derrete logo em cima.»\n10:00–22:00 · Carteira: "+Money.euro(journey.coins)+" · Bolsa de "+person.name+". Cada dose ocupa 1 espaço. Clica depois na dose para comer ou partilhar.", choices, func(choice):
		journey.notify(add_butter(journey,owner,plain_id) if choice==2 else buy(journey,owner,choice==1)))
	return ""
func _purchase_error(journey: Node2D,owner: int) -> String:
	if owner<0 or owner>=journey.scene.people.size(): return "Escolha inválida."
	if not world.is_visible_in_tree() or journey.world!=world or not opened(journey.scene.day_cycle.minutes): return "A banca está fechada. Volta entre as 10:00 e as 22:00."
	var person: CharacterBody2D = journey.scene.people[owner]
	if person.position.distance_to(position)>240: return "Aproxima-te da banca para pedir castanhas."
	if not world.interactions._reachable(person,{"position":position,"radius":0.0,"kind":"street_scene","node":self}): return "Aproxima-te pela frente da banca."
	return ""
func buy(journey: Node2D,owner: int,butter: bool) -> String:
	var error := _purchase_error(journey,owner)
	if not error.is_empty(): return error
	var person: CharacterBody2D = journey.scene.people[owner]
	var item := Catalog.item(butter)
	if journey.coins<int(item.price): return "Não há dinheiro suficiente para esta dose."
	if not person.inventory.can_add(item): return "A bolsa de "+person.name+" está cheia. Come, partilha ou pousa um objeto antes de comprar."
	journey.serial += 1; item.id = "chestnuts_"+str(journey.serial)
	if not person.inventory.try_add(item): return "A compra não foi concluída; o dinheiro fica na carteira."
	journey.coins -= int(item.price); _served(journey)
	return person.name+" guardou "+item.name.to_lower()+". Clica na dose na bolsa para comer, dar ou partilhar."
func add_butter(journey: Node2D,owner: int,id: String) -> String:
	var error := _purchase_error(journey,owner)
	if not error.is_empty(): return error
	var bag: RefCounted = journey.scene.people[owner].inventory
	for i in bag.items.size():
		var old: Dictionary = bag.items[i]
		if str(old.get("id",""))!=id or old.get("type","")!="chestnuts_roasted": continue
		if journey.coins<Catalog.BUTTER_PRICE: return "Faltam 0,30 € para juntar manteiga."
		var item := Catalog.item(true); item.id = id
		bag.items[i] = item; journey.coins -= Catalog.BUTTER_PRICE; bag.changed.emit(); _served(journey)
		return "O Sr. Amílcar juntou manteiga às castanhas. A dose continua na mesma bolsa."
	return "Essa dose já não está na bolsa ou já tem manteiga."
func _served(journey: Node2D) -> void:
	serving = 3.0; step(0,journey.scene.day_cycle)
	journey.dirty = true; journey.changed.emit()
func _draw() -> void:
	var pose: Dictionary = ART.data.stall[frame]
	if texture==null: texture = load(pose.path)
	var source := Rect2(pose.rect[0],pose.rect[1],pose.rect[2],pose.rect[3])
	var factor: float = 220.0*float(pose.height_ratio)/source.size.y
	draw_texture_rect_region(texture,Rect2(-Vector2(pose.foot[0],pose.foot[1])*factor,source.size*factor),source)
