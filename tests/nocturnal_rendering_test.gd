## Run with graphics: validates painted poses, fixed owl torsos and graded emission.
extends SceneTree
const NightAnimal = preload("res://scripts/nocturnal_animal.gd")
var failed := false
class Habitat:
	extends Node2D
	var elapsed := 0.0
class ErrorLog:
	extends Logger
	var errors: Array[String] = []
	func _log_error(_function: String, file: String, line: int, code: String, _rationale: String, _editor_notify: bool, _error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
		errors.append("%s:%d %s"%[file,line,code])
func _initialize() -> void:
	call_deferred("run")
func check(value: bool, message: String) -> void:
	if not value:
		failed = true
		push_error(message)
func frame() -> Image:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()
func specimen(habitat: Node2D, species: String, at: Vector2, state: String):
	var a := NightAnimal.new()
	a.species = species
	a.ecosystem = habitat
	a.position = at
	a.state = state
	habitat.add_child(a)
	a.art.scale = Vector2.ONE*1.65
	return a
func run() -> void:
	var log := ErrorLog.new()
	OS.add_logger(log)
	root.size = Vector2i(1280,720)
	RenderingServer.set_default_clear_color(Color("36423e"))
	var habitat := Habitat.new()
	root.add_child(habitat)
	for slot in 8:
		var bat = specimen(habitat,"bat",Vector2(80+slot*155,150),"cruise")
		bat.phase = (slot%4+0.1)/15.0
		bat.facing = Vector2.RIGHT if slot<4 else Vector2.DOWN
	for slot in 9:
		var owl = specimen(habitat,"owl",Vector2(80+slot*140,400),"watch")
		owl.head_yaw = -PI+slot*PI/4
	for slot in 4:
		var owl = specimen(habitat,"owl",Vector2(180+slot*290,610),"fly")
		owl.phase = (slot+0.1)/6.0
		owl.facing = Vector2.RIGHT if slot<3 else Vector2.LEFT
	var sheet := await frame()
	sheet.save_png("res://output/nocturnal-poses.png")
	var head_hashes: Dictionary = {}
	var body_hash := 0
	for slot in 9:
		var x := 80+slot*140
		var head := sheet.get_region(Rect2i(x-27,309,54,37))
		var body := sheet.get_region(Rect2i(x-16,361,32,34))
		head_hashes[hash(head.get_data())] = true
		if slot==0: body_hash = hash(body.get_data())
		else: check(hash(body.get_data())==body_hash,"Turning the owl's head must leave body pixels fixed")
	check(head_hashes.size()>=7,"Front, side, rear and mirrored heads visibly differ")
	var front_owl = habitat.get_child(12)
	front_owl.art.material.set_shader_parameter("eye_open",0.0)
	front_owl.art.queue_redraw()
	var closed_eyes := await frame()
	closed_eyes.save_png("res://output/nocturnal-eyes-closed.png")
	check(hash(closed_eyes.get_region(Rect2i(613,309,54,37)).get_data())!=hash(sheet.get_region(Rect2i(613,309,54,37)).get_data()),"Closing the owl's eyes visibly changes its painted face")
	check(hash(closed_eyes.get_region(Rect2i(624,361,32,34)).get_data())==body_hash,"Blinking leaves the owl's body fixed")
	front_owl.art.material.set_shader_parameter("eye_open",1.0)
	for slot in 8:
		var tile := sheet.get_region(Rect2i(20+slot*155,90,120,100))
		var painted := 0
		for y in tile.get_height():
			for x in tile.get_width():
				if tile.get_pixel(x,y).r>0.27: painted += 1
		check(painted>100,"Every bat wing pose visibly renders: "+str(slot))
	root.remove_child(habitat)
	habitat.queue_free()
	var snake_habitat := Habitat.new()
	root.add_child(snake_habitat)
	for slot in 4:
		var snake = specimen(snake_habitat,"snake",Vector2(170+slot*300,360),"slither")
		snake.art.scale = Vector2.ONE*3
		snake.gait_distance = slot*9+0.2
		snake.velocity = Vector2.RIGHT*58
		snake.facing = Vector2.RIGHT
	var snake_sheet := await frame()
	snake_sheet.save_png("res://output/nocturnal-snake-poses.png")
	for slot in 4:
		var tile := snake_sheet.get_region(Rect2i(45+slot*300,280,250,160))
		var painted := 0
		for y in tile.get_height():
			for x in tile.get_width():
				if tile.get_pixel(x,y).r>0.27: painted += 1
		check(painted>200,"Each painted snake slither pose is visible")
	root.remove_child(snake_habitat)
	snake_habitat.queue_free()
	print("Rendering: painted poses verified; loading forest")
	var scene = load("res://scenes/garden.tscn").instantiate()
	root.add_child(scene)
	print("Rendering: forest ready")
	scene.set_process(false)
	for person in scene.people: person.set_physics_process(false)
	scene.day_cycle.minutes = 23*60
	scene.daylight.set_shader_parameter("daylight",scene.day_cycle.light_color())
	scene.hud.queue_redraw()
	var eco = scene.world.wildlife
	var owl
	for a in eco.animals:
		if a.species=="owl":
			owl = a
			break
	scene.camera.position = scene._camera_target()
	scene.camera.zoom = Vector2.ONE*1.15
	scene.camera.force_update_scroll()
	for i in 100: eco.step(0.05)
	print("Rendering: night simulation ready")
	var forest := await frame()
	forest.save_png("res://output/nocturnal-forest.png")
	scene.camera.position = owl.position-Vector2(0,owl.altitude+20)
	scene.camera.zoom = Vector2.ONE*2.2
	scene.camera.force_update_scroll()
	var perched := await frame()
	perched.save_png("res://output/nocturnal-owl.png")
	owl.head_yaw = 0
	owl.eye_open = 1
	owl.art.material.set_shader_parameter("eye_open",1.0)
	owl.eye_glint = 0
	owl.art.queue_redraw()
	eco.night_glow.queue_redraw()
	var quiet_eyes := await frame()
	owl.eye_glint = 1
	eco.night_glow.queue_redraw()
	var shining_eyes := await frame()
	shining_eyes.save_png("res://output/nocturnal-owl-reflection.png")
	var eye_at: Vector2 = owl.position-Vector2(0,owl.altitude)+owl.art.eye_points()[0].position
	var eye_pixel := Vector2i(scene.world.actors.get_global_transform_with_canvas()*eye_at)
	check(shining_eyes.get_pixelv(eye_pixel).g>quiet_eyes.get_pixelv(eye_pixel).g+0.08,"The brief owl eye reflection visibly stands out under night lighting")
	owl.eye_glint = 0
	for a in eco.animals:
		if a.species=="owl" and int(a.home.node.get_meta("kind"))==1:
			scene.camera.position = a.position-Vector2(0,a.altitude+20)
			scene.camera.force_update_scroll()
			var oak := await frame()
			oak.save_png("res://output/nocturnal-owl-oak.png")
			break
	scene.camera.zoom = Vector2.ONE*1.15
	scene.camera.position = owl.position+Vector2(0,-120)
	scene.camera.force_update_scroll()
	# A light centered on a clear real patch must survive the full-screen night tint.
	var insect = eco.firefly_patches[0].members[0]
	var clear := false
	for attempt in 80:
		var at: Vector2 = owl.position+Vector2(-180+attempt%10*40,120+attempt/10*35)
		if scene.world.is_walkable(at,5) and not eco._covered_at(at,at):
			insect.position = at
			insect.anchor = at
			clear = true
			break
	check(clear,"A visible vegetation-edge light can be inspected")
	for patch in eco.firefly_patches:
		for other in patch.members: other.glow_visible = false
	insect.state = "glimmer"
	insect.altitude = 0
	insect.glow = 1
	insect.phase = PI/2-eco.elapsed*insect.pulse_rate
	insect.glow_visible = true
	eco.night_glow.queue_redraw()
	var lit := await frame()
	lit.save_png("res://output/nocturnal-fireflies.png")
	var screen_at: Vector2 = scene.world.actors.get_global_transform_with_canvas()*(insect.position+Vector2(0,-insect.altitude))
	var pixel := Vector2i(screen_at).clamp(Vector2i.ZERO,lit.get_size()-Vector2i.ONE)
	eco.night_glow.hide()
	var unlit := await frame()
	var light_color := lit.get_pixelv(pixel)
	var base_color := unlit.get_pixelv(pixel)
	check(light_color.g>base_color.g+0.25 and light_color.r>base_color.r+0.2,"Firefly core stays luminous above the night grade and follows the camera")
	eco.night_glow.show()
	# Opaque branches and foliage suppress the emitter using the world's own cutouts.
	var covered := false
	for tree in eco.trees:
		for height in [60,90,120]:
			var at: Vector2 = tree.node.position-Vector2(0,height)
			if eco._covered_at(at,at):
				insect.position = at
				insect.anchor = at
				scene.camera.position = at
				scene.camera.force_update_scroll()
				insect.cooldown = 10
				insect._firefly_think()
				covered = not insect.glow_visible
				break
		if covered: break
	check(covered,"Firefly emission is hidden by actual painted foliage")
	# Even a stale visible flag cannot leak ground light through a branch.
	insect.glow_visible = true
	eco.night_glow.queue_redraw()
	var blocked := await frame()
	eco.night_glow.hide()
	var baseline := await frame()
	screen_at = scene.world.actors.get_global_transform_with_canvas()*(insect.position+Vector2(0,-insect.altitude))
	pixel = Vector2i(screen_at).clamp(Vector2i.ZERO,blocked.get_size()-Vector2i.ONE)
	var actual := blocked.get_pixelv(pixel)
	var expected := baseline.get_pixelv(pixel)
	check(absf(actual.r-expected.r)<0.08 and absf(actual.g-expected.g)<0.08,"Ground lights cannot leak emission through foliage")
	# Review a resident snake on reachable ground beside its actual river bank.
	var river_snake
	for a in eco.animals:
		if a.species=="snake":
			river_snake = a
			break
	for attempt in 40:
		var at: Vector2 = river_snake.anchor+Vector2.from_angle(attempt*TAU/40)*45
		if scene.world.is_walkable(at,16) and not eco._covered_at(at,at):
			river_snake.position = at
			break
	river_snake.set_state("coil",5)
	river_snake.facing = Vector2.RIGHT
	river_snake.altitude = 0
	river_snake.art.position = Vector2.ZERO
	river_snake.art.queue_redraw()
	scene.camera.position = river_snake.position-Vector2(0,10)
	scene.camera.zoom = Vector2.ONE*2.2
	scene.camera.force_update_scroll()
	var river := await frame()
	river.save_png("res://output/nocturnal-river-snake.png")
	river_snake.art.hide()
	var without_snake := await frame()
	var snake_pixel := Vector2i(scene.world.actors.get_global_transform_with_canvas()*river_snake.position)
	var changed := 0
	for y in range(snake_pixel.y-35,snake_pixel.y+35):
		for x in range(snake_pixel.x-85,snake_pixel.x+85):
			var a := river.get_pixel(x,y)
			var b := without_snake.get_pixel(x,y)
			if absf(a.r-b.r)+absf(a.g-b.g)+absf(a.b-b.b)>0.045: changed += 1
	check(changed>50,"A resident snake visibly renders against the real river-bank painting")
	OS.remove_logger(log)
	check(log.errors.is_empty(),"Rendering errors: "+str(log.errors))
	if not failed: print("PASS: painted snake and bat poses, fixed owl torso, blinking and brief eye reflections, ground light emission, camera alignment and foliage occlusion")
	quit(1 if failed else 0)
