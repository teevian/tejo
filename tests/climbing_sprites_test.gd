extends SceneTree
## GPU verification of every authored key, then real paired-action choreography.
const Actions = preload("res://scripts/climbing_art.gd")
const Person = preload("res://scripts/climbing_person.gd")
const CELL := Vector2i(220,220)
var failed := false
var scene: Node2D
var cards: Array[Node2D] = []
const LABELS := ["Saltar","Cair","Aterrar","Trepar","Subir corda","Segurar corda","Puxar corda","Empurrar pedra","Dar pé","Receber pé","Puxar pela mão","Receber ajuda","Levar às costas","Subir às costas","Subir a fenda","Passar de gatas"]

class Pose:
	extends Node2D
	var kind := 0
	var action := "jump"
	var frame := 0
	func _draw() -> void:
		Actions.draw_action(self,kind,action,frame)

class Card:
	extends Node2D
	var action := "jump"
	var label := ""
	var frame := 0
	func _draw() -> void:
		draw_style_box(panel(),Rect2(4,4,352,248))
		draw_string(ThemeDB.fallback_font,Vector2(16,30),label,HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color("eadbbd"))
		for kind in 2:
			Actions.draw_action(self,kind,action,frame,Vector2(83+kind*174,234))
	static func panel() -> StyleBoxFlat:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("292e2d")
		style.corner_radius_top_left = 10
		style.corner_radius_top_right = 10
		style.corner_radius_bottom_left = 10
		style.corner_radius_bottom_right = 10
		return style

func _initialize() -> void:
	call_deferred("run")
	create_timer(60,true,false,true).timeout.connect(func():
		push_error("Climbing sprite verification timed out")
		quit(1))

func check(condition: bool, message: String) -> void:
	if not condition:
		failed = true
		push_error(message)

func redraw(view: SubViewport) -> Image:
	await process_frame
	await process_frame
	RenderingServer.force_draw()
	return view.get_texture().get_image()

func run() -> void:
	if DisplayServer.get_name()=="headless":
		push_error("This test requires a graphics window to verify painted frames")
		quit(1)
		return
	var view := SubViewport.new()
	view.size = Vector2i(CELL.x*8,CELL.y*16)
	view.transparent_bg = true
	view.world_2d = World2D.new()
	view.disable_3d = true
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(view)
	for kind in 2:
		for index in 16:
			var action: String = Actions.ACTIONS[index]
			for frame in 4:
				var pose := Pose.new()
				pose.kind = kind
				pose.action = action
				pose.frame = frame
				pose.position = Vector2((kind*4+frame)*CELL.x+110,index*CELL.y+205)
				view.add_child(pose)
				var bounds := Actions.region(action,frame)
				check(Rect2(Vector2.ZERO,Actions.ATLASES[kind][index/4].get_size()).encloses(bounds),"Climbing frame outside its atlas")
	var sheet := await redraw(view)
	for kind in 2:
		for index in 16:
			var hashes: Array[int] = []
			for frame in 4:
				var tile := sheet.get_region(Rect2i((kind*4+frame)*CELL.x,index*CELL.y,CELL.x,CELL.y))
				var count := 0
				for y in CELL.y:
					for x in CELL.x:
						if tile.get_pixel(x,y).a>0.8: count += 1
				check(count>1100,"Missing painted body for %s action %s key %d"%[kind,Actions.ACTIONS[index],frame])
				hashes.append(hash(tile.get_data()))
			check(hashes[0]!=hashes[1] and hashes[1]!=hashes[2] and hashes[2]!=hashes[3],"An action repeats drawings instead of distinct keys")
	sheet.save_png("res://output/climbing-sprites-sheet.png")
	view.queue_free()
	await process_frame
	# The production person selects action clips from physics and contact state.
	var person := Person.new()
	root.add_child(person)
	person.grounded = false
	person.velocity.y = -300
	check(person.animation_state().action=="jump","Ascending physics must select jump art")
	person.velocity.y = 300
	check(person.animation_state().action=="fall","Descending physics must select falling art")
	person.hanging = true
	check(person.animation_state().action=="fall" and person.animation_state().frame==3,"The rope catch must show the arrest reaction first")
	person.hang_time = 0.20
	check(person.animation_state().action=="rope","An arrested fall must grip the rope")
	person.hanging = false
	person.grounded = true
	person.landing_time = 0.20
	check(person.animation_state().action=="land","Contact must select the recovery sequence")
	person.landing_time = 0
	person.anchor = "balance"
	check(person.animation_state().action=="push","Holding the slab must have a braced posture")
	person.queue_free()
	# Actual game helper roles follow either character, including swapped roles.
	scene = load("res://scenes/rock_climbing.tscn").instantiate()
	root.add_child(scene)
	while not scene._initialization_complete: await process_frame
	scene.set_physics_process(false)
	scene.set_process(false)
	for kind in 2:
		for action in ["boost","ride","pull","rope"]:
			var climber = scene.people[kind]
			var helper = scene.people[1-kind]
			for p in scene.people:
				p.traversal.clear()
				p.grounded = true
				p.anchor = ""
				p.view_offset = Vector2.ZERO
				p.choreography_offset = Vector2.ZERO
				p.position = Vector2(500+p.kind*36,4300)
			helper.anchor = "support"
			climber.travel(climber.position+Vector2(40,-190),1,action,1.0)
			climber.progress = 0.15
			scene._sync_climbing_poses()
			var expected: String = {"boost":"legup","ride":"carry","pull":"help","rope":"haul"}[action]
			check(helper.animation_state().action==expected,"Wrong helper role for "+action)
			if action in ["boost","ride"]:
				var from: Vector2 = helper.position+helper.contact_point("back" if action=="ride" else "hand")
				var to: Vector2 = climber.position+climber.contact_point("hip" if action=="ride" else "foot")
				check(from.distance_to(to)<1,"Paired contact separates before release for "+action)
			var visible: PackedVector2Array = scene.visual_rope_points()
			check(visible[0].is_equal_approx(scene.people[0].position+scene.people[0].rope_grip()),"Rope must end at the animated grip")
			climber.step(1.0)
			helper.anchor = ""
			scene._sync_climbing_poses()
			check(helper.assist_action.is_empty() and climber.choreography_offset==Vector2.ZERO,"Paired actions must release both bodies on completion")
	# Chimney bodies must face outward with their backs meeting, even when the
	# foot-root projection alone would place the two heads across one another.
	for phase in [0.10,0.35,0.60,0.85]:
		for kind in 2:
			var p = scene.people[kind]
			p.position = Vector2(500+kind*36,4300)
			p.travel(p.position+Vector2(-35,-200),10,"chimney",1.35)
			p.progress = phase
		scene._sync_climbing_poses()
		check(scene.people[0].face==-1 and scene.people[1].face==1,"Chimney climbers must face away from one another")
		var back_a: Vector2 = scene.people[0].position+scene.people[0].contact_point("back")
		var back_b: Vector2 = scene.people[1].position+scene.people[1].contact_point("back")
		check(absf(back_a.distance_to(back_b)-6)<0.1,"Backs must stay together throughout the chimney cycle")
	scene.queue_free()
	await process_frame
	# Export the same renderer at native game scale, with every action animated.
	var overview := SubViewport.new()
	overview.size = Vector2i(1440,1024)
	overview.world_2d = World2D.new()
	overview.disable_3d = true
	overview.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(overview)
	for index in 16:
		var card := Card.new()
		card.action = Actions.ACTIONS[index]
		card.label = LABELS[index]
		card.position = Vector2((index%4)*360,(index/4)*256)
		overview.add_child(card)
		cards.append(card)
	DirAccess.make_dir_recursive_absolute("/tmp/tejo-climb-work/preview")
	for frame in 12:
		for card in cards:
			card.frame = Actions.frame_for(card.action,-1 if Actions.CYCLES.has(card.action) else float(frame%6)/5.0,frame*0.10)
			card.queue_redraw()
		var rendered := await redraw(overview)
		rendered.save_png("/tmp/tejo-climb-work/preview/%02d.png"%frame)
		if frame==2: rendered.save_png("res://output/climbing-sprites-preview.png")
	overview.queue_free()
	if not failed: print("PASS: 128 distinct painted keys, action/physics selection, both cooperative roles, registered contacts and live rope grips")
	quit(1 if failed else 0)
