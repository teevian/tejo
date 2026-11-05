extends SceneTree
var scene: Node2D
var failed := false
var world: Node2D
var social: Node2D
func _initialize() -> void:
	create_timer(180).timeout.connect(func(): push_error("Social test timed out"); quit(2))
	call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok: failed = true; push_error(message)
func at_time(minutes: float) -> void:
	scene.day_cycle.minutes = minutes
	world.synchronize_clock(scene.day_cycle,true)
func tick(seconds: float, advance := true) -> void:
	for i in roundi(seconds*4):
		if advance: scene.day_cycle.advance(.25)
		world.step_environment(.25,scene.day_cycle)
		await physics_frame
func prepare_client(actor: CharacterBody2D, host: CharacterBody2D) -> void:
	actor._outside()
	actor.state = "activity"
	actor.route.clear()
	actor.greet_time = 0
	actor.position = world.population.free_point(host.position+Vector2(-250,100),true)
	actor.dwell = 90
	social.cooldowns.clear()
func run() -> void:
	scene = load("res://scenes/sintra_village.tscn").instantiate()
	root.add_child(scene)
	for i in 3: await physics_frame
	scene.set_process(false)
	world = scene.world
	social = world.social_life
	for player in scene.people:
		player.process_mode = Node.PROCESS_MODE_DISABLED
		player.position = Vector2(1500,14000)
	check(social.actors.size()==145+world.passers.residents.size(),"Original residents, twenty story neighbours and street visitors share the encounter system")
	var poses: Dictionary = preload("res://data/village/social-art.json").data.characters
	check(poses.size()==15,"Fifteen characters have additional authored social/activity poses")
	for actor in social.actors:
		check(not actor.motion.personality.is_empty() and actor.motion.personality.lines.size()>=2,"Individual personality: "+actor.entry.id)
	var total_poses := 0
	for id in poses:
		check(poses[id].frames.size()==(6 if id in ["gil","tiago","alexandre","martim","afonso"] else 4),"Complete new authored poses: "+id)
		total_poses += poses[id].frames.size()
		for pose in poses[id].frames:
			var image: Image = load(pose.get("path",poses[id].path)).get_image()
			check(Rect2(Vector2.ZERO,image.get_size()).encloses(Rect2(pose.rect[0],pose.rect[1],pose.rect[2],pose.rect[3])),"Native pose stays inside the atlas: "+id)
	check(total_poses==70,"Seventy new complete poses are integrated")
	# A real approach, handover, memory commit and continuation; no player nearby.
	at_time(960)
	var gil: CharacterBody2D = social.by_id.gil
	var vendor: CharacterBody2D = social.by_id.enzo_gelados
	prepare_client(gil,vendor)
	var old_gelati: int = gil.memory.get("gelati",0)
	check(social._start("gelato",[gil,vendor],vendor.position),"NPC can start a purchase")
	social.next_decision = 100
	var start: Vector2 = gil.position
	await tick(38,false)
	check(gil.position.distance_to(start)>50,"Customer actually walks to the vendor")
	check(gil.memory.get("gelati",0)==old_gelati+1 and gil.snack_until>gil.clock,"Only a completed purchase gives the NPC a cone")
	check(gil.encounter_id<0 and not gil.social_lock,"Customer resumes daily life after the purchase")
	gil.motion.step(gil,.1,0)
	check(gil.motion.extra==3,"Customer has the authored cone pose when pausing to eat")
	check(gil.greet().contains("gelado"),"Greeting remembers the real purchase")
	# Interrupting an encounter releases both people and never records a fake sale.
	at_time(960)
	prepare_client(gil,vendor)
	old_gelati = gil.memory.get("gelati",0)
	check(social._start("gelato",[gil,vendor],vendor.position),"Another purchase can be interrupted")
	gil.greet()
	check(gil.encounter_id<0 and vendor.encounter_id<0 and not vendor.social_lock,"Player interaction releases the partner too")
	check(gil.memory.get("gelati",0)==old_gelati,"Interrupted purchase does not award a cone")
	# The family responds to the shutter together, including the non-speaking child.
	at_time(1050)
	var mother: CharacterBody2D = social.by_id.leonor
	var father: CharacterBody2D = social.by_id.daniel_familia
	var child: CharacterBody2D = social.by_id.matilde
	social.cooldowns.clear()
	check(social._start("family_photo",[mother,father,child],mother.position,false),"A family photograph uses all three actual participants")
	if not social.encounters.is_empty():
		var photo: Dictionary = social.encounters[-1]
		for i in 3:
			photo.remaining = 0
			social._advance(photo,.01)
		check(mother.social_pose=="capture" and child.social_pose=="pose" and mother.flash_until>mother.clock,"The child keeps posing while her mother takes the photograph")
		mother.begin_appointment((mother.routine_index+1)%mother.schedule.size())
		check(child.encounter_id<0 and father.encounter_id<0 and not child.social_lock,"The next appointment releases the whole family")
	# Actual friends alternate turns and remember whom they met.
	at_time(1080)
	var tiago: CharacterBody2D = social.by_id.tiago
	prepare_client(gil,tiago)
	check(social._start("chat",[gil,tiago],tiago.position),"Friends can approach for a conversation")
	social.next_decision = 100
	await tick(35,false)
	check(gil.memory.has("met_tiago") and tiago.memory.has("met_gil"),"Both speakers remember their meeting")
	check(social.stats.get("chat",0)>0,"Conversation finishes and both actors continue")
	# Timelines contain unequal holds and distinct activity phases, not a fixed toggle.
	var phases: Dictionary = {}
	var holds: Dictionary = {}
	for id in ["gil","nuno","teresa","matilde","farid"]:
		var actor: CharacterBody2D = social.by_id[id]
		actor.social_pose = ""
		actor.greet_time = 0
		actor.snack_until = 0
		for i in 160:
			actor.motion.step(actor,.1,0)
			phases[actor.motion.phase] = true
			holds[snappedf(actor.motion.remaining,.1)] = true
	check(phases.size()>=10 and holds.size()>25,"Activities use varied authored gestures, rests and hold lengths")
	gil.social_pose = ""
	gil.motion.remaining = 8
	gil.motion.step(gil,.1,8)
	gil.motion.step(gil,.1,0)
	check(gil.frame<2 and gil.motion.phase!="walk","Stopping a walk immediately restores a standing pose")
	gil.social_pose = "clap"
	var claps: Dictionary = {}
	for i in 40:
		gil.motion.step(gil,.1,0)
		claps[gil.motion.extra] = true
	check(claps.has(4) and claps.has(5) and claps.has(0),"Applause visibly opens hands, makes contact and pauses")
	gil.social_pose = ""
	# Unscripted decisions at different times, with the player still far away.
	social.stats.clear()
	for minute in [600.0,840.0,1020.0,1110.0]:
		at_time(minute)
		var previous: Dictionary = {}
		for actor in social.actors: previous[actor.entry.id] = actor.position
		for i in 720:
			scene.day_cycle.advance(.25)
			world.step_environment(.25,scene.day_cycle)
			await physics_frame
			for actor in social.actors:
				check(actor.position.distance_to(previous[actor.entry.id])<90,"Autonomous encounters never teleport: "+actor.entry.id)
				if actor.available(): check(world.is_walkable(actor.position,10),"Autonomous walking remains on public paving: "+actor.entry.id)
				previous[actor.entry.id] = actor.position
	check(social.stats.get("chat",0)>2,"Residents initiate and complete conversations on their own")
	check(social.stats.size()>=4,"Different autonomous encounters happen over the day: "+str(social.stats))
	var raffle_buyers: Array = []
	for record in social.history:
		if record.kind!="raffle": continue
		var buyer: String = record.people[0]+str(floori(record.minute/1440))
		check(not raffle_buyers.has(buyer),"Autonomous purchases respect one raffle per resident per day")
		raffle_buyers.append(buyer)
	print("Autonomous completed encounters: ",social.stats)
	# Clock jumps and overnight sleep release all temporary reservations.
	at_time(180)
	check(social.encounters.is_empty() and social.actors.all(func(a): return a.encounter_id<0 and not a.social_lock),"Sleep/time jump cancels every temporary encounter")
	check(social.actors.filter(func(a):return not world.passers.night_people.has(a)).all(func(a):return not a.available()),"Daytime residents and visitors still sleep indoors")
	check(world.passers.night_people.all(func(a):return a.available()),"Night shift remains outside while daytime residents sleep")
	scene.queue_free()
	for i in 3: await physics_frame
	if not failed: print("PASS: personal gestures, authored poses, real approaches, reciprocal conversations, purchases/memory, cancellation, autonomous daily encounters and paving")
	quit(1 if failed else 0)
