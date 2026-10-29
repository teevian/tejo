extends RefCounted
# Five authored viewpoints, mirrored to eight directions. The same painted anatomy
# is articulated through eight gait keys, interpolated continuously, not redrawn.
const ATLASES: Array[Texture2D] = [preload("res://assets/characters/open_world/te-walk-v2.png"),preload("res://assets/characters/open_world/jo-walk-v2.png")]
const SCALE := 0.48 # Phone art compatibility; walking has its own fixed stature.
const HEIGHTS := [186.0,182.0]
const STRIDE := 176.0
const GAIT_FRAMES := 8
const TE: Array[Rect2] = [Rect2(22,16,115,211),Rect2(26,246,108,212),Rect2(35,470,93,217),Rect2(22,690,124,216),Rect2(22,916,115,211)]
const JO: Array[Rect2] = [Rect2(35,36,113,219),Rect2(37,264,109,214),Rect2(49,481,85,224),Rect2(37,707,112,208),Rect2(36,919,114,207)]
# Contact / down / passing / up, then the other leg. Continuous interpolation
# preserves the phase when turning, so a direction change never restarts a step.
const SWING := [0.0,0.7071,1.0,0.7071,0.0,-0.7071,-1.0,-0.7071]
static func direction_row(facing: Vector2) -> int:
	var angle := atan2(absf(facing.x),facing.y)
	return clampi(roundi(angle/(PI/4.0)),0,4)
static func gait_sample(phase: float) -> float:
	var cell := fposmod(phase,TAU)/TAU*GAIT_FRAMES
	var index := int(cell)
	var t := cell-float(index)
	# Cubic Hermite tangents keep velocity continuous at every key, including wrap.
	var a: float = SWING[index]
	var b: float = SWING[(index+1)%8]
	var m0: float = (b-SWING[(index+7)%8])*0.5
	var m1: float = (SWING[(index+2)%8]-a)*0.5
	return (2*t*t*t-3*t*t+1)*a+(t*t*t-2*t*t+t)*m0+(-2*t*t*t+3*t*t)*b+(t*t*t-t*t)*m1
static func deform(uv: Vector2, size: Vector2, phase: float, row: int, amount: float) -> Vector2:
	var point := Vector2((uv.x-0.5)*size.x,(uv.y-1.0)*size.y)
	var right_view := sin(float(row)*PI/4.0)
	var depth_view := cos(float(row)*PI/4.0)
	var side := -1.0 if uv.x<0.5 else 1.0
	var cycle := phase+(PI if side>0 else 0.0)
	var swing := gait_sample(cycle)*amount
	var lift := maxf(0.0,cos(cycle))*amount
	# Pelvis and head stay fixed in size. Only rigid-length limb trajectories move.
	if uv.y>0.62:
		var leg := clampf((uv.y-0.62)/0.32,0,1)
		var knee := smoothstep(0.0,0.55,leg)
		var ankle := smoothstep(0.45,1.0,leg)
		point.x += right_view*swing*(14.0*knee+17.0*ankle)
		point.y += depth_view*swing*(4.0*knee+9.0*ankle)-lift*(3.0*knee+5.0*ankle)
		# Heel-to-toe roll rotates the painted shoe as a unit, rather than resizing it.
		if uv.y>0.94:
			point.y += (uv.x-0.5)*right_view*swing*3.0
	elif uv.y>0.30:
		var edge := smoothstep(0.20,0.40,absf(uv.x-0.5))
		var arm := smoothstep(0.30,0.62,uv.y)*edge
		point.x -= right_view*swing*9.0*arm
		point.y -= depth_view*swing*6.0*arm
	# A two-pixel vertical weight transfer affects the whole figure, never its scale.
	point.y -= (1.0-cos(phase*2.0))*0.65*amount
	return point
static func draw_pose(canvas: CanvasItem, kind: int, facing: Vector2, moving: bool, distance: float, weight := -1.0) -> void:
	var row := direction_row(facing)
	var region := TE[row] if kind==0 else JO[row]
	# One isotropic calibration for each authored view, shared by every gait phase.
	var size := region.size*(HEIGHTS[kind]/region.size.y)
	var amount := (1.0 if moving else 0.0) if weight<0 else weight
	var phase := fposmod(distance/STRIDE*TAU,TAU)
	var vertices := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	const COLS := 18
	const ROWS := 32
	for y in range(ROWS+1):
		for x in range(COLS+1):
			var uv := Vector2(float(x)/COLS,float(y)/ROWS)
			var point := deform(uv,size,phase,row,amount)
			if facing.x<0:
				point.x = -point.x
			vertices.append(Vector3(point.x,point.y,0))
			uvs.append((region.position+uv*region.size)/ATLASES[kind].get_size())
			if x<COLS and y<ROWS:
				var a := y*(COLS+1)+x
				indices.append_array(PackedInt32Array([a,a+1,a+COLS+1,a+1,a+COLS+2,a+COLS+1]))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX]=vertices
	arrays[Mesh.ARRAY_TEX_UV]=uvs
	arrays[Mesh.ARRAY_INDEX]=indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	canvas.draw_mesh(mesh,ATLASES[kind])
