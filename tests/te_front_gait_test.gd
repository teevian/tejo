## Requires graphics: checks stable facial/torso pixels and the original limb motion.
extends SceneTree
# The incoming gait is the independent reference for the baked atlas.
# te_walk_consistency_test verifies its final, slightly slimmer rendition.
const Art = preload("res://tools/pulled_walk_reference.gd")
const ORIGINAL_ATLAS = preload("res://assets/characters/open_world/te-walk-v4.png")
const ORIGINAL: Array[Rect2] = [
	Rect2(42,26,96,219),Rect2(223,26,94,219),Rect2(223,26,94,219),
	Rect2(399,26,102,219),Rect2(399,26,102,219),Rect2(583,26,94,219),
	Rect2(583,26,94,219),Rect2(766,26,89,219),Rect2(766,26,89,219)]
var failed := false
class ErrorLog:
	extends Logger
	var errors: Array[String] = []
	func _log_error(_function: String, file: String, line: int, code: String, _rationale: String, _editor_notify: bool, _error_type: int, _backtraces: Array[ScriptBacktrace]) -> void:
		errors.append("%s:%d %s"%[file,line,code])
var error_log := ErrorLog.new()
class Board:
	extends Node2D
	func _ready() -> void:
		var ink := ShaderMaterial.new()
		ink.shader = preload("res://shaders/opaque_cutout.gdshader")
		material = ink
	func _draw() -> void:
		var factor := Art.HEIGHTS[0]/219.0
		for frame in 9:
			var distance := maxf(0,frame-1)*Art.STRIDE/8.0
			var at := Vector2(80+160*frame,210)
			var region: Rect2 = ORIGINAL[frame]
			draw_texture_rect_region(ORIGINAL_ATLAS,Rect2(at-Vector2(region.size.x*.5,region.size.y)*factor,region.size*factor),region)
			Art.draw_pose(self,0,Vector2.DOWN,frame>0,distance,at+Vector2(0,240))
			Art.draw_pose(self,0,Vector2.DOWN,false,0,at+Vector2(0,480))
func _initialize() -> void:
	OS.add_logger(error_log)
	call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		push_error(message)
func mismatch(image: Image, a: Vector2i, b: Vector2i, rect: Rect2i) -> float:
	var differences := 0
	for y in range(rect.position.y,rect.end.y):
		for x in range(rect.position.x,rect.end.x):
			var aa := image.get_pixelv(a+Vector2i(x,y))
			var bb := image.get_pixelv(b+Vector2i(x,y))
			if absf(aa.a-bb.a)>.025 or (minf(aa.a,bb.a)>.1 and Vector3(aa.r-bb.r,aa.g-bb.g,aa.b-bb.b).length()>.035): differences += 1
	return float(differences)/rect.get_area()
func run() -> void:
	if DisplayServer.get_name()=="headless":
		push_error("Front gait verification requires a graphics window")
		quit(1)
		return
	var view := SubViewport.new()
	view.size = Vector2i(1440,720)
	view.transparent_bg = true
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(view)
	view.add_child(Board.new())
	for i in 4: await process_frame
	RenderingServer.force_draw()
	var pixels := view.get_texture().get_image()
	var leg_frames := {}
	for frame in 9:
		var foot := Vector2i(80+frame*160,450)
		var rest := Vector2i(80+frame*160,690)
		var old := Vector2i(80+frame*160,210)
		check(mismatch(pixels,foot,rest,Rect2i(-60,-160,120,65))<.005,"Same face and shoulders as rest in gait tick "+str(frame))
		check(mismatch(pixels,foot,rest,Rect2i(-15,-86,30,26))<.005,"Stable shirt and chest in gait tick "+str(frame))
		check(mismatch(pixels,foot,old,Rect2i(-65,-55,130,54))<.005,"Original leg/hand position and paint preserved in gait tick "+str(frame))
		if frame>0:
			var crop := pixels.get_region(Rect2i(foot+Vector2i(-65,-55),Vector2i(130,54)))
			leg_frames[hash(crop.get_data())] = true
			check(Art.frame_for(true,float(frame-1)*112.0/8.0)==frame,"Original eight-tick cadence")
	check(leg_frames.size()==4,"All four original limb poses still alternate, held for two ticks")
	check(Art.STRIDE==112 and Art.GAIT_FRAMES==8 and Art.frame_for(true,112)==1,"Original stride length and loop boundary")
	check(error_log.errors.is_empty(),"No runtime errors: "+str(error_log.errors))
	if not failed: print("PASS: identical front face, shoulder silhouette and torso across all eight gait ticks; original arms/legs, anchors, stride and four-pose cadence preserved")
	quit(1 if failed else 0)
