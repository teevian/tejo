extends RefCounted
## Authored daily choices and stable, reachable appointments in the actual town.
const DATA = preload("res://data/village/daily-routines.json")
var population: Node2D
var appointments: Dictionary = {}
var residences: Dictionary = {}
var reservations: Dictionary = {}
var doors: Dictionary = {}

static func minute(text: String) -> float:
	var parts := text.split(":")
	return float(parts[0])*60.0+float(parts[1])

func prepare(actor: CharacterBody2D) -> void:
	actor.profile = DATA.data.people[actor.entry.id]
	actor.schedule = actor.profile.schedule.duplicate(true)
	for block in actor.schedule:
		block.minute = minute(block.at)
		block.destination = destination(actor,block.place,block.mode=="inside")
		block.location = location_name(actor,block.place)

func index_at(actor: CharacterBody2D, minutes: float) -> int:
	for i in range(actor.schedule.size()-1,-1,-1):
		if minutes>=float(actor.schedule[i].minute): return i
	return 0

func location_name(actor: CharacterBody2D, place: String) -> String:
	if place=="residence": return "o alojamento" if actor.profile.residence=="hotel" else "casa"
	if place in ["regular","nearby"]: return population.world.area_at(actor.home)
	return DATA.data.places[place].name

func destination(actor: CharacterBody2D, place: String, inside: bool) -> Vector2:
	var key: String = actor.entry.id+":"+place
	if appointments.has(key): return appointments[key]
	var point: Vector2 = actor.home
	if place=="residence":
		point = residence(actor)
	elif place=="nearby":
		point += Vector2(-125,25)
	elif place!="regular":
		var authored: Array = DATA.data.places[place].at
		point = Vector2(authored[0],authored[1])
		if inside: point = doorway(point,false,"Lawrence’s Hotel" if place=="hotel" else "Café")
		else:
			var offset := int(actor.entry.column)-2
			point += Vector2(offset*82,(actor.ordinal%2)*68)
	if not inside and place!="regular":
		var occupied: Array = reservations.get(place,[])
		point = clear_destination(point,occupied)
		occupied.append(point)
		reservations[place] = occupied
	appointments[key] = point
	return point

func clear_destination(preferred: Vector2, occupied: Array, clearance := 20.0) -> Vector2:
	for projection in [true,false]:
		for radius in range(0,577,32):
			for i in (1 if radius==0 else 16):
				var at := preferred+Vector2.from_angle(i*TAU/16)*radius
				if not population.world.is_walkable(at,clearance): continue
				if occupied.any(func(other): return at.distance_to(other)<76): continue
				if projection and not clear_paint(at): continue
				return at
	push_error("No public routine destination near "+str(preferred))
	return preferred

func clear_paint(at: Vector2) -> bool:
	for building in population.world.buildings:
		if building.position.y<at.y: continue
		for height in [5.0,65.0,140.0]:
			if building.screen_bounds.has_point(at-Vector2(0,height)): return false
	return true

func doorway(nearby: Vector2, houses_only := false, requested_label := "") -> Vector2:
	var candidates: Array = population.world.buildings.duplicate()
	candidates.sort_custom(func(a,b): return a.entry_position.distance_squared_to(nearby)<b.entry_position.distance_squared_to(nearby))
	for building in candidates:
		if houses_only and building.label!="Habitação": continue
		if not requested_label.is_empty() and building.label!=requested_label: continue
		for offset in [Vector2.ZERO,Vector2(0,32),Vector2(-32,32),Vector2(32,32),Vector2(0,64)]:
			var at: Vector2 = building.entry_position+offset
			if population.world.is_walkable(at,20):
				doors[at] = building.entry_id
				return at
	# An unusual frontage can have a very narrow public approach.
	if houses_only: return doorway(nearby)
	return clear_destination(nearby,[])

func residence(actor: CharacterBody2D) -> Vector2:
	var kind: String = actor.profile.residence
	if kind=="hotel":
		var at: Array = DATA.data.places.hotel.at
		if not residences.has(kind): residences[kind] = doorway(Vector2(at[0],at[1]),false,"Lawrence’s Hotel")
		return residences[kind]
	var key: String = actor.entry.id if kind=="local" else kind
	if not residences.has(key):
		var anchor: Vector2 = actor.home
		var adult: String = {"family_republic":"leonor","family_ferreira":"miguel","family_park":"ingrid"}.get(kind,"")
		if not adult.is_empty(): anchor = population.by_id[adult].home
		residences[key] = doorway(anchor+Vector2(220,0),true)
	return residences[key]

func path_length(path: PackedVector2Array) -> float:
	var distance := 0.0
	for i in range(1,path.size()): distance += path[i-1].distance_to(path[i])
	return distance

func advance_on_path(path: PackedVector2Array, distance: float) -> Vector2:
	for i in range(1,path.size()):
		var segment := path[i-1].distance_to(path[i])
		if distance<segment: return path[i-1].lerp(path[i],distance/maxf(segment,.001))
		distance -= segment
	return path[-1]
