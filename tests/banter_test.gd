extends SceneTree
var failed := false
class ErrorLog:
	extends Logger
	var errors: Array[String] = []
	func _log_error(_function: String, file: String, line: int, code: String, _rationale: String, _editor_notify: bool, _error_type: int, _backtraces: Array[ScriptBacktrace]) -> void:
		errors.append("%s:%d %s"%[file,line,code])
var error_log := ErrorLog.new()
func _initialize() -> void:
	OS.add_logger(error_log)
	call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		push_error(message)
func finish(director: RefCounted) -> void:
	while director.is_active(): director.advance()
func run() -> void:
	var Director = load("res://scripts/dialogue_director.gd")
	var director = Director.new()
	var additions: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/dialogue/sintra_banter.json")).topics
	check(additions.size()>=50 and director.topics.size()>=80,"New conversations are loaded alongside the original stories")
	var ids := {}
	for topic in director.topics:
		check(not ids.has(topic.id),"Unique conversation ID: "+topic.id)
		ids[topic.id] = true
		for line in topic.lines: check(line.text.length()<=140,"Dialogue fits the painted cards: "+topic.id)
	for topic in additions:
		var test = Director.new()
		for flag in topic.get("require_flags",[]): test.flags[flag] = true
		var nearby: Array = [topic.near] if topic.has("near") else []
		if topic.get("near")=="capuchos_puppy": nearby.append("convento_capuchos")
		var context := {"scene":"sintra_trail","location":"serra_sintra","initiator":topic.initiator,"near":nearby,"day_phase":topic.get("day_phase","Manhã"),"puppy_mood":topic.get("puppy_mood","")}
		var reached := false
		if topic.has("puppy_mood"):
			var wrong := context.duplicate(true)
			wrong.puppy_mood = "trusted" if topic.puppy_mood!="trusted" else "guard"
			check(not test.matches(topic,wrong),"Puppy dialogue respects the actual confidence stage")
		if topic.has("day_phase"):
			var wrong := context.duplicate(true)
			wrong.day_phase = "Noite" if topic.day_phase!="Noite" else "Manhã"
			check(not test.matches(topic,wrong),"Time-specific dialogue stays in the correct phase")
		for i in 18:
			check(test.start(context),"A matching context starts dialogue")
			if test.active_topic.id==topic.id: reached = true
			finish(test)
			if reached: break
		check(reached,"Every new conversation can rotate into its actual context: "+topic.id)
	var scene = load("res://scenes/garden.tscn").instantiate()
	root.add_child(scene)
	scene.set_process(false)
	for person in scene.people: person.set_physics_process(false)
	var ball: Node2D
	for object in scene.world.scenery_props:
		if object.kind==3: ball = object
	scene.people[0].position = ball.position-Vector2(50,0)
	scene.people[0].facing = Vector2.RIGHT
	scene._interact()
	check(scene.hud.comment_panel.visible and not scene.hud.comment_label.text.is_empty(),"Interaction comments are actually visible in the game")
	var first: String = scene.hud.comment_label.text
	scene._interact()
	check(scene.hud.comment_label.text!=first,"Repeated actions rotate comments")
	var remaining: float = scene.hud.comment_time
	scene._toggle_map()
	scene.hud._process(2)
	check(not scene.hud.comment_panel.visible and scene.hud.comment_time==remaining,"Map hides comments and preserves reading time")
	scene._toggle_map()
	scene._toggle_pause()
	scene.hud._process(2)
	check(not scene.hud.comment_panel.visible and scene.hud.comment_time==remaining,"Pause also preserves reading time")
	scene._toggle_pause()
	scene.hud.dialogue_active = true
	scene.hud._process(2)
	check(not scene.hud.comment_panel.visible,"Comments do not cover conversation cards")
	scene.hud.dialogue_active = false
	scene.hud._process(remaining+1)
	scene.hud._process(0)
	check(not scene.hud.comment_panel.visible,"Comments expire normally")
	for choices in preload("res://data/world_comments.json").data.values():
		for message in choices:
			scene.hud.show_comment(str(message).replace("%s","Capuchos / Fonte"))
			check(scene.hud.comment_label.get_line_count()<=3,"World comment fits its panel")
			check(scene.hud.comment_panel.position.y+scene.hud.comment_panel.size.y<=697,"World comments remain inside the screen")
	check(error_log.errors.is_empty(),"No runtime errors: "+str(error_log.errors))
	if not failed: print("PASS: 51 reachable rotating conversations, context and mood filters, readable dialogue, visible interaction comments and modal reading time")
	quit(1 if failed else 0)
