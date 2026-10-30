extends Node2D
## Five authored viewpoints plus mirrored western views: genuine eight-way anatomy.
const REST_ATLAS: Texture2D = preload("res://assets/wildlife/forest-fauna-atlas.png")
const REST_REGIONS := [Rect2(630,640,260,225),Rect2(890,675,232,190)]
const REST_PIVOTS := [Vector2(152,205),Vector2(120,175)]
const TEXTURES := {
	"fox":preload("res://assets/wildlife/fox-directions.png"),
	"squirrel":preload("res://assets/wildlife/squirrel-directions.png"),
	"bird":preload("res://assets/wildlife/bird-directions.png"),
	"frog":preload("res://assets/wildlife/frog-directions.png"),
	"butterfly":preload("res://assets/wildlife/butterfly-directions.png")
}
const DATA := {
	"fox":preload("res://assets/wildlife/fox-directions.json"),
	"squirrel":preload("res://assets/wildlife/squirrel-directions.json"),
	"bird":preload("res://assets/wildlife/bird-directions.json"),
	"frog":preload("res://assets/wildlife/frog-directions.json"),
	"butterfly":preload("res://assets/wildlife/butterfly-directions.json")
}
const SCALES := {"fox":0.30,"squirrel":0.14,"bird":0.095,"frog":0.08,"butterfly":0.065}
var animal: Node2D

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR

static func direction_index(facing: Vector2) -> int:
	return posmod(roundi((facing.angle()+PI/2)/(PI/4)),8)

func pose_frame() -> int:
	var time: float = animal.ecosystem.elapsed+animal.phase
	match animal.species:
		"fox":
			if animal.state in ["bound","pounce"]: return 3
			if animal.velocity.length()>3:
				return [1,2,3,2][int(animal.gait_distance/30)%4] if animal.state in ["flee","chase","dash"] else int(animal.gait_distance/26)%2
		"squirrel":
			if animal.state=="startled": return 3
			if animal.state in ["climb","descend"]: return 1+int(time*10)%2
			if animal.velocity.length()>3: return [1,2,1,3][int(animal.gait_distance/22)%4]
		"bird":
			if animal.state in ["fly","land"]: return [1,2,3,2][int(time*12)%4]
		"frog":
			if animal.state=="hop": return 1 if animal.state_time<0.36 else 2
			if animal.state=="surface": return 3
		"butterfly":
			return 3 if animal.state in ["nectar","rest"] else [0,1,2,1][int(time*16)%4]
	return 0

func sprite_spec() -> Dictionary:
	var direction := direction_index(animal.facing)
	if animal.species=="squirrel" and animal.state in ["climb","descend"]:
		direction = 0 if animal.state=="climb" else 4
	var column := direction if direction<=4 else 8-direction
	var frame := pose_frame()
	var index := frame*5+column
	var data: Dictionary = DATA[animal.species].data
	var region: Array = data.regions[index]
	var pivot: Array = data.pivots[index]
	return {"texture":TEXTURES[animal.species],"region":Rect2(region[0],region[1],region[2],region[3]),
		"pivot":Vector2(pivot[0],pivot[1]),"scale":SCALES[animal.species],"flip":direction>4,"direction":direction,"frame":frame}

func _draw() -> void:
	# Retain the specific drinking and curled sleeping poses, which do not locomote.
	if animal.species=="fox" and animal.state in ["drink","sniff","sleep"]:
		var old_frame := 1 if animal.state=="sleep" else 0
		var region: Rect2 = REST_REGIONS[old_frame]
		var pivot: Vector2 = REST_PIVOTS[old_frame]
		draw_set_transform(Vector2(0,sin(animal.ecosystem.elapsed*3)*0.5),0,Vector2(-1 if animal.facing.x<0 else 1,1))
		draw_texture_rect_region(REST_ATLAS,Rect2(-pivot*0.29,region.size*0.29),region,Color.WHITE,false,true)
		draw_set_transform(Vector2.ZERO)
		return
	var spec := sprite_spec()
	var bob := 0.0
	var tilt := 0.0
	var time: float = animal.ecosystem.elapsed+animal.phase
	if animal.species=="bird":
		tilt = sin(time*4)*0.045 if animal.state=="fly" else 0.0
		bob = sin(time*2)*0.3
	elif animal.species=="butterfly":
		tilt = sin(time*2.8)*0.16
	elif animal.species=="squirrel" and animal.state=="forage":
		tilt = sin(time*5)*0.018
	elif animal.species=="fox" and animal.state=="watch":
		tilt = sin(time*1.6)*0.012
	var scale_value: float = spec.scale
	var region: Rect2 = spec.region
	var pivot: Vector2 = spec.pivot
	draw_set_transform(Vector2(0,bob),tilt,Vector2(-1 if spec.flip else 1,1))
	draw_texture_rect_region(spec.texture,Rect2(-pivot*scale_value,region.size*scale_value),region,Color.WHITE,false,true)
	draw_set_transform(Vector2.ZERO)
