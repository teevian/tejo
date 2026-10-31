## Graphics regression for all four diagonals: stable identity and original gait.
extends SceneTree
# The incoming gait is the independent reference for the baked atlas.
# te_walk_consistency_test verifies its final, slightly slimmer rendition.
const Art = preload("res://tools/pulled_walk_reference.gd")
const ORIGINAL_ATLAS = preload("res://assets/characters/open_world/te-walk-v4.png")
const ORIGINAL: Array = [
	[Rect2(44,292,92,213),Rect2(218,292,105,213),Rect2(218,292,105,213),
	 Rect2(405,292,90,213),Rect2(405,292,90,213),Rect2(562,292,136,213),
	 Rect2(562,292,136,213),Rect2(760,292,101,213),Rect2(760,292,101,213)],
	[Rect2(49,813,82,212),Rect2(221,813,99,212),Rect2(221,813,99,212),
	 Rect2(398,813,105,212),Rect2(398,813,105,212),Rect2(564,813,133,212),
	 Rect2(564,813,133,212),Rect2(747,813,127,212),Rect2(747,813,127,212)]]
# Hand patches sit above the unaltered lower-body rectangle, exercising the
# actual painted arm cutouts as well as the feet checked separately below.
const HANDS: Array = [
	[Rect2i(-29,-60,5,6),Rect2i(-24,-59,5,5),Rect2i(-40,-68,5,6),Rect2i(24,-72,5,6)],
	[Rect2i(25,-66,6,6),Rect2i(27,-66,6,6),Rect2i(39,-78,6,6),Rect2i(34,-76,6,6)]]
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
		for view_index in 2:
			for side in 2:
				var facing := Vector2(1 if side==0 else -1,1 if view_index==0 else -1).normalized()
				for frame in 9:
					var at := Vector2(80+160*frame,210+view_index*1440+side*720)
					var region: Rect2 = ORIGINAL[view_index][frame]
					draw_set_transform(at,0,Vector2(-1 if side==1 else 1,1))
					draw_texture_rect_region(ORIGINAL_ATLAS,Rect2(-Vector2(region.size.x*.5,region.size.y)*factor,region.size*factor),region)
					draw_set_transform(Vector2.ZERO)
					Art.draw_pose(self,0,facing,frame>0,maxf(0,frame-1)*112.0/8.0,at+Vector2(0,240))
					Art.draw_pose(self,0,facing,false,0,at+Vector2(0,480))
func _initialize() -> void:
	OS.add_logger(error_log)
	call_deferred("run")
	create_timer(30.0,true,false,true).timeout.connect(func():
		push_error("Diagonal gait verification timed out")
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
func painted(image: Image, at: Vector2i, rect: Rect2i) -> int:
	var count := 0
	for y in range(rect.position.y,rect.end.y):
		for x in range(rect.position.x,rect.end.x):
			if image.get_pixelv(at+Vector2i(x,y)).a>.8: count += 1
	return count
func run() -> void:
	if DisplayServer.get_name()=="headless":
		push_error("Diagonal gait verification requires a graphics window")
		quit(1)
		return
	var view := SubViewport.new()
	view.size = Vector2i(1440,2880)
	view.transparent_bg = true
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(view)
	view.add_child(Board.new())
	for i in 4: await process_frame
	RenderingServer.force_draw()
	var pixels := view.get_texture().get_image()
	for view_index in 2:
		for side in 2:
			var leg_frames := {}
			for frame in 9:
				var foot := Vector2i(80+frame*160,450+view_index*1440+side*720)
				var rest := foot+Vector2i(0,240)
				var old := foot-Vector2i(0,240)
				var label := "view %d, side %d, tick %d"%[view_index,side,frame]
				var head := Rect2i(-50,-155,100,52 if view_index==0 else 55)
				var torso := Rect2i(-13,-82,26,18) if view_index==0 else Rect2i(-10,-73,20,11)
				check(mismatch(pixels,foot,rest,head)<.005,"Same resting diagonal head and shoulders: "+label)
				check(mismatch(pixels,foot,rest,torso)<.005,"Same resting diagonal torso: "+label)
				check(mismatch(pixels,foot,old,Rect2i(-65,-55,130,54))<.005,"Original diagonal legs, feet and anchors: "+label)
				if frame>0:
					var hand: Rect2i = HANDS[view_index][(frame-1)/2]
					if side==1: hand.position.x = -hand.end.x
					check(painted(pixels,old,hand)>hand.get_area()/3,"Hand comparison contains visible painting: "+label)
					check(mismatch(pixels,foot,old,hand)<.005,"Original hand position and painting: "+label)
					var crop := pixels.get_region(Rect2i(foot+Vector2i(-65,-55),Vector2i(130,54)))
					leg_frames[hash(crop.get_data())] = true
					check(Art.frame_for(true,float(frame-1)*112.0/8.0)==frame,"Original eight-tick cadence")
				if side==0:
					check(mismatch(pixels,foot,foot+Vector2i(0,720),Rect2i(-65,-155,130,155),true)<.005,"Exact west/east diagonal mirrors: "+label)
			check(leg_frames.size()==4,"Four original diagonal leg poses, held for two ticks")
	check(Art.STRIDE==112 and Art.GAIT_FRAMES==8 and Art.frame_for(true,112)==1,"Original stride and loop boundary")
	check(error_log.errors.is_empty(),"No runtime errors: "+str(error_log.errors))
	if not failed: print("PASS: stable heads, shoulders and torsos across all four diagonals; original hands, legs, foot anchors, mirrored views and eight-tick cadence preserved")
	quit(1 if failed else 0)
