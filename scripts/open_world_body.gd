extends Node2D
const Art = preload("res://scripts/open_world_art.gd")
const PhoneArt = preload("res://scripts/jo_phone_art.gd")
var person: CharacterBody2D

func _ready() -> void:
	# Generated cutouts contain some translucent paint. Keep solid paint opaque,
	# while retaining empty pixels and a narrow antialiased silhouette edge.
	var ink := ShaderMaterial.new()
	ink.shader = preload("res://shaders/opaque_cutout.gdshader")
	material = ink

func _draw() -> void:
	if not is_instance_valid(person):
		return
	if person.kind == 1 and person.phone_state != person.PhoneState.NONE and not person.moving:
		var frame := 0
		match person.phone_state:
			person.PhoneState.TAKING_OUT: frame = mini(3,int(person.phone_time/0.72*4))
			person.PhoneState.READING: frame = 4+int(person.phone_time*2)%4
			person.PhoneState.PUTTING_AWAY: frame = mini(3,int(person.phone_stow_start*(1-clampf(person.phone_time/0.36,0,1))*4))
		var factor := Art.SCALE/0.32*0.66
		draw_set_transform(Vector2.ZERO,0,Vector2.ONE*factor)
		PhoneArt.draw_pose(self,frame)
		draw_set_transform(Vector2.ZERO)
	else:
		Art.draw_pose(self,person.kind,person.visual_facing,person.moving,person.walked,person.gait_weight)
