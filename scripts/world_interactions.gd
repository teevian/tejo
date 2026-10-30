extends Node2D
signal discovered(flag: String)
const ItemArt = preload("res://scripts/item_art.gd")
const Pickup = preload("res://scripts/world_pickup.gd")
const MAX_JUMP := 240.0
var world: Node2D
var targets: Array[Dictionary] = []
var current_target: Dictionary = {}
var discoveries: Dictionary = {}
var next_id := 0

func _ready() -> void:
	name = "WorldInteractions"
	z_index = 6
	for prop in world.props:
		var kind: int = prop.get_meta("kind")
		var category: String = ["tree","tree","fern","rock","fountain","bench"][kind]
		var label: String = ["Árvore","Sobreiro","Fetos","Rochedo","Fonte","Banco"][kind]
		targets.append({"id":"prop_"+str(targets.size()),"kind":category,"label":label,"position":prop.position,"reach":float(prop.get_meta("radius"))+105.0,"radius":float(prop.get_meta("radius")),"node":prop})
	for rock in world.boulders:
		targets.append({"id":"rock_"+str(targets.size()),"kind":"rock","label":"Pedra com musgo","position":rock.position,"reach":rock.radius+100.0,"radius":rock.radius,"node":rock.node})
	for entry in [[Vector2(4190,1560),"Parede da capela"],[Vector2(3990,1435),"Arco antigo"],[Vector2(4260,5000),"Vestígios da muralha"]]:
		targets.append({"id":"ruin_"+str(targets.size()),"kind":"ruin","label":entry[1],"position":entry[0],"reach":115.0,"radius":0.0})
	for object in world.scenery_props:
		var category: String = "football" if object.kind==3 else ("signpost" if object.kind==0 else "curiosity")
		targets.append({"id":"discovery_"+str(targets.size()),"kind":category,"label":object.label,"position":object.position,"reach":100.0,"radius":object.contact_radius,"node":object})
	# Visible, non-blocking objects distributed throughout both halves of the map.
	var placements := [
		[0,Vector2(945,2970)],[1,Vector2(715,3040)],[2,Vector2(1130,3030)],[4,Vector2(1260,3000)],
		[1,Vector2(750,1110)],[0,Vector2(1770,1910)],[5,Vector2(2250,970)],[0,Vector2(2730,2240)],
		[3,Vector2(4180,1510)],[1,Vector2(4030,3000)],[2,Vector2(1240,4210)],[4,Vector2(1560,4300)],
		[0,Vector2(2660,3900)],[3,Vector2(4200,5010)],[5,Vector2(3980,4200)],[0,Vector2(3100,4890)]]
	for entry in placements:
		var at: Vector2 = find_drop_position(entry[1])
		if at!=Vector2.INF:
			spawn_pickup(ItemArt.ITEMS[entry[0]],at)

	# Useful discoveries remain scattered along the new paths; food has real inventory cost.
	for at in [Vector2(1130,3100),Vector2(2680,2240),Vector2(5860,2840),Vector2(7000,4860),Vector2(7025,4920),Vector2(7065,4960),Vector2(8340,5650),Vector2(2000,6390),Vector2(11260,4020)]:
		var point := find_drop_position(at)
		if point!=Vector2.INF:
			spawn_pickup(preload("res://scripts/puppy_art.gd").FOOD,point)
	for at in [Vector2(6100,2150),Vector2(8600,3400),Vector2(8700,6550),Vector2(1800,6750),Vector2(10840,4900)]:
		for offset in [Vector2.ZERO,Vector2(85,40)]:
			var point := find_drop_position(at+offset)
			if point!=Vector2.INF: spawn_pickup(ItemArt.ITEMS[1 if offset==Vector2.ZERO else 0],point)

func spawn_pickup(item: Dictionary, at: Vector2) -> Dictionary:
	var node := Pickup.new()
	node.item = item.duplicate(true)
	node.position = at
	world.actors.add_child(node)
	var id := "pickup_"+str(next_id)
	next_id += 1
	if not node.item.has("id"):
		node.item.id = id
	var target := {"id":id,"kind":"pickup","label":item.name,"position":at,"reach":85.0,"radius":0.0,"node":node,"item":node.item}
	targets.append(target)
	return target

func find_drop_position(nearby: Vector2, from := Vector2.INF) -> Vector2:
	for radius in [0.0,34.0,65.0,100.0]:
		for step in 12:
			var at: Vector2 = nearby+Vector2.from_angle(float(step)*TAU/12.0)*radius
			if not world.is_walkable(at,18):
				continue
			if from!=Vector2.INF and not world.can_walk_line(from,at):
				continue
			var occupied := false
			for target in targets:
				if target.kind=="pickup" and is_instance_valid(target.node) and target.node.visible and at.distance_to(target.position)<28:
					occupied = true
			if not occupied:
				return at
	return Vector2.INF

func _reachable(person: CharacterBody2D, target: Dictionary) -> bool:
	var point: Vector2 = target.position
	if target.has("node") and target.node.has_method("configure_mapped"):
		point = _painted_contact(target.node,person.position)
	elif target.kind=="bench":
		point.x += clampf(person.position.x-point.x,-90,90)
	elif target.radius>0:
		point += point.direction_to(person.position)*(float(target.radius)+18.0)
	var ray := PhysicsRayQueryParameters2D.create(person.position,point,1)
	ray.exclude = [person.get_rid()]
	var hit := world.get_world_2d().direct_space_state.intersect_ray(ray)
	return hit.is_empty() or hit.collider==target.get("node")

func _painted_contact(object: Node2D, from: Vector2) -> Vector2:
	var closest := object.position
	var distance := INF
	for polygon in object.footprints:
		for i in polygon.size():
			var point := Geometry2D.get_closest_point_to_segment(from,polygon[i],polygon[(i+1)%polygon.size()])
			if point.distance_squared_to(from)<distance:
				distance = point.distance_squared_to(from)
				closest = point
	return closest

func river_target(person: CharacterBody2D) -> Dictionary:
	var y := person.position.y
	var center: float = world.river_x(y)
	if not world.in_water(Vector2(center,y)):
		return {}
	var half_width := 75.0 if y>3600 else 130.0
	var side := -1.0 if person.position.x<center else 1.0
	var bank := Vector2(center+side*(half_width+28),y)
	if person.position.distance_to(bank)>110:
		return {}
	var landing := Vector2(center-side*(half_width+36),y)
	var can_jump: bool = person.position.distance_to(landing)<=MAX_JUMP and world.is_walkable(landing,18) and not world.in_water(person.position,12)
	# Keep the launch on the clear bank: jumping never bypasses walls or trees.
	can_jump = can_jump and world.can_walk_line(person.position,bank)
	return {"id":"river","kind":"river","label":"Ribeira","position":bank,"reach":110.0,"radius":0.0,"landing":landing,"can_jump":can_jump}

func nearest(person: CharacterBody2D) -> Dictionary:
	var result: Dictionary = river_target(person)
	var best := 100000.0
	if not result.is_empty():
		best = person.position.distance_to(result.position)+15.0
	for target in targets:
		if target.kind=="football": target.position = target.node.position
		if target.kind=="pickup" and (not is_instance_valid(target.node) or not target.node.visible):
			continue
		var distance := person.position.distance_to(target.position)
		var painted: bool = target.has("node") and target.node.has_method("configure_mapped")
		if painted:
			if not target.node.ground_bounds.grow(100).has_point(person.position): continue
			distance = person.position.distance_to(_painted_contact(target.node,person.position))
		if distance>(100.0 if painted else float(target.reach)):
			continue
		var score: float = distance if painted else maxf(0,distance-float(target.radius))
		if target.kind=="bench":
			var footprint := Rect2(target.position+world.WorldScale.BENCH_FOOTPRINT.position,world.WorldScale.BENCH_FOOTPRINT.size)
			score = person.position.distance_to(person.position.clamp(footprint.position,footprint.end))
		var direction: Vector2 = person.position.direction_to(target.position)
		score += (1-person.facing.dot(direction))*14.0
		if target.kind=="pickup":
			# An item at the character's feet remains selectable beside a wide bench.
			score -= 64.0 if distance<=55 else 18.0
		if score<best and _reachable(person,target):
			best = score
			result = target
	if is_instance_valid(world.puppy):
		var puppy_target: Dictionary = world.puppy.target_for(person)
		if not puppy_target.is_empty() and (result.is_empty() or result.kind!="pickup"):
			return puppy_target
	return result

func prompt(person: CharacterBody2D, target: Dictionary) -> String:
	if person.jumping or person.collecting_time>0:
		return ""
	if person.seating:
		return "Cancelar a aproximação ao banco"
	if person.seated:
		return "Levantar os dois do banco"
	if target.is_empty():
		return ""
	match target.kind:
		"football": return "Dar um pontapé na bola"
		"signpost": return "Ler a placa antiga"
		"puppy": return "Deixar comida / fazer festas ao cachorro"
		"pickup": return "Apanhar "+str(target.label).to_lower()+" · porte "+str(target.item.porte)
		"bench": return "Sentar os dois no banco"
		"fountain": return "Beber da fonte"
		"river": return "Saltar a ribeira" if target.can_jump else "Observar a ribeira"
		"tree": return "Examinar "+str(target.label).to_lower()
		_: return "Examinar "+str(target.label).to_lower()

func interact(person: CharacterBody2D) -> String:
	if person.jumping or person.collecting_time>0:
		return ""
	if person.seated or person.seating:
		var bench_id: String = person.seat_id
		for friend in world.people:
			if friend.seat_id==bench_id:
				friend.stand_up()
		return "De novo a caminho."
	var target := nearest(person)
	if target.is_empty():
		return "Aproxima-te de um objeto para interagir."
	for friend in world.people:
		friend.cancel_shoulder()
		friend._finish_phone()
	match target.kind:
		"football":
			target.node.kick(person)
			return "A bola ainda rola, apesar de todos estes anos."
		"signpost", "curiosity":
			_discover(target.id)
			return str(target.label)
		"puppy":
			return world.puppy.interact(person)
		"pickup":
			if not person.inventory.try_add(target.item):
				return "A bolsa de %s está cheia: %d/5 de porte. Larga um objeto para levar este."%[person.name,person.inventory.used_porte()]
			target.node.hide()
			person.collecting_time = 0.55
			_discover("collected_"+str(target.item.type))
			return "%s guardou %s. Porte %d/5."%[person.name,str(target.label).to_lower(),person.inventory.used_porte()]
		"bench":
			# Reserve both independent places only after both routes are validated.
			for friend in world.people:
				var seat: Vector2 = target.node.seat_position(friend.kind)
				if friend.jumping or friend.collecting_time>0:
					return "Espera que %s termine a ação para se sentarem os dois."%friend.name
				if not world.is_walkable(seat,14) or world.find_path(friend.position,seat).is_empty():
					return "Não há passagem livre para os dois lugares deste banco."
			for friend in world.people:
				friend.begin_sitting(target.id,target.node.seat_position(friend.kind),friend.kind)
			return "Sentamo-nos os dois. Espaço ou movimento para voltar ao caminho."
		"river":
			if target.can_jump:
				var launch := person.position
				person.start_jump(target.landing)
				if is_instance_valid(person.partner) and not person.partner.controlled:
					var follower_landing: Vector2 = target.landing
					for offset in [Vector2(0,70),Vector2(0,-70),Vector2(0,45),Vector2(0,-45)]:
						var candidate: Vector2 = target.landing+offset
						if launch.distance_to(candidate)<=MAX_JUMP and world.is_walkable(candidate,18) and world.can_walk_line(target.landing,candidate):
							follower_landing = candidate
							break
					person.partner.queued_jump = {"from":launch,"to":follower_landing}
				return "Um salto até à outra margem."
			return "Aqui a ribeira é demasiado larga ou a outra margem não está livre. Procura uma ponte ou um troço mais estreito a sul."
		"tree":
			_discover("examined_tree")
			if not target.get("gift_given",false):
				var at := find_drop_position(person.position+Vector2(35,35),person.position)
				if at!=Vector2.INF:
					target.gift_given = true
					spawn_pickup(ItemArt.ITEMS[1],at)
					return "Entre as raízes há uma pinha caída. Podes apanhá-la."
			return "A casca é rugosa e fresca. O musgo cresce à sombra do tronco."
		"rock":
			_discover("examined_rock")
			return "O granito está coberto de líquenes. Esta pedra é demasiado grande para levar; procura pedrinhas soltas."
		"ruin":
			_discover("ruins_examined")
			return "Entre as pedras antigas ainda se veem marcas de ferramentas. Há pequenos fragmentos soltos no caminho."
		"fountain":
			person.collecting_time = 0.65
			_discover("fountain_water")
			return "A água da fonte é fresca. Ficamos um momento a ouvir a água."
		"fern":
			_discover("examined_ferns")
			return "As folhas guardam gotas de água. Os rebentos novos ainda estão enrolados."
	return ""

func drop(person: CharacterBody2D, index: int) -> String:
	if person.jumping or person.collecting_time>0 or index<0 or index>=person.inventory.items.size():
		return ""
	var at := find_drop_position(person.position+Vector2(48,35),person.position)
	if at==Vector2.INF:
		return "Não há espaço livre aqui para pousar o objeto."
	var item: Dictionary = person.inventory.take(index)
	for friend in world.people:
		friend.cancel_shoulder()
		friend._finish_phone()
	if item.type=="dog_food" and is_instance_valid(world.puppy) and world.puppy.food.is_empty() and at.distance_to(world.puppy.home)<850:
		world.puppy.leave_food(at)
		return world.puppy.feedback
	spawn_pickup(item,at)
	return "%s pousou %s. Podes voltar a apanhá-lo."%[person.name,str(item.name).to_lower()]

func _discover(flag: String) -> void:
	if discoveries.has(flag):
		return
	discoveries[flag] = true
	discovered.emit(flag)

func highlight(target: Dictionary) -> void:
	current_target = target
	queue_redraw()

func _draw() -> void:
	if current_target.is_empty():
		return
	var at: Vector2 = current_target.position
	draw_arc(at,18,0,TAU,32,Color(0.95,0.85,0.58,0.8),1.5,true)
	var marker := at+Vector2(0,-27)
	draw_colored_polygon(PackedVector2Array([marker+Vector2(0,-4),marker+Vector2(3,0),marker+Vector2(0,4),marker+Vector2(-3,0)]),Color("edd8a0"))
