extends SceneTree
var failed := false

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failed = true
		push_error(message)

func run() -> void:
	var cycle = preload("res://scripts/day_cycle.gd").new()
	check(cycle.clock_text()=="08:00" and cycle.phase()=="Manhã", "Start in the morning")
	for entry in [[0,"Madrugada"],[6,"Manhã"],[12,"Meio-dia"],[14,"Tarde"],[18,"Crepúsculo"],[20,"Noite"]]:
		cycle.minutes = entry[0]*60.0
		check(cycle.phase()==entry[1], "Phase boundary: "+entry[1])
		var at_boundary: Color = cycle.light_color()
		cycle.minutes = fposmod(cycle.minutes-0.001,1440.0)
		var before: Color = cycle.light_color()
		check(absf(before.r-at_boundary.r)<0.001 and absf(before.b-at_boundary.b)<0.001, "Light must remain continuous")
	cycle.minutes = 1439.5
	cycle.advance(1.0)
	check(cycle.day==2 and cycle.clock_text()=="00:00" and cycle.phase()=="Madrugada", "Midnight rollover")
	cycle.advance(2880.0)
	check(cycle.day==4 and is_equal_approx(cycle.minutes,0.5), "Large updates preserve elapsed days")
	var scene = load("res://scenes/garden.tscn").instantiate()
	root.add_child(scene)
	scene.set_process(false)
	var initial: float = scene.day_cycle.minutes
	scene._process(60.0)
	check(is_equal_approx(scene.day_cycle.minutes,initial+60.0), "Game advances shared clock")
	check(scene.hud.day_cycle==scene.day_cycle, "HUD uses shared clock")
	check(scene.daylight.get_shader_parameter("daylight")==scene.day_cycle.light_color(), "World lighting follows clock")
	initial = scene.day_cycle.minutes
	scene._toggle_pause()
	scene._process(60.0)
	check(scene.day_cycle.minutes==initial, "Pause freezes time")
	scene._toggle_pause()
	scene._toggle_map()
	scene._process(60.0)
	check(scene.day_cycle.minutes==initial, "Map freezes time")
	scene._toggle_map()
	scene._process(1.0)
	check(scene.day_cycle.minutes>initial, "Closing map resumes time")
	check(scene.dialogue_context().day_phase==scene.day_cycle.phase(), "Dialogue context shares time")
	if not failed:
		print("PASS: six phases, smooth lighting, midnight, shared clock, pause and map")
	quit(1 if failed else 0)
