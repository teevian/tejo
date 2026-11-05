extends SceneTree
var scene: Node2D
func _initialize() -> void:
	create_timer(120,true,false,true).timeout.connect(func():push_error("Neighbourhood audit timeout");quit(2))
	call_deferred("run")
func run() -> void:
	scene = load("res://scenes/sintra_village.tscn").instantiate(); root.add_child(scene)
	for i in 5: await physics_frame
	scene.set_process(false)
	for p in scene.people: p.set_physics_process(false); p.position = Vector2(1500,14000)
	var n: Node2D = scene.world.neighbourhood
	for time in [180,480]:
		scene.day_cycle.minutes = time; scene.world.synchronize_clock(scene.day_cycle,true)
		for i in 20:
			scene.world.step_environment(.25,scene.day_cycle); await physics_frame
		print("PRESENCE ",JSON.stringify(n.presence.audit(scene.day_cycle)))
		if time==180:
			for a in scene.world.social_life.actors:
				if a.available() and not scene.world.passers.night_people.has(a): print("AWAKE ",a.entry.id," state ",a.state," mode ",a.appointment.mode," minute ",a.appointment.minute," pos ",a.position," anchor ",a.anchor)
	print("CAST ",n.residents.size()," social ",scene.world.social_life.actors.size()," places ",n.places)
	for a in n.residents: print("NEIGHBOUR ",a.entry.id," ",a.state," ",a.position," home ",a.home," plan ",a.schedule.size())
	scene.queue_free(); await physics_frame; quit()
