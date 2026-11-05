extends RefCounted
## Unequal authored holds, intentional pauses and personal stride; never deform sprites.
const DATA = preload("res://data/village/npc-personalities.json")
var personality: Dictionary = {}
var rng := RandomNumberGenerator.new()
var extra := -1
var phase := "rest"
var remaining := 0.0
var sequence: Array = []
var index := 0
var elapsed := 0.0
var stride_phase := 0.0
var changes := 0
var hop := 0.0
var actor_id := ""

func configure(entry: Dictionary) -> void:
	actor_id = entry.id
	personality = DATA.data.people.get(entry.id,entry.get("personality",{}))
	rng.seed = absi(str(entry.id).hash())+11032026
	remaining = rng.randf_range(.2,2.8)

func step(actor: CharacterBody2D, delta: float, walked: float) -> void:
	elapsed += delta
	hop = 0
	var planted: bool = actor.gait.kind=="cane" and not actor.route.is_empty() and actor.state in ["walking","commuting","returning","yielding"] and not actor.event_busy and not actor.social_lock and actor.greet_time<=0
	if walked>.02 or planted:
		if phase!="walk":
			sequence.clear()
			index = 0
			remaining = 0
		phase = "walk"
		extra = -1
		stride_phase = fposmod(stride_phase+walked/float(personality.stride_length),1)
		actor.frame = 2 if stride_phase<.44+float(personality.restlessness)*.12 else 3
		return
	var requested: String = actor.social_pose
	if actor.greet_time>0 and requested.is_empty(): requested = "greet"
	if actor.snack_until>actor.clock and requested.is_empty() and actor.entry.has("friend_of"): requested = "enjoy"
	if not requested.is_empty():
		remaining = 0
		sequence.clear()
		index = 0
		phase = requested
		extra = _social_extra(requested)
		actor.frame = 1 if requested in ["speak","offer","capture","clap","greet"] else 0
		if requested=="play":
			var beat := int(elapsed*(3.4+float(personality.restlessness)))%4
			extra = [1,-1,3,-1][beat]
			actor.frame = 1 if beat%2 else 0
		elif requested=="clap" and actor.entry.has("friend_of"):
			var interval: float = .22+float(personality.restlessness)*.12
			var beat := fposmod(elapsed+float(personality.stride_length)*.13,interval*6+1.0)
			extra = 4+int(beat/interval)%2 if beat<interval*6 else 0
		return
	remaining -= delta
	if remaining<=0:
		if sequence.is_empty() or index>=sequence.size():
			sequence = _sequence(actor)
			index = 0
		var step_data: Array = sequence[index]
		phase = step_data[0]
		extra = int(step_data[1])
		actor.frame = int(step_data[2])
		remaining = float(step_data[3])*rng.randf_range(.82,1.24)
		index += 1
		changes += 1
	if phase=="hop": hop = sin(clampf(1-remaining/.5,0,1)*PI)*8

func _social_extra(pose: String) -> int:
	# Quiet exchanges use each person's new candid poses; a greeting is not a grin loop.
	if pose in ["listen","speak","greet","pose","thanks"]: return -1
	var style: String = personality.style
	if actor_id in ["gil","tiago","alexandre","martim","afonso"]:
		return {"listen":0,"greet":1,"speak":1,"pose":1,"clap":2,"enjoy":3,"offer":1,"thanks":1}.get(pose,0)
	if actor_id=="matilde": return {"hop":1,"greet":3,"pose":3,"speak":3,"listen":0}.get(pose,0)
	if actor_id=="leonor": return {"capture":1,"review":2,"speak":3,"greet":3,"listen":0}.get(pose,0)
	if style in ["guitar","violin"]: return {"play":1,"thanks":2,"clap":2,"speak":2,"listen":0,"work":3}.get(pose,0)
	if style=="guide": return {"speak":1,"greet":3,"listen":2,"pose":3}.get(pose,0)
	if style in ["pottery","gelato","raffle","police"]: return {"offer":1,"speak":1,"greet":2,"thanks":2,"listen":0,"work":3}.get(pose,0)
	return -1

func _sequence(actor: CharacterBody2D) -> Array:
	var hold: float = rng.randf_range(personality.idle_hold[0],personality.idle_hold[1])
	var action: float = rng.randf_range(personality.gesture_hold[0],personality.gesture_hold[1])
	var style: String = personality.style
	if actor_id in ["gil","tiago","alexandre","martim","afonso"]:
		return [["rest",0,0,hold],["look",0,0,1.1],["work",-1,1,action],["rest",0,0,hold*.55]]
	match style:
		"guitar","violin": return [["ready",0,0,1.5],["play",1,0,.35],["play",-1,1,.43],["play",1,0,.52],["play",-1,0,.3],["tune",3,0,1.1],["rest",0,0,2.2]]
		"guide": return [["listen",0,0,hold],["explain",1,1,1.8],["listen",2,0,1.3],["smile",3,1,action],["rest",0,0,hold*.6]]
		"pottery": return [["rest",0,0,hold],["polish",3,0,2.1],["inspect",-1,1,action],["rest",0,0,2.5]]
		"gelato": return [["ready",0,0,hold],["prepare",3,1,1.8],["rest",0,0,hold*.5]]
		"raffle": return [["ready",0,0,hold],["count",3,0,1.4],["look",0,1,1.6],["rest",0,0,hold*.6]]
		"police": return [["watch",0,0,hold],["radio",3,1,1.5],["listen",0,0,2.1],["rest",0,0,hold*.5]]
		"camera":
			if actor_id=="leonor": return [["look",0,0,hold],["capture",1,1,.8],["review",2,0,2],["rest",0,0,hold*.7]]
			return [["look",-1,0,hold],["aim",-1,1,1.25],["capture",-1,1,.25],["review",-1,0,2.2]]
		"hop":
			if str(actor.appointment.get("activity","")).contains("macaca"): return [["ready",0,0,hold*.5],["hop",1,0,.35],["land",2,0,.45],["rest",0,0,1.4],["wave",3,1,.8]]
			return [["rest",0,0,hold],["wave",3,1,action],["rest",0,0,hold*.6]]
		"knit","garden","painting","bread","textile": return [["prepare",-1,0,hold*.4],["work",-1,1,action],["work",-1,0,.9],["work",-1,1,.75],["inspect",-1,0,hold]]
		"reader","newspaper","wheelchair","notes","drawing","map": return [["focus",-1,0,hold],["turn_page",-1,1,action],["focus",-1,0,hold*.8],["look_up",-1,1,1.3]]
		"ball","bubbles": return [["ready",-1,0,hold*.55],["play",-1,1,.65],["wait",-1,0,1.9],["play",-1,1,action],["rest",-1,0,hold*.65]]
	return [["rest",-1,0,hold],["gesture",-1,1,action],["look",-1,0,2.3],["rest",-1,0,hold*.4]]
