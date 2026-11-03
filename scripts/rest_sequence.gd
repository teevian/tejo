extends RefCounted
## Each stage starts its clocks only after BOTH authored transitions have settled.
var rng := RandomNumberGenerator.new()
var stage := "idle"
var elapsed := 0.0
var companion_delay := 0.0
var seat_delay := 0.0
var waits: Array[float] = []
var pending: Array[bool] = []

func _init() -> void:
	rng.randomize()
	reset()

func reset() -> void:
	stage = "idle"
	elapsed = 0
	companion_delay = rng.randf_range(7,10)
	seat_delay = rng.randf_range(10,15)
	waits.clear()
	pending.clear()

func _barrier(people: Array, pose: int) -> bool:
	return people.all(func(p): return p.ground_seated and p.ground_pose==pose and p.rest_transition.is_empty())

func _timed_stage(next: String, minimum: float, maximum: float) -> void:
	stage = next
	elapsed = 0
	waits = [rng.randf_range(minimum,maximum),rng.randf_range(minimum,maximum)]
	pending = [true,true]

func advance(delta: float, people: Array, selected: int, forced := false) -> bool:
	if people.any(func(p): return p.wake_leader or p.wake_waiting or (p.rest_target=="standing" and not p.ground_rest)):
		stage = "waking"
		return false
	if stage=="waking":
		if people.all(func(p): return not p.ground_rest): reset()
		return false
	if forced and stage in ["idle","companion"]: return true
	match stage:
		"idle":
			elapsed += delta
			var companion = people[1-selected]
			# Count the actual animation, including its first authored lowering key.
			if companion.phone_state==companion.PhoneState.TAKING_OUT or companion.phone_state==companion.PhoneState.READING or companion.sand_state==companion.SandState.DRAWING or companion.rest_target=="sand":
				stage = "companion"
				elapsed = 0
		"companion":
			elapsed += delta
			return elapsed>=seat_delay
		"approach":
			if people.all(func(p): return p.ground_waiting and p.phone_state==p.PhoneState.NONE):
				for p in people: p.start_ground_settle()
				stage = "seating"
		"seating":
			if _barrier(people,0): _timed_stage("seated",15,20)
		"seated", "reclined", "lying":
			elapsed += delta
			for i in people.size():
				if not pending[i]: continue
				waits[i] -= delta
				if waits[i]>0 and not forced: continue
				pending[i] = false
				match stage:
					"seated": people[i].begin_reclining()
					"reclined": people[i].begin_lying()
					"lying": people[i].close_rest_eyes()
			if stage=="seated" and _barrier(people,4): _timed_stage("reclined",5,15)
			elif stage=="reclined" and _barrier(people,1): _timed_stage("lying",5,10)
			elif stage=="lying" and people.all(func(p): return p.is_sleeping()): stage = "sleep"
	return false
