extends RefCounted
## Five drawn keys: left diagonal, half-left, forward/sky, half-right, right diagonal.
const MIN_WAIT := 1.5
const MAX_WAIT := 3.5
const KEY_SECONDS := 0.12
var rng := RandomNumberGenerator.new()
var pose := -1
var key := 2
var target := 2
var remaining := 0.0
var turn_time := 0.0
var scheduled_wait := 0.0

func _init() -> void:
	rng.randomize()

func reset() -> void:
	pose = -1
	key = 2
	target = 2
	remaining = 0
	turn_time = 0

func _schedule() -> void:
	scheduled_wait = rng.randf_range(MIN_WAIT,MAX_WAIT)
	remaining = scheduled_wait

func step(delta: float, resting_pose: int, partner_side: int, partner_looking := false) -> void:
	if pose!=resting_pose:
		reset()
		pose = resting_pose
		_schedule()
	remaining -= delta
	if remaining<=0:
		var toward := 4 if partner_side>=0 else 0
		var choices: Array[int] = []
		var weights: Array[float] = []
		for candidate in [0,2,4]:
			if candidate==target: continue
			choices.append(candidate)
			if pose==0:
				weights.append(1.5 if candidate==2 else 1.0)
			else:
				# Listening favours the sky, with occasional reciprocal glances.
				var weight := 1.5
				if candidate==2: weight = 5.0
				elif candidate==toward: weight = 6.0 if partner_looking else 4.0
				weights.append(weight)
		var pick: float = rng.randf()*weights.reduce(func(a,b): return a+b,0.0)
		for i in choices.size():
			pick -= weights[i]
			if pick<=0 or i==choices.size()-1:
				target = choices[i]
				break
		turn_time = 0
		_schedule()
	if key!=target:
		turn_time += delta
		while turn_time>=KEY_SECONDS and key!=target:
			key += 1 if target>key else -1
			turn_time -= KEY_SECONDS
	else:
		turn_time = 0
