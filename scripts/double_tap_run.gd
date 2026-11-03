extends RefCounted
## Same direction twice, with a release between taps; key repeat cannot trigger it.
const WINDOW := 0.28
var running := false
var held := Vector2i.ZERO
var last_tap := Vector2i.ZERO
var elapsed := WINDOW+1.0

func step(input: Vector2, delta: float) -> bool:
	elapsed += delta
	var direction := Vector2i(signi(roundi(input.x)),signi(roundi(input.y)))
	if direction==Vector2i.ZERO:
		running = false
		held = Vector2i.ZERO
	elif direction!=held:
		# Once started, running follows direction changes until movement is released.
		running = running or (held==Vector2i.ZERO and direction==last_tap and elapsed<=WINDOW)
		last_tap = direction
		elapsed = 0
		held = direction
	return running

func reset() -> void:
	running = false
	held = Vector2i.ZERO
	last_tap = Vector2i.ZERO
	elapsed = WINDOW+1.0
