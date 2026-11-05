extends Node2D
## Persistent residents and friends, with authored homes, occupations and local strolls.
const Resident = preload("res://scripts/village_resident.gd")
const ROSTER = preload("res://data/village/residents.json")
const Routines = preload("res://scripts/village_routines.gd")
var world: Node2D
var residents: Array[CharacterBody2D] = []
var by_id: Dictionary = {}
var routines := Routines.new()
var elapsed := 0.0
var last_minute := -INF
var initialized := false

func _ready() -> void:
	name = "VillagePopulation"
	for i in ROSTER.data.residents.size():
		var entry: Dictionary = ROSTER.data.residents[i]
		var actor := Resident.new()
		actor.population = self
		actor.entry = entry
		actor.ordinal = i
		actor.name = entry.id
		actor.home = free_point(Vector2(entry.home[0],entry.home[1]),true)
		actor.position = actor.home
		actor.anchor = actor.home
		world.actors.add_child(actor)
		residents.append(actor)
		by_id[entry.id] = actor
		actor.prepare_stroll()
		world.interactions.targets.append({"id":"village_resident_"+entry.id,"kind":"resident","label":entry.name,"position":actor.position,"reach":155.0,"radius":12.0,"node":actor})
	routines.population = self
	for actor in residents: routines.prepare(actor)
	for actor in residents:
		if actor.profile.has("guardian"): by_id[actor.profile.guardian].dependants.append(actor)

func clear_point(at: Vector2, projection := false) -> bool:
	if not world.is_walkable(at,18): return false
	for actor in residents:
		if actor.visible and actor.position.distance_to(at)<76: return false
	if projection:
		for building in world.buildings:
			if building.position.y<at.y: continue
			if building.screen_bounds.has_point(at-Vector2(0,35)) or building.screen_bounds.has_point(at-Vector2(0,100)):
				return false
	return true

func free_point(preferred: Vector2, projection := false) -> Vector2:
	if clear_point(preferred,projection): return preferred
	for radius in range(32,545,32):
		for i in 16:
			var at := preferred+Vector2.from_angle(i*TAU/16)*radius
			if clear_point(at,projection): return at
	if projection: return free_point(preferred,false)
	return Vector2.INF

func step(delta: float, cycle: RefCounted) -> void:
	elapsed += delta
	var now: float = (cycle.day-1)*1440.0+cycle.minutes
	if not initialized or now-last_minute>5.0 or now<last_minute or cycle.minutes_per_second>5:
		synchronize(cycle,true)
	for actor in residents:
		var index: int = routines.index_at(actor,cycle.minutes)
		if index!=actor.routine_index: actor.begin_appointment(index)
	for actor in residents: actor.step(delta,cycle)
	last_minute = now

func synchronize(cycle: RefCounted, force := false) -> void:
	var now: float = (cycle.day-1)*1440.0+cycle.minutes
	if initialized and not force and absf(now-last_minute)<.5: return
	for actor in residents: actor.seek_day(cycle.minutes)
	last_minute = now
	initialized = true

func waiting_for_child(actor: CharacterBody2D) -> bool:
	for child in actor.dependants:
		if not child.visible: continue
		if child.greet_time>0: return true
		if child.state=="commuting" and actor.position.distance_to(child.position)>180:
			if actor.position.distance_to(actor.anchor)>150 or actor.appointment.mode=="inside": return true
	return false

func clear_stroll_point(actor: CharacterBody2D, preferred: Vector2) -> Vector2:
	for radius in [0.0,28.0,56.0,84.0]:
		for i in 8:
			var point: Vector2 = preferred+Vector2.from_angle(i*TAU/8)*radius
			if point.distance_to(actor.anchor)>430 or point.distance_to(actor.anchor)<45: continue
			if world.is_walkable(point,20) and world.can_walk_line(actor.anchor,point): return point
	return Vector2.INF

func yield_goal(actor: CharacterBody2D) -> Vector2:
	for player in world.people:
		var gap: float = actor.position.distance_to(player.position)
		if gap>95 or (not player.moving and gap>48): continue
		var away: Vector2 = player.position.direction_to(actor.position)
		if away.is_zero_approx(): away = Vector2.RIGHT
		for direction in [away,away.rotated(PI*.5),away.rotated(-PI*.5),away.rotated(PI*.25),away.rotated(-PI*.25)]:
			var target: Vector2 = actor.position+direction*90
			if world.is_walkable(target,20) and world.can_walk_line(actor.position,target): return target
	return Vector2.INF

func neighbouring_velocity(actor: CharacterBody2D) -> Vector2:
	var result := Vector2.ZERO
	var neighbours: Array = world.nearby_people(actor.position) if world.has_method("nearby_people") else (world.social_life.actors if is_instance_valid(world.social_life) else residents)
	for other in neighbours:
		if other==actor or not other.visible or other.state=="entering": continue
		var gap := actor.position.distance_to(other.position)
		if gap<58 and gap>1:
			result += other.position.direction_to(actor.position)*(58-gap)*1.6
	if actor.state=="commuting" and actor.appointment.mode=="inside" and actor.position.distance_to(actor.anchor)<100: result *= .08
	return result
