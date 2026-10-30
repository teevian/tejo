extends SceneTree
const Animal = preload("res://scripts/wildlife_animal.gd")
var failed := false
var specimens: Array = []
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
func run() -> void:
	var log := ErrorLog.new()
	OS.add_logger(log)
	root.size = Vector2i(1280,720)
	RenderingServer.set_default_clear_color(Color("36423e"))
	var habitat := Habitat.new()
	root.add_child(habitat)
	var species_list := ["fox","squirrel","bird","frog","butterfly"]
	var labels := ["N","NE","E","SE","S","SW","W","NW"]
	for direction in 8:
		var label := Label.new()
		label.text = labels[direction]
		label.position = Vector2(90+direction*150,14)
		habitat.add_child(label)
	for row in 5:
		for direction in 8:
			var a := Animal.new()
			a.species = species_list[row]
			a.ecosystem = habitat
			a.position = Vector2(105+direction*150,130+row*135)
			a.facing = Vector2.from_angle(-PI/2+direction*PI/4)
			a.set_state("forage",10)
			habitat.add_child(a)
			a.art.scale = Vector2.ONE*1.25
			specimens.append(a)
	var hashes: Dictionary = {}
	for pose in range(5):
		for a in specimens:
			a.gait_distance = 30*pose
			a.state_time = 0.15
			habitat.elapsed = pose*0.09
			if pose==0:
				a.set_state("forage",10)
				a.velocity = Vector2.ZERO
			else:
				a.velocity = a.facing*500
				match a.species:
					"fox": a.state = "bound" if pose==4 else "flee"
					"squirrel": a.state = "startled" if pose==4 else "flee"
					"bird": a.state = "fly"
					"frog": a.state = "surface" if pose==4 else "hop"
					"butterfly": a.state = "flutter"
			a.art.queue_redraw()
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		var frame := root.get_texture().get_image()
		for i in specimens.size():
			var row := i/8
			var direction := i%8
			var tile := frame.get_region(Rect2i(30+direction*150,45+row*135,150,115))
			var pixels := 0
			for y in tile.get_height():
				for x in tile.get_width():
					var c := tile.get_pixel(x,y)
					if absf(c.r-0.212)>0.03 or absf(c.g-0.259)>0.03 or absf(c.b-0.243)>0.03:
						pixels += 1
			check(pixels>25,"Rendered sprite must be visible: "+specimens[i].species+" dir "+str(direction)+" pose "+str(pose))
			var key: String = specimens[i].species+str(direction)
			if not hashes.has(key): hashes[key] = {}
			hashes[key][hash(tile.get_data())] = true
		if pose in [0,2,4]:
			frame.save_png("res://output/wildlife-directions-%d.png"%pose)
	for key in hashes:
		check(hashes[key].size()>=2,"Animation must change pixels: "+key)
	OS.remove_logger(log)
	check(log.errors.is_empty(),"Rendering errors: "+str(log.errors))
	if not failed:
		print("PASS: all five species visibly render in eight directions, pose changes alter pixels, no drawing errors")
	quit(1 if failed else 0)
