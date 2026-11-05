extends SceneTree
var scene: Node2D
var world: Node2D
var n: Node2D
var failed := false
func _initialize() -> void:
	seed(5112026)
	create_timer(360,true,false,true).timeout.connect(func():push_error("Neighbourhood test timeout");quit(2))
	call_deferred("run")
func check(ok: bool,text: String) -> void:
	if not ok: failed = true; push_error(text)
func at(time: float) -> void:
	scene.day_cycle.minutes = time; world.synchronize_clock(scene.day_cycle,true)
func ticks(seconds: float,advance := true) -> void:
	for i in roundi(seconds*4):
		if advance: scene.day_cycle.advance(.25)
		world.step_environment(.25,scene.day_cycle); await physics_frame
func run() -> void:
	scene = load("res://scenes/sintra_village.tscn").instantiate(); root.add_child(scene)
	for i in 5: await physics_frame
	scene.set_process(false); world = scene.world; n = world.neighbourhood
	for p in scene.people: p.set_physics_process(false); p.position = Vector2(1500,14000)
	check(not world.living_life.storage_enabled,"Tests never load or write the human player's community save")
	check(n.residents.size()==20,"Exactly twenty new authored story identities")
	var ids: Dictionary = {}
	for a in world.social_life.actors:
		check(not ids.has(a.entry.id),"No duplicated actor identity: "+a.entry.id); ids[a.entry.id] = true
	for a in n.residents:
		check(a.entry.story.length()>60 and a.motion.personality.lines.size()>=2,"Personal story and voice: "+a.entry.id)
		check(n.ART.data.characters[a.entry.id].frames.size()==8,"Four personal acting expressions and four directional walking frames: "+a.entry.id)
		for b in a.schedule:
			check(world.is_walkable(b.destination,12),"Actual public approach to a daily appointment: "+a.entry.id+" "+b.place)
			check(not world.find_path(a.home,b.destination).is_empty(),"Connected daily path: "+a.entry.id)
	check(n.ART.data.props.size()==8 and n.ART.data.pigeon.size()==8,"Authored painted objects and letter-carrying courier animation")
	check(not world.is_walkable(n.objects.foosball.position-Vector2(0,18),1),"Foosball table is a real navigable obstacle")
	at(450)
	var previous: Dictionary = {}
	for a in n.residents: previous[a.entry.id] = a.position
	var poses: Dictionary = {}
	var audits: Array = []
	for i in 4320:
		scene.day_cycle.advance(.25); world.step_environment(.25,scene.day_cycle); await physics_frame
		for a in n.residents:
			check(a.position.distance_to(previous[a.entry.id])<90,"An ordinary day never teleports a neighbour: "+a.entry.id)
			previous[a.entry.id] = a.position
			if not poses.has(a.entry.id): poses[a.entry.id] = {}
			if a.story_frame>=0: poses[a.entry.id][a.story_frame] = true
		if i%480==0 and scene.day_cycle.minutes>=480 and scene.day_cycle.minutes<1330:
			var audit: Dictionary = n.presence.audit(scene.day_cycle); audits.append(audit)
			for area in audit.areas: check(int(audit.areas[area])>0,"No empty district at "+str(scene.day_cycle.minutes)+": "+area)
			check(float(audit.samples_with_life)/audit.street_samples>.94,"Street coverage remains widespread through the ordinary day")
	# The Lord Byron now closes at 01:30. Give its guests their real walk home
	# before checking overnight sleep; 01:30 is no longer an all-asleep deadline.
	await ticks(150)
	for a in world.social_life.actors:
		if a.available() and not world.passers.night_people.has(a): print("OVERNIGHT ",a.entry.id," ",a.state," mode ",a.appointment.mode," at ",a.position," -> ",a.anchor," goal ",a.goal," route ",a.route.size()," lock ",a.event_busy," ",a.social_lock)
	for a in world.passers.night_people:
		if not a.available(): print("NIGHT ",a.entry.id," ",a.state," shopping ",a.shopping)
	check(world.social_life.actors.filter(func(a):return not world.passers.night_people.has(a)).all(func(a):return not a.available()),"Ordinary continuous play brings all daytime people indoors overnight")
	check(world.passers.night_people.all(func(a):return a.available()),"Night workers begin their own shift by walking outside")
	for role in ["picnic","pigeon","queue","window","foosball","raffle","papers"]:
		check(int(n.state.get("episodes_"+role,0))>0,"The story actually unfolds without a nearby player: "+role)
	for a in n.residents:
		check(poses[a.entry.id].size()>=2,"Different visible acting beats: "+a.entry.id+" "+str(poses[a.entry.id]))
	check(int(n.state.get("pigeon_deliveries",0))>0 and int(n.state.get("pigeon_receipts",0))>0,"Courier really travels both directions before the receipt is counted")
	check(n.by_id.beatriz_fila.entered_shops>0,"Queue optimizer actually enters the Piriquita")
	check(not n.episodes.observations.is_empty() and int(n.state.get("quiet_deliveries",0))>0,"Window observer sees real passers and grocer uses the television interval")
	check(world.passers.residents.any(func(a):return a.shop_entries>0),"Background visitors really enter and leave nearby shops")
	# Exact television break rather than an arbitrary random disappearing face.
	at(1108); check(n.by_id.odete_janela.state=="inside","Odete leaves her window for the 18:20 television programme")
	at(1125); check(n.by_id.odete_janela.state=="window","Odete returns to the same native window at 18:40")
	# Transactional story participation through the actual choices panel.
	at(650); await ticks(45,false)
	var p: CharacterBody2D = scene.people[0]
	p.inventory.items.clear()
	n.dialogues.open_scene("papers",p); world.living_life.panel.choose(1)
	check(p.inventory.items.any(func(item):return item.type=="neighbour_pen"),"Waiter lends an actual inventory pen")
	n.dialogues.open_scene("raffle",p); world.living_life.panel.choose(2)
	check(n.state.get("vasco_pen",false) and not p.inventory.items.any(func(item):return item.type=="neighbour_pen"),"Loaned pen actually reaches the bureaucratic scout")
	n.dialogues.open_scene("raffle",p); world.living_life.panel.choose(1)
	check(p.inventory.items.any(func(item):return item.type=="raffle_ticket"),"Resolved scout procedure yields a real numbered Minecraft raffle ticket")
	var count: int = p.inventory.items.size()
	n.dialogues.open_scene("raffle",p); world.living_life.panel.choose(1)
	check(p.inventory.items.size()==count,"Repeated conversation cannot duplicate a day's raffle ticket")
	p.inventory.items.clear()
	check(not n.episodes.papers.is_empty(),"Wind leaves collectible papers in the public world")
	if not n.episodes.papers.is_empty():
		var paper: Node2D = n.episodes.papers[0]
		n.episodes.collect_paper(paper,p)
		check(paper.collected and p.inventory.items[0].type=="neighbour_exam","A loose exam is actually carried and removed from the street")
		n.dialogues.open_scene("papers",p); world.living_life.panel.choose(0)
		check(p.inventory.items.is_empty() and int(n.state.get("papers_returned",0))>0,"Returning an exam removes that exact carried sheet")
	at(1020); await ticks(1,false)
	for i in 3:
		n.dialogues.open_scene("foosball",p)
		var defence: int = n.episodes.player_match.defence
		world.living_life.panel.choose((defence+1)%3)
	check(int(n.state.get("player_wins",0))==1 and n.episodes.player_match.is_empty(),"Player can finish and win an actual three-goal foosball match")
	at(720); n.dialogues.open_scene("picnic",p); world.living_life.panel.choose(0)
	check(n.objects.thermos.index==2 and int(n.state.get("thermos_opened",0))>0,"Helping the picnic visibly changes the thermos object")
	# A clock seek must remove old paper targets as well as their nodes.
	at(700); await ticks(.5,false)
	check(world.interactions.targets.all(func(t):return not t.has("node") or is_instance_valid(t.node)),"Reset leaves no dangling interaction targets")
	print("Neighbourhood audit: 20 story people, 7 autonomous stories, ",world.passers.residents.size()," background lives, ",n.presence.windows.size()," native window positions with occupancy checks")
	for audit in audits: print("COVERAGE ",JSON.stringify(audit))
	scene.queue_free()
	for i in 10: await physics_frame
	if not failed: print("PASS: new stories, real errands, native poses, all districts populated, shops, window timing, picnic, pigeon post, queue, foosball, raffle and exam recovery")
	quit(1 if failed else 0)
