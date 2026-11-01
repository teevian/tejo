extends RefCounted
## Continuous weathered granite, with ledges rooted in the central outcrop.
## Y in the authoring data points down, like the climbing simulation.
const CENTER := Vector2(640,0)
const CREST := 1320.0
const FOOT := 4720.0
const SIDES := 40
const Route = preload("res://scripts/climbing_route.gd")

static func surface(box: Dictionary, x: float, z: float) -> float:
	return Route.height_at(int(box.get("id",18)),float(box.left),float(box.right),float(box.y),float(box.slope),x,z)

static func mountain_center(y: float) -> Vector2:
	return CENTER+Vector2(sin(y*0.0031)*17,cos(y*0.0023)*14)

static func mountain_radius(y: float, angle: float) -> Vector2:
	var t := clampf((y-CREST)/(FOOT-CREST),0,1)
	var crown := sqrt(maxf(0.002,1-pow(1-clampf((y-CREST)/245,0,1),2)))
	var shape := 1+0.085*sin(angle*2+y*0.0017)+0.048*cos(angle*6-y*0.0029)+0.020*sin(angle*9+y*0.006)
	# Narrow, uneven joints separate broad rounded masses without opening holes.
	var joint := pow(0.5+0.5*cos(y*0.019+sin(angle*2.0)*1.2+sin(angle*5.0)*0.3),16)*0.075
	var bulge := 1+0.065*sin(y*0.008+angle*2)+0.035*cos(y*0.014-angle*4)
	return Vector2(410+85*t,395+75*t)*crown*(shape-joint)*bulge

static func mountain_point(y: float, angle: float) -> Vector3:
	var c := mountain_center(y)
	var r := mountain_radius(y,angle)
	return Vector3(c.x+cos(angle)*r.x,y,c.y+sin(angle)*r.y)

static func inside_mountain(point: Vector3) -> bool:
	if point.y<CREST or point.y>FOOT: return false
	var offset := Vector2(point.x,point.z)-mountain_center(point.y)
	var angle := offset.angle()
	var r := mountain_radius(point.y,angle)
	return pow(offset.x/r.x,2)+pow(offset.y/r.y,2)<1

static func mountain_mesh() -> ArrayMesh:
	var rings: Array[PackedVector3Array] = []
	for j in 97:
		var ring := PackedVector3Array()
		var y := lerpf(CREST,FOOT,float(j)/96)
		for i in 64: ring.append(mountain_point(y,TAU*i/64))
		rings.append(ring)
	return skin(rings,Vector3(640,CREST-5,0),Vector3(640,FOOT+10,0))

static func ledge_rings(box: Dictionary, seed: int, rooted := true) -> Array[PackedVector3Array]:
	var rings: Array[PackedVector3Array] = []
	var center := Vector2((float(box.left)+float(box.right))*0.5,(float(box.back)+float(box.front))*0.5)
	var radius := Vector2((float(box.right)-float(box.left))*0.5,(float(box.front)-float(box.back))*0.5)
	var height := float(box.height)
	if not rooted and int(box.get("id",18))<18:
		height *= 0.93+sin(seed*1.31)*0.12
	# Eroded lip, rounded shoulder, swollen body, and an inward-sloping buttress.
	var depths := [0.0,16.0,height*0.38,height*0.82,height+38,height+145,height+260]
	var scales := [1.0,1.035,1.0,0.91,0.75,0.60,0.42]
	if not rooted:
		depths = [0.0,9.0,height*0.28,height*0.60,height*0.90,height]
		scales = [1.0,1.035,1.10,1.08,0.75,0.16]
		if int(box.get("id",18))<18:
			match seed%4:
				0: scales = [1.0,1.025,1.02,0.97,0.82,0.64]
				1: scales = [1.0,1.025,1.08,1.02,0.72,0.32]
				2: scales = [1.0,1.035,1.03,0.96,0.79,0.55]
	for j in depths.size():
		var ring := PackedVector3Array()
		var root_mix := smoothstep(0.22,1.0,float(j)/(depths.size()-1)) if rooted else 0.0
		var c := center.lerp(CENTER,root_mix)
		if not rooted:
			c += Vector2(sin(seed*1.7)*13,cos(seed*1.1)*9)*sin(PI*j/(depths.size()-1))
			if int(box.get("id",18))<18:
				c += (CENTER-center)*float(j)/(depths.size()-1)*0.12
		for i in SIDES:
			var a := TAU*i/SIDES
			var cs := cos(a); var sn := sin(a)
			# A broad usable ridge, with rounded corners rather than six planar faces.
			var exponent := 0.65 if j<2 else 0.82
			var shape := Vector2(signf(cs)*pow(absf(cs),exponent),signf(sn)*pow(absf(sn),exponent))
			var irregular := (sin(a*3+seed*1.73)+sin(a*7-seed*0.61)*0.5)*0.045
			irregular -= pow(maxf(0,cos(a*2+seed*0.6)),16)*0.035
			var relief := 1+irregular*(0.35 if j==0 else 1.0)
			var r: Vector2 = radius*float(scales[j])*relief
			if rooted: r = r.lerp(Vector2(120,105),root_mix*0.8)
			var point := c+shape*r
			var plane := surface(box,point.x,point.y)
			var weathering := (sin(a*3+seed)+cos(a*2-seed*0.7))*minf(5,float(depths[j])*0.05)
			if not rooted and int(box.get("id",18))<18:
				weathering += sin(a+seed*1.9)*float(depths[j])*0.13
			ring.append(Vector3(point.x,plane+float(depths[j])+weathering,point.y))
		rings.append(ring)
	return rings

static func ledge_mesh(box: Dictionary, seed: int, rooted := true) -> ArrayMesh:
	var rings := ledge_rings(box,seed,rooted)
	var top := Vector3((float(box.left)+float(box.right))*0.5,0,(float(box.back)+float(box.front))*0.5)
	top.y = surface(box,top.x,top.z)
	var lid: Array[PackedVector3Array] = []
	for scale_value in [0.20,0.40,0.60,0.80]:
		var ring := PackedVector3Array()
		for outside in rings[0]:
			var point: Vector3 = top.lerp(outside,scale_value)
			point.y = surface(box,point.x,point.z)
			ring.append(point)
		lid.append(ring)
	var bottom := Vector3.ZERO
	for point in rings[-1]: bottom += point/SIDES
	lid.append_array(rings)
	return skin(lid,top,bottom,4)

static func boulder_mesh(radius: Vector3, seed: int, cleaved := false) -> ArrayMesh:
	var rings: Array[PackedVector3Array] = []
	for j in 17:
		var phi := lerpf(0.04,PI-0.04,float(j)/16)
		var ring := PackedVector3Array()
		for i in 32:
			var a := TAU*i/32
			var r := 1+0.085*sin(a*3+seed*1.7)*sin(phi)+0.04*cos(a*5-phi*4+seed)
			var x := cos(a)*sin(phi)*radius.x*r
			var z := sin(a)*sin(phi)*radius.z*r
			var y := -cos(phi)*radius.y*(1+0.025*sin(a*4+seed)*sin(phi))
			if cleaved:
				var point := Vector3(x/radius.x,y/radius.y,z/radius.z)
				for plane in [Vector3(0.68,0.18,0.71).normalized(),Vector3(-0.72,-0.13,0.68).normalized(),Vector3(0.30,0.44,-0.85).normalized()]:
					point -= plane*maxf(0,point.dot(plane)-0.82)
				x = point.x*radius.x; y = point.y*radius.y; z = point.z*radius.z
			ring.append(Vector3(x,y,z))
		rings.append(ring)
	return skin(rings,Vector3(0,-radius.y,0),Vector3(0,radius.y,0))

static func skin(rings: Array[PackedVector3Array], top: Vector3, bottom: Vector3, lid_rings := 0) -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	tool.set_smooth_group(0)
	var n := rings[0].size()
	for i in n:
		var next := (i+1)%n
		triangle(tool,top,rings[0][next],rings[0][i],Vector3.UP)
		for j in rings.size()-1:
			var center := (rings[j][i]+rings[j][next]+rings[j+1][i]+rings[j+1][next])*0.25
			var origin := (rings[j][0]+rings[j][n/2])*0.5
			var outward := Vector3(center.x-origin.x,0,center.z-origin.z).normalized()
			if j<lid_rings: outward = Vector3.UP
			triangle(tool,rings[j][i],rings[j][next],rings[j+1][i],outward)
			triangle(tool,rings[j][next],rings[j+1][next],rings[j+1][i],outward)
		triangle(tool,bottom,rings[-1][i],rings[-1][next],Vector3.DOWN)
	tool.index()
	tool.generate_normals()
	return tool.commit()

static func triangle(tool: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, expected: Vector3) -> void:
	# Godot uses clockwise front faces; generated normals must point out of the rock.
	a.y = -a.y; b.y = -b.y; c.y = -c.y
	if (b-a).cross(c-a).dot(expected)>0:
		var swap := b; b = c; c = swap
	for point in [a,b,c]: tool.add_vertex(point)
