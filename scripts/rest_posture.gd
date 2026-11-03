extends RefCounted
## Occasional whole-body adjustments while resting; head glances keep their own clock.
const MIN_WAIT := 20.0
const MAX_WAIT := 35.0
var rng := RandomNumberGenerator.new()
var pose := -1
var remaining := 0.0

func _init() -> void:
	rng.randomize()

func reset() -> void:
	pose = -1
	remaining = 0

func step(delta: float, current: int) -> int:
	if current<1:
		reset()
		return -1
	if pose!=current:
		pose = current
		remaining = rng.randf_range(MIN_WAIT,MAX_WAIT)
	remaining -= delta
	if remaining>0: return -1
	var candidates: Array[int] = []
	for candidate in [1,2,3]:
		if candidate!=current: candidates.append(candidate)
	return candidates[rng.randi_range(0,candidates.size()-1)]
