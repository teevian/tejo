## Graphics regression: actual right/left pixels, mirrored anatomy and old feet.
extends SceneTree
# The incoming gait is the independent reference for the baked atlas.
# te_walk_consistency_test verifies its final, slightly slimmer rendition.
const Art = preload("res://tools/pulled_walk_reference.gd")
const ORIGINAL_ATLAS = preload("res://assets/characters/open_world/te-walk-v4.png")
const ORIGINAL: Array[Rect2] = [
	Rect2(57,553,67,212),Rect2(199,553,142,212),Rect2(199,553,142,212),
	Rect2(412,553,76,212),Rect2(412,553,76,212),Rect2(557,553,146,212),
	Rect2(557,553,146,212),Rect2(761,553,98,212),Rect2(761,553,98,212)]
# Independent rigid offsets for the original arm paintings. Their articulation
# and proportions must remain identical after attaching to the fixed shoulder.
const ARM_OFFSETS: Array[Vector2] = [Vector2(15.5,13),Vector2(-6.5,-4),Vector2(-30.5,-15),Vector2(-17.5,-4)]
const HANDS: Array[Rect2i] = [Rect2i(-18,-46,5,4),Rect2i(13,-61,5,6),Rect2i(23,-73,4,5),Rect2i(14,-71,4,4)]
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
	func old_pose(frame: int, at: Vector2, flip: bool, shift := Vector2.ZERO) -> void:
		var factor := Art.HEIGHTS[0]/219.0
		var region: Rect2 = ORIGINAL[frame]
		draw_set_transform(at,0,Vector2(-1 if flip else 1,1))
		draw_texture_rect_region(ORIGINAL_ATLAS,Rect2((shift-Vector2(region.size.x*.5,region.size.y))*factor,region.size*factor),region)
		draw_set_transform(Vector2.ZERO)
	func _draw() -> void:
		for side in 2:
			var facing := Vector2.RIGHT if side==0 else Vector2.LEFT
			for frame in 9:
				var distance := maxf(0,frame-1)*112.0/8.0
				var at := Vector2(80+160*frame,210+side*960)
				old_pose(frame,at,side==1)
				Art.draw_pose(self,0,facing,frame>0,distance,at+Vector2(0,240))
				Art.draw_pose(self,0,facing,false,0,at+Vector2(0,480))
				var key := maxi(0,(frame-1)/2)
				old_pose(frame,at+Vector2(0,720),side==1,ARM_OFFSETS[key] if frame>0 else Vector2.ZERO)
func _initialize() -> void:
	OS.add_logger(error_log)
	call_deferred("run")
	create_timer(30.0,true,false,true).timeout.connect(func():
		push_error("Side gait verification timed out")
		quit(1))
func check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		push_error(message)
func mismatch(image: Image, a: Vector2i, b: Vector2i, rect: Rect2i, mirror_b := false) -> float:
	var differences := 0
	for y in range(rect.position.y,rect.end.y):
		for x in range(rect.position.x,rect.end.x):
			var aa := image.get_pixelv(a+Vector2i(x,y))
			var bb := image.get_pixelv(b+Vector2i(-x-1 if mirror_b else x,y))
			if absf(aa.a-bb.a)>.025 or (minf(aa.a,bb.a)>.1 and Vector3(aa.r-bb.r,aa.g-bb.g,aa.b-bb.b).length()>.035): differences += 1
	return float(differences)/rect.get_area()
func run() -> void:
	if DisplayServer.get_name()=="headless":
		push_error("Side gait verification requires a graphics window")
		quit(1)
		return
	var view := SubViewport.new()
	view.size = Vector2i(1440,1920)
	view.transparent_bg = true
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(view)
	view.add_child(Board.new())
	for i in 4: await process_frame
	RenderingServer.force_draw()
	var pixels := view.get_texture().get_image()
	for side in 2:
		var leg_frames := {}
		for frame in 9:
			var foot := Vector2i(80+frame*160,450+side*960)
			var rest := foot+Vector2i(0,240)
			var old := foot-Vector2i(0,240)
			var arm := foot+Vector2i(0,480)
			check(mismatch(pixels,foot,rest,Rect2i(-45,-155,90,59))<.005,"Same side-facing head, neck and shoulders as rest: side %d tick %d"%[side,frame])
			check(mismatch(pixels,foot,old,Rect2i(-65,-30,130,29))<.005,"Original lower legs, shoes and foot anchors: side %d tick %d"%[side,frame])
			if frame>0:
				var key := maxi(0,(frame-1)/2)
				var hand: Rect2i = HANDS[key]
				# Compare shirt where it is visible beside each swinging arm.
				var shirt := Rect2i(9,-74,2,9) if key==0 else Rect2i(-20,-70,3,5)
				if side==1:
					hand.position.x = -hand.end.x
					shirt.position.x = -shirt.end.x
				check(mismatch(pixels,foot,arm,hand)<.005,"Original painted hand without deformation: side %d tick %d"%[side,frame])
				check(mismatch(pixels,foot,rest,shirt)<.005,"Stable visible torso: side %d tick %d"%[side,frame])
				var crop := pixels.get_region(Rect2i(foot+Vector2i(-65,-30),Vector2i(130,29)))
				leg_frames[hash(crop.get_data())] = true
				check(Art.frame_for(true,float(frame-1)*112.0/8.0)==frame,"Original eight-tick cadence")
			if side==0:
				check(mismatch(pixels,foot,foot+Vector2i(0,960),Rect2i(-65,-155,130,155),true)<.005,"Left and right are exact mirrors in tick "+str(frame))
		check(leg_frames.size()==4,"Four distinct original side leg poses, held for two ticks")
	check(Art.STRIDE==112 and Art.GAIT_FRAMES==8 and Art.frame_for(true,112)==1,"Original stride and loop boundary")
	check(error_log.errors.is_empty(),"No runtime errors: "+str(error_log.errors))
	if not failed: print("PASS: stable side-facing head/torso in both directions; mirrored anatomy, rigid painted hands, original feet and four-pose cadence preserved")
	quit(1 if failed else 0)
