extends Node2D

var world_width := 1280.0
var clock := 0.0
var rng := RandomNumberGenerator.new()

func _process(delta: float) -> void:
	clock += delta
	queue_redraw()

func _draw() -> void:
	rng.seed = 681
	# The painting provides the near foliage; only a few drifting leaves overlay it.
	for i in int(world_width / 180.0):
		var x := fmod(i*113.7+clock*(10+i%3*4),world_width + 50)-25
		var y := 205+fmod(i*61.2+clock*(9+i%4),390)
		var center := Vector2(x+sin(clock*0.8+i)*17,y)
		var axis := Vector2(cos(clock+i),sin(clock+i))*4
		draw_line(center-axis,center+axis,Color(0.75,0.72,0.46,0.35),2.5,true)
	for i in int(world_width / 117.0):
		var center := Vector2(185+i*117+sin(clock*0.6+i)*10,502+sin(clock*0.9+i*2)*23)
		var alpha := (sin(clock*1.8+i*1.4)*0.5+0.5)*0.22
		draw_circle(center,5,Color(1,0.88,0.49,alpha*0.10))
		draw_circle(center,1.3,Color(1,0.93,0.65,alpha))
