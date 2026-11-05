extends Node2D
## Spread existing mobile lives along actual streets; never spawn copies around the camera.
var director: Node2D
var samples: Array[Vector2] = []
var assignments: Array[Dictionary] = []
var windows: Array[Node2D] = []
var window_owners: Dictionary = {}
var duty_clock := 0.0
var street_trips := 0
var last_day := -1
const MOBILE := ["tourist","phone","camera","reader","birds","umbrella","painting","bubbles","magician","piper","cleanup"]
func bind() -> void:
	for road in director.world.routes:
		for i in range(road.points.size()-1):
			var a: Vector2 = road.points[i]; var b: Vector2 = road.points[i+1]
			var n := maxi(1,ceili(a.distance_to(b)/430.0))
			for j in range(n):
				var p: Vector2 = a.lerp(b,(float(j)+.5)/n)
				if director.world.is_walkable(p,26) and director.routines.clear_paint(p) and not samples.any(func(s):return s.distance_to(p)<240): samples.append(p)
	# Morning, afternoon and evening each get their own spread. Meal, cinema,
	# family, service, dog and vehicle appointments keep their original destinations.
	for band in [[480,745],[835,1100],[1125,1300]]: _spread(band[0],band[1])
	_build_peeking_windows()
func _spread(start: int,end: int) -> void:
	var all: Array = director.world.social_life.actors
	var candidates: Array = director.world.festival_life.residents.filter(func(a):return int(a.entry.age)>=18 and int(a.entry.age)<70 and MOBILE.has(str(a.entry.role)) and not a.profile.has("guardian"))
	for a in candidates:
		# An early stroll gives the outer streets life before the later attractions open.
		if start==480:
			var first: Dictionary = a.schedule[director.routines.index_at(a,start)]
			if first.mode=="inside":
				var near: Vector2 = director.routines.clear_destination(a.home,[])
				a.schedule.append({"minute":475+a.ordinal%6,"at":"08:00","destination":near,"place":"morning_street","mode":"activity","activity":"a passear antes de as lojas abrirem","location":director.world.area_at(near),"stroll":true})
				a.schedule.sort_custom(func(x,y):return x.minute<y.minute)
	var covered: Array[Vector2] = []
	for a in all:
		var block: Dictionary = a.schedule[director.routines.index_at(a,start+35)]
		if block.mode!="inside": covered.append(block.destination)
	var used: Dictionary = {}
	for iteration in candidates.size():
		var best := Vector2.INF; var largest := 0.0
		for p in samples:
			var gap := INF
			for point in covered: gap = minf(gap,p.distance_to(point))
			if gap>largest: largest = gap; best = p
		if best==Vector2.INF or largest<520: break
		var choices: Array = candidates.filter(func(a):return not used.has(a.entry.id) and a.home.distance_to(best)<6200)
		choices.sort_custom(func(a,b):return a.home.distance_squared_to(best)<b.home.distance_squared_to(best))
		var assigned := false
		for a in choices:
			var blocks: Array = a.schedule.filter(func(b):return float(b.minute)>=start-10 and float(b.minute)<end and b.mode=="activity" and b.place not in ["cinema","football","fruit","sweets","flowers","chess","home","meal"])
			if blocks.is_empty():
				var current: Dictionary = a.schedule[director.routines.index_at(a,start+35)]
				if current.mode=="activity" and current.place not in ["cinema","football"]: blocks = [current]
			if blocks.is_empty(): continue
			var destination: Vector2 = director.routines.clear_destination(best,[])
			if director.world.find_path(a.home,destination).is_empty(): continue
			for block in blocks:
				block.destination = destination; block.location = director.world.area_at(destination)
				block.stroll = true
			used[a.entry.id] = true; covered.append(destination)
			assignments.append({"id":a.entry.id,"at":destination,"start":start,"end":end,"purpose":blocks[0].activity})
			assigned = true
			break
		if not assigned: covered.append(best)
func _build_peeking_windows() -> void:
	var all: Array = director.world.social_life.actors
	var selected: Array = all.filter(func(a):return not a.entry.get("neighbour",false) and not a.entry.has("living_art") and int(a.entry.age)>=18 and not a.profile.has("guardian"))
	for a in selected:
		var used: Dictionary = {}
		for block in a.schedule:
			if block.mode!="inside": continue
			var near: Vector2 = block.destination
			var choices: Array = director.world.buildings.filter(func(b):return b.entry_position.distance_to(near)<160 and not b.has_meta("side_facing"))
			choices.sort_custom(func(x,y):return x.entry_position.distance_squared_to(near)<y.entry_position.distance_squared_to(near))
			for b in choices:
				if used.has(b.entry_id): break
				var before: int = director.world.living_life.windows.size()
				director.world.living_life._attach_window(a,b)
				if director.world.living_life.windows.size()>before:
					var w: Node2D = director.world.living_life.windows[-1]
					w.set_meta("ambient_peek",true); w.set_meta("peek_destination",near)
					windows.append(w); window_owners[a.entry.id] = true; used[b.entry_id] = true
				break
func synchronize(cycle: RefCounted) -> void:
	last_day = cycle.day
	_update_windows(cycle)
func _update_windows(cycle: RefCounted) -> void:
	var occupied: Dictionary = {}
	for w in director.world.living_life.windows:
		if not w.get_meta("ambient_peek",false) and w.resident_owner.state=="window": occupied[str(w.building.entry_id)+str(w.pane)] = true
	for w in windows: _window(w,cycle,occupied)
func _window(w: Node2D,cycle: RefCounted,occupied: Dictionary) -> void:
	var a: CharacterBody2D = w.resident_owner
	# Same identity, one body: the upper body appears only at the door actually entered.
	var destination: Vector2 = w.get_meta("peek_destination",Vector2.INF)
	var at_door: bool = a.state=="inside" and a.appointment.destination.distance_to(destination)<8
	var awake: bool = cycle.minutes>=420 and cycle.minutes<1390
	var phase: float = fposmod(a.clock+a.ordinal*2.3,29)
	var key: String = str(w.building.entry_id)+str(w.pane)
	var visible_face: bool = at_door and awake and phase<21 and not occupied.has(key)
	w.set_meta("peek_visible",visible_face)
	if visible_face: occupied[key] = true
	w.queue_redraw()
func step(delta: float,cycle: RefCounted) -> void:
	_update_windows(cycle)
	duty_clock -= delta
	if duty_clock>0 or cycle.minutes<490 or cycle.minutes>1320: return
	duty_clock = 12
	# A local detour can fill a real nearby gap after an encounter; retain the next appointment.
	var all: Array = director.world.social_life.actors
	for a in director.world.festival_life.residents:
		if not MOBILE.has(str(a.entry.role)) or a.profile.has("guardian") or int(a.entry.age)>=70: continue
		if not director.world.social_life._eligible(a,65) or a.state!="activity" or a.appointment.place=="cinema": continue
		var nearby: int = all.filter(func(b):return b.available() and b.position.distance_to(a.position)<600).size()
		if nearby<4: continue
		var best := Vector2.INF; var score := 0.0
		for p in samples:
			var distance: float = a.position.distance_to(p)
			if distance<350 or distance>1500: continue
			var gap := INF
			for b in all:
				if b.available(): gap = minf(gap,b.position.distance_to(p))
			if gap>score and gap>450: score = gap; best = p
		if best==Vector2.INF: continue
		if a._begin_walk(best,"walking"):
			a.anchor = best; a.prepare_stroll(); street_trips += 1
			return
func audit(cycle: RefCounted) -> Dictionary:
	var points: Array[Vector2] = []
	for a in director.world.social_life.actors:
		if a.available() or a.state=="window": points.append(a.position)
	for w in windows:
		if w.get_meta("peek_visible",false): points.append(w.contact)
	var max_gap := 0.0; var occupied := 0
	for p in samples:
		var gap := INF
		for at in points: gap = minf(gap,p.distance_to(at))
		max_gap = maxf(max_gap,gap)
		if gap<1050: occupied += 1
	var areas: Dictionary = {}
	for key in director.world.living_life.DATA.data.zones:
		var raw: Array = director.world.living_life.DATA.data.zones[key]
		var center := Vector2(raw[0],raw[1])
		areas[key] = points.filter(func(p):return p.distance_to(center)<1800).size()
	return {"minute":cycle.minutes,"street_samples":samples.size(),"samples_with_life":occupied,"worst_gap":roundi(max_gap),"areas":areas,"public_people":points.size(),"assigned_walks":assignments.size(),"windows":windows.size()}
