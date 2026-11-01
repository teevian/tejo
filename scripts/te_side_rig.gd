extends RefCounted
## One fixed painted model, animated by rigid joints. No per-frame rescaling.
const SHADER = preload("res://shaders/te_side_rig.gdshader")
const ORIGINAL: Texture2D = preload("res://assets/characters/open_world/te-side-rig-v19-original.png")
const CLOTH: Texture2D = preload("res://assets/characters/open_world/te-side-rig-v19-body.png")
const ANCHOR := Vector2(200,520)
const HEIGHT := 480.0
const STRIDE := 144.0
const HALF_STEP := 52.0
const STANCE := .6
const HIP := Vector2(190,335)
const KNEE := Vector2(184,397)
const ANKLE := Vector2(176,478)
const FAR_OFFSET := Vector2(12,-6)
const SHOULDER := Vector2(164,204)
const ELBOW := Vector2(159,278)
const WRIST := Vector2(177,334)
const FAR_SHOULDER := Vector2(210,200)
const THIGH := [Vector2(156,321),Vector2(212,321),Vector2(218,346),Vector2(216,369),Vector2(202,379),Vector2(198,400),Vector2(190,406),Vector2(174,404),Vector2(158,388)]
const CALF := [Vector2(168,386),Vector2(198,386),Vector2(198,402),Vector2(188,427),Vector2(183,450),Vector2(183,477),Vector2(170,483),Vector2(159,474),Vector2(151,454),Vector2(150,427),Vector2(157,407)]
const SHOE := [Vector2(145,486),Vector2(158,474),Vector2(174,473),Vector2(187,488),Vector2(213,493),Vector2(237,503),Vector2(239,513),Vector2(225,522),Vector2(192,525),Vector2(164,520),Vector2(144,510)]
const UPPER_ARM := [Vector2(146,184),Vector2(171,182),Vector2(194,199),Vector2(194,228),Vector2(179,251),Vector2(177,267),Vector2(174,283),Vector2(159,291),Vector2(145,279),Vector2(139,254),Vector2(137,229),Vector2(138,205)]
const FOREARM := [Vector2(145,268),Vector2(172,267),Vector2(181,295),Vector2(180,318),Vector2(189,334),Vector2(198,348),Vector2(198,360),Vector2(188,369),Vector2(175,372),Vector2(160,367),Vector2(153,356),Vector2(153,337),Vector2(150,315),Vector2(144,291)]
const TORSO := [Vector2(0,160),Vector2(400,160),Vector2(400,335),Vector2(0,335)]
const SOLE := [Vector2(148,506),Vector2(163,516),Vector2(192,520),Vector2(226,514),Vector2(235,505)]

static func foot(phase: float, strength := 1.0) -> Dictionary:
	var t := fposmod(phase,1.0)
	var x := 0.0
	var lift := 0.0
	var angle := 0.0
	if t<STANCE:
		x = lerpf(HALF_STEP,-HALF_STEP,t/STANCE)
		angle = lerpf(deg_to_rad(-7),0.0,smoothstep(0.0,.1,t))
		angle += deg_to_rad(11)*smoothstep(.42,STANCE,t)
	else:
		var u := (t-STANCE)/(1-STANCE)
		# Hermite tangents match stance velocity at lift-off and heel contact.
		var m := -2*HALF_STEP/STANCE*(1-STANCE)
		x = (2*u*u*u-3*u*u+1)*(-HALF_STEP)+(u*u*u-2*u*u+u)*m+(-2*u*u*u+3*u*u)*HALF_STEP+(u*u*u-u*u)*m
		lift = 13*sin(PI*u)
		angle = lerpf(deg_to_rad(11),deg_to_rad(-7),smoothstep(0,1,u))
	angle *= strength
	var sole_max := -1000.0
	for p in SOLE: sole_max = maxf(sole_max,(p-ANKLE).rotated(angle).y)
	var ankle := Vector2(lerpf(ANKLE.x,HIP.x+x,strength),520-sole_max-lift*strength)
	return {"ankle":ankle,"angle":angle,"stance":t<STANCE,"phase":t}

static func knee_for(hip: Vector2, ankle: Vector2) -> Vector2:
	var a := HIP.distance_to(KNEE)
	var b := KNEE.distance_to(ANKLE)
	var v := ankle-hip
	var d := clampf(v.length(),absf(a-b)+.001,a+b-.001)
	var direction := v.normalized()
	var along := (a*a-b*b+d*d)/(2*d)
	var off := sqrt(maxf(0,a*a-along*along))
	return hip+direction*along+Vector2(direction.y,-direction.x)*off

static func state(phase: float, strength := 1.0) -> Dictionary:
	var near := foot(phase,strength)
	var far := foot(phase+.5,strength)
	var support_length := lerpf(HIP.distance_to(ANKLE),HIP.distance_to(KNEE)+KNEE.distance_to(ANKLE)-.9,strength)
	var drop := 0.0
	for leg in [near,far]:
		var dx: float = leg.ankle.x-HIP.x
		var dy := sqrt(maxf(1,support_length*support_length-dx*dx))
		drop = maxf(drop,leg.ankle.y-dy-HIP.y)
	var root := Vector2(0,drop)
	for leg in [near,far]:
		leg.hip = HIP+root
		leg.knee = knee_for(leg.hip,leg.ankle)
	# Register the lowest projected sole to the same ground anchor.
	var near_sole := -1000.0
	var far_sole := -1000.0
	for p in SOLE:
		near_sole = maxf(near_sole,near.ankle.y+(p-ANKLE).rotated(near.angle).y)
		far_sole = maxf(far_sole,far.ankle.y+FAR_OFFSET.y+(p-ANKLE).rotated(far.angle).y)
	var ground := Vector2(0,520-maxf(near_sole,far_sole))
	root += ground
	for leg in [near,far]:
		leg.hip += ground
		leg.knee += ground
		leg.ankle += ground
	return {"root":root,"near":near,"far":far}

static func paint(canvas: CanvasItem, texture: Texture2D, points: Array, source_pivot: Vector2, target_pivot: Vector2, rotation: float, factor: float, tint := Color.WHITE, local_scale := 1.0) -> void:
	var vertices := PackedVector2Array()
	var uv := PackedVector2Array()
	for p: Vector2 in points:
		vertices.append((target_pivot+(p-source_pivot).rotated(rotation)*local_scale-ANCHOR)*factor)
		uv.append(p/texture.get_size())
	canvas.draw_polygon(vertices,PackedColorArray([tint]),uv,texture)

static func cap(canvas: CanvasItem, texture: Texture2D, source: Vector2, target: Vector2, radius: float, factor: float, tint: Color, local_scale := 1.0) -> void:
	var circle: Array[Vector2] = []
	for i in 16: circle.append(source+Vector2.from_angle(i*TAU/16)*radius)
	paint(canvas,texture,circle,source,target,0,factor,tint,local_scale)

static func leg(canvas: CanvasItem, pose: Dictionary, offset: Vector2, factor: float, tint: Color) -> void:
	var upper_rotation: float = (pose.knee-pose.hip).angle()-(KNEE-HIP).angle()
	var lower_rotation: float = (pose.ankle-pose.knee).angle()-(ANKLE-KNEE).angle()
	paint(canvas,CLOTH,THIGH,HIP,pose.hip+offset,upper_rotation,factor,tint)
	cap(canvas,CLOTH,KNEE,pose.knee+offset,10,factor,tint)
	paint(canvas,CLOTH,CALF,KNEE,pose.knee+offset,lower_rotation,factor,tint)
	paint(canvas,CLOTH,SHOE,ANKLE,pose.ankle+offset,pose.angle,factor,tint)

static func arm(canvas: CanvasItem, phase: float, root: Vector2, shoulder: Vector2, factor: float, strength: float, tint: Color) -> void:
	var depth := .82 if shoulder==FAR_SHOULDER else 1.0
	var desired_swing := -deg_to_rad(14)*cos(phase*TAU)
	var swing := lerpf(atan2((ELBOW-SHOULDER).x,(ELBOW-SHOULDER).y),desired_swing,strength)
	var lower_angle := lerpf(atan2((WRIST-ELBOW).x,(WRIST-ELBOW).y),desired_swing+deg_to_rad(12+3*sin(phase*TAU)),strength)
	var upper := Vector2(sin(swing),cos(swing))*SHOULDER.distance_to(ELBOW)*depth
	var elbow := shoulder+root+upper
	var upper_rotation := upper.angle()-(ELBOW-SHOULDER).angle()
	var lower_rotation := Vector2(sin(lower_angle),cos(lower_angle)).angle()-(WRIST-ELBOW).angle()
	var upper_tint := Color(tint.r,tint.g,tint.b,.1 if shoulder==FAR_SHOULDER else 1.0)
	paint(canvas,ORIGINAL,UPPER_ARM,SHOULDER,shoulder+root,upper_rotation,factor,upper_tint,depth)
	var skin_tint := Color(tint.r,tint.g,tint.b,.1)
	cap(canvas,ORIGINAL,ELBOW,elbow,11,factor,skin_tint,depth)
	paint(canvas,ORIGINAL,FOREARM,ELBOW,elbow,lower_rotation,factor,skin_tint,depth)

static func draw_pose(canvas: CanvasItem, distance: float, height: float, strength := 1.0) -> void:
	if not (canvas.material is ShaderMaterial and canvas.material.shader==SHADER):
		var ink := ShaderMaterial.new()
		ink.shader = SHADER
		canvas.material = ink
	var phase := distance/STRIDE
	var pose := state(phase,strength)
	var factor := height/HEIGHT
	leg(canvas,pose.far,FAR_OFFSET,factor,Color(.87,.87,.87,1))
	arm(canvas,phase+.5,pose.root,FAR_SHOULDER,factor,strength,Color(.86,.86,.86,1))
	leg(canvas,pose.near,Vector2.ZERO,factor,Color.WHITE)
	paint(canvas,CLOTH,TORSO,Vector2.ZERO,pose.root,0,factor)
	var head := [Vector2(0,0),Vector2(400,0),Vector2(400,180),Vector2(0,180)]
	paint(canvas,ORIGINAL,head,Vector2.ZERO,pose.root,0,factor)
	arm(canvas,phase,pose.root,SHOULDER,factor,strength,Color.WHITE)
