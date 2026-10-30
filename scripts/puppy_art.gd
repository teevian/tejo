extends RefCounted
const ATLAS: Texture2D = preload("res://assets/puppy/capuchos-puppy.png")
const DATA = preload("res://assets/puppy/capuchos-puppy.json")
const EXPRESSIONS := {
	"angry":preload("res://assets/puppy/capuchos-puppy-angry.png"),
	"wary":preload("res://assets/puppy/capuchos-puppy-wary.png"),
	"trusted":ATLAS}
const EXPRESSION_DATA := {
	"angry":preload("res://assets/puppy/capuchos-puppy-angry.json"),
	"wary":preload("res://assets/puppy/capuchos-puppy-wary.json"),
	"trusted":DATA}
const FOOD := {"type":"dog_food","name":"Ração para cachorro","porte":1,"art":6}

static func region(index: int) -> Rect2:
	var bounds: Array = DATA.data.regions[index]
	return Rect2(bounds[0],bounds[1],bounds[2],bounds[3])

static func expression(puppy: Node2D) -> String:
	if puppy.friendly or puppy.trust>=.60: return "trusted"
	return "angry" if puppy.trust<.22 else "wary"

static func pose_index(puppy: Node2D) -> int:
	var index := 0
	var moving: bool = puppy.velocity.length()>5
	var frame := 1+int(puppy.gait/17)%2 if moving else 0
	if absf(puppy.facing.y)>absf(puppy.facing.x)*1.2:
		index = (8 if puppy.facing.y<0 else 4)+frame
	else:
		index = frame
	if puppy.state in ["bark","chase_jo","nip"]: index = 3
	elif puppy.state=="sniff": index = 7
	elif puppy.state=="eat": index = 11
	elif puppy.state=="invite": index = 12
	elif puppy.state=="happy": index = 13
	elif puppy.state=="pet": index = 14
	return index

static func sprite_spec(puppy: Node2D) -> Dictionary:
	var mood := expression(puppy)
	var index := pose_index(puppy)
	var data: Dictionary = EXPRESSION_DATA[mood].data
	var bounds: Array = data.regions[index]
	return {"texture":EXPRESSIONS[mood],"region":Rect2(bounds[0],bounds[1],bounds[2],bounds[3]),
		"scale":64.0/float(data.reference_height),"flip":puppy.facing.x<0,"mood":mood,"frame":index}

static func draw_pose(canvas: CanvasItem, puppy: Node2D) -> void:
	var spec := sprite_spec(puppy)
	var rect: Rect2 = spec.region
	var scale_value: float = spec.scale
	var pivot := Vector2(rect.size.x*.5,rect.size.y-3)
	var hop: float = -sin(clampf(puppy.state_time/.32,0,1)*PI)*15 if puppy.state=="nip" else 0.0
	canvas.draw_set_transform(Vector2(0,hop),0,Vector2(-1 if spec.flip else 1,1))
	canvas.draw_texture_rect_region(spec.texture,Rect2(-pivot*scale_value,rect.size*scale_value),rect)
	canvas.draw_set_transform(Vector2.ZERO)

static func draw_portrait(canvas: CanvasItem, puppy: Node2D, box: Rect2) -> void:
	var mood := expression(puppy)
	var bounds: Array = EXPRESSION_DATA[mood].data.regions[4]
	# Same actual face as the in-world south-facing pose, enlarged for readability.
	var source := Rect2(bounds[0],bounds[1]+bounds[3]*.24,bounds[2],bounds[3]*.59)
	var factor := minf(box.size.x/source.size.x,box.size.y/source.size.y)
	canvas.draw_texture_rect_region(EXPRESSIONS[mood],Rect2(box.get_center()-source.size*factor*.5,source.size*factor),source)

static func draw_food(canvas: CanvasItem, box: Rect2) -> void:
	var rect := region(15)
	var scale_value := minf(box.size.x/rect.size.x,box.size.y/rect.size.y)
	canvas.draw_texture_rect_region(ATLAS,Rect2(box.get_center()-rect.size*scale_value*.5,rect.size*scale_value),rect)
