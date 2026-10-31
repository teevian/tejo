extends Node2D
## Painted atlas components; head yaw changes the view, never spins a flat face.
const BAT: Texture2D = preload("res://assets/wildlife/bat-flight.png")
const OWL: Texture2D = preload("res://assets/wildlife/owl-modules.png")
const SNAKE: Texture2D = preload("res://assets/wildlife/snake-slither.png")
const SNAKE_REGIONS := [Rect2(26,291,494,215),Rect2(528,277,547,204),Rect2(1098,282,512,220),Rect2(1621,266,526,206)]
const EYE_SHADER = preload("res://shaders/owl_eyes.gdshader")
const EYE_POINTS := [[Vector2(988,264)],[Vector2(1440,284)],[Vector2(1878,273)],[Vector2(193,623),Vector2(283,621)],[Vector2(649,621),Vector2(716,616)],[Vector2(1072,619)],[Vector2(1458,628)],[]]
const BAT_REGIONS := [Rect2(68,63,316,363),Rect2(390,192,560,225),Rect2(945,256,406,235),Rect2(1395,182,331,230),Rect2(50,488,338,295),Rect2(382,586,598,185),Rect2(967,619,415,202),Rect2(1408,536,328,236)]
const BAT_PIVOTS := [Vector2(206,292),Vector2(307,158),Vector2(235,59),Vector2(198,155),Vector2(175,216),Vector2(307,107),Vector2(212,81),Vector2(189,157)]
const OWL_REGIONS := [Rect2(52,161,240,316),Rect2(355,160,226,338),Rect2(650,19,378,466),Rect2(1013,104,589,366),Rect2(1550,207,412,291),Rect2(101,516,268,245),Rect2(485,516,250,239),Rect2(852,514,269,241),Rect2(1232,518,236,227),Rect2(1611,518,247,222)]
const OWL_FLIGHT_PIVOTS := [Vector2(230,340),Vector2(375,245),Vector2(275,140)]
static var flight_outlines: Dictionary = {}
var animal: Node2D

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	if animal.species=="owl":
		var eyes := ShaderMaterial.new()
		eyes.shader = EYE_SHADER
		material = eyes

func eye_points() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if animal.state in ["shelter","hidden"]: return result
	if animal.state=="watch":
		var yaw: float = absf(animal.head_yaw)/PI*4
		var frame := mini(4,floori(yaw))
		for sample in 2:
			var index := mini(4,frame+sample)
			var weight := 1.0-(yaw-frame) if sample==0 else yaw-frame
			if weight<0.01: continue
			var region: Rect2 = OWL_REGIONS[5+index]
			var pivot := Vector2(region.size.x*0.5,region.size.y-10)
			for point in EYE_POINTS[3+index]:
				var at: Vector2 = (point-region.position-pivot)*0.085
				if animal.head_yaw>0: at.x = -at.x
				result.append({"position":at+Vector2(0,-32),"weight":weight,"radius":0.85 if index in [0,1] else 0.65})
	else:
		var frame: int = [0,1,2,1][int((animal.ecosystem.elapsed+animal.phase)*6)%4]
		var at: Vector2 = (EYE_POINTS[frame][0]-OWL_REGIONS[2+frame].position-OWL_FLIGHT_PIVOTS[frame])*0.105
		if animal.facing.x<0: at.x = -at.x
		at = at.rotated(animal.facing.y*0.15)
		result.append({"position":at,"weight":1.0,"radius":0.75})
	return result

func _part(texture: Texture2D, region: Rect2, pivot: Vector2, size: float, at := Vector2.ZERO, flip := false, opacity := 1.0, tilt := 0.0) -> void:
	draw_set_transform(at,tilt,Vector2(-1 if flip else 1,1))
	draw_texture_rect_region(texture,Rect2(-pivot*size,region.size*size),region,Color(1,1,1,opacity),false,true)
	draw_set_transform(Vector2.ZERO)

func _owl_flight(frame: int, flip: bool, tilt: float) -> void:
	var region: Rect2 = OWL_REGIONS[2+frame]
	if not flight_outlines.has(frame):
		# The generated sheet is irregular: neighboring bounding boxes overlap.
		# Draw the original pixels within this silhouette, excluding neighboring feathers.
		var source := OWL.get_image()
		if source.is_compressed(): source.decompress()
		var mask := BitMap.new()
		mask.create_from_image_alpha(source.get_region(Rect2i(region)),0.03)
		var largest := PackedVector2Array()
		var largest_area := 0.0
		for polygon in mask.opaque_to_polygons(Rect2i(Vector2i.ZERO,Vector2i(region.size)),0.5):
			var bounds := Rect2(polygon[0],Vector2.ZERO)
			for point in polygon: bounds = bounds.expand(point)
			if bounds.get_area()>largest_area:
				largest_area = bounds.get_area()
				largest = polygon
		var vertices := PackedVector2Array()
		var uvs := PackedVector2Array()
		for point in largest:
			vertices.append((point-OWL_FLIGHT_PIVOTS[frame])*0.105)
			uvs.append((region.position+point)/OWL.get_size())
		flight_outlines[frame] = {"vertices":vertices,"uvs":uvs}
	var shape: Dictionary = flight_outlines[frame]
	draw_set_transform(Vector2.ZERO,tilt,Vector2(-1 if flip else 1,1))
	draw_polygon(shape.vertices,PackedColorArray([Color.WHITE]),shape.uvs,OWL)
	draw_set_transform(Vector2.ZERO)

func _draw() -> void:
	var time: float = animal.ecosystem.elapsed+animal.phase
	match animal.species:
		"bat":
			var frame := int(time*15)%4
			if absf(animal.facing.y)>absf(animal.facing.x): frame += 4
			var tilt := clampf(animal.facing.y*0.25,-0.25,0.25) if frame<4 else 0.0
			_part(BAT,BAT_REGIONS[frame],BAT_PIVOTS[frame],0.064,Vector2.ZERO,animal.facing.x<0,1.0,tilt)
		"owl":
			if animal.state in ["watch","shelter"]:
				_part(OWL,OWL_REGIONS[0],Vector2(118,316),0.105)
				var yaw: float = absf(animal.head_yaw)/PI*4
				var frame := mini(4,floori(yaw))
				var blend := yaw-frame
				var region: Rect2 = OWL_REGIONS[5+frame]
				var neck := Vector2(0,-32)
				_part(OWL,region,Vector2(region.size.x*0.5,region.size.y-10),0.085,neck,animal.head_yaw>0,1.0-blend)
				if blend>0.001 and frame<4:
					region = OWL_REGIONS[6+frame]
					_part(OWL,region,Vector2(region.size.x*0.5,region.size.y-10),0.085,neck,animal.head_yaw>0,blend)
			else:
				var frame: int = [0,1,2,1][int(time*6)%4]
				_owl_flight(frame,animal.facing.x<0,animal.facing.y*0.15)
		"firefly":
			# Body stays within world depth; the occlusion-tested light is emitted above grading.
			draw_circle(Vector2.ZERO,1.0,Color(0.47,0.48,0.20,animal.glow))
		"snake":
			var frame := int(animal.gait_distance/9)%4 if animal.velocity.length()>1 else 0
			var region: Rect2 = SNAKE_REGIONS[frame]
			_part(SNAKE,region,region.size*0.5,0.12,Vector2.ZERO,false,1.0,animal.facing.angle())
