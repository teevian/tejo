extends SceneTree
var scene: Node2D
var world: Node2D
var night: Node2D
var failed := false
func _initialize() -> void:
	create_timer(300,true,false,true).timeout.connect(func():push_error("Nightlife timeout");quit(2))
	call_deferred("run")
func check(ok: bool,message: String) -> void:
	if not ok: failed = true; push_error(message)
func at(time: float) -> void:
	scene.day_cycle.minutes = time; world.synchronize_clock(scene.day_cycle,true)
func ticks(seconds: float,advance := true) -> void:
	for i in roundi(seconds*4):
		if advance: scene.day_cycle.advance(.25)
		world.step_environment(.25,scene.day_cycle); await physics_frame
func run() -> void:
	scene = load("res://scenes/sintra_village.tscn").instantiate(); root.add_child(scene)
	for i in 5: await physics_frame
	scene.set_process(false); world = scene.world; night = world.nightlife
	for p in scene.people: p.set_physics_process(false); p.position = Vector2(1500,14000)
	check(not world.living_life.storage_enabled,"Never write the player's save in tests")
	check(night.patrons.size()==10,"Nine adult guests and a closing-shift host, all existing identities")
	check(night.patrons.all(func(a):return a.entry.age>=18),"The night bar has adult patrons")
	check(night.patrons.filter(func(a):return a.entry.age<30).size()>=8,"Mostly young adult guests")
	check(night.building.label=="Recanto Lord Byron","Nightlife belongs to the real bar frontage")
	check(not world.is_walkable(night.counter.position-Vector2(0,12),1),"The bar counter blocks movement and was baked into navigation")
	for a in night.patrons:
		for point in [night.spots[a.entry.id],night.dance_spots.get(a.entry.id,night.spots[a.entry.id])]:
			check(world.is_walkable(point,12),"Accessible bar spot: "+a.entry.id)
			check(not world.find_path(a.home,point).is_empty(),"Connected walk to the bar: "+a.entry.id)
		var frames: Array = night.ART.data.characters[a.entry.id]
		check(frames.size()==(2 if a.entry.id=="nuno" else 4),"Native individual conversation and dance poses: "+a.entry.id)
		if frames.size()==4: check(frames[2].rect!=frames[3].rect,"Distinct complete dance counterposes: "+a.entry.id)
	at(720)
	check(not night.opened and not night.music.playing and night.light_level==0,"Bar music and warm lights are off at noon")
	at(1229); check(not night.opened,"Not open before 20:30")
	at(1230); check(night.opened,"Opens exactly at 20:30")
	# Continuous ordinary play: arrivals, conversations, dance, midnight, and homeward walks.
	at(1190)
	var previous: Dictionary = {}
	for a in night.patrons: previous[a.entry.id] = a.position
	var poses: Dictionary = {}; var arrivals: Dictionary = {}; var departures: Dictionary = {}
	var max_present := 0; var after_midnight := 0
	for i in 2280: # 19:50 through 05:20, including the midnight wrap.
		scene.day_cycle.advance(.25); world.step_environment(.25,scene.day_cycle); await physics_frame
		var present := 0
		for a in night.patrons:
			check(a.position.distance_to(previous[a.entry.id])<90,"No teleport on an ordinary night: "+a.entry.id)
			previous[a.entry.id] = a.position
			if a.available(): check(world.is_walkable(a.position,10),"Walk remains on public paving: "+a.entry.id)
			if a.get_meta("nightlife_owned",false):
				present += 1; arrivals[a.entry.id] = true
				if not poses.has(a.entry.id): poses[a.entry.id] = {}
				poses[a.entry.id][a.get_meta("nightlife_frame",-1)] = true
			elif arrivals.has(a.entry.id) and a.appointment.get("place","")!="nightlife": departures[a.entry.id] = true
		max_present = maxi(max_present,present)
		if scene.day_cycle.minutes<70 and night.opened: after_midnight = maxi(after_midnight,present)
	check(max_present>=8,"A real crowd arrives without the camera nearby: "+str(max_present))
	check(after_midnight>=5,"Nightlife continues across midnight: "+str(after_midnight))
	check(night.conversation_turns>=12,"Actual alternating conversations continue after the generic social cutoff")
	check(night.dance_changes>=20,"Dancers repeatedly use distinct native counterposes")
	for id in ["gil","afonso","camila","beatriz"]:
		check(poses.get(id,{}).has(2) and poses.get(id,{}).has(3),"Individual changes between both dance poses: "+id)
	check(departures.size()==10,"Staggered guests and host all leave their night activity: "+str(departures.keys()))
	check(night.patrons.all(func(a):return not a.available() and not a.event_busy),"Everyone reaches a real indoor destination after closing")
	check(not night.opened and not night.music.playing and night.light_level==0,"Closing switches off music and bar lights")
	at(1380); await ticks(75,false)
	check(night.patrons.filter(func(a):return a.get_meta("nightlife_owned",false)).size()>=8,"Returning to the village at night restores the existing gathering")
	var before: int = night.music_requests
	night.interact(scene.people[0]); world.living_life.panel.choose(0)
	check(night.music_requests==before+1 and night.track==1 and night.music.stream==night.tracks[1],"Player request changes the actual instrumental and dance rhythm")
	var moving: Array = night.patrons.filter(func(a):return a.get_meta("nightlife_mode","")=="dance")
	if not moving.is_empty():
		var a: CharacterBody2D = moving[0]; night.greet(a); await ticks(.5,false)
		check(a.get_meta("nightlife_mode","")!="dance","Greeting interrupts a dancer naturally")
	at(180)
	check(night.patrons.all(func(a):return not a.get_meta("nightlife_owned",false) and a.get_meta("nightlife_pose",{}).is_empty()),"Seeking the clock releases all bar poses and reservations")
	at(1380)
	world.hide(); check(night.music.stream_paused,"Music pauses when leaving the village"); world.show()
	at(720); check(night.patrons.any(func(a):return a.appointment.place!="nightlife"),"Daytime lives still belong to their original routines")
	print("NIGHT AUDIT center=",night.center," arrivals=",arrivals.size()," max_present=",max_present," after_midnight=",after_midnight," speech_turns=",night.conversation_turns," dance_changes=",night.dance_changes)
	for a in night.patrons: print("BAR SPOT ",a.entry.id," ",night.spots[a.entry.id]," dance ",night.dance_spots.get(a.entry.id,Vector2.ZERO))
	scene.queue_free()
	for i in 10: await physics_frame
	if not failed: print("PASS: adult nightlife, arrivals on foot, candid conversation, native dancing, midnight, closing, return home, lights, music, player participation and catch-up")
	quit(1 if failed else 0)
