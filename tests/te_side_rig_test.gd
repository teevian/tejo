extends SceneTree
const Rig = preload("res://scripts/te_side_rig.gd")
const Art = preload("res://scripts/open_world_art.gd")
const Person = preload("res://scripts/open_world_person.gd")
var failed := false
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		push_error(message)
class Head extends Node2D:
	var phase := 0.0
	var mirror := false
	func _ready() -> void:
		var ink := ShaderMaterial.new()
		ink.shader = preload("res://shaders/opaque_cutout.gdshader")
		material = ink
	func _draw() -> void:
		var factor := Art.HEIGHTS[0]/Rig.HEIGHT
		var root: Vector2 = Rig.state(phase).root
		draw_set_transform(Vector2.ZERO,0,Vector2(-1 if mirror else 1,1))
		draw_texture_rect_region(Rig.ORIGINAL,Rect2((root-Rig.ANCHOR)*factor,Vector2(400,180)*factor),Rect2(0,0,400,180))
func run() -> void:
	var leg_a := Rig.HIP.distance_to(Rig.KNEE)
	var leg_b := Rig.KNEE.distance_to(Rig.ANKLE)
	var roots: Array[Vector2] = []
	for frame in 256:
		var phase := frame/256.0
		var pose := Rig.state(phase)
		roots.append(pose.root)
		for limb in [pose.near,pose.far]:
			check(absf(limb.hip.distance_to(limb.knee)-leg_a)<.005,"Thigh length must not change during a step")
			check(absf(limb.knee.distance_to(limb.ankle)-leg_b)<.005,"Calf length must not change during a step")
			if limb.stance:
				var a: Vector2 = limb.hip-limb.knee
				var b: Vector2 = limb.ankle-limb.knee
				check(absf(PI-absf(a.angle_to(b)))<deg_to_rad(48),"Supporting leg must not crouch")
		check(Rig.state(phase+1).root.distance_to(pose.root)<.001,"Stride must loop without a body jump")
		check(Rig.state(phase+1).near.ankle.distance_to(pose.near.ankle)<.001,"Foot trajectory must loop continuously")
	for strength in [.1,.4,.7]:
		for frame in 64:
			var pose := Rig.state(frame/64.0,strength)
			for limb in [pose.near,pose.far]:
				check(absf(limb.hip.distance_to(limb.knee)-leg_a)<.005,"Starting/stopping must preserve thigh length")
				check(absf(limb.knee.distance_to(limb.ankle)-leg_b)<.005,"Starting/stopping must preserve calf length")
	var root_span := 0.0
	for a in roots:
		for b in roots: root_span = maxf(root_span,a.distance_to(b))
	check(root_span<17,"Natural body rise must remain small, with no lateral rocking")
	if DisplayServer.get_name()=="headless":
		if not failed: print("PASS: constant rigid limb lengths, upright support, continuous stride, bounded body rise")
		quit(1 if failed else 0)
		return
	var view := SubViewport.new()
	view.size = Vector2i(600,800)
	view.transparent_bg = true
	view.world_2d = World2D.new()
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(view)
	var people: Array = []
	var heads: Array = []
	for side in 2:
		var person := Person.new()
		person.kind = 0
		person.facing = Vector2.LEFT if side else Vector2.RIGHT
		person.visual_facing = person.facing
		person.moving = true
		person.velocity = person.facing*235
		person.position = Vector2(150+300*side,350)
		person.scale = Vector2.ONE*1.7
		view.add_child(person)
		person.set_physics_process(false)
		people.append(person)
		var head := Head.new()
		head.mirror = side==1
		head.position = person.position+Vector2(0,400)
		head.scale = person.scale
		view.add_child(head)
		heads.append(head)
	DirAccess.make_dir_recursive_absolute("/tmp/tejo-v19-side")
	for frame in 32:
		var phase := frame/32.0
		for person in people:
			person.walked = phase*Rig.STRIDE
			person.body.queue_redraw()
		for head in heads:
			head.phase = phase
			head.queue_redraw()
		for i in 2: await process_frame
		RenderingServer.force_draw()
		var image := view.get_texture().get_image()
		image.get_region(Rect2i(0,0,600,400)).save_png("/tmp/tejo-v19-side/%02d.png"%frame)
		for side in 2:
			var error := 0.0
			var n := 0
			for y in range(65,143):
				for x in range(side*300+90,side*300+220):
					var a := image.get_pixel(x,y)
					var b := image.get_pixel(x,y+400)
					if b.a>.8:
						error += absf(a.r-b.r)+absf(a.g-b.g)+absf(a.b-b.b)+absf(a.a-b.a)
						n += 1
			check(n>1500 and error/maxi(n*4,1)<.002,"Actual lateral head/hair must match the same unscaled approved painting at every phase")
	if not failed: print("PASS: actual right/left Te, constant original head/hair, rigid limb lengths, continuous stride and upright support")
	quit(1 if failed else 0)
