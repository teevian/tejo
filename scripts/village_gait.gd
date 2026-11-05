extends RefCounted
## Speed, step length and support timing belong to the individual, including commutes.
var kind := "adult"
var walk_speed := 72.0
var commute_speed := 125.0
var stride := 90.0
var cycle := 1.0
var offset := 0.0
func configure(actor: CharacterBody2D) -> void:
	var e: Dictionary = actor.entry
	var variation: int = absi(str(e.id).hash())
	offset = float(variation%100)/100
	walk_speed = maxf(float(e.speed),62)+variation%17
	commute_speed = 130+variation%12
	stride = 82+variation%25
	if int(e.age)<13:
		kind = "child_run"; walk_speed = 130+variation%25; commute_speed = 150+variation%20; stride = 66+variation%16; cycle = .43
	elif int(e.age)<18:
		kind = "brisk"; walk_speed = 95+variation%20; commute_speed = 135+variation%15; stride = 85+variation%12
	elif int(e.age)>=75:
		kind = "elder"; walk_speed = 31+variation%9; commute_speed = 43+variation%7; stride = 38+variation%12; cycle = 1.6
	elif int(e.age)>=65:
		kind = "older"; walk_speed = 43+variation%12; commute_speed = 59+variation%12; stride = 52+variation%14; cycle = 1.3
	if e.id in ["antonio","helena_turista","artur_cinema","salim_turista"]:
		kind = "cane"; walk_speed = 33+variation%5; commute_speed = walk_speed+5; stride = 31+variation%7; cycle = 1.65+offset*.4
	if e.id=="duarte": kind = "wheelchair"; walk_speed = 70; commute_speed = 98; stride = 106; cycle = 1.25
	if e.id in ["dinis","camila","joao"]: kind = "hurried"; walk_speed = 165 if e.id=="dinis" else 110; commute_speed = walk_speed+10; stride = 114; cycle = .5
	if e.id in ["bia","ana_fruta","quim_doces"]: kind = "loaded"; walk_speed = minf(walk_speed,64); stride = 58
	e.speed = walk_speed
	actor.motion.personality = actor.motion.personality.duplicate(true)
	actor.motion.personality.stride_length = stride
func support_phase(clock: float) -> int:
	var t: float = fposmod(clock/cycle+offset,1)
	return 0 if t<.24 else (1 if t<.61 else (2 if t<.79 else 3))
func speed(actor: CharacterBody2D) -> float:
	var result: float = commute_speed if actor.state=="commuting" else walk_speed
	if kind=="cane": result *= [0.0,1.0,.30,.72][support_phase(actor.clock)]
	elif kind=="child_run": result *= .92+sin(actor.clock*1.7+offset*TAU)*.12
	elif kind=="wheelchair": result *= .72+.28*maxf(0,sin(actor.clock*TAU/cycle))
	elif kind=="loaded": result *= .93+.07*sin(actor.clock*3+offset*TAU)
	return result
func localize_schedule(actor: CharacterBody2D) -> void:
	if int(actor.entry.age)<70: return
	var world: Node2D = actor.population.world
	var routines: RefCounted = actor.population.routines
	for block in actor.schedule:
		if block.place in ["cinema","residence","home"]: continue
		if block.mode=="inside":
			block.destination = routines.doorway(actor.home,false,"Café")
		elif actor.home.distance_to(block.destination)>2300:
			# Retired neighbours keep a local circuit instead of sprinting across town.
			var offset_point := Vector2(160+actor.ordinal%4*65,70)
			block.destination = routines.clear_destination(actor.home+offset_point,[],26)
		block.location = world.area_at(block.destination)
