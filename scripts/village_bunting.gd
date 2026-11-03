extends Node2D
## Light paper decorations spanning the public shopping streets.
var span := Vector2(500,0)
func _draw() -> void:
	var points := PackedVector2Array()
	var colors := [Color("b96260"),Color("bd9a45"),Color("547e8d"),Color("82966b"),Color("d5c5a0")]
	for i in 41:
		var t := i/40.0
		points.append(span*t+Vector2(0,-280+sin(t*PI)*60))
	draw_polyline(points,Color("515d50"),2,true)
	for i in int(span.length()/48):
		var t := (i+.5)/(int(span.length()/48))
		var at := span*t+Vector2(0,-280+sin(t*PI)*60)
		draw_colored_polygon(PackedVector2Array([at-Vector2(12,0),at+Vector2(12,0),at+Vector2(3,28)]),colors[i%colors.size()])
