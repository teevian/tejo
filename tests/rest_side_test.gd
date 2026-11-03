extends SceneTree
const Person = preload("res://scripts/open_world_person.gd")
const Posture = preload("res://scripts/rest_posture.gd")
var failed := false

func _initialize() -> void:
	call_deferred("run")
	create_timer(20,true,false,true).timeout.connect(func(): quit(1))

func check(ok: bool, message: String) -> void:
	if not ok:
		failed = true
		push_error(message)

func frames(amount: int) -> void:
	for i in amount: await physics_frame

func run() -> void:
	var posture = Posture.new()
	posture.rng.seed = 991
	var current := 1
	var seen := {}
	for i in 2000:
		var next: int = posture.step(1,current)
		if next>=1:
			check(next!=current,"Side rest must change to a different whole-body posture")
			current = next
			seen[current] = true
			posture.step(0,current)
			check(posture.remaining>=20 and posture.remaining<=35,"Whole-body adjustments must have separate, slower random waits")
	check(seen.size()==3,"Rest should include the back and both shoulders")
	var phone := Rect2i(325,393,48,46)
	var reference: Image = Person.RestArt.ATLASES[0].get_image()
	var sides: Image = Person.RestArt.SIDE_ATLASES[0].get_image()
	var device_outline := PackedVector2Array([Vector2(321,397),Vector2(353,388),Vector2(377,434),Vector2(341,444)])
	for row in 2:
		for frame in 4:
			var changed := 0
			for y in phone.size.y:
				for x in phone.size.x:
					var at := Vector2i(x,y)+phone.position
					# The reference crop also contains the edge of Te's original fingers.
					if not Geometry2D.is_point_in_polygon(Vector2(at),device_outline): continue
					var original := reference.get_pixelv(at+Vector2i(1440,560))
					var actual := sides.get_pixelv(at+Vector2i(frame*640+80,row*560))
					# Ignore RGB in transparent pixels and one-byte alpha compositing roundoff.
					if original.a>0.12 and (absf(original.r-actual.r)>0.01 or absf(original.g-actual.g)>0.01 or absf(original.b-actual.b)>0.01 or absf(original.a-actual.a)>0.01): changed += 1
			check(changed==0,"The shared phone must keep its ground position and painted pixels in every roll key")
	var scene = load("res://scenes/walking_test.tscn").instantiate()
	root.add_child(scene)
	await frames(2)
	var p = scene.people[0]
	var other = scene.people[1]
	for actor in scene.people:
		actor.partner = other if actor==p else p
		actor.ground_seated = true
		actor.ground_rest = true
		actor.ground_pose = 1
		actor.eyes_closed = true
		actor.seat_id = "ground_rest"
		actor.rest_posture.step(0,1)
	p.rest_posture.remaining = 0.01
	await frames(3)
	check(p.rest_transition=="roll" and p.rest_roll_to in [2,3],"Actual resting physics must start a shoulder roll")
	var at: Vector2 = p.position
	var held: float = p.rest_time
	scene._toggle_pause()
	await frames(10)
	check(p.rest_time==held,"Pause must freeze a shoulder roll")
	scene._toggle_pause()
	p.in_dialogue = true
	p.map_blocked = true
	await frames(10)
	check(p.rest_time==held,"The map must freeze a shoulder roll")
	p.in_dialogue = false
	p.map_blocked = false
	await frames(60)
	check(p.ground_pose in [2,3] and p.rest_transition.is_empty() and p.position==at,"The side-lying endpoint must settle without moving the actor")
	var target := 3 if p.ground_pose==2 else 2
	p.begin_ground_roll(target)
	await frames(60)
	check(p.rest_transition=="roll" and p.current_side_roll().y<0.4,"Switching shoulders must pass back through the supine pose")
	Input.action_press("walk_right")
	await frames(3)
	check(p.rest_transition=="sit_up" and other.is_sleeping(),"Movement must reverse the selected actor's roll before stretching and calling the sleeping partner")
	check(p.position==at,"The actor must wait for the roll-back and rise before moving")
	await frames(380)
	Input.action_release("walk_right")
	check(p.rest_transition.is_empty() and p.moving and p.position.x>at.x,"Walking must resume after rolling back, sitting up and standing")
	scene.queue_free()
	await process_frame
	if not failed: print("PASS: both shoulder poses, random rest changes, fixed shared phone, reversible rolls, modal freeze and animated wake-up")
	quit(1 if failed else 0)
