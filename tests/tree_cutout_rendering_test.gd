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
	create_timer(40).timeout.connect(func(): quit(1))
func check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		push_error(message)
func run() -> void:
	if DisplayServer.get_name()=="headless":
		push_error("Run the tree cutout check with a graphics window")
		quit(1)
		return
	var world = load("res://scripts/sintra_open_world.gd").new()
	root.add_child(world)
	world.hide()
	world.process_mode = Node.PROCESS_MODE_DISABLED
	var view := SubViewport.new()
	view.size = Vector2i(1254,1254)
	view.transparent_bg = true
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(view)
	var fixtures := [
		["RelicOakEast",[Vector2(1080,410),Vector2(1130,370),Vector2(1160,330),Vector2(1020,655),Vector2(1110,670)],[Vector2(940,560),Vector2(920,680),Vector2(980,500),Vector2(987,400)]],
		["RelicOakWest",[Vector2(440,550),Vector2(500,630),Vector2(205,665)],[Vector2(360,590),Vector2(400,570),Vector2(320,600)]],
		["RelicOakNorth",[Vector2(800,250),Vector2(590,366)],[Vector2(680,300),Vector2(630,260),Vector2(735,315)]]
	]
	for entry in fixtures:
		var object: Node2D = world.actors.get_node(entry[0])
		var surface := Polygon2D.new()
		surface.polygon = object.surface.uv
		surface.uv = object.surface.uv
		surface.texture = object.surface.texture
		surface.material = object.surface.material
		view.add_child(surface)
		for i in 3: await process_frame
		RenderingServer.force_draw()
		var image := view.get_texture().get_image()
		for point in entry[1]:
			check(image.get_pixelv(Vector2i(point)).a<.03,"Ground between branches must be transparent: %s %s"%[entry[0],point])
			check(not object.covers_point(world.Heritage.point(1,point/1254)),"Fauna visibility also sees the opening: "+entry[0])
		for point in entry[2]:
			check(image.get_pixelv(Vector2i(point)).a>.98,"Solid bark keeps its pixels: %s %s"%[entry[0],point])
			check(object.covers_point(world.Heritage.point(1,point/1254)),"Fauna sees the real trunk: "+entry[0])
		surface.queue_free()
		await process_frame
	check(error_log.errors.is_empty(),"No runtime errors: "+str(error_log.errors))
	if not failed: print("PASS: actual alpha leaves soil and branch openings transparent, preserves all three trunks, and agrees with wildlife visibility")
	quit(1 if failed else 0)
