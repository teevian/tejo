extends Node2D
const Route = preload("res://scripts/climbing_route.gd")
var scene: Node2D
var font: Font = ThemeDB.fallback_font

func _draw() -> void:
	if not is_instance_valid(scene.camera): return
	var camera: Vector2 = scene.camera.position
	# Every mark is projected from the same world as the real 3D granite.
	for platform in scene.platforms:
		if not platform.enabled or float(platform.get("fragile",0))<=0: continue
		if absf(float(platform.y)-camera.y)>650: continue
		var bounds: Dictionary = scene.space.boxes[platform.id]
		var life := float(platform.fragile)
		var timer := float(platform.timer)
		if timer>=0:
			var point: Vector2 = scene.space.prop(platform.id,(float(bounds.left)+float(bounds.right))*0.5,28)
			draw_arc(point,10,-PI/2,-PI/2+TAU*timer/life,24,Color("edc47c"),3,true)
	if not scene.space.rotating:
		for edge in scene.links:
			if not scene.platforms[edge.to].enabled or scene.edge_gap(edge)>=75: continue
			if edge.mode=="rock" and scene.flags.get("rock_step",false): continue
			if edge.mode=="balance" and scene.platforms[Route.BALANCE_STEP].enabled: continue
			var low: Dictionary = scene.platforms[edge.from]
			var high: Dictionary = scene.platforms[edge.to]
			if absf(float(low.y)-camera.y)>650: continue
			var x := float(high.x)+8 if edge.dir>0 else float(high.end)-8
			var count := maxi(2,int((float(low.y)-float(high.y))/43))
			for i in count:
				var point := Vector2(x+sin(i*2.3)*9,lerpf(float(low.y)-30,float(high.y)+18,float(i)/count))
				draw_line(point,point+Vector2(9,-3),Color(0.93,0.92,0.80,0.68),3,true)
	# The slab and loose stones are now real 3D geometry resting on the mountain.
	draw_arc(scene.space.prop(6,260,-10),20,PI,TAU,20,Color("e5d7ad"),2,true)
	# Rope station: loop round a natural granite horn, never an unexplained button.
	draw_arc(scene.space.prop(13,820,-53),19,0,TAU,25,Color("d5ad70"),4,true)
	for climber in scene.people:
		if climber.anchor=="rope":
			draw_line(scene.space.prop(13,820,-53),climber.position+climber.view_offset+Vector2(0,-62),Color("ddbc83"),2.5,true)
	# Small chalk chevrons mark sheltered openings without replacing the rock art
	# with a door. Both ends remain at their actual 3D coordinates while turning.
	for tunnel in Route.TUNNELS:
		for index in [0,tunnel.path.size()-1]:
			var world: Vector3 = tunnel.path[index]
			var mouth: Vector2 = scene.space.project(world)
			if absf(mouth.y-camera.y)>650: continue
			draw_arc(mouth+Vector2(0,-80),90,PI,TAU,30,Color(0.76,0.80,0.65,0.45),2,true)
			draw_polyline(PackedVector2Array([mouth+Vector2(-10,-45),mouth+Vector2(0,-35),mouth+Vector2(10,-45)]),Color("ddc99a"),3,true)
	var scout: Vector2 = scene.space.prop(28,650,-48)
	draw_arc(scout,18,0,TAU,25,Color("d5ad70"),3,true)
	for climber in scene.people:
		if climber.anchor=="belay": draw_line(scout,climber.position+Vector2(0,-62),Color("ddbc83"),2.5,true)
	if scene.people.size()==2:
		var rope: PackedVector2Array = scene.rope_points()
		draw_polyline(rope,Color("524433"),4,true)
		draw_polyline(rope,Color("e9b77d") if scene.rope_taut else Color("d8b97b"),2,true)
	# Discreet trail marker at the foot; summit cairn and flag reward the ascent.
	var base: Vector2 = scene.space.prop(0,160)
	draw_line(base,base+Vector2(0,-107),Color("705f45"),8,true)
	draw_style_box(_wood(),Rect2(base+Vector2(-70,-119),Vector2(174,45)))
	draw_string(font,base+Vector2(-57,-91),"↑ Penedo da Amizade",HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("f5e3b9"))
	draw_line(scene.space.prop(17,1020,-30),scene.space.prop(17,1020,-125),Color("7c6d55"),3,true)
	var wind := sin(scene.clock*2)*4
	var flag: Vector2 = scene.space.prop(17,1020,-125)
	draw_colored_polygon(PackedVector2Array([flag,flag+Vector2(45,6+wind),flag+Vector2(34,22+wind),flag+Vector2(0,17)]),Color("c97f5f"))

func _wood() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color("586448")
	box.border_color = Color("c0b790")
	box.set_border_width_all(1)
	box.set_corner_radius_all(4)
	return box
