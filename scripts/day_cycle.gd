extends RefCounted
## One game minute per real second; all time-dependent systems share this clock.
signal time_changed
signal phase_changed(phase: String)

const MINUTES_PER_DAY := 1440.0
const PHASES := ["Madrugada", "Manhã", "Meio-dia", "Tarde", "Crepúsculo", "Noite"]
const STARTS := [0.0, 6.0, 12.0, 14.0, 18.0, 20.0]
const LIGHT_HOURS := [0.0, 4.0, 6.0, 8.0, 12.0, 14.0, 17.0, 18.0, 19.0, 20.0, 22.0, 24.0]
const LIGHT_COLORS := [Color("485577"), Color("505f80"), Color("c2a7a0"), Color("f5e6cd"), Color("ffffff"), Color("fff4df"), Color("edc293"), Color("d39b88"), Color("a17891"), Color("657195"), Color("485577"), Color("485577")]
var minutes := 480.0
var day := 1
var minutes_per_second := 1.0

func advance(delta: float) -> void:
	if delta <= 0.0 or minutes_per_second <= 0.0:
		return
	var previous_phase := phase()
	var previous_minute := floori(minutes)
	var total := minutes + delta * minutes_per_second
	day += floori(total / MINUTES_PER_DAY)
	minutes = fposmod(total, MINUTES_PER_DAY)
	if previous_phase != phase():
		phase_changed.emit(phase())
	if previous_minute != floori(minutes) or total >= MINUTES_PER_DAY:
		time_changed.emit()

func phase() -> String:
	for i in range(STARTS.size()-1, -1, -1):
		if minutes / 60.0 >= STARTS[i]:
			return PHASES[i]
	return PHASES[0]

func clock_text() -> String:
	var whole := floori(minutes)
	return "%02d:%02d" % [whole / 60, whole % 60]

func light_color() -> Color:
	var hour := minutes / 60.0
	for i in range(LIGHT_HOURS.size()-1):
		if hour <= LIGHT_HOURS[i+1]:
			var blend := smoothstep(LIGHT_HOURS[i], LIGHT_HOURS[i+1], hour)
			return LIGHT_COLORS[i].lerp(LIGHT_COLORS[i+1], blend)
	return LIGHT_COLORS[0]
