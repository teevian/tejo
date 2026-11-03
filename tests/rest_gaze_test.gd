extends SceneTree
const Gaze = preload("res://scripts/rest_gaze.gd")
var failed := false

func check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		push_error(message)

func _initialize() -> void:
	call_deferred("run")
	create_timer(15,true,false,true).timeout.connect(func(): quit(1))

func run() -> void:
	var a = Gaze.new()
	var b = Gaze.new()
	a.rng.seed = 42
	b.rng.seed = 951
	for pose in 2:
		a.reset()
		b.reset()
		var seen := {}
		var waits := {}
		var distinct := false
		var previous := 2
		var target := 2
		var since_change := 0.0
		for i in 36000:
			a.step(1.0/60.0,pose,1,b.target==0)
			b.step(1.0/60.0,pose,-1,a.target==4)
			check(absi(a.key-previous)<=1,"Head turns must pass through the intermediate drawing")
			check(a.scheduled_wait>=1.5 and a.scheduled_wait<=3.5,"Every gaze wait must stay between 1.5 and 3.5 seconds")
			if a.target!=target:
				check(since_change>=1.48 and since_change<=3.52,"The interval between actual changes must stay within the requested bounds")
				since_change = 0
				seen[a.target] = true
				waits[snappedf(a.scheduled_wait,0.1)] = true
			previous = a.key
			target = a.target
			since_change += 1.0/60.0
			distinct = distinct or a.key!=b.key or absf(a.remaining-b.remaining)>0.1
		check(seen.size()==3,"Both seated and supine rest must visit both sides and the forward/sky view")
		check(waits.size()>10 and distinct,"Each character needs varied independent waits")
	# The real character must advance only while fully resting, and freeze in modals.
	var floor_scene = load("res://scenes/walking_test.tscn").instantiate()
	root.add_child(floor_scene)
	await physics_frame
	var p = floor_scene.people[0]
	p.ground_seated = true
	p.ground_rest = true
	p.seat_id = "ground_rest"
	p.rest_gaze.rng.seed = 817
	await physics_frame
	p.rest_gaze.remaining = 0.01
	for i in 20: await physics_frame
	check(p.rest_gaze.key in [0,4],"Resting physics must animate a complete diagonal head turn")
	var held: float = p.rest_gaze.remaining
	p.in_dialogue = true
	p.map_blocked = true
	for i in 20: await physics_frame
	check(p.rest_gaze.remaining==held,"The map/dialogue must freeze the head timer")
	p.in_dialogue = false
	p.map_blocked = false
	floor_scene._toggle_pause()
	for i in 20: await physics_frame
	check(p.rest_gaze.remaining==held,"Pause must freeze the head timer")
	floor_scene._toggle_pause()
	p.stand_up(true)
	check(p.rest_gaze.key==2 and p.rest_gaze.pose==-1,"Leaving the ground must reset the head animation")
	floor_scene.queue_free()
	await process_frame
	if not failed: print("PASS: independent random 1.5-to-3.5-second gaze changes, five smooth head keys, all seated/supine directions and modal freeze")
	quit(1 if failed else 0)
